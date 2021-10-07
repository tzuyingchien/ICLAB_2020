//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_addsub.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
//synopsys translate_on


module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_d,
	in_valid_t,
	in_valid_w1,
	in_valid_w2,
	data_point,
	target,
	weight1,
	weight2,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;


parameter 	IDLE		= 3'd0,
			INPUT_W		= 3'd1,
			IDLE_2		= 3'd2,
			INPUT_D 	= 3'd3,
			CAL_H_1st	= 3'd4,
			CAL_ERR		= 3'd5,
			OUTPUT 		= 3'd6; // back to IDLE when finish 2500 round (unsetting)

			

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
input [inst_sig_width+inst_exp_width:0] data_point, target;
input [inst_sig_width+inst_exp_width:0] weight1, weight2;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [2:0] 	cs;
reg [31:0] 	w1 [11:0];
reg [31:0]	w2 [2:0];
reg [31:0]	data[3:0];
reg [31:0]	t;
reg [31:0] 	y1[2:0];//y1,0, y1,1, y1,2
reg [31:0] 	err_1[2:0];
reg [31:0] 	err_2;
reg [31:0] 	ans;//y2,0

reg [3:0]	cnt_in;
reg [3:0] 	cnt_cal;
reg [11:0]	cnt_turn;
reg [3:0] 	i;
reg [1:0]	j, idx, idy;
reg [2:0]	k;

wire [31:0] mul_out_0, mul_out_1, mul_out_2, mul_out_3;
reg [31:0] mul_in_0, mul_in_1, mul_in_2, mul_in_3, mul_in_4, mul_in_5, mul_in_6, mul_in_7;
reg [31:0] add_a, add_b, add_c, add_d, add_e, add_f, add_g, add_h;
wire [31:0] add_out_0, add_out_1, add_out_2, add_out_3;

