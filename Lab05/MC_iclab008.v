module MC(
	//io
	clk,
	rst_n,
	in_valid,
	in_data,
	size,
	action,
	out_valid,
	out_data
);
//io
input	clk;
input	rst_n;
input	in_valid;
input	[30:0]in_data;
input	[1:0]size;
input	[2:0]action;
output	reg out_valid;
output	reg[30:0]out_data;
//---------------------------------------------------------------------
//   parameter and register declaration                                      
//---------------------------------------------------------------------
parameter 	IDLE 	= 4'd0,
			INPUT 	= 4'd1,
			ADD		= 4'd2,
			EX		= 4'd3,
			TR		= 4'd5,
			MIRROR	= 4'd6,
			ROTATE	= 4'd7,
			COPY	= 4'd8,
			SAVE	= 4'd9,
			OUTPUT 	= 4'd10,
			OUTPUT_1= 4'd11;
reg	[3:0] cs;
//reg [2:0] act;
wire [2:0] act;
reg [3:0] idx, idy, idx_CUR, idy_CUR;
reg [8:0] cnt;
reg row_finish;
reg [4:0] cnt_row, cnt_col, row_size;
reg [30:0] tmp[15:0]; //for the cal row
reg [61:0] mul_out;
reg [4:0] i;
reg finish_out;
reg input_tmp;//flag

//MEM
reg [7:0] 	CUR_addr, TMP_addr;
reg [30:0] 	CUR_in, TMP_in;
wire[30:0] 	TMP_out;
wire[30:0] 	CUR_out;
reg			TMP_CEN, TMP_WEN, TMP_OEN;
reg			CUR_CEN, CUR_WEN, CUR_OEN;


//---------------------------------------------------------------------
//   FSM                                        
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n)
		cs <= 0;
	else begin
		case(cs)
			IDLE:	cs <= 	in_valid ? INPUT : cs;
			INPUT:	begin
						if(in_valid) cs <= cs;
						else begin
							case(act)
								3'b000: cs <= OUTPUT;
								3'b001: cs <= ADD;
								3'b010: cs <= EX;
								3'b011: cs <= TR;
								3'b100: cs <= MIRROR;
								3'b101: cs <= ROTATE;
							endcase
						end
					end
			TR:		begin
						case(row_size)
							5'd1: cs <= cnt == 'd4 ? 	COPY : cs;
							5'd3: cs <= cnt == 'd16 ? 	COPY : cs;
							5'd7: cs <= cnt == 'd64 ? 	COPY : cs;
							5'd15:cs <= cnt == 'd256 ? 	COPY : cs;
						endcase			
					end 
			ADD:	cs <= OUTPUT;
			EX :	begin
						case(row_size)
							5'd1: cs <= cnt == 'd6 ? 	SAVE : cs;
							5'd3: cs <= cnt == 'd18 ? 	SAVE : cs;
							5'd7: cs <= cnt == 'd66 ? 	SAVE : cs;
							5'd15:cs <= cnt == 'd258 ? 	SAVE : cs;
						endcase			
					end 
					//cs <= 	(cnt == row_size + 'd2 && cnt_row == row_size) ? SAVE : cs;//setting flag row_finish
//			SAVE:	cs <= OUTPUT;
 			MIRROR: begin
						case(row_size)
							5'd1: cs <= cnt == 'd4 ? 	COPY : cs;
							5'd3: cs <= cnt == 'd16 ? 	COPY : cs;
							5'd7: cs <= cnt == 'd64 ? 	COPY : cs;
							5'd15:cs <= cnt == 'd256 ? 	COPY : cs;
						endcase			
					end
			ROTATE: begin
						case(row_size)
							5'd1: cs <= cnt == 'd4 ? 	COPY : cs;
							5'd3: cs <= cnt == 'd16 ? 	COPY : cs;
							5'd7: cs <= cnt == 'd64 ? 	COPY : cs;
							5'd15:cs <= cnt == 'd256 ? 	COPY : cs;
						endcase			
					end
			COPY:	begin
						case(row_size)
							5'd1: cs <= cnt == 'd4 ? 	OUTPUT_1 : cs;
							5'd3: cs <= cnt == 'd16 ? 	OUTPUT_1 : cs;
							5'd7: cs <= cnt == 'd64 ? 	OUTPUT_1 : cs;
							5'd15:cs <= cnt == 'd256 ? 	OUTPUT_1 : cs;
						endcase			
					end
			SAVE:	cs <= 	cnt == row_size ? 
							(cnt_col == row_size ? OUTPUT : EX) : cs;
			OUTPUT: begin
						case(row_size)
							5'd1: cs <= cnt == 'd5 ? IDLE : cs;
							5'd3: cs <= cnt == 'd17 ? IDLE : cs;
							5'd7: cs <= cnt == 'd65 ? IDLE : cs;
							5'd15:cs <= cnt == 'd257 ? IDLE : cs;
						endcase
					end 
			OUTPUT_1:
					begin
						cs <= IDLE;
					end
					//save matrix cal to current matrix
		endcase
	end
