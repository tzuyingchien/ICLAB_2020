// synopsys translate_off 
`ifdef RTL
`include "GATED_OR.v"
`else
`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on
module SP(
	// Input signals
	clk,
	rst_n,
    cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, cg_en, in_valid;
input [2:0] in_mode;
input [8:0] in_data;
output reg out_valid;
output reg [8:0] out_data;


//---------------------------------------------------------------------
//   reg and wire DECLARATION                         
//---------------------------------------------------------------------
reg [4:0]	cs;
reg [4:0]	cnt;//0~16
reg [2:0]	cnt_cur;//0~6
reg [2:0] 	cnt_cal;//0~3
reg [10:0] 	a[5:0];
reg [8:0]	a_ini[5:0];
reg [8:0] 	b;
reg [2:0]	mode;
reg [17:0]	ff_out;
reg [8:0]	tmp_a, tmp_b, tmp_c;
reg [8:0] 	mul_in_0, mul_in_1;
reg [10:0] 	add_in_0;
reg [8:0]	add_in_1;
reg [8:0]	cmp_0, cmp_1;
reg [2:0]	ff_cmp[5:0];
integer 	i;

 parameter 	IDLE		= 5'b00000,
			INPUT		= 5'b00001,
			INV			= 5'b00011,
			MUL			= 5'b00111,
			MUL_2		= 5'b01111,
			SORT		= 5'b01011,
			SORT_2		= 5'b11011,
			SUM			= 5'b11101,
			MUL_N		= 5'b01001,
			SORT_N		= 5'b01101,
			MUL_C01 	= 5'b00101,
			MUL_C23 	= 5'b00100,
			MUL_C45 	= 5'b00110,
			MUL_MERGE 	= 5'b01110,
			MUL_SET_POS = 5'b01100,//103254 -> 012345
			OUTPUT		= 5'b11111;


parameter	cnt_cal_0 	= 3'b000,
			cnt_cal_1 	= 3'b001,
			cnt_cal_2 	= 3'b011,
            cnt_cal_3 	= 3'b010,
			cnt_cal_4 	= 3'b110,
            cnt_cal_5 	= 3'b100,
			cnt_cal_6 	= 3'b101,
            cnt_cal_7 	= 3'b111;

wire[17:0] 	mul_out = mul_in_0 * mul_in_1;
wire[11:0] 	add_out = add_in_0 + add_in_1;
wire		cmp_out = cmp_0 > cmp_1;





//---------------------------------------------------------------------
//   FSM                     
//---------------------------------------------------------------------
wire sleep_fsm = !(cs == IDLE || (cs == INV && cnt_cur == 'd5) || (cs == MUL && cnt == 5'd4 ) || (cs == SORT&&cnt == 5'd15)
				|| ((cs == INPUT || cs == MUL_2 ||cs == SORT_2|| cs == SUM || cs == OUTPUT || cs == MUL_N || cs == SORT_N||cs == MUL_MERGE) && cnt == 5'd5) 
				|| cs == MUL_C01 || cs == MUL_C23 || cs == MUL_C45 || cs == MUL_SET_POS);
GATED_OR GATED_sleep_fsm	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_fsm), .RST_N(rst_n), .CLOCK_GATED(clk_fsm));
always@(negedge rst_n or posedge clk_fsm) begin
	if(!rst_n)	cs <= 0;
	else begin
		case(cs)
			IDLE:		cs <= 	in_valid ?	INPUT	: cs;
			INPUT:		cs <= 	cnt == 5'd5 ?
								(mode[0] == 1'b1 ? INV :
								mode[1] == 1'b1 ? MUL_C01 : MUL_N) : cs;
			INV:		cs <= 	cnt_cur == 'd5 && cnt == 5'd15 && cnt_cal == cnt_cal_3 ?
								(mode[1] == 1'b1 ? MUL : MUL_N) : cs;				
			MUL:		cs <= 	cnt == 5'd4 && cnt_cal == cnt_cal_3 ? MUL_2 : cs;
			MUL_2:		cs <= 	cnt == 5'd5 && cnt_cal == cnt_cal_4 ? 
								(mode[2] == 1'b1 ? SORT : SORT_N) : cs;
			SORT:		cs <= 	cnt == 5'd15 ? SORT_2 : cs;
			SORT_2:		cs <= 	cnt == 5'd5 ? SUM : cs;
			SUM:		cs <= 	cnt == 5'd5 && cnt_cal == cnt_cal_2 ? OUTPUT : cs;
			OUTPUT:		cs <= 	cnt == 5'd5 ? IDLE : cs;
			MUL_N:		cs <= 	cnt == 5'd5 ? 
								(mode[2] == 1'b1 ? SORT : SORT_N) : cs;
			SORT_N:		cs <= 	cnt == 5'd5 ? SUM : cs;
			MUL_C01:	cs <= 	cnt == 5'd2 && cnt_cal == cnt_cal_3 ? MUL_C23 : cs;
			MUL_C23:	cs <= 	cnt == 5'd2 && cnt_cal == cnt_cal_3 ? MUL_C45 : cs;
			MUL_C45:	cs <= 	cnt == 5'd2 && cnt_cal == cnt_cal_3 ? MUL_MERGE : cs;
			MUL_MERGE:	cs <= 	cnt == 5'd5 && cnt_cal == cnt_cal_4 ? MUL_SET_POS : cs;
			MUL_SET_POS:cs <= 	mode[2] == 1'b1 ? SORT : SORT_N;
			//default:	cs <= 	5'dx;
		endcase
	end
end

//---------------------------------------------------------------------
//   INPUT                    
//---------------------------------------------------------------------
//in_data
wire sleep_a = !(cs == IDLE || cs == INPUT || (cs == INV && cnt == 'd15 && cnt_cal == cnt_cal_3) || (cs == MUL_2 && cnt_cal == cnt_cal_4) || cs == SORT_2 
				|| (cs == SUM && cnt_cal == cnt_cal_2) || cs == MUL_N || cs == SORT_N || (cs == MUL_MERGE && cnt_cal == cnt_cal_4));
GATED_OR GATED_sleep_a	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_a), .RST_N(rst_n), .CLOCK_GATED(clk_a));

always@(negedge rst_n or posedge clk_a) begin
 	if(!rst_n)	for(i = 0; i < 6; i = i + 1)
					a[i] <= 0;
	else begin
		case(cs)
			IDLE:	begin
						for(i = 1; i < 6; i = i + 1) a[i] <= 0;
						a[0] <= in_valid ? in_data : 0;
					end
			INPUT:	a[cnt] <= in_data;
			INV:	begin
						if(cnt == 5'd15 && cnt_cal == cnt_cal_3) begin
							a[cnt_cur] <= 	add_out == 'd511	? 'd2 :
											add_out == 'd510 	? 'd1 : 
											add_out == 'd509 	? 'd0 : add_out;
						end
					end
			MUL_2:	begin
						if(cnt_cal == cnt_cal_4) 
							a[cnt] <= add_out[9:0];//9bit + 9bit B + A
					end
			SORT_2:	a[cnt] <= add_out;
			SUM:	begin
						if(cnt_cal == cnt_cal_2)	a[cnt] <= 	add_out == 'd511	? 'd2 :
														add_out == 'd510 	? 'd1 : 
														add_out == 'd509 	? 'd0 : add_out;
					end
			MUL_N:	a[cnt] <= 	add_out == 'd511	? 'd2 :
								add_out == 'd510 	? 'd1 : 
								add_out == 'd509 	? 'd0 : add_out;
			SORT_N:	a[cnt] <= 	add_out == 'd511	? 'd2 :
								add_out == 'd510 	? 'd1 : 
								add_out == 'd509 	? 'd0 : add_out;
			MUL_MERGE:
					begin
						if(cnt_cal == cnt_cal_4) 
							a[cnt] <= 	add_out[9:0] == 'd511	? 'd2 :
										add_out[9:0] == 'd510 	? 'd1 : 
										add_out[9:0] == 'd509 	? 'd0 :  add_out[9:0];//A + B
					end
			default:begin
						for(i = 0; i < 6; i = i + 1)
							a[i] <= a[i];
					end
		endcase
	end
end

wire sleep_mode = !(cs == IDLE);
GATED_OR GATED_sleep_mode	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_a), .RST_N(rst_n), .CLOCK_GATED(clk_mode));

//mode
always@(negedge rst_n or posedge clk_mode) begin
	if(!rst_n)	mode <= 0;
	else begin
		case(cs)
			IDLE:		mode <= in_valid	?	in_mode : 3'dx;
			//default:	mode <= mode;
		endcase
	end
end

//copy a
//in_data
wire sleep_a_ini = 	!(cs == IDLE || cs == INPUT || (cs == MUL_2 && cnt_cal == cnt_cal_4) || cs == MUL_N || (cs == MUL_MERGE && cnt_cal == cnt_cal_4) || cs == MUL_SET_POS );
GATED_OR GATED_sleep_a_ini	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_a_ini), .RST_N(rst_n), .CLOCK_GATED(clk_a_ini));

always@(negedge rst_n or posedge clk_a_ini) begin
	if(!rst_n)	for(i = 0; i < 6; i = i + 1)
					a_ini[i] <= 0;
	else begin
		case(cs)
			IDLE:	begin
						for(i = 1; i < 6; i = i + 1) a_ini[i] <= 0;
						a_ini[0] <= in_valid ? in_data : 0;
					end
			INPUT:	begin
						a_ini[cnt] <= in_data;
					end
			MUL_2:	begin
						if(cnt_cal == cnt_cal_4)	a_ini[cnt] <= 	ff_out == 'd511 ? 2 :
															ff_out == 'd510 ? 1 :
															ff_out == 'd509 ? 0 : ff_out;
					end
			MUL_N:	a_ini[cnt] <= a[cnt];
			MUL_MERGE:
					begin
						if(cnt_cal == cnt_cal_4) a_ini[cnt] <= ff_out == 'd511 ? 2 :
						                                  ff_out == 'd510 ? 1 :
						                                  ff_out == 'd509 ? 0 : ff_out;			
					end
			MUL_SET_POS:
					begin
						a_ini[0] <= a_ini[1];
						a_ini[1] <= a_ini[0];
						a_ini[2] <= a_ini[3];
						a_ini[3] <= a_ini[2];
						a_ini[4] <= a_ini[5];
						a_ini[5] <= a_ini[4];
					end
			default:begin
						for(i = 0; i < 6; i = i + 1)
							a_ini[i] <= a_ini[i];
					end
		endcase
	end
end
//---------------------------------------------------------------------
//   cnt                   
//---------------------------------------------------------------------
/* wire sleep_cnt = 	!(cs == IDLE || cs == INPUT || cs == INV || cs == MUL || cs == MUL_2 || cs ==SORT || cs == SORT_2 || cs == SUM 
					|| cs == OUTPUT || cs == MUL_N || cs == SORT_N || cs == MUL_C01 || cs == MUL_C23 || cs == MUL_C45 || cs == MUL_MERGE);
GATED_OR GATED_sleep_cnt (.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_cnt), .RST_N(rst_n), .CLOCK_GATED(clk_cnt));
 */
always@(negedge rst_n or posedge clk) begin
	if(!rst_n)	cnt <= 0;
	else begin
	
		//cnt15:	cnt <= cs == INV ? (cnt_cal == cnt_cal_3 ? 0 : cnt15; 
	
	
		case(cs)
			IDLE:		cnt <= 	in_valid ? 'd1 : 'd0;
			INPUT:		cnt <= 	cnt == 5'd5 ? 0 : cnt + 'd1;
			
			INV:		cnt <= 	cnt_cal == cnt_cal_3 ? 
								(cnt == 5'd15 ? 0 : cnt + 'd1 ) : cnt;
			
			
			
			
			MUL:		cnt <= 	cnt_cal == cnt_cal_3 ?
								(cnt == 5'd4 ? 0 : cnt + 'd1) : cnt;
			MUL_2:		cnt <= 	cnt_cal == cnt_cal_4 ?
								(cnt == 5'd5 ? 0 : cnt + 'd1) : cnt;
			SORT:		cnt <= 	cnt == 5'd15 ? 0 : cnt + 'd1;
			SORT_2:		cnt <= 	cnt == 5'd5 ? 0 : cnt + 'd1;
			SUM:		cnt <= 	cnt_cal == cnt_cal_2 ? 
								(cnt == 5'd5 ? 'd1 : cnt + 'd1) : cnt;
			OUTPUT:		cnt <= 	cnt == 5'd5 ? 0 : cnt + 'd1;
			MUL_N:		cnt <= 	cnt == 5'd5 ? 0 : cnt + 'd1;
			SORT_N:		cnt <= 	cnt == 5'd5 ? 0 : cnt + 'd1;
			MUL_C01, MUL_C23, MUL_C45:	
						cnt <= 	cnt_cal == cnt_cal_3 ?
								(cnt == 5'd2 ? 'd0 : cnt + 'd1) : cnt;
			MUL_MERGE:	cnt <= 	cnt_cal == cnt_cal_4 ?
								(cnt == 5'd5 ? 'd0 : cnt + 'd1) : cnt;
			default:	cnt <= 'd0;
		endcase
	end
end
//---------------------------------------------------------------------
//   cnt_cur : processing number (0~5)               
//---------------------------------------------------------------------
wire sleep_cnt_cur = !(cs == INPUT || cs == INV );
GATED_OR GATED_sleep_cnt_cur (.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_cnt_cur), .RST_N(rst_n), .CLOCK_GATED(clk_cnt_cur));

always@(negedge rst_n or posedge clk_cnt_cur) begin
	if(!rst_n)	cnt_cur <= 0;
	else begin
		case(cs)
			INPUT:		cnt_cur <= 'd0;
			INV:		cnt_cur <= 	cnt == 5'd15 && cnt_cal == cnt_cal_3 ? 
									(cnt_cur == 'd5 ? 0 : cnt_cur + 'd1) : cnt_cur;
			default:	cnt_cur <= 	'dx;
		endcase
	end
end
//---------------------------------------------------------------------
//   cnt_cal : mul -> mod -> mod -> mod (0~3)                  
//---------------------------------------------------------------------
wire sleep_cnt_cal = 	!(cs == INPUT || cs == INV || cs == MUL || cs == MUL_2 || cs == SUM 
						|| cs == MUL_C01 || cs == MUL_C23 || cs == MUL_C45 || cs == MUL_MERGE);
GATED_OR GATED_sleep_cnt_cal (.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_cnt_cal), .RST_N(rst_n), .CLOCK_GATED(clk_cnt_cal));

always@(negedge rst_n or posedge clk) begin
	if(!rst_n)	cnt_cal <= 0;
	else if(cs == INPUT)
		cnt_cal <= 	3'd0;
	else begin
 		case(cnt_cal)
			cnt_cal_0: cnt_cal <= cnt_cal_1;
			cnt_cal_1: cnt_cal <= cnt_cal_2;
			cnt_cal_2: cnt_cal <= (cs == SUM)	? cnt_cal_0 : cnt_cal_3;
			cnt_cal_3: cnt_cal <= (cs == INV||cs == MUL||cs == MUL_C01||cs == MUL_C23||cs == MUL_C45)? 'd0: cnt_cal_4;
			cnt_cal_4: cnt_cal <= (cs == MUL_2||cs == MUL_MERGE)? cnt_cal_0 : cnt_cal_5;
			cnt_cal_5: cnt_cal <= cnt_cal_6;
			cnt_cal_6: cnt_cal <= cnt_cal_7;
			cnt_cal_7: cnt_cal <= cnt_cal_0;
			
		
		
/* 			INPUT:						cnt_cal <= 	3'd0;
			INV, MUL:					cnt_cal <= 	cnt_cal == 3'd3 ? 0 : cnt_cal + 1'd1;
			MUL_2:						cnt_cal <= 	cnt_cal == 3'd4 ? 0 : cnt_cal + 1'd1;
			SUM:						cnt_cal <= 	cnt_cal == 3'd2 ? 0 : cnt_cal + 1'd1;
			MUL_C01, MUL_C23, MUL_C45:	cnt_cal <= 	cnt_cal == 3'd3 ? 0 : cnt_cal + 1'd1;
			MUL_MERGE:					cnt_cal <= 	cnt_cal == 3'd4 ? 0 : cnt_cal + 1'd1;
			default:					cnt_cal <= 	cnt_cal;
 */		endcase
	end
end
//---------------------------------------------------------------------
//   mul_in_0                    
//---------------------------------------------------------------------
always@(*) begin
	case(cs)
		INV:begin
				if(cnt_cal == cnt_cal_0) begin
					if(cnt == 'd0) 		mul_in_0 = a[cnt_cur]; // first turn of B
					else if(cnt == 'd3)	mul_in_0 = 'd1;
					else 				mul_in_0 = tmp_b;
				end
				else mul_in_0 = 2'd3;
			end
		MUL:begin
				if(cnt_cal == cnt_cal_0) begin
					if(cnt == 'd0)	mul_in_0 = a[0];
					else 			mul_in_0 = ff_out[8:0];
				end
				else mul_in_0 = 2'd3;
			end
		MUL_2:begin
				if(cnt_cal == cnt_cal_0)	mul_in_0 = tmp_b;
				else 				mul_in_0 = 2'd3;
			end
		SUM:begin
				if(cnt_cal != cnt_cal_0) mul_in_0 = 2'd3;
				else 				mul_in_0 = 'dx;
			end
		MUL_C01:
			begin
				if(cnt_cal == cnt_cal_0) begin
					case(cnt)
						'd0:	mul_in_0 = a[3];//b3
						'd1:	mul_in_0 = a[4];//b4
						'd2:	mul_in_0 = a[5];//b5
						default:mul_in_0 = 'dx;
					endcase
				end
				else mul_in_0 = 2'd3;
			end
		MUL_C23:
			begin
				if(cnt_cal == cnt_cal_0) begin
					case(cnt)
						'd0:	mul_in_0 = a[1];
						'd1:	mul_in_0 = a[4];
						'd2:	mul_in_0 = a[5];
						default:mul_in_0 = 'dx;
					endcase
				end
				else mul_in_0 = 2'd3;
			end
		MUL_C45:
			begin
				if(cnt_cal == cnt_cal_0) begin
					case(cnt)
						'd0:	mul_in_0 = a[1];
						'd1:	mul_in_0 = a[2];
						'd2:	mul_in_0 = a[3];
						default:mul_in_0 = 'dx;
					endcase
				end
				else mul_in_0 = 2'd3;
			end
		MUL_MERGE:
			begin
				if(cnt_cal == cnt_cal_0) begin
					case(cnt)
						'd0, 'd1:	mul_in_0 = tmp_a;
						'd2, 'd3:	mul_in_0 = tmp_b;
						'd4, 'd5:	mul_in_0 = tmp_c;
						default:mul_in_0 = 'dx;
					endcase
				end
				else if(cnt_cal == cnt_cal_4) mul_in_0 = 'dx;
				else mul_in_0 = 2'd3;
			end
		default:mul_in_0 = 'd0;
	endcase
end
//---------------------------------------------------------------------
//   mul_in_1                    
//---------------------------------------------------------------------
always@(*) begin
	case(cs)
		INV:begin
				if(cnt_cal == cnt_cal_0) begin
					if(cnt == 'd0 || cnt == 'd1) 	mul_in_1 = a[cnt_cur]; // first turn of B and first turn of A
					else if(cnt[0] == 1'b0)			mul_in_1 = tmp_b;
					else 							mul_in_1 = tmp_a;
				end
				else mul_in_1 = ff_out[17:9];
			end
		MUL:begin
				if(cnt_cal == 3'd0)	mul_in_1 = a[cnt + 'd1];
				else				mul_in_1 = ff_out[17:9];
			end
		MUL_2:begin
				if(cnt_cal == 3'd0)	mul_in_1 = a_ini[cnt];
				else 				mul_in_1 = ff_out[17:9];
			end
		SUM:begin
				if(cnt_cal != 3'd0)	mul_in_1 = ff_out[17:9];
				else 				mul_in_1 = 'dx;
			end
		MUL_C01:
			begin
				if(cnt_cal == 3'd0)begin
					if(cnt == 'd0) 	mul_in_1 = a[2];//b2
					else 			mul_in_1 = ff_out;
				end
				else mul_in_1 = ff_out[17:9];
			end
		MUL_C23:
			begin
				if(cnt_cal == 3'd0)begin
					if(cnt == 'd0) 	mul_in_1 = a[0];
					else 			mul_in_1 = ff_out;
				end
				else mul_in_1 = ff_out[17:9];
			end
		MUL_C45:
			begin
				if(cnt_cal == 3'd0)begin
					if(cnt == 'd0) 	mul_in_1 = a[0];
					else 			mul_in_1 = ff_out;
				end
				else mul_in_1 = ff_out[17:9];
			end
		MUL_MERGE:
			begin
				if(cnt_cal == 3'd0)begin
					case(cnt)
						'd0:	mul_in_1 = a[0];
						'd1:	mul_in_1 = a[1];
						'd2:	mul_in_1 = a[2];
						'd3:	mul_in_1 = a[3];
						'd4:	mul_in_1 = a[4];
						'd5:	mul_in_1 = a[5];
						default:mul_in_1 = 'dx;
					endcase
				end
				else
					mul_in_1 = ff_out[17:9];
			end
		default:	mul_in_1 = 'dx;
	endcase
end
//---------------------------------------------------------------------
//   add_in_0                    
//---------------------------------------------------------------------
always@(*) begin
	case(cs)
		INV, MUL:begin
					if(cnt_cal != 0) 	add_in_0 = mul_out;//3 * N
					else 				add_in_0 = 'dx;
				end
		MUL_2:	begin
					if(cnt_cal == cnt_cal_4)		add_in_0 = a[cnt];
					else if(cnt_cal != 0) 	add_in_0 = mul_out;//3 * N
					else 					add_in_0 = 'dx;
				end
		SORT_2:	add_in_0 = a[cnt];
		SUM:	begin
					if(cnt_cal == 3'd0) add_in_0 = a[cnt];
					else 				add_in_0 = mul_out;//3 * N
				end
		MUL_N:	add_in_0 = a[cnt];
		SORT_N:	add_in_0 = a[cnt];
		MUL_C01, MUL_C23, MUL_C45:
				begin
					if(cnt_cal != 3'd0)	add_in_0 = mul_out;
					else				add_in_0 = 'dx;
				end
		MUL_MERGE:
				begin
					if(cnt_cal != 3'd0) begin
						if(cnt_cal == cnt_cal_4) add_in_0 = a[cnt];
						else 				add_in_0 = mul_out;
					end
					else add_in_0 = 'dx;
				end
		default:	add_in_0 = 'dx;
	endcase
end
//---------------------------------------------------------------------
//   add_in_1                    
//---------------------------------------------------------------------
always@(*) begin
	case(cs)
		INV, MUL:begin
					if(cnt_cal != 0) 	add_in_1 = ff_out[8:0];//M
					else 				add_in_1 = 'dx;
				end
		MUL_2:	begin
					if(cnt_cal == cnt_cal_4)		add_in_1 = a_ini[cnt];
					else if(cnt_cal != 0) 	add_in_1 = ff_out[8:0];//M
					else 					add_in_1 = 'dx;
				end
		SORT_2:	add_in_1 = a_ini[ff_cmp[cnt]];
		SUM:	begin
					if(cnt_cal == 3'd0) add_in_1 = a_ini[cnt];
					else 				add_in_1 = ff_out[8:0];
				end
		MUL_N:	add_in_1 = a_ini[cnt];
		SORT_N:	add_in_1 = a_ini[cnt];
		MUL_C01, MUL_C23, MUL_C45:
				begin
					if(cnt_cal != 3'd0) add_in_1 = ff_out[8:0];
					else add_in_1 = 'dx;
				end
		MUL_MERGE:
				begin
					if(cnt_cal != 3'd0) begin
						if(cnt_cal == cnt_cal_4) add_in_1 = a_ini[cnt];
						else 				add_in_1 = ff_out[8:0];
					end
					else add_in_1 = 'dx;
				end
		default:	add_in_1 = 'dx;
	endcase
end
//---------------------------------------------------------------------
//   cmp_0                    
//---------------------------------------------------------------------
always@(*) begin
	case(cs)
		SORT:begin
				cmp_0 = a_ini[ff_cmp[tmp_a]];
			end
		default:	cmp_0 = 9'dx;
	endcase
end
//---------------------------------------------------------------------
//   cmp_1                    
//---------------------------------------------------------------------
always@(*) begin
	case(cs)
		SORT:begin
				cmp_1 = a_ini[ff_cmp[tmp_b]];
			end
		default:	cmp_1 = 9'dx;
	endcase
end
//---------------------------------------------------------------------
//   ff_out                  
//---------------------------------------------------------------------
wire sleep_ff_out = !(cs == INV || cs == MUL || cs == MUL_2 || cs == SUM || cs == MUL_C01 || cs == MUL_C23 || cs == MUL_C45 || cs == MUL_MERGE);
GATED_OR GATED_ff_out		(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_ff_out), 	.RST_N(rst_n), .CLOCK_GATED(clk_ff_out));
always@(negedge rst_n or posedge clk_ff_out) begin
	if(!rst_n)	ff_out <= 0;
	else begin
		case(cs)
			INV, MUL, MUL_2:begin
								if(cnt_cal == 'd0)	ff_out <= mul_out;
								else				ff_out <= add_out;
							end
			SUM:	ff_out <= add_out;
			MUL_C01, MUL_C23, MUL_C45:
						ff_out <= cnt_cal == 3'd0 ? mul_out : add_out;
					/* begin
						if(cnt_cal == 'd0)	ff_out <= mul_out;
						else				ff_out <= add_out;
					end */
			MUL_MERGE:
					begin
						if(cnt_cal == 3'd0) ff_out <= mul_out;
						else 				ff_out <= add_out;
					end
		endcase
	end
end

//---------------------------------------------------------------------
//   ff_cmp                  
//---------------------------------------------------------------------
wire sleep_ff_cmp = !(cs == IDLE || (cs == SORT && cnt != 'd0));
GATED_OR GATED_ff_cmp		(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_ff_cmp), 	.RST_N(rst_n), .CLOCK_GATED(clk_ff_cmp));

always@(negedge rst_n or posedge clk_ff_cmp) begin
	if(!rst_n)	for(i = 0; i < 6; i = i + 1)
					ff_cmp[i] <= 0;
	else begin
		case(cs)
			IDLE:begin
					for(i = 0; i < 6; i = i + 1)
						ff_cmp[i] <= i;
				end
			SORT:begin
 					if(cnt != 'd0) begin
						ff_cmp[tmp_a] <= cmp_out ? ff_cmp[tmp_b] : ff_cmp[tmp_a];
						ff_cmp[tmp_b] <= cmp_out ? ff_cmp[tmp_a] : ff_cmp[tmp_b];
					end
 				/* if(cnt != 'd0) begin
						if(cmp_out) begin
							ff_cmp[tmp_a] <= ff_cmp[tmp_b];
							ff_cmp[tmp_b] <= ff_cmp[tmp_a];
						end
					end */
					
				end
			/* default:
				begin
					for(i = 0; i < 6; i = i + 1)
						ff_cmp[i] <= ff_cmp[i];
				end */
		endcase
	end
end

//---------------------------------------------------------------------
//   tmp_a                 
//---------------------------------------------------------------------
wire sleep_tmp_a = !(cs == INV || cs == SORT || (cs == MUL_C01) && cnt == 'd2 && cnt_cal == cnt_cal_3);
GATED_OR GATED_tmp_a	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_tmp_a), .RST_N(rst_n), .CLOCK_GATED(clk_tmp_a));

always@(negedge rst_n or posedge clk_tmp_a) begin
	if(!rst_n)	tmp_a <= 0;
	else begin
		case(cs)
			INV:begin
					if(cnt[0] == 1'b1 && cnt_cal == cnt_cal_3)	tmp_a <= add_out;
					else 									tmp_a <= tmp_a;
				end
			SORT:begin
					case(cnt)
						5'd0, 5'd5, 5'd10:	tmp_a <= 1'd0;
						5'd1, 5'd6, 5'd11:	tmp_a <= 2'd2;
						5'd2, 5'd7, 5'd12:	tmp_a <= 3'd4;
						5'd3, 5'd8, 5'd13:	tmp_a <= 1'd1;
						5'd4, 5'd9, 5'd14:	tmp_a <= 2'd3;
					endcase
				end
			MUL_C01:if(cnt == 'd2 && cnt_cal == cnt_cal_3)	tmp_a <= add_out;//b2*3*4*5
			//MUL_C23, MUL_C45, MUL_MERGE:	tmp_a <= tmp_a;
			//default:tmp_a <= 'dx;
		endcase
	end
end
//---------------------------------------------------------------------
//   tmp_b                 
//---------------------------------------------------------------------
wire sleep_tmp_b = !(cs == INV || cs == MUL || cs == SORT || (cs == MUL_C23 && cnt == 'd2 && cnt_cal == cnt_cal_3) );
GATED_OR GATED_tmp_b	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_tmp_b), .RST_N(rst_n), .CLOCK_GATED(clk_tmp_b));

always@(negedge rst_n or posedge clk_tmp_b) begin
	if(!rst_n)	tmp_b <= 0;
	else begin
		case(cs)
			INV:begin
					if(cnt[0] == 1'b0 && cnt_cal == cnt_cal_3)	tmp_b <= add_out;
					else 									tmp_b <= tmp_b;
				end
			MUL:	tmp_b <= cnt == 'd4 && cnt_cal == cnt_cal_3 ? add_out : tmp_b;//save b0 * b1 * b2 * b3 * b4 * b5
			//MUL_2:	tmp_b <= tmp_b;//maintain b0 * b1 * b2 * b3 * b4 * b5
			SORT:begin
					case(cnt)
						'd0, 'd5, 'd10:	tmp_b <= 1'd1;
						'd1, 'd6, 'd11:	tmp_b <= 2'd3;
						'd2, 'd7, 'd12:	tmp_b <= 3'd5;
						'd3, 'd8, 'd13:	tmp_b <= 2'd2;
						'd4, 'd9, 'd14:	tmp_b <= 3'd4;
					endcase
				end
			MUL_C23:	if(cnt == 'd2 && cnt_cal == cnt_cal_3)	tmp_b <= add_out;//b0*1*4*5
			//MUL_C45, MUL_MERGE:	tmp_b <= tmp_b;
			//default:tmp_b <= 'dx;
		endcase
	end
end
//---------------------------------------------------------------------
//   tmp_c                 
//---------------------------------------------------------------------
wire sleep_tmp_c = !((cs == MUL_C45 && cnt == 'd2 && cnt_cal == cnt_cal_3));
GATED_OR GATED_tmp_c	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_tmp_c), .RST_N(rst_n), .CLOCK_GATED(clk_tmp_c));

always@(negedge rst_n or posedge clk_tmp_c) begin
	if(!rst_n)	tmp_c <= 0;
	else begin
		case(cs)
			MUL_C45:	if(cnt == 'd2 && cnt_cal == cnt_cal_3)	tmp_c <= add_out;//b0*1*2*3
			//MUL_MERGE:	tmp_c <= tmp_c;
			//default:	tmp_c <= tmp_c;
		endcase 
	end
end
//---------------------------------------------------------------------
//   OUTPUT : out_valid               
//---------------------------------------------------------------------
wire sleep_out_valid = !(cs == OUTPUT || (cs == SUM && cnt == 'd5 && cnt_cal == cnt_cal_2) || cs == IDLE);
GATED_OR GATED_out_valid	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_out_valid), .RST_N(rst_n), .CLOCK_GATED(clk_out_valid));
always@(negedge rst_n or posedge clk_out_valid) begin
	if(!rst_n)	out_valid <= 0;
	else begin
		if((cs == SUM && cnt == 'd5 && cnt_cal == cnt_cal_2) || cs == OUTPUT) out_valid <= 1'd1;
		else out_valid <= 1'd0;
	end
end

//---------------------------------------------------------------------
//   OUTPUT : out_data              
//---------------------------------------------------------------------
wire sleep_out_data = !(cs == OUTPUT || (cs == SUM && cnt == 'd5 && cnt_cal == cnt_cal_2));
GATED_OR GATED_out_data	(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_out_data), .RST_N(rst_n), .CLOCK_GATED(clk_out_data));

always@(negedge rst_n or posedge clk_out_data) begin
	if(!rst_n)	out_data <= 0;
	else begin
		if(cs == SUM && cnt == 'd5 && cnt_cal == cnt_cal_2) 	out_data <= a[0];
		else if(cs == OUTPUT) 							out_data <= a[cnt];
																	
		else											out_data <= 0;
	end
end










endmodule