//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cs <= 0;
	end
	else begin
		case(cs)
			IDLE		:	cs <= in_valid_w1		? INPUT_W	: cs;			
            INPUT_W		:	cs <= (cnt_in == 4'd12)	? IDLE_2	: cs;
			IDLE_2		:	cs <= in_valid_d		? INPUT_D	: cs;
			INPUT_D 	:	cs <= (cnt_in == 4'd4)	? CAL_H_1st	: cs;
			CAL_H_1st	:	cs <= (cnt_cal == 4'd7)	? CAL_ERR : cs;
			CAL_ERR		: 	cs <= (cnt_cal == 4'd8) ? OUTPUT : cs;
			OUTPUT	    :	cs <= (cnt_turn == 12'd2500) ? IDLE : IDLE_2;//unfinished
		endcase
	end
end
//---------------------------------------------------------------------
//   INPUT_W
//---------------------------------------------------------------------
//input weight1----------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(i = 0; i < 12; i = i + 1) begin
			w1[i] <= 0;
		end
	end
	else begin
		if(in_valid_w1) begin
			w1[cnt_in] <= weight1;
		end
		else if (cs == IDLE) begin
			for(i = 0; i < 12; i = i + 1) begin
				w1[i] <= 0;
			end
		end
		else if(cs == CAL_ERR) begin
			case(cnt_cal)
				4'd6:	begin
							w1[0] <= add_out_0;
							w1[1] <= add_out_1;							
							w1[2] <= add_out_2;
							w1[3] <= add_out_3;
						end
				4'd7:	begin
							w1[4] <= add_out_0;
							w1[5] <= add_out_1;							
							w1[6] <= add_out_2;
							w1[7] <= add_out_3;
						end
				4'd8:	begin
							w1[8]  <= add_out_0;
							w1[9]  <= add_out_1;							
							w1[10] <= add_out_2;
							w1[11] <= add_out_3;
						end
				default:begin
							for(i = 0; i < 12; i = i + 1) begin
								w1[i] <= w1[i];
							end
						end
			endcase
		end
		else begin
			for(i = 0; i < 12; i = i + 1) begin
				w1[i] <= w1[i];
			end
		end
	end
end
//input weight2----------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(j = 0; j < 3; j = j + 1) begin
			w2[j] <= 0;
		end
	end
	else begin
		if(in_valid_w2) begin
			w2[cnt_in] <= weight2;
		end
		else if(cs == CAL_ERR) begin
			case(cnt_cal) 
				4'd3:	begin
							w2[0] <= add_out_0;
							w2[1] <= add_out_1;
							w2[2] <= add_out_2;
						end
				default:begin
							w2[0] <= w2[0];
							w2[1] <= w2[1];
							w2[2] <= w2[2];
						end
			endcase
		end
		else if (cs == IDLE) begin
			for(j = 0; j < 3; j = j + 1) begin
				w2[j] <= 0;
			end
		end
		else begin
			for(j = 0; j < 3; j = j + 1) begin
				w2[j] <= w2[j];
			end
		end
	end
end
//---------------------------------------------------------------------
//   INPUT_W : cnt_in
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_in <= 0;
	end
	else begin
		if(in_valid_w1 || in_valid_d) begin
			cnt_in <= cnt_in + 1;
		end
		else if (cs == IDLE_2 || cs == IDLE) begin
			cnt_in <= 0;
		end
		else begin
			cnt_in <= cnt_in;
		end
	end
end
//---------------------------------------------------------------------
//   INPUT_D
//---------------------------------------------------------------------
// input data------------------------------
 always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(k = 0; k <= 3; k = k + 1) begin
			data[k] <= 0;
		end
	end
	else begin
		if(in_valid_d) begin
			data[cnt_in] <= data_point;
		end
		else if(cs == OUTPUT) begin
			for(k = 0; k <= 3; k = k + 1) begin
				data[k] <= 0;
			end
		end
		else begin
			for(k = 0; k <= 3; k = k + 1) begin
				data[k] <= data[k];
			end		
		end
	end
end
//input target-----------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		t <= 0;
	end
	else begin
		if(in_valid_t) t <= {!target[31], target[30:0]};//save as -target
		else if(cs == OUTPUT) t <= 0;
		else t <= t;
	end
end

//---------------------------------------------------------------------
//   MUTIPLIER
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		mul_in_0 <= 0;
        mul_in_1 <= 0;
	    mul_in_2 <= 0;
	    mul_in_3 <= 0;
	end
	else begin
		if(cs == CAL_H_1st) begin
			case(cnt_cal)
				3'd0:	begin
							mul_in_0 <= w1[0];
							mul_in_1 <= data[0];
							mul_in_2 <= w1[1];
							mul_in_3 <= data[1];
							mul_in_4 <= w1[2];
							mul_in_5 <= data[2];
							mul_in_6 <= w1[3];
							mul_in_7 <= data[3];
						end
				3'd1:	begin
							mul_in_0 <= w1[4];
							mul_in_1 <= data[0];
							mul_in_2 <= w1[5];
							mul_in_3 <= data[1];
							mul_in_4 <= w1[6];
							mul_in_5 <= data[2];
							mul_in_6 <= w1[7];
							mul_in_7 <= data[3];
						end
				3'd2:	begin
							mul_in_0 <= w1[8];
							mul_in_1 <= data[0];
							mul_in_2 <= w1[9];
							mul_in_3 <= data[1];
							mul_in_4 <= w1[10];
							mul_in_5 <= data[2];
							mul_in_6 <= w1[11];
							mul_in_7 <= data[3];
						end
						
				3'd3:	begin 
							//cal w2,00 * y1,0
							mul_in_0 <= w2[0];
							mul_in_1 <= add_out_2[31] ? 0 : add_out_2;
							//cal 0.001 * d0/d1/d2 (for update W1,..)
							mul_in_2 <= 32'h3A83126F;
							mul_in_3 <= data[0];
							mul_in_4 <= 32'h3A83126F;
							mul_in_5 <= data[1];
							mul_in_6 <= 32'h3A83126F;
							mul_in_7 <= data[2];
						end
				3'd4:	begin 
							//cal w2,01 * y1,1
							mul_in_0 <= w2[1];
							mul_in_1 <= add_out_2[31] ? 0 : add_out_2;
							//cal 0.001 * y1,0
							
 							//cal 0.001 * d3 (for update W1,..)
							mul_in_4 <= 32'h3A83126F;
							mul_in_5 <= data[3];
						end
				3'd5:	begin //cal w2,02 * y1,2
							mul_in_0 <= w2[2];
							mul_in_1 <= add_out_2[31] ? 0 : add_out_2;
							
						end
				default:begin
							mul_in_0 <= mul_in_0; 
							mul_in_1 <= mul_in_1; 
							mul_in_2 <= mul_in_2; 
							mul_in_3 <= mul_in_3; 
							mul_in_4 <= mul_in_4; 
							mul_in_5 <= mul_in_5; 
							mul_in_6 <= mul_in_6; 
							mul_in_7 <= mul_in_7; 		
						end
			endcase
		end
		else if (cs == CAL_ERR) begin
			case(cnt_cal)
				4'd0:	begin//cal 0.001 * err2
							mul_in_0 <= 32'h3A83126F;
							mul_in_1 <= add_out_1;
							//cal g'(h1) * w2
							mul_in_2 <= y1[0] ? 32'h3f800000 : 32'h0;
							mul_in_3 <= w2[0];
							mul_in_4 <= y1[1] ? 32'h3f800000 : 32'h0; 
							mul_in_5 <= w2[1]; 
							mul_in_6 <= y1[2] ? 32'h3f800000 : 32'h0; 
							mul_in_7 <= w2[2]; 									
						end
				4'd1:	begin//cal 0.001 * err_2 * y1,0 / y1,1 / y1,2
							mul_in_0 <= mul_out_0;
							mul_in_1 <= y1[0];
							mul_in_2 <= mul_out_0;
							mul_in_3 <= y1[1];
							mul_in_4 <= mul_out_0;
							mul_in_5 <= y1[2];
						end
				4'd2:	begin
							//cal w2 * err2
							mul_in_0 <= y1[0] ? w2[0] : 32'h0;
							mul_in_1 <= err_2;
							mul_in_2 <= y1[1] ? w2[1] : 32'h0;
							mul_in_3 <= err_2;
							mul_in_4 <= y1[2] ? w2[2] : 32'h0;
							mul_in_5 <= err_2;
						end
				4'd3:	begin
							//cal 0.001 * err1
							mul_in_0 <= 32'h3A83126F;
							mul_in_1 <= mul_out_0;
							mul_in_2 <= 32'h3A83126F;
							mul_in_3 <= mul_out_1;
							mul_in_4 <= 32'h3A83126F;
							mul_in_5 <= mul_out_2;
						end
				4'd4:	begin//cal err1,0 * d0/1/2/3
							mul_in_0 <= mul_out_0;
							mul_in_1 <= data[0];
							mul_in_2 <= mul_out_0;
							mul_in_3 <= data[1];
							mul_in_4 <= mul_out_0;
							mul_in_5 <= data[2];
							mul_in_6 <= mul_out_0;
							mul_in_7 <= data[3];
						end
				4'd5:	begin//cal err1,1 * d0/1/2/3
							mul_in_0 <= err_1[1];
							mul_in_1 <= data[0];
							mul_in_2 <= err_1[1];
							mul_in_3 <= data[1];
							mul_in_4 <= err_1[1];
							mul_in_5 <= data[2];
							mul_in_6 <= err_1[1];
							mul_in_7 <= data[3];
						end
				4'd6:	begin//cal err1,2 * d0/1/2/3
							mul_in_0 <= err_1[2];
							mul_in_1 <= data[0];
							mul_in_2 <= err_1[2];
							mul_in_3 <= data[1];
							mul_in_4 <= err_1[2];
							mul_in_5 <= data[2];
							mul_in_6 <= err_1[2];
							mul_in_7 <= data[3];
						end		 
				default:begin
							mul_in_0 <= mul_in_0; 
							mul_in_1 <= mul_in_1; 
							mul_in_2 <= mul_in_2; 
							mul_in_3 <= mul_in_3; 
							mul_in_4 <= mul_in_4; 
							mul_in_5 <= mul_in_5; 
							mul_in_6 <= mul_in_6; 
							mul_in_7 <= mul_in_7; 		
						end
			endcase 
		end
		else if(cs == OUTPUT) begin
			mul_in_0 <= 0; 
			mul_in_1 <= 0; 
			mul_in_2 <= 0; 
			mul_in_3 <= 0; 
			mul_in_4 <= 0; 
			mul_in_5 <= 0;
			mul_in_6 <= 0; 
			mul_in_7 <= 0;
		end
		else begin
			mul_in_0 <= mul_in_0; 
			mul_in_1 <= mul_in_1; 
			mul_in_2 <= mul_in_2; 
			mul_in_3 <= mul_in_3; 
			mul_in_4 <= mul_in_4; 
			mul_in_5 <= mul_in_5;
			mul_in_6 <= mul_in_6; 
			mul_in_7 <= mul_in_7; 		
		end
	end
end
					
					
					
					
					
//---------------------------------------------------------------------
//   DESIGNWARE
//---------------------------------------------------------------------
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
U1 ( .a(mul_in_0), .b(mul_in_1), .rnd(3'b100), .z(mul_out_0) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
U2 ( .a(mul_in_2), .b(mul_in_3), .rnd(3'b100), .z(mul_out_1) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
U3 ( .a(mul_in_4), .b(mul_in_5), .rnd(3'b100), .z(mul_out_2) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
U4 ( .a(mul_in_6), .b(mul_in_7), .rnd(3'b100), .z(mul_out_3) );

// do (W00 * d0 + W01 * d1 + W02 * d2 + W03 * d3) part-----------------

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A0 (.a(add_a), .b(add_b), .rnd(3'b100), .z(add_out_0));// cal the 1st add
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1 (.a(add_c), .b(add_d), .rnd(3'b100), .z(add_out_1));// cal the 3rd add
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2 (.a(add_e), .b(add_f), .rnd(3'b100), .z(add_out_2));// cal the 2nd add(1st + 3rd)
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A3 (.a(add_g), .b(add_h), .rnd(3'b100), .z(add_out_3));// cal the 2nd add(1st + 3rd)
//DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S0 (.a(sub_a), .b(sub_b), .rnd(3'b100), .z(sub_out_0));
//---------------------------------------------------------------------
//   ADDER
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		add_a <= 0;
		add_b <= 0;
		add_c <= 0;
		add_d <= 0;
		add_e <= 0;
		add_f <= 0;
	end
	else begin
		if(cs == CAL_H_1st) begin
			case(cnt_cal)	
				4'd0, 4'd1, 4'd2, 4'd3 :	
					begin			
						add_a <= mul_out_0;
						add_b <= mul_out_1;
						add_c <= mul_out_2;
						add_d <= mul_out_3;
						add_e <= add_out_0;
						add_f <= add_out_1;
					end
				4'd4:
					begin
						add_a <= 0;//cal three part addition of y2,0
						add_b <= mul_out_0;
						add_e <= add_out_0;//because h1,2 are unfinished
						add_f <= add_out_1;
					end
				4'd5, 4'd6:
					begin
						add_a <= add_out_0;//cal three part addition of y2,0
						add_b <= mul_out_0;
						add_e <= add_out_0;//because h1,2 are unfinished
						add_f <= add_out_1;
					end
				4'd7:
					begin
						add_c <= add_out_0;//cal err_2
						add_d <= t;
					end
			endcase
		end
		else if(cs == CAL_ERR) begin
			case(cnt_cal) 
				4'd2:	begin//cal w2,00 - 0.001 * err2 * y1,0/y1,1/y1,2(for update w2)
							add_a <= w2[0];
							add_b <= {!mul_out_0[31], mul_out_0[30:0]};
							add_c <= w2[1];
							add_d <= {!mul_out_1[31], mul_out_1[30:0]};
							add_e <= w2[2];
							add_f <= {!mul_out_2[31], mul_out_2[30:0]};
						end
				4'd5:	begin//cal w1,00 w1,01 w1,02 w1,03
							add_a <= w1[0];
							add_b <= {!mul_out_0[31], mul_out_0[30:0]};
							add_c <= w1[1];
							add_d <= {!mul_out_1[31], mul_out_1[30:0]};
							add_e <= w1[2];
							add_f <= {!mul_out_2[31], mul_out_2[30:0]};
							add_g <= w1[3];
							add_h <= {!mul_out_3[31], mul_out_3[30:0]};
						end	
				4'd6:	begin//cal w1,10 w1,11 w1,12 w1,13
							add_a <= w1[4];
							add_b <= {!mul_out_0[31], mul_out_0[30:0]};
							add_c <= w1[5];
							add_d <= {!mul_out_1[31], mul_out_1[30:0]};
							add_e <= w1[6];
							add_f <= {!mul_out_2[31], mul_out_2[30:0]};
							add_g <= w1[7];
							add_h <= {!mul_out_3[31], mul_out_3[30:0]};
						end	
				4'd7:	begin//cal w1,20 w1,21 w1,22 w1,23
							add_a <= w1[8];
							add_b <= {!mul_out_0[31], mul_out_0[30:0]};
							add_c <= w1[9];
							add_d <= {!mul_out_1[31], mul_out_1[30:0]};
							add_e <= w1[10];
							add_f <= {!mul_out_2[31], mul_out_2[30:0]};
							add_g <= w1[11];
							add_h <= {!mul_out_3[31], mul_out_3[30:0]};
						end															
				default:begin
							add_a <= add_a;
							add_b <= add_b;
							add_c <= add_c;
							add_d <= add_d;
							add_e <= add_e;
							add_f <= add_f;
							add_g <= add_g;
							add_h <= add_h;
						end
			endcase
		end
		else if (cs == OUTPUT) begin
			add_a <= 0;
			add_b <= 0;
			add_c <= 0;
			add_d <= 0;
			add_e <= 0;
			add_f <= 0;
			add_g <= 0;
			add_h <= 0;
		end
		else begin
			add_a <= add_a;
			add_b <= add_b;
			add_c <= add_c;
			add_d <= add_d;
			add_e <= add_e;
			add_f <= add_f;
			add_g <= add_g;
			add_h <= add_h;
		end
	end
end

//---------------------------------------------------------------------
//save y1,0, y1,1, y1,2
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(idx = 0; idx < 3; idx = idx + 1) begin
			y1[idx] <= 0;
		end
	end
	else begin
		if(cs == CAL_H_1st) begin
			case(cnt_cal)
				4'd3: 	begin
							y1[0] <= add_out_2[31] ? 0 : add_out_2;
						end
				4'd4: 	begin
							y1[1] <= add_out_2[31] ? 0 : add_out_2;
						end
				4'd5: 	begin
							y1[2] <= add_out_2[31] ? 0 : add_out_2;
						end
				default:begin
							for(idx = 0; idx < 3; idx = idx + 1) begin
								y1[idx] <= y1[idx];
							end
						end
			endcase
		end
		else if(cs == OUTPUT) begin
			for(idx = 0; idx < 3; idx = idx + 1) begin
				y1[idx] <= 0;
			end
		end
		else begin
			for(idx = 0; idx < 3; idx = idx + 1) begin
				y1[idx] <= y1[idx];
			end
		end
	end
end

//do (y2,0 = W2,00 * y1,0 + W2,01 * y1,1 + W2,02 * y1,2 ) 
//save ans
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		ans <= 0;
	end
	else begin
		if(cs == CAL_H_1st) begin
			case(cnt_cal)
				4'd0, 4'd1, 4'd2, 4'd3, 4'd4: ans <= 0;
				4'd5, 4'd6, 4'd7: ans <= add_out_0;
				default : ans <= ans;
			endcase
		end
		else if(cs == OUTPUT) begin
			ans <= 0;
		end
		else ans <= ans;
	end
end


//---------------------------------------------------------------------
//   cnt_cal
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_cal <= 0;
	end
	else begin
		if(cs == CAL_H_1st) begin
			case(cnt_cal)
				4'd7: 		cnt_cal <= 0;
				default:	cnt_cal <= cnt_cal + 1;
			endcase
		end
		else if(cs == CAL_ERR) begin
			case(cnt_cal)
				4'd8: 		cnt_cal <= 0;
				default:	cnt_cal <= cnt_cal + 1;
			endcase
		end
		else if (cs == OUTPUT) begin
			cnt_cal <= 0;
		end
		else begin
			cnt_cal <= cnt_cal;
		end
	end
end

//---------------------------------------------------------------------
//   cnt_turn
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_turn <= 0;
	end
	else begin
		if(in_valid_t) begin
			cnt_turn <= cnt_turn + 1;
		end
		else if (cs == INPUT_W) begin
			cnt_turn <= 0;
		end
		else begin
			cnt_turn <= cnt_turn;
		end
	end
end

//---------------------------------------------------------------------
//   CAL_ERR : save err1,0, err1,1, err1,2
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(idy = 0; idy < 3; idy = idy + 1) begin
			err_1[idy] <= 0;
		end
	end
	else begin
		case(cs)
			CAL_ERR :	
				begin
					case(cnt_cal) 
						4'd4: 	begin//0.001 * err1
									err_1[0] <= mul_out_0;
									err_1[1] <= mul_out_1;
									err_1[2] <= mul_out_2;
								end
						default:begin
									err_1[0] <= err_1[0];
						            err_1[1] <= err_1[1];
						            err_1[2] <= err_1[2];
								end										
					endcase
				end
			OUTPUT:
				begin
					err_1[0] <= 0;
					err_1[1] <= 0;
					err_1[2] <= 0;
				end
			default:begin
				err_1[0] <= err_1[0];
		        err_1[1] <= err_1[1];
				err_1[2] <= err_1[2];
	
			end
		endcase
	end
end
//---------------------------------------------------------------------
//   save err_2
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		err_2 <= 0;
	end
	else begin
		if(cs == CAL_ERR) begin
			if(cnt_cal == 4'd0) begin
				err_2 <= add_out_1;
			end
		end
		else if (cs == OUTPUT) begin
			err_2 <= 0;
		end
		else err_2 <= err_2;
	end
end

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		out <= 0;
		out_valid <= 0;
	end
	else begin
		if(cs == CAL_ERR && cnt_cal == 4'd8) begin
			out <= ans;
			out_valid <= 1;
		end
		else begin
			out <= 0;
			out_valid <= 0;
		end
	end
end






/* always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		
	end
	else begin

	end
end

 */


endmodule
