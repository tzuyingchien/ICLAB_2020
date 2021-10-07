module CS_IP
#(parameter WIDTH_DATA = 128, parameter WIDTH_RESULT =8)
(
    data,
    in_valid,
    clk,
    rst_n,
    result,
    out_valid
);

input [(WIDTH_DATA-1):0] data;
input in_valid, clk, rst_n;

output reg [(WIDTH_RESULT-1):0] result;
output reg out_valid;

//================================================================
// register
//================================================================
reg [1:0] cnt;
//================================================================
// combinational circuit : level 1
//================================================================
wire [WIDTH_RESULT-1:0] ans;
wire [8:0] tmp_final_1;

genvar i, j;
generate
	//case 128,8
	if(WIDTH_DATA == 'd128 && WIDTH_RESULT == 'd8) begin : if_case
		//first layer
		wire [8:0] 	out_0, out_1, out_2, out_3, out_4, out_5, out_6, out_7;
		wire [9:0]	out_8, out_9, out_10, out_11;
		
		assign		out_0 = data[7:0] 		+ data[15:8];
		assign		out_1 = data[23:16] 	+ data[31:24];
		assign		out_2 = data[39:32] 	+ data[47:40];
		assign		out_3 = data[55:48] 	+ data[63:56];
		assign		out_4 = data[71:64] 	+ data[79:72];
		assign		out_5 = data[87:80] 	+ data[95:88];
		assign		out_6 = data[103:96] 	+ data[111:104];
		assign		out_7 = data[119:112]	+ data[127:120];
		
		assign		out_8  = out_0 + out_1;
		assign		out_9  = out_2 + out_3;
		assign		out_10 = out_4 + out_5;
		assign		out_11 = out_6 + out_7;
		
		reg [9:0] 	l1_out_0, l1_out_1, l1_out_2, l1_out_3;
		always@(posedge clk or negedge rst_n) begin //ff
			if(!rst_n) begin
				l1_out_0 <= 0;
				l1_out_1 <= 0;
				l1_out_2 <= 0;
				l1_out_3 <= 0;
			end
			else begin
				l1_out_0 <= out_8;
				l1_out_1 <= out_9;
				l1_out_2 <= out_10;
				l1_out_3 <= out_11;
			end
		end
		
		//second layer
		wire[10:0] out2_0, out2_1;
		wire[11:0] out2_2;
		assign out2_0 = l1_out_0 + l1_out_1;
		assign out2_1 = l1_out_2 + l1_out_3;
		assign out2_2 = out2_0 + out2_1;
		wire[8:0] tmp_ans;
		assign tmp_ans = out2_2[11:8] + out2_2[7:0];
		assign ans = tmp_ans[8] + tmp_ans[7:0];
		
	end
	
