module CLK_1_MODULE(// Input signals
			clk_1,
			clk_2,
			rst_n,
			in_valid,
			in,
			mode,
			operator,
			// Output signals,
			clk1_in_0, clk1_in_1, clk1_in_2, clk1_in_3, clk1_in_4, clk1_in_5, clk1_in_6, clk1_in_7, clk1_in_8, clk1_in_9, 
			clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19,
			clk1_op_0, clk1_op_1, clk1_op_2, clk1_op_3, clk1_op_4, clk1_op_5, clk1_op_6, clk1_op_7, clk1_op_8, clk1_op_9, 
			clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19,
			clk1_expression_0, clk1_expression_1, clk1_expression_2,
			clk1_operators_0, clk1_operators_1, clk1_operators_2,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0, clk1_flag_1, clk1_flag_2, clk1_flag_3, clk1_flag_4, clk1_flag_5, clk1_flag_6, clk1_flag_7, 
			clk1_flag_8, clk1_flag_9, clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, 
			clk1_flag_15, clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_1, clk_2, rst_n, in_valid, operator, mode;
input [2:0] in;

output reg [2:0] clk1_in_0, clk1_in_1, clk1_in_2, clk1_in_3, clk1_in_4, clk1_in_5, clk1_in_6, clk1_in_7, clk1_in_8, clk1_in_9, 
				 clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19;
output reg clk1_op_0, clk1_op_1, clk1_op_2, clk1_op_3, clk1_op_4, clk1_op_5, clk1_op_6, clk1_op_7, clk1_op_8, clk1_op_9, 
		   clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19;
output reg [59:0] clk1_expression_0, clk1_expression_1, clk1_expression_2;
output reg [19:0] clk1_operators_0, clk1_operators_1, clk1_operators_2;
output reg clk1_mode;
output reg [19 :0] clk1_control_signal;
output clk1_flag_0, clk1_flag_1, clk1_flag_2, clk1_flag_3, clk1_flag_4, clk1_flag_5, clk1_flag_6, clk1_flag_7, 
	   clk1_flag_8, clk1_flag_9, clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, 
	   clk1_flag_15, clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19;

//---------------------------------------------------------------------
//   reg and wire declaration
//---------------------------------------------------------------------
reg [2:0] 	ff_in;
reg 		ff_mode;
reg 		ff_op;

//in (data)
always@(negedge rst_n or posedge clk_1) begin
	if(!rst_n)	ff_in <= 0;
	else 		ff_in <= in;
end

always@(*) begin
	clk1_in_0 	= ff_in;
end

//mode
always@(negedge rst_n or posedge clk_1) begin
	if(!rst_n)	ff_mode <= 0;
	else 		ff_mode <= mode;
end

always@(*) begin
	clk1_in_1 	= ff_mode;
end

//operator
always@(negedge rst_n or posedge clk_1) begin
	if(!rst_n)	ff_op <= 0;
	else 		ff_op <= operator;
end

always@(*) begin
	clk1_in_2 	= ff_op;
end

//in_valid (original)
//assign clk1_flag_0 = in_valid;
//in_valid
syn_XOR xor_syn_1(.IN(in_valid),.OUT(clk1_flag_1),.TX_CLK(clk_1),.RX_CLK(clk_2),.RST_N(rst_n));   	
synchronizer syn_1(.D(in_valid), .Q(clk1_flag_0), .clk(clk_2), .rst_n(rst_n));

endmodule





//========================================================================================================================================================
//========================================================================================================================================================
module CLK_2_MODULE(// Input signals
			clk_2,
			clk_3,
			rst_n,
			clk1_in_0, clk1_in_1, clk1_in_2, clk1_in_3, clk1_in_4, clk1_in_5, clk1_in_6, clk1_in_7, clk1_in_8, clk1_in_9, 
			clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19,
			clk1_op_0, clk1_op_1, clk1_op_2, clk1_op_3, clk1_op_4, clk1_op_5, clk1_op_6, clk1_op_7, clk1_op_8, clk1_op_9, 
			clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19,
			clk1_expression_0, clk1_expression_1, clk1_expression_2,
			clk1_operators_0, clk1_operators_1, clk1_operators_2,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0, clk1_flag_1, clk1_flag_2, clk1_flag_3, clk1_flag_4, clk1_flag_5, clk1_flag_6, clk1_flag_7, 
			clk1_flag_8, clk1_flag_9, clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, 
			clk1_flag_15, clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19,
			
			// output signals
			clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_2, clk_3, rst_n;

input [2:0] clk1_in_0, clk1_in_1, clk1_in_2, clk1_in_3, clk1_in_4, clk1_in_5, clk1_in_6, clk1_in_7, clk1_in_8, clk1_in_9, 
	 	    clk1_in_10, clk1_in_11, clk1_in_12, clk1_in_13, clk1_in_14, clk1_in_15, clk1_in_16, clk1_in_17, clk1_in_18, clk1_in_19;
input clk1_op_0, clk1_op_1, clk1_op_2, clk1_op_3, clk1_op_4, clk1_op_5, clk1_op_6, clk1_op_7, clk1_op_8, clk1_op_9, 
  	  clk1_op_10, clk1_op_11, clk1_op_12, clk1_op_13, clk1_op_14, clk1_op_15, clk1_op_16, clk1_op_17, clk1_op_18, clk1_op_19;
input [59:0] clk1_expression_0, clk1_expression_1, clk1_expression_2;
input [19:0] clk1_operators_0, clk1_operators_1, clk1_operators_2;
input clk1_mode;
input [19 :0] clk1_control_signal;
input clk1_flag_0, clk1_flag_1, clk1_flag_2, clk1_flag_3, clk1_flag_4, clk1_flag_5, clk1_flag_6, clk1_flag_7, 
	  clk1_flag_8, clk1_flag_9, clk1_flag_10, clk1_flag_11, clk1_flag_12, clk1_flag_13, clk1_flag_14, 
	  clk1_flag_15, clk1_flag_16, clk1_flag_17, clk1_flag_18, clk1_flag_19;


output reg [63:0] clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3;
output reg clk2_mode;
output reg [8:0] clk2_control_signal;
output clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7;
//---------------------------------------------------------------------
//   reg and parameter DECLARATION                         
//---------------------------------------------------------------------			
reg  [2:0] 	in[18:0];
reg  [2:0] 	cs;
reg  [4:0] 	cnt;
reg  [19:0]	operator;
reg  		mode;
reg  signed[29:0]	stack[9:0];//double check!
reg  [3:0] 	top;

wire 		in_valid;
wire 		in_valid_ini;//continuous in_valid
wire		out_valid;

reg   signed[29:0] out;
reg   signed[29:0] out_postfix;
wire  signed[29:0] out_0;
wire  signed[29:0] out_1;
wire  signed[29:0] out_2;
wire  signed[29:0] out_3;
wire  signed[29:0] out_4;


parameter 	IDLE 	= 3'd0,
			INPUT 	= 3'd1,
			CAL		= 3'd2,
			OUTPUT 	= 3'd7;
integer		i;

assign 		in_valid_ini 	= clk1_flag_0;
assign 		in_valid 		= clk1_flag_1;

syn_XOR syn_2(.IN(out_valid),.OUT(clk2_flag_1),.TX_CLK(clk_2),.RX_CLK(clk_3),.RST_N(rst_n));   	
//---------------------------------------------------------------------
// FSM
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n) 	begin
		cs <= 0;
	end
	else begin
		case(cs)
			IDLE:		cs <= 	in_valid_ini == 1'b1		 	? 	INPUT : cs;
			INPUT:		cs <= 	(!in_valid_ini && !in_valid)	?	
								(mode == 1'b1 					?	OUTPUT: CAL) : cs;
			CAL:		cs <= 	cnt == 'd1 						?	OUTPUT: cs;		
			OUTPUT:		cs <= 	IDLE;
			default:	cs <= 	cs;
		endcase
	end
end

//data
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n) begin
		for(i = 0; i < 20; i = i + 1) begin
			in[i] <= 0;
		end
	end
	else begin 
		case(cs)
			IDLE:	begin
						for(i = 0; i < 20; i = i + 1) begin
							in[i] <= 0;
						end
					end
			INPUT:	in[cnt] <= in_valid ? clk1_in_0 : 0;
			default:begin
						for(i = 0; i < 20; i = i + 1) begin
							in[i] <= in[i];
						end
					end
		endcase
	end
end
//operator
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n) operator <= 0;
	else begin 
		case(cs)
			IDLE:		operator <= 0;
			INPUT:		operator[cnt] <= in_valid ? clk1_in_2 : 0;
			default:	operator <= operator;
		endcase
	end