end
//---------------------------------------------------------------------
//   act                                        
//---------------------------------------------------------------------
/* always@(*) begin
	if(in_valid && !cnt) act = action;
	//else act = act;
end
 */
reg [2:0]ff_act;
always@(posedge clk or negedge rst_n)begin
if(!rst_n)
	ff_act <= 'd0;
else
	ff_act <= act;
end

assign act = (in_valid && !cnt) ? action : ff_act;
//assign act = (in_valid && !cnt) ? action : act; 
/* always@(negedge rst_n or posedge clk) begin
	if(!rst_n) act <= 0;
	else begin
		if(in_valid && !cnt) act <= action;
		else act <= act;
	end
end
 */
//---------------------------------------------------------------------
//   input_tmp  : if action  is setup/add/mul , input_tmp will be 1                               
//---------------------------------------------------------------------
always@(*) begin
		if(in_valid && !cnt) begin
			case(action)
				3'b000, 3'b001, 3'b010: input_tmp <= 1;
				default : input_tmp <= 0;
			endcase
		end
		else begin
			case(act)
				3'b000, 3'b001, 3'b010: input_tmp <= 1;
				default : input_tmp <= 0;
			endcase
		end
end
///---------------------------------------------------------------------
//   size (row_size)                                        
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) row_size <= 0;
	else begin
		if(in_valid && cs == IDLE) begin
			if(action == 3'b000) begin
				case(size)
					2'b00: row_size <= 5'd1;
					2'b01: row_size <= 5'd3;
					2'b10: row_size <= 5'd7;
					2'b11: row_size <= 5'd15;
					default: row_size <= row_size;
				endcase
			end
		end
		else row_size <= row_size;
	end
end
//---------------------------------------------------------------------
//   TMP: idx, idy                                        
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) idx <= 0;
	else begin
		if(in_valid && input_tmp) begin
			idx <= 	(idx == row_size && row_size) ? //row size will be 0 at the first cycle of INPUT
					(idy == row_size ? row_size : 0) : idx + 1; //it will be the same value when idx=idy=row_size (for setup, or will be overwritten)
		end
		else if (cs == IDLE) idx <= 0;
		else if (cs == EX) begin
			idx <= 	idx == row_size ? 0 : idx + 1;
		end		
		else if (cs == TR && cnt > 'd0) begin
			idx <= idx == row_size ? 0 : idx + 1;
		end
		else if (cs == MIRROR && cnt > 'd0) begin
			idx <= idx == row_size ? 0 : idx + 1;
		end
		else if (cs == ROTATE && cnt > 'd0) begin
			idx <= 	idy == row_size ? 
					(idx == row_size ? 0 : idx + 1) : idx;
		end
		else if (cs == SAVE) begin
			idx <= cnt == row_size ? 0 : cnt; //set back to 0 when SAVE finish
		end
		else if(!in_valid) begin
			if(cs == OUTPUT) begin
				idx <= 	idx == row_size  ? 0 : idx + 1;
			end
			else idx <= 0; // for the first cycle of OUTPUT
		end
		else idx <= idx;
	end
end
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) idy <= 0;
	else begin
		if(in_valid && input_tmp) begin
			
			idy <= 	(idx == row_size && row_size) ? 
					(idy == row_size ? row_size : idy + 1) : idy; //it will be the same value when idx=idy=row_size (for setup, or will be overwritten)
		end
		else if(cs == IDLE) begin
			idy <= 0;
		end
		else if(cs == EX) begin
			idy <= 	cnt_col;
		end		
		else if (cs == TR && cnt > 'd0) begin
			idy <= 	idx == row_size ?
					(idy == row_size ? 0 : idy + 1) : idy;
		end
		else if (cs == MIRROR && cnt > 'd0) begin
			idy <= 	idx == row_size ?
					(idy == row_size ? 0 : idy + 1) : idy;
		end
		else if (cs == ROTATE && cnt > 'd0) begin
			idy <= 	idy == row_size ? 0 : idy + 1;
		end
		else if (cs == SAVE) begin
			idy <= cnt == row_size ? 0 : cnt_col; //set back to 0 when SAVE finish
		end
		else if(!in_valid) begin
			if(cs == OUTPUT) begin
				idy <= 	idx == row_size ? 
						(idy == row_size ? 0 : idy + 1) : idy;
			end
			else idy <= 0; // for the first cycle of OUTPUT
		end
		else idy <= idy;
	end
end
//---------------------------------------------------------------------
//   CUR: idx_CUR, idy_CUR                                        
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) idx_CUR <= 0;
	else begin
		if(in_valid) begin
			idx_CUR <= 	(idx_CUR == row_size && row_size) ? //row size will be 0 at the first cycle of INPUT
					(idy_CUR == row_size ? row_size : 0) : idx_CUR + 1; //it will be the same value when idx_CUR=idy_CUR=row_size (for setup, or will be overwritten)
		end
		else if (cs == IDLE) idx_CUR <= 0;
		else if (cs == EX) begin
			idx_CUR <= 	idy_CUR == row_size ? 
						(idx_CUR == row_size ? 0 : idx_CUR + 1) : idx_CUR;
		end
		else if(!in_valid) begin
			if(cs == OUTPUT) begin
				idx_CUR <= 	idx_CUR == row_size  ? 0 : idx_CUR + 1;
			end
			else idx_CUR <= 0; // for the first cycle of OUTPUT
		end
		else idx_CUR <= idx_CUR;
	end
end
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) idy_CUR <= 0;
	else begin
		if(in_valid) begin
			idy_CUR <= 	(idx_CUR == row_size && row_size) ? 
					(idy_CUR == row_size ? row_size : idy_CUR + 1) : idy_CUR; //it will be the same value when idx_CUR=idy_CUR=row_size (for setup, or will be overwritten)
		end
		else if(cs == IDLE) begin
			idy_CUR <= 0;
		end
		else if(cs == EX) begin
			idy_CUR <= 	idy_CUR == row_size  ? 0 : idy_CUR + 'd1;
		end
		else if(!in_valid) begin
			if(cs == OUTPUT) begin
				idy_CUR <= 	idx_CUR == row_size ? 
						(idy_CUR == row_size ? 0 : idy_CUR + 1) : idy_CUR;
			end
			else idy_CUR <= 0; // for the first cycle of OUTPUT
		end
		else idy_CUR <= idy_CUR;
	end
end
//---------------------------------------------------------------------
//   ADD                                 
//---------------------------------------------------------------------
reg [30:0] tmp_add; //satify the difference one cycle of input and CUR
reg [30:0] add_input;
reg [30:0] add_cur;
wire[31:0] sum = add_input + add_cur;
wire[30:0] mod_sum = sum[31] + sum[30:0];
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) tmp_add <= 0;
	else begin
		if(action == 3'b001 || act == 3'b001) tmp_add <= in_data;
		else tmp_add <= tmp_add;
	end
end

always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		add_input <= 0;
		add_cur <= 0;
	end
	else begin
		if(act == 3'b001 || act == 3'b001) begin
			add_input <= tmp_add;
			add_cur <= CUR_out;
		end
		else begin
			add_input <= add_input;
			add_cur <= add_cur;
		end
	end
	
end
//---------------------------------------------------------------------
//   EX : mod                                  
//---------------------------------------------------------------------
//mul
wire [61:0] mul_out_w = TMP_out * CUR_out;
wire [31:0]	mod_1 = mul_out[61:31] + mul_out[30:0];
wire [31:0] mod_2 = mod_1[31] + mod_1[30:0];
wire [30:0] mod_3 = mod_2[31] + mod_2[30:0];
reg  [30:0] mod_out;
//add
wire [31:0] add_out = tmp[cnt_row - 'd1] + mod_out;
wire [30:0] mod_add = add_out[31] + add_out[30:0];

//FF : mul_out
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) mul_out <= 0;
	else begin
		if(cs == EX) begin
			mul_out <= mul_out_w;
		end
		else mul_out <= mul_out;
	end
end
//FF : mod_out
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) mod_out <= 0;
	else begin
		if(cs == EX) begin
			mod_out <= mod_3;
		end
		else mod_out <= mod_out;
	end
end
//---------------------------------------------------------------------
//   EX : tmp (save the calculating row)                                      
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for (i = 0; i < 16; i = i + 1) tmp[i] <= 0;
	end
	else begin
		if(cs == EX) begin
			if(cnt == 'd0) begin
				for (i = 0; i < 16; i = i + 1) tmp[i] <= 0; //clear
			end
			else if(cnt > 'd2 ) begin
				tmp[cnt_row - 'd1] <= mod_add;
			end
			else begin
				for (i = 0; i < 16; i = i + 1) tmp[i] <= tmp[i];
			end
		end
		else begin
			for (i = 0; i < 16; i = i + 1) tmp[i] <= tmp[i];
		end

	end
end
//---------------------------------------------------------------------
//   EX : row_finish
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) row_finish <= 0;
	else begin
		case(cs)
			EX:	begin
					row_finish <= idx == row_size ? 1 : 0;
				end
			default: row_finish <= row_finish;
		endcase
	end
end
///---------------------------------------------------------------------
//   cnt
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) cnt <= 0;
	else begin
		if(in_valid) begin
			cnt <= cnt + 'd1;
		end
		else if (!in_valid && cs == INPUT) cnt <= 0;
		else if (cs == EX) begin
			case(row_size)
				5'd1:  cnt <= cnt == 'd6 ? 		0 : cnt + 'd1;
				5'd3:  cnt <= cnt == 'd18 ? 	0 : cnt + 'd1;
				5'd7:  cnt <= cnt == 'd66 ? 	0 : cnt + 'd1;
				5'd15: cnt <= cnt == 'd258 ?	0 : cnt + 'd1;
			endcase
		end
 		else if (cs == TR) begin
			case(row_size)
				5'd1:  cnt <= cnt == 'd4 ? 		0 : cnt + 'd1;
				5'd3:  cnt <= cnt == 'd16 ? 	0 : cnt + 'd1;//not done yet
				5'd7:  cnt <= cnt == 'd64 ? 	0 : cnt + 'd1;
				5'd15: cnt <= cnt == 'd256 ?	0 : cnt + 'd1;
			endcase
		end
 		else if (cs == MIRROR) begin
			case(row_size)
				5'd1:  cnt <= cnt == 'd4 ? 		0 : cnt + 'd1;
				5'd3:  cnt <= cnt == 'd16 ? 	0 : cnt + 'd1;//not done yet
				5'd7:  cnt <= cnt == 'd64 ? 	0 : cnt + 'd1;
				5'd15: cnt <= cnt == 'd256 ?	0 : cnt + 'd1;
			endcase
		end
 		else if (cs == ROTATE) begin
			case(row_size)
				5'd1:  cnt <= cnt == 'd4 ? 		0 : cnt + 'd1;
				5'd3:  cnt <= cnt == 'd16 ? 	0 : cnt + 'd1;//not done yet
				5'd7:  cnt <= cnt == 'd64 ? 	0 : cnt + 'd1;
				5'd15: cnt <= cnt == 'd256 ?	0 : cnt + 'd1;
			endcase
		end
		else if (cs == COPY) begin
			case(row_size)
				5'd1:  cnt <= cnt == 'd4 ? 		0 : cnt + 'd1;
				5'd3:  cnt <= cnt == 'd16 ? 	0 : cnt + 'd1;//not done yet
				5'd7:  cnt <= cnt == 'd64 ? 	0 : cnt + 'd1;
				5'd15: cnt <= cnt == 'd256 ?	0 : cnt + 'd1;
			endcase
		end
		else if (cs == SAVE) begin
			case(row_size)
				5'd1: cnt <= cnt == 'd1  ? 0 : cnt + 'd1;
				5'd3: cnt <= cnt == 'd3  ? 0 : cnt + 'd1;
				5'd7: cnt <= cnt == 'd7  ? 0 : cnt + 'd1;
				5'd15:cnt <= cnt == 'd15 ? 0 : cnt + 'd1;
			endcase
		end
		else if(cs == OUTPUT) begin
			case(row_size)
				5'd1: cnt <= cnt == 'd5   ? 0 : cnt + 'd1;
				5'd3: cnt <= cnt == 'd17  ? 0 : cnt + 'd1;
				5'd7: cnt <= cnt == 'd65  ? 0 : cnt + 'd1;
				5'd15:cnt <= cnt == 'd257 ? 0 : cnt + 'd1;
			endcase
		end
		else cnt <= cnt;
	end
end


//---------------------------------------------------------------------
//   cnt_row
//---------------------------------------------------------------------
//cnt_delay
reg[8:0]cnt_delay;
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) cnt_delay <= 0;
	else begin
		if(cs == EX) begin
			if(cnt == 'd2) cnt_delay <= 0;
			else begin
				case(row_size)
					5'd1:  cnt_delay <= cnt_delay == 'd1 ? 0 : cnt_delay + 1;
					5'd3:  cnt_delay <= cnt_delay == 'd3 ? 0 : cnt_delay + 1;
					5'd7:  cnt_delay <= cnt_delay == 'd7 ? 0 : cnt_delay + 1;
					5'd15: cnt_delay <= cnt_delay == 'd15 ? 0 : cnt_delay + 1;
					
				endcase
			end
		end
		else cnt_delay <= cnt_delay;
	end
end

always@(negedge rst_n or posedge clk) begin
	if(!rst_n) cnt_row <= 0;
	else begin
		if (cs == EX) begin
			if(cnt=='d2) cnt_row <= 1;
			else begin
				case(row_size)
					5'd1:  cnt_row <= cnt_delay == 'd1 ? cnt_row + 'd1 : cnt_row;
			        5'd3:  cnt_row <= cnt_delay == 'd3 ? cnt_row + 'd1 : cnt_row;
			        5'd7:  cnt_row <= cnt_delay == 'd7 ? cnt_row + 'd1 : cnt_row;
			        5'd15: cnt_row <= cnt_delay == 'd15 ? cnt_row + 'd1 : cnt_row;
				endcase
			end
		end
		else if (cs == SAVE) begin
			cnt_row <= 'd0;
		end
		else cnt_row <= cnt_row;	
	end
end
//---------------------------------------------------------------------
//   cnt_col : which row is calculated (calculation finished when cnt_col == row_size_
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) cnt_col <= 0;
	else begin
		if (cs == SAVE && cnt == row_size) cnt_col <= cnt_col + 'd1;
		else if (cs == IDLE) cnt_col <= 0;
		else cnt_col <= cnt_col;
	end
end
//---------------------------------------------------------------------
//   MEM : TMP                                          
//---------------------------------------------------------------------
RA1SH TMP(.Q(TMP_out),
   .CLK(clk),
   .CEN(TMP_CEN),
   .WEN(TMP_WEN),
   .A(TMP_addr),
   .D(TMP_in),
   .OEN(TMP_OEN));

//data
always@(*) begin
 	if(in_valid && cs == IDLE && action == 3'b010) begin
		TMP_in = in_data;
	end
	else if (in_valid && act == 3'b010) begin
		TMP_in = in_data;
	end
	else if (in_valid && (cs == IDLE && action == 3'b001) || cs == ADD) begin
		TMP_in = mod_sum;
	end
	else if (in_valid && act == 3'b001 || cs == ADD) begin
		TMP_in = mod_sum;
	end
	else if (act == 3'b001 && cs == INPUT) begin //add ( in_valid down && cs == INPUT)
		TMP_in = mod_sum;
	end
 	else if (cs == TR && cnt > 'd0) begin
		TMP_in = CUR_out;
	end
	else if (cs == MIRROR && cnt > 'd0) begin
		TMP_in = CUR_out;
	end
	else if (cs == ROTATE && cnt > 'd0) begin
		TMP_in = CUR_out;
	end
	else begin
		if(cs == SAVE) begin
			TMP_in = tmp[cnt];
		end
		else TMP_in = 'd0;
	end
end

//address
always@(*) begin
	if(in_valid && cs == IDLE && action == 3'b010) begin //first cycle of INPUT
			case(row_size)
				5'd1:	TMP_addr = {idy[0], idx[0]};
				5'd3:	TMP_addr = {idy[1:0], idx[1:0]};		
				5'd7:	TMP_addr = {idy[2:0], idx[2:0]};
				5'd15:	TMP_addr = {idy, idx};
				default:TMP_addr = {idy, idx}; // should happen only at the first cycle of INPUT ( same as {16'd0,16'd0} )
			endcase		
	end
	else if (in_valid && cs == IDLE && action == 3'b001) begin
		TMP_addr = cnt - 'd2;
	end
	else if(in_valid && act == 3'b010 ) begin //mul //|| action == 3'b010)
		case(row_size)
			5'd1:	TMP_addr = {idy[0], idx[0]};
			5'd3:	TMP_addr = {idy[1:0], idx[1:0]};		
			5'd7:	TMP_addr = {idy[2:0], idx[2:0]};
			5'd15:	TMP_addr = {idy, idx};
			default:TMP_addr = {idy, idx}; // should happen only at the first cycle of INPUT ( same as {16'd0,16'd0} )
		endcase		
	end
	else if(in_valid && act == 3'b001  ) begin //add //|| action == 3'b001
		TMP_addr = cnt - 'd2;
	end
	else if (act == 3'b001 && cs == INPUT) begin
		TMP_addr = cnt - 'd2;
	end
	else if (cs == ADD) begin //last cycle of ADD
		case(row_size)
			5'd1:	TMP_addr = 3;
			5'd3:	TMP_addr = 15;
			5'd7:	TMP_addr = 63;
			5'd15:	TMP_addr = 255;
			default: TMP_addr = 0;
		endcase
	end
	else if(cs == EX) begin
		case(row_size)
			5'd1:	TMP_addr = {cnt_col[0], cnt[0]};
			5'd3:	TMP_addr = {cnt_col[1:0], cnt[1:0]};		
			5'd7:	TMP_addr = {cnt_col[2:0], cnt[2:0]};
			5'd15:	TMP_addr = {cnt_col, cnt[3:0]};
			default:TMP_addr = {cnt_col, cnt[3:0]}; 
		endcase		
	end
	else if (cs == TR && cnt > 'd0) begin
		case(row_size)
			5'd1:	TMP_addr = {idx[0], idy[0]};
			5'd3:	TMP_addr = {idx[1:0], idy[1:0]};		
			5'd7:	TMP_addr = {idx[2:0], idy[2:0]};
			5'd15:	TMP_addr = {idx, idy};
			default:TMP_addr = {idx, idy}; 
		endcase		
	end
	else if (cs == MIRROR && cnt > 'd0) begin
		case(row_size)
			5'd1:	TMP_addr = {idy[0], ~idx[0]};
			5'd3:	TMP_addr = {idy[1:0], ~idx[1:0]};		
			5'd7:	TMP_addr = {idy[2:0], ~idx[2:0]};
			5'd15:	TMP_addr = {idy, ~idx};
			default:TMP_addr = {idy, ~idx}; 
		endcase		
	end
	else if (cs == ROTATE && cnt > 'd0) begin
		case(row_size)
			5'd1:	TMP_addr = {~idy[0], idx[0]};
			5'd3:	TMP_addr = {~idy[1:0], idx[1:0]};		
			5'd7:	TMP_addr = {~idy[2:0], idx[2:0]};
			5'd15:	TMP_addr = {~idy, idx};
			default:TMP_addr = {~idy, idx}; 
		endcase		
	end
	else if (cs == COPY) begin
		TMP_addr = cnt;
	end
	else if(cs == SAVE) begin
		case(row_size)
			5'd1:	TMP_addr = {cnt_col[0], cnt[0]};
			5'd3:	TMP_addr = {cnt_col[1:0], cnt[1:0]};		
			5'd7:	TMP_addr = {cnt_col[2:0], cnt[2:0]};
			5'd15:	TMP_addr = {cnt_col, cnt[3:0]};
			default:TMP_addr = {cnt_col, cnt[3:0]}; 
		endcase		
	end
	else if(cs == OUTPUT) begin
		case(row_size)
			5'd1:	TMP_addr = {idy[0], idx[0]};
			5'd3:	TMP_addr = {idy[1:0], idx[1:0]};		
			5'd7:	TMP_addr = {idy[2:0], idx[2:0]};
			5'd15:	TMP_addr = {idy, idx};
			default:TMP_addr = {idy, idx};
		endcase
	end
	else TMP_addr = 0;
	
	
	
end

//control
always@(*) begin
	if(in_valid && cs == IDLE && action == 3'b010) begin
		//write
		TMP_CEN = 'd0;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
	else if(in_valid && cs == IDLE && action == 3'b001) begin
		//write
		TMP_CEN = 'd0;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
	else if(in_valid && act == 3'b010) begin
		//write
		TMP_CEN = 'd0;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
	else if(in_valid && act == 3'b001) begin
		//write
		TMP_CEN = 'd0;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
	else if (act == 3'b001 && cs == INPUT) begin
		//write
		TMP_CEN = 'd0;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
	else if(cs == ADD || cs == SAVE) begin
		//write
		TMP_CEN = 'd0;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
	else if ((cs == TR || cs == MIRROR || cs == ROTATE )&& cnt > 'd0 ) begin
		//write		
		TMP_CEN = 'd0;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
	else if (cs == EX || cs == COPY || cs == OUTPUT) begin
		//read
		TMP_CEN = 'd0;
		TMP_WEN = 'd1;
	    TMP_OEN = 'd0;
	end
	else begin
		//standby
		TMP_CEN = 'd1;
		TMP_WEN = 'd0;
		TMP_OEN = 'd0;
	end
end
//---------------------------------------------------------------------
//   MEM : CUR                                          
//---------------------------------------------------------------------
RA1SH CUR(.Q(CUR_out),
   .CLK(clk),
   .CEN(CUR_CEN),
   .WEN(CUR_WEN),
   .A(CUR_addr),
   .D(CUR_in),
   .OEN(CUR_OEN));

//data
always@(*) begin
	if(in_valid && cs == IDLE && action == 3'b000) begin
		CUR_in = in_data;
	end
	else if(act == 3'b000) begin
		CUR_in = in_data;
	end
	else if (cs == COPY && cnt > 'd0) begin
		CUR_in = TMP_out;
	end
	else if (cs == OUTPUT && (act == 3'b001 || act == 3'b010)) begin//add or mul
		CUR_in = out_data;
	end
	else CUR_in = 0;
end

//address
always@(*) begin
	if(in_valid && cs == IDLE && action == 3'b000) begin
		case(row_size)
			5'd1:	CUR_addr = {idy_CUR[0], idx_CUR[0]};
			5'd3:	CUR_addr = {idy_CUR[1:0], idx_CUR[1:0]};		
			5'd7:	CUR_addr = {idy_CUR[2:0], idx_CUR[2:0]};
			5'd15:	CUR_addr = {idy_CUR, idx_CUR};
			default:CUR_addr = {idy_CUR, idx_CUR}; // should happen only at the first cycle of INPUT ( same as {16'd0,16'd0} )
		endcase
	end
	else if(act == 3'b000) begin
		case(row_size)
			5'd1:	CUR_addr = {idy_CUR[0], idx_CUR[0]};
			5'd3:	CUR_addr = {idy_CUR[1:0], idx_CUR[1:0]};		
			5'd7:	CUR_addr = {idy_CUR[2:0], idx_CUR[2:0]};
			5'd15:	CUR_addr = {idy_CUR, idx_CUR};
			default:CUR_addr = {idy_CUR, idx_CUR}; // should happen only at the first cycle of INPUT ( same as {16'd0,16'd0} )
		endcase
	end
	else if (cs == IDLE && action == 3'b001) begin
		CUR_addr = cnt;
	end
	else if (act == 3'b001 && cs != OUTPUT) begin
		CUR_addr = cnt;
	end
 
	else if(cs == EX) begin
		case(row_size)		
			5'd1:	CUR_addr = {idy_CUR[0], idx_CUR[0]};
			5'd3:	CUR_addr = {idy_CUR[1:0], idx_CUR[1:0]};		
			5'd7:	CUR_addr = {idy_CUR[2:0], idx_CUR[2:0]};
			5'd15:	CUR_addr = {idy_CUR, idx_CUR};
			default:CUR_addr = {idy_CUR, idx_CUR}; // should happen only at the first cycle of INPUT ( same as {16'd0,16'd0} )
		endcase
	end
	else if (cs == TR || cs == MIRROR || cs == ROTATE) begin
		CUR_addr = cnt;
	end
	else if (cs == COPY && cnt > 'd0) begin
		CUR_addr = cnt - 'd1;
	end
	else if(cs == OUTPUT) begin
		CUR_addr = cnt - 'd2;
	end
	else CUR_addr = 0;
end

//control
always@(*) begin
	if(in_valid && cs == IDLE && action == 3'b000) begin
		//write
		CUR_CEN = 'd0;
		CUR_WEN = 'd0;
		CUR_OEN = 'd0;
	end
	else if (in_valid && act == 3'b000) begin
		//write
		CUR_CEN = 'd0;
		CUR_WEN = 'd0;
		CUR_OEN = 'd0;
	end
	else if (in_valid && cs == IDLE && action == 3'b001) begin
		//read
		CUR_CEN = 'd0;
		CUR_WEN = 'd1;
	    CUR_OEN = 'd0;
	end
	else if (in_valid && act == 3'b001) begin
		//read
		CUR_CEN = 'd0;
		CUR_WEN = 'd1;
	    CUR_OEN = 'd0;
	end
	else if (cs == EX) begin
		//read
		CUR_CEN = 'd0;
		CUR_WEN = 'd1;
	    CUR_OEN = 'd0;
	end
	else if (cs == TR) begin
		//read
		CUR_CEN = 'd0;
		CUR_WEN = 'd1;
	    CUR_OEN = 'd0;		
	end
	else if (cs == MIRROR) begin
		//read
		CUR_CEN = 'd0;
		CUR_WEN = 'd1;
	    CUR_OEN = 'd0;		
	end
	else if (cs == ROTATE) begin
		//read
		CUR_CEN = 'd0;
		CUR_WEN = 'd1;
	    CUR_OEN = 'd0;		
	end	
	else if (cs == COPY && cnt > 'd0) begin
		//write
		CUR_CEN = 'd0;
		CUR_WEN = 'd0;
		CUR_OEN = 'd0;
	end
 	else if(act == 3'b000) begin
		//if setup, output after input
		CUR_CEN = 'd0;
		CUR_WEN = 'd1;
		CUR_OEN = 'd0;
	end
	else if (out_valid && cnt > 'd0) begin
		if(act == 3'b001 || act == 3'b010) begin //add or mul
			//write
			CUR_CEN = 'd0;
			CUR_WEN = 'd0;
			CUR_OEN = 'd0;
		end
		else begin
			//standby
			CUR_CEN = 'd1;
			CUR_WEN = 'd0;
			CUR_OEN = 'd0;
		end
	end
	else begin
		//standby
		CUR_CEN = 'd1;
		CUR_WEN = 'd0;
		CUR_OEN = 'd0;
	end
end

//---------------------------------------------------------------------
//   OUTPUT                                          
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		out_data <= 0;
	end
	else begin
		case(cs)
			OUTPUT:
				begin
					if(cnt < 'd1) out_data <= 0;
					else begin
						case(row_size)
							5'd1:	out_data <= cnt == 'd5 ? 	0 : (act == 3'b000 ? CUR_out : TMP_out);
							5'd3:	out_data <= cnt == 'd17 ? 	0 : (act == 3'b000 ? CUR_out : TMP_out);
							5'd7:	out_data <= cnt == 'd65 ? 	0 : (act == 3'b000 ? CUR_out : TMP_out);
							5'd15:	out_data <= cnt == 'd257 ? 	0 : (act == 3'b000 ? CUR_out : TMP_out);
						endcase
					end
				end
			OUTPUT_1:out_data <= 0;
		endcase
	end
end

always@(negedge rst_n or posedge clk) begin
	if(!rst_n) out_valid <= 0;
	else begin
		if(cs == OUTPUT) begin
			if(cnt < 'd1) out_valid <= 0;
			else begin
				case(row_size)
					5'd1:	out_valid <= cnt == 'd5 ? 0 : 1;
					5'd3:	out_valid <= cnt == 'd17 ? 0 : 1;
					5'd7:	out_valid <= cnt == 'd65 ? 0 : 1;
					5'd15:	out_valid <= cnt == 'd257 ? 0 : 1;
				endcase
			end
		end
		else if (cs == OUTPUT_1) begin
			out_valid <= 1;
		end
		else out_valid <= 0;
	end
end
//---------------------------------------------------------------------
//   OUTPUT : finish_out                                        
//---------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) finish_out <= 0;
	else begin
		if(cs == OUTPUT) begin
			if(idx == row_size && idy == row_size && !finish_out) finish_out <= 1;
			else finish_out <= 0;
		end
	end
end


endmodule