/*  	if(WIDTH_DATA == 'd128 && WIDTH_RESULT == 'd8) begin :if_case
		for(i = WIDTH_RESULT; i <= WIDTH_DATA; i = i<<1) begin : loop_turn
			for(j = 0; j < (WIDTH_DATA / i )>>1; j = j + 1) begin : loop_datacnt
				wire [(WIDTH_RESULT+ $clog2(i) -4):0]tmp_1; 	
				wire [(WIDTH_RESULT+ $clog2(i) -4):0]tmp_2; 	
				wire [(WIDTH_RESULT+ $clog2(i) -3):0]tmp_ans;  
				//wire [WIDTH_RESULT-1:0]tmp_result;
				
 				if(i == WIDTH_RESULT)begin //the first turn
					assign tmp_1 	= data[WIDTH_RESULT * (j<<1) + WIDTH_RESULT - 1 : WIDTH_RESULT * (j<<1)];
					assign tmp_2 	= data[WIDTH_RESULT * ((j+1)<<1) - 1 :  WIDTH_RESULT * (j<<1) + WIDTH_RESULT];
					assign tmp_ans  = tmp_1 + tmp_2;
					//assign tmp_result = tmp_ans[WIDTH_RESULT] + tmp_ans[WIDTH_RESULT-1 : 0];
				end
 				else if (i == WIDTH_DATA>>1) begin //last turn
					assign tmp_1 	= if_case.loop_turn[i/2].loop_datacnt[0].tmp_ans;
					assign tmp_2 	= if_case.loop_turn[i/2].loop_datacnt[1].tmp_ans;
					assign tmp_ans  = tmp_1 + tmp_2;
					//assign ans 		= tmp_ans[WIDTH_RESULT] + tmp_ans[WIDTH_RESULT-1 : 0];
					assign tmp_final_1 = tmp_ans[11:8] + tmp_ans[7:0];
					assign ans = tmp_final_1[8] + tmp_final_1[7:0];
				end
 				else begin
					assign tmp_1 	= if_case.loop_turn[i/2].loop_datacnt[j*2].tmp_ans;
					assign tmp_2 	= if_case.loop_turn[i/2].loop_datacnt[j*2 + 1].tmp_ans;
					assign tmp_ans  = tmp_1 + tmp_2;
					//assign tmp_result = tmp_ans[WIDTH_RESULT] + tmp_ans[WIDTH_RESULT-1 : 0];
				end
 			end
		end 
	
	end
 */	else if(WIDTH_DATA == WIDTH_RESULT) begin : full_case // case 256,256 / 128,128
		assign ans 		= data[WIDTH_DATA-1 : 0];
	end
	else if (WIDTH_DATA == WIDTH_RESULT << 1) begin : twice_case
		wire [WIDTH_RESULT-1:0]tmp_1; 	
		wire [WIDTH_RESULT-1:0]tmp_2; 	
		wire [WIDTH_RESULT	:0]tmp_ans;  
	
		assign tmp_1 	= data[WIDTH_DATA-1 : WIDTH_RESULT];
		assign tmp_2 	= data[WIDTH_RESULT-1 : 0];
		assign tmp_ans 	= tmp_1 + tmp_2;
		assign ans 		= tmp_ans[WIDTH_RESULT] + tmp_ans[WIDTH_RESULT-1 : 0];
	
	end
	else begin : else_case
 		for(i = WIDTH_RESULT; i <= WIDTH_DATA; i = i<<1) begin : loop_turn
			for(j = 0; j < (WIDTH_DATA / i )/2; j = j + 1) begin : loop_datacnt
				
				wire [WIDTH_RESULT-1:0]tmp_1; 	
				wire [WIDTH_RESULT-1:0]tmp_2; 	
				wire [WIDTH_RESULT	:0]tmp_ans;  
				wire [WIDTH_RESULT-1:0]tmp_result;
				
				 if(i == WIDTH_RESULT)begin //the first turn
 					assign tmp_1 	= data[WIDTH_RESULT * (j*2) + WIDTH_RESULT - 1 : WIDTH_RESULT * (j*2)];
					assign tmp_2 	= data[WIDTH_RESULT * ((j+1)*2) - 1 :  WIDTH_RESULT * (j*2) + WIDTH_RESULT];				
					assign tmp_ans  = tmp_1 + tmp_2;
					assign tmp_result = tmp_ans[WIDTH_RESULT] + tmp_ans[WIDTH_RESULT-1 : 0];
				end
				else if (i == WIDTH_DATA/2) begin
					assign tmp_1 	= else_case.loop_turn[i/2].loop_datacnt[j*2].tmp_result;
					assign tmp_2 	= else_case.loop_turn[i/2].loop_datacnt[j*2 + 1].tmp_result;
					assign tmp_ans  = tmp_1 + tmp_2;
					assign ans 		= tmp_ans[WIDTH_RESULT] + tmp_ans[WIDTH_RESULT-1 : 0];
				end
				else begin
					assign tmp_1 	= else_case.loop_turn[i/2].loop_datacnt[j*2].tmp_result;
					assign tmp_2 	= else_case.loop_turn[i/2].loop_datacnt[j*2 + 1].tmp_result;
					assign tmp_ans  = tmp_1 + tmp_2;
					assign tmp_result = tmp_ans[WIDTH_RESULT] + tmp_ans[WIDTH_RESULT-1 : 0];
				end
			end
			
		end
	end
endgenerate





reg [WIDTH_RESULT-1:0]save_ans;
 always@(negedge rst_n or posedge clk) begin
	if(!rst_n)	save_ans <= 0;
	else begin
 			if(in_valid) save_ans <= ans;
			else save_ans <= save_ans;
 		
		
	end
end


always@(negedge rst_n or posedge clk) begin
	if(!rst_n)	begin
		out_valid <= 0; 
		result <= 0;
	end
	else begin
		if(WIDTH_DATA == 'd128 && WIDTH_RESULT == 'd8) begin
			if(cnt == 0) begin
				out_valid <= 1;
				result <= ans;
			end
			else begin
				out_valid <= 0; 
				result <= 0;
			end
		end
		else begin
			if(!in_valid && cnt == 0) begin
				out_valid <= 1;
				result <= save_ans;
			end
			else begin
				out_valid <= 0; 
				result <= 0;
			end
		end
	end
end

always@(negedge rst_n or posedge clk) begin
	if(!rst_n)	begin
		cnt <= 3;
	end
	else begin
		if(in_valid) cnt <= 0;
		else if(cnt == 0) begin
			if (WIDTH_DATA == 'd128 && WIDTH_RESULT == 'd8) begin
				cnt <= 2;
			end
			else begin
				cnt <= 1;
			end
		end
		else if(out_valid) cnt <= 2;
		else cnt <= cnt;
	end
end

 endmodule
