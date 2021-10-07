module bridge(input clk, INF.bridge_inf inf);
/* 		input	rst_n,
		input	C_addr,
		input	C_data_w,
		input	C_in_valid,
		input	C_r_wb,
		
		input	AR_READY,
		input	R_VALID,
		input	R_DATA,
		input	R_RESP,?????????????????
		input	AW_READY,
		input	W_READY,
		input	B_VALID,
		input	B_RESP,
		
		output	C_out_valid,
		output	C_data_r,
		
		output	AR_VALID,
		output	AR_ADDR,
		output	R_READY,
		
		output	AW_VALID,
		output	AW_ADDR,
		output	W_VALID,
		output	W_DATA,
		output	B_READY
 */
logic 		ff_read_req;
logic 		ff_write_req;
logic		ff_write_data_req;
logic 		ff_wait_rvalid;
logic 		ff_wait_wready;
logic 		ff_wait_bresp;
logic[16:0] id_to_addr, id_to_addr_w;
logic[9:0]	tmp, tmp_w;
logic[15:0]	ff_addr;

always_comb begin
	//tmp			= {inf.C_addr, 2'b00};
	tmp			= {ff_addr, 2'b00};
	id_to_addr 	= {1'd1, 6'd0, tmp};
end
always_comb begin
	//tmp_w			= {inf.C_data_w[31:24], 2'b00};
	tmp_w			= {ff_addr[7:0], 2'b00};
	id_to_addr_w 	= {1'd1, 6'd0, tmp_w};
end


always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_addr <= 	0;
	else			ff_addr <= inf.C_r_wb ? inf.C_addr : {8'd0, inf.C_data_w[31:24]};
end
//read address
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_read_req <= 	0;
	else 			ff_read_req <= 	inf.C_in_valid && inf.C_r_wb == 1'b1 	? 1 : 
									inf.AR_READY 							? 0 : ff_read_req;
end

always_comb begin
	inf.AR_VALID 	= ff_read_req ? 1 : 0;
	inf.AR_ADDR 	= ff_read_req ? id_to_addr : 0;
end
//		output	AW_VALID,
//		output	AW_ADDR,
//write address
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_write_req <= 	0;
	else 			ff_write_req <= 	inf.C_in_valid && inf.C_r_wb == 1'b0	? 1 : 
										inf.AW_READY 							? 0 : ff_write_req;
end

always_comb begin
	inf.AW_VALID 	= ff_write_req ? 1 : 0;
	inf.AW_ADDR 	= ff_write_req ? id_to_addr_w : 0;
end


//read data
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_wait_rvalid <= 	0;
	else 			ff_wait_rvalid <= 	inf.AR_READY 	? 1 ://addr ready -> rready can be high until rvalid is high 
										inf.R_VALID 	? 0 : ff_wait_rvalid;
end

always_comb begin
	inf.R_READY		= ff_wait_rvalid ? 1 : 0;
end



//write data
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_write_data_req <= 	0;
	else			ff_write_data_req <= 	inf.AW_READY 	? 1 : 
											inf.W_READY		? 0 : ff_write_data_req;
end

/* always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_wait_wready <= 	0;
	else			ff_wait_wready <= 	inf.AW_VALID 	? 1	:
										inf.W_READY		? 0	: ff_wait_wready;
		
end
 */
logic [31:0] ff_w_data;
/* always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_w_data <= 0;
	else 			ff_w_data <= 	inf.W_READY ? {inf.C_data_w[7:0], inf.C_data_w[15:8], inf.C_data_w[23:16], inf.C_data_w[31:24]}:
									inf.R_VALID || inf.B_VALID ? {inf.R_DATA[7:0], inf.R_DATA[15:8], inf.R_DATA[23:16], inf.R_DATA[31:24]}:
									ff_w_data;
end
 */


always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_w_data <= 0;
	else 			ff_w_data <= {inf.C_data_w[7:0], inf.C_data_w[15:8], inf.C_data_w[23:16], inf.C_data_w[31:24]}; 
end

always_comb begin
	//inf.W_DATA 	= {inf.C_data_w[7:0], inf.C_data_w[15:8], inf.C_data_w[23:16], inf.C_data_w[31:24]};
	inf.W_DATA 	= ff_w_data;
	inf.W_VALID = ff_write_data_req;
end

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_wait_bresp <= 	0;
	else 			ff_wait_bresp <= 	inf.AW_READY 	? 1 :
										inf.B_VALID 	? 0 : ff_wait_bresp;
end

always_comb begin
	inf.B_READY = ff_wait_bresp;
end

//output to farm
logic 			ff_r_valid;
logic [31:0]	ff_c_data_r;
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_r_valid <= 	0;
	else 			ff_r_valid <= 	inf.R_VALID || inf.B_VALID;
end
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)	ff_c_data_r <= 	0;
	else 			ff_c_data_r <= 	inf.R_VALID || inf.B_VALID ? 
									{inf.R_DATA[7:0], inf.R_DATA[15:8], inf.R_DATA[23:16], inf.R_DATA[31:24]} : ff_c_data_r;
end

always_comb begin
	//inf.C_out_valid	= inf.R_VALID || inf.B_VALID;
	inf.C_out_valid	= ff_r_valid;
	//inf.C_data_r	= {inf.R_DATA[7:0], inf.R_DATA[15:8], inf.R_DATA[23:16], inf.R_DATA[31:24]};
	inf.C_data_r	= ff_c_data_r;
	//inf.C_data_r	= ff_w_data;
	//inf.C_data_r	= inf.R_DATA;
end


endmodule