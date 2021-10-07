//synopsys translate_off
`include "CS_IP.v"
//synopsys translate_on

module CS
#(parameter WIDTH_DATA_1 = 384, parameter WIDTH_RESULT_1 = 8,
parameter WIDTH_DATA_2 = 128, parameter WIDTH_RESULT_2 = 8)
(
    data,
    in_valid,
    clk,
    rst_n,
    result,
    out_valid
);

input [511:0] data;
input in_valid, clk, rst_n;

output reg [(WIDTH_RESULT_1 + WIDTH_RESULT_2 -1):0] result;
output reg out_valid;
// ================================================================
//    reg and wire declaration
// ================================================================
reg [1:0] cnt;
wire [7:0] out_1, out_2, out_3, out_4;
wire out_valid_1, out_valid_2, out_valid_3, out_valid_4;

//call CS_IP.v
CS_IP #(128,8) CS_IP_1//data_2
(
    .data(data[127:0]),
    .in_valid(in_valid),
    .clk(clk),
    .rst_n(rst_n),
    .result(out_1),
    .out_valid(out_valid_1)
);

CS_IP #(128,8) CS_IP_2
(
    .data(data[255:128]),
    .in_valid(in_valid),
    .clk(clk),
    .rst_n(rst_n),
    .result(out_2),
    .out_valid(out_valid_2)
);

CS_IP #(128,8) CS_IP_3
(
    .data(data[383:256]),
    .in_valid(in_valid),
    .clk(clk),
    .rst_n(rst_n),
    .result(out_3),
    .out_valid(out_valid_3)
);

CS_IP #(128,8) CS_IP_4
(
    .data(data[511:384]),
    .in_valid(in_valid),
    .clk(clk),
    .rst_n(rst_n),
    .result(out_4),
    .out_valid(out_valid_4)
);

wire [8:0] tmp_final_1 = out_2 + out_3;
wire [9:0] tmp_final_2 = tmp_final_1 + out_4;
wire [8:0] final_1 = tmp_final_2[9:8] + tmp_final_2[7:0];
//wire [8:0] tmp_final_2 = final_1 + out_4;
wire [7:0] final_2 = final_1[8] + final_1[7:0];


always@(*) begin
	if(cnt == 2) result = {~final_2, ~out_1};
	else result = 0;
end




always@(negedge rst_n or posedge clk) begin
	if(!rst_n)	begin
		out_valid <= 0; 
		//result <= 0;
	end
	else begin
		if(cnt == 1) begin
			out_valid <= 1;
			//result <= {final_2, out_1};
		end
		else begin
			out_valid <= 0; 
			//result <= 0;
		end
	end
end

always@(negedge rst_n or posedge clk) begin
	if(!rst_n)	begin
		cnt <= 0;
	end
	else begin
		if(in_valid) cnt <= 1;
		else if(cnt == 1) cnt <= 2;
		//else if(out_valid) cnt <= 2;
		else cnt <= 0;
	end
end


















endmodule