end
//mode
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n) mode <= 0;
	else begin 
		case(cs)
			IDLE:		mode <= 0;
			INPUT:		mode <= in_valid && cnt == 'd0 ? clk1_in_1 : mode;
			default:	mode <= mode;
		endcase
	end
end
//---------------------------------------------------------------------
// CAL:	prefix
//---------------------------------------------------------------------
//stack
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n)  begin
		for(i = 0; i < 11; i = i + 1) stack[i] <= 0;
	end
	else begin
		case(cs)
			IDLE:	for (i = 0; i < 11; i = i + 1) stack[i] <= 0;
			INPUT:	begin//postfix
						if(mode == 1'b1 || clk1_in_1 == 1'b1) begin
							if(in_valid) begin
								if(top > 'd1) begin
									for(i = 0; i < 11; i = i + 1) begin
										if(i == top)				stack[i] <= clk1_in_2 == 1'b0 	? clk1_in_0 : 0;
										else if(i == top - 'd1) 	stack[i] <= clk1_in_2 == 1'b0 	? stack[i] : 0;			
										else if(i == top - 'd2)		stack[i] <= clk1_in_2 == 1'b0	? stack[i] : out_postfix;
										else 						stack[i] <= stack[i];
									end
								end
								else if(top == 'd1) begin
									stack[0] <= stack[0];
									stack[1] <= clk1_in_0;
									for(i = 2; i < 11; i = i + 1) stack[i] <= stack[i]; 
								end
								else begin
									stack[0] <= clk1_in_0;
									for(i = 1; i < 11; i = i + 1) stack[i] <= stack[i];
								end
							end
							else begin
								for(i = 0; i < 11; i = i + 1) stack[i] <= stack[i];
							end
						end
						else begin
							for(i = 0; i < 11; i = i + 1) stack[i] <= 0;
						end
					end
			CAL:	begin//prefix
						if(top > 'd1) begin
							for(i = 0; i < 11; i = i + 1) begin
								if(i == top) 			stack[i] <= operator[cnt-1] == 1'b0 	? in[cnt-1] : 0;// if it is number : store in stack, if it is operator: save the result
								else if(i == top - 'd1) stack[i] <= operator[cnt-1] == 1'b0		? stack[i] : 0;
								else if(i == top - 'd2) stack[i] <= operator[cnt-1] == 1'b0		? stack[i] : out;
								else 					stack[i] <= stack[i];
							end
							
							//stack[top] 		<= operator[cnt] == 1'b0 	? in[cnt] : 0;// if it is number : store in stack, if it is operator: save the result
							//stack[top-1] 	<= operator[cnt] == 1'b00	? stack[top] : out;
						end
						/* else if (top == 'd1) begin
							stack[0] <= operator[cnt-1] == 1'b0		?	stack[0] : out;
							stack[1] <= operator[cnt-1] == 1'b0		? 	stack[1] : 0;
							stack[2] <= operator[cnt-1] == 1'b0		?	in[cnt-1]: 0;
							for(i = 3; i < 11; i = i + 1) stack[i] <= stack[i];
						end */
						else if (top == 'd1) begin
							stack[0] <= stack[0];
							stack[1] <= in[cnt-1];
							for(i = 2; i < 11; i = i + 1) stack[i] <= stack[i];
						end
						else begin// the first element
							
							stack[0] 		<= in[cnt-1];
							for(i = 1; i < 11; i = i + 1) stack[i] <= stack[i];
						end
					end
			default:for(i = 0; i < 11; i = i + 1) stack[i] <= stack[i];

		endcase
	end
end

//top
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n)  top <= 0;
	else begin
		case(cs)
			IDLE:		top <= 0;
			INPUT:		begin
							/* if(cnt == 'd0) begin
								if(clk1_in_1 == 1'b1 && in_valid) top <= clk1_in_2 == 1'b0 ? top + 'd1 : top - 'd1;
								//else top <= 0;
							end
							else begin
								if(mode == 1'b1 && in_valid) top <= clk1_in_2 == 1'b0 ? top + 'd1 : top - 'd1;
								//else top <= 0;
							end  */
							if((mode == 1'b1 || (clk1_in_1 == 1'b1 & cnt =='d0)) && in_valid) top <= clk1_in_2 == 1'b0 ? top + 'd1 : top - 'd1;
						end
			CAL:		top <= cnt == 'd0 ? 'd1: (operator[cnt-1] == 1'b0	? top + 'd1 : top - 'd1);
			default:	top <= 0;
		endcase
	end
end

reg [29:0] op1, op2;
//assign 	op1 	= mode == 1'd0 || clk1_in_1 == 1'd0 ? stack[top - 1] : stack[top - 2];
always@(*) begin
	if(cnt == 'd0) begin
		if(clk1_in_1 == 1'b0) begin
			op1 = top > 'd1 ? stack[top - 1] : 0;
			op2 = top > 'd1 ? stack[top - 2] : 0;
		end
		else begin
			op1 = top > 'd1 ? stack[top - 2] : 0;
			op2 = top > 'd1 ? stack[top - 1] : 0;
		end
	end
	else begin
		if(mode == 1'b0) begin
			op1 = top > 'd1 ? stack[top - 1] : 0;
			op2 = top > 'd1 ? stack[top - 2] : 0;
		end
		else begin
			op1 = top > 'd1 ? stack[top - 2] : 0;
			op2 = top > 'd1 ? stack[top - 1] : 0;
		end
	end
		
		/* if(mode == 1'b0 || clk1_in_1 == 1'd0) begin //prefix
			op1 = top > 'd1 ? stack[top - 1] : 0;
			op2 = top > 'd1 ? stack[top - 2] : 0;
		end
		else begin
			op1 = top > 'd1 ? stack[top - 2] : 0;
			op2 = top > 'd1 ? stack[top - 1] : 0;
		end */
end


//cal
assign out_0	= 	top > 'd0 ? op1 + op2 : 0;//add
assign out_1	= 	top > 'd0 ? op1 - op2 : 0;//sub
assign out_2	= 	top > 'd0 ? op1 * op2 : 0;//mul
assign out_3 	= 	top > 'd0 ? 
					(out_0[29] == 1'b0 ? out_0 : {1'b0, ~out_0[28:0]} + 1'd1) : 0;//abs
assign out_4	= 	top > 'd0 ? {out_1[29], out_1[27:0], 1'b0} : 0;//2*(a-b) : {signed bit, out_1 * 2} 

/* always@(*) begin
	if(top > 'd0) begin
		case({stack[top-1][29], stack[top-2][29]})
			2'b00:	out_3 = out_0;//both positive
			2'b01:	out_3 = out_1;//top :positive, top-1 : negative
			2'b10:	out_3 = {1'b1, out_1[28:0]};//top :negative, top-1 : positive
			2'b11:	out_3 = {1'b1, out_0[28:0]};//both negative
		endcase
	end
	else out_3 = 0;
end
 */
always@(*) begin
	case(in[cnt-1])
		3'b000:		out = out_0;
		3'b001: 	out = out_1;
		3'b010: 	out = out_2;
		3'b011: 	out = out_3;
		3'b100: 	out = out_4;
		default:	out = 0;
	endcase
end

always@(*) begin
	case(clk1_in_0)
		3'b000:		out_postfix = out_0;
		3'b001: 	out_postfix = out_1;
		3'b010: 	out_postfix = out_2;
		3'b011: 	out_postfix = out_3;
		3'b100: 	out_postfix = out_4;
		default:	out_postfix = 0;
	endcase
end

reg [29:0] ff_out_postfix_0, ff_out_postfix_1, ff_out_postfix_2;

/* always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n) begin
		ff_out_postfix_0  <= 30'd0;
		ff_out_postfix_1  <= 30'd0;
		ff_out_postfix_2  <= 30'd0;
	end
	else begin
		ff_out_postfix_0 <= out_0;
		ff_out_postfix_1 <= out_1;
		ff_out_postfix_2 <= out_2;
	end */
	

//---------------------------------------------------------------------
// cnt
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n) cnt <= 0;
	else begin
		case(cs)
			IDLE: 		cnt <= 0;
			INPUT:		cnt <= in_valid 	? cnt + 'd1 : cnt;
			CAL:		cnt <= cnt > 'd0 	? cnt - 'd1 : 0;
			default:	cnt <= cnt;
		endcase
	end
end
//---------------------------------------------------------------------
// OUTPUT
//---------------------------------------------------------------------
reg [29:0] ff_out;
always@(negedge rst_n or posedge clk_2) begin
	if(!rst_n)  ff_out <= 0;
	else begin
		case(cs)
			//CAL:		ff_out <= cnt == 'd1 ? stack[0] : 0;
			OUTPUT:		ff_out <= stack[0];
			default:	ff_out <= ff_out;
		endcase
		//ff_out <= cs == OUTPUT ? stack[0] : ff_out;
	end
end

//assign	out_valid = cs == OUTPUT ? 1 : 0;

assign 	out_valid = cs == CAL && cnt == 'd3 && mode == 1'b0 ? 1 :
					cs == OUTPUT && mode == 1'b1 ? 1 : 0;

/* assign 	out_valid = cs == CAL && cnt == 'd2 && mode == 1'b0 ? 1 :
					!in_valid_ini && !in_valid && mode == 1'b1 ? 1 : 0;
 *///!in_valid_ini && !in_valid
assign 	clk2_flag_0 = out_valid;

always@(*) begin
	clk2_out_0 = ff_out[29] == 1'b0 ? {35'h0, ff_out[28:0]} : {35'h7_ffff_ffff, ff_out[28:0]};
end

endmodule

//========================================================================================================================================================
//========================================================================================================================================================
module CLK_3_MODULE(// Input signals
			clk_3,
			rst_n,
			clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7,
			
			// Output signals
			out_valid,
			out
		  
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_3, rst_n;


input [63:0] clk2_out_0, clk2_out_1, clk2_out_2, clk2_out_3;
input clk2_mode;
input [8:0] clk2_control_signal;
input clk2_flag_0, clk2_flag_1, clk2_flag_2, clk2_flag_3, clk2_flag_4, clk2_flag_5, clk2_flag_6, clk2_flag_7;

output reg out_valid;
output reg [63:0]out; 		

//---------------------------------------------------------------------
//  DESIGN
//---------------------------------------------------------------------
reg [7:0] 	cnt;
reg [63:0] 	ff_out;

always@(negedge rst_n or posedge clk_3) begin
	if(!rst_n)	out_valid <= 0;
	else		out_valid <= clk2_flag_1;
end

always@(negedge rst_n or posedge clk_3) begin
	if(!rst_n)	ff_out <= 0;
	else 		ff_out <= clk2_out_0;
end

always@(*) begin
	out = out_valid ? clk2_out_0 : 0;
end



/* always@(negedge rst_n or posedge clk_3) begin
	if(!rst_n)	cnt <= 0;
	else 		cnt <= cnt == 'd100 ? 0 : cnt + 'd1;
end

always@(negedge rst_n or posedge clk_3) begin
	if(!rst_n) 	out <= 0;
	else 		out <= cnt == 'd100 ? 	1 : 0;
end
always@(negedge rst_n or posedge clk_3) begin
	if(!rst_n) 	out_valid <= 0;
	else 		out_valid <= cnt == 'd100 ? 	1 : 0;
end
 */
endmodule


