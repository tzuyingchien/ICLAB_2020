module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
//output [8:0] out_n;         							// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
output reg [9:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment


wire [6:0]	sel_0, sel_1, sel_2, sel_3, sel_4, sel_5;
wire [6:0]	id_0, id_1, id_2, id_3, id_4, id_5;
wire [3:0]	gm_0, gm_1, gm_2, gm_3, gm_4, gm_5;
wire [9:0]	cal_out_0, cal_out_1, cal_out_2, cal_out_3, cal_out_4, cal_out_5;
wire [9:0]	sort0_out_0, sort0_out_1, sort0_out_2, sort0_out_3, sort0_out_4, sort0_out_5,
			sort1_out_0, sort1_out_1, sort1_out_2, sort1_out_3, sort1_out_4, sort1_out_5,
			sort2_out_0, sort2_out_1, sort2_out_2, sort2_out_3, sort2_out_4, sort2_out_5,
			sort3_out_0, sort3_out_1, sort3_out_2, sort3_out_3, sort3_out_4, sort3_out_5,
			sort4_out_0, sort4_out_1, sort4_out_2, sort4_out_3, sort4_out_4, sort4_out_5,
			sort5_out_0, sort5_out_1, sort5_out_2, sort5_out_3, sort5_out_4, sort5_out_5;
wire [9:0]	mulin_1, mulin_2, mulin_3;
//wire [9:0] 	add_1, add_2, add_3;
wire [9:0] 	secadd_1, secadd_2, secadd_3;



//================================================================
//    DESIGN
//================================================================
// --------------------------------------------------
// write your design here
// --------------------------------------------------

cal_id cal_id(		.W_0(W_0), .V_GS_0(V_GS_0), .V_DS_0(V_DS_0),
					.W_1(W_1), .V_GS_1(V_GS_1), .V_DS_1(V_DS_1),
					.W_2(W_2), .V_GS_2(V_GS_2), .V_DS_2(V_DS_2),
					.W_3(W_3), .V_GS_3(V_GS_3), .V_DS_3(V_DS_3),
					.W_4(W_4), .V_GS_4(V_GS_4), .V_DS_4(V_DS_4),
					.W_5(W_5), .V_GS_5(V_GS_5), .V_DS_5(V_DS_5),
					.id_0(id_0), .id_1(id_1), .id_2(id_2), .id_3(id_3), .id_4(id_4), .id_5(id_5));
cal_gm cal_gm(		.W_0(W_0), .V_GS_0(V_GS_0), .V_DS_0(V_DS_0),
					.W_1(W_1), .V_GS_1(V_GS_1), .V_DS_1(V_DS_1),
					.W_2(W_2), .V_GS_2(V_GS_2), .V_DS_2(V_DS_2),
					.W_3(W_3), .V_GS_3(V_GS_3), .V_DS_3(V_DS_3),
					.W_4(W_4), .V_GS_4(V_GS_4), .V_DS_4(V_DS_4),
					.W_5(W_5), .V_GS_5(V_GS_5), .V_DS_5(V_DS_5),
					.gm_0(gm_0), .gm_1(gm_1), .gm_2(gm_2), .gm_3(gm_3), .gm_4(gm_4), .gm_5(gm_5));

cal	cal(			.mode_0(mode[0]), .W_0(W_0), .W_1(W_1), .W_2(W_2), .W_3(W_3), .W_4(W_4), .W_5(W_5), 
					.in_0(sel_0), .in_1(sel_1), .in_2(sel_2), .in_3(sel_3), .in_4(sel_4), .in_5(sel_5),
					.cal_out_0(cal_out_0), .cal_out_1(cal_out_1), .cal_out_2(cal_out_2), .cal_out_3(cal_out_3), .cal_out_4(cal_out_4), .cal_out_5(cal_out_5)
					);

sort_0 sort_0		(.in_0(cal_out_0), .in_1(cal_out_1), .in_2(cal_out_2), .in_3(cal_out_3), .in_4(cal_out_4), .in_5(cal_out_5),
					.sort0_out_0(sort0_out_0), .sort0_out_1(sort0_out_1), .sort0_out_2(sort0_out_2), .sort0_out_3(sort0_out_3), .sort0_out_4(sort0_out_4), .sort0_out_5(sort0_out_5));

sort_1 sort_1		(.in_0(sort0_out_0), .in_1(sort0_out_1), .in_2(sort0_out_2), .in_3(sort0_out_3), .in_4(sort0_out_4), .in_5(sort0_out_5),
					.sort1_out_0(sort1_out_0), .sort1_out_1(sort1_out_1), .sort1_out_2(sort1_out_2), .sort1_out_3(sort1_out_3), .sort1_out_4(sort1_out_4), .sort1_out_5(sort1_out_5));

sort_0 sort_2		(.in_0(sort1_out_0), .in_1(sort1_out_1), .in_2(sort1_out_2), .in_3(sort1_out_3), .in_4(sort1_out_4), .in_5(sort1_out_5),
					.sort0_out_0(sort2_out_0), .sort0_out_1(sort2_out_1), .sort0_out_2(sort2_out_2), .sort0_out_3(sort2_out_3), .sort0_out_4(sort2_out_4), .sort0_out_5(sort2_out_5));

sort_1 sort_3		(.in_0(sort2_out_0), .in_1(sort2_out_1), .in_2(sort2_out_2), .in_3(sort2_out_3), .in_4(sort2_out_4), .in_5(sort2_out_5),
					.sort1_out_0(sort3_out_0), .sort1_out_1(sort3_out_1), .sort1_out_2(sort3_out_2), .sort1_out_3(sort3_out_3), .sort1_out_4(sort3_out_4), .sort1_out_5(sort3_out_5));

sort_0 sort_4		(.in_0(sort3_out_0), .in_1(sort3_out_1), .in_2(sort3_out_2), .in_3(sort3_out_3), .in_4(sort3_out_4), .in_5(sort3_out_5),
					.sort0_out_0(sort4_out_0), .sort0_out_1(sort4_out_1), .sort0_out_2(sort4_out_2), .sort0_out_3(sort4_out_3), .sort0_out_4(sort4_out_4), .sort0_out_5(sort4_out_5));

sort_1 sort_5		(.in_0(sort4_out_0), .in_1(sort4_out_1), .in_2(sort4_out_2), .in_3(sort4_out_3), .in_4(sort4_out_4), .in_5(sort4_out_5),
					.sort1_out_0(sort5_out_0), .sort1_out_1(sort5_out_1), .sort1_out_2(sort5_out_2), .sort1_out_3(sort5_out_3), .sort1_out_4(sort5_out_4), .sort1_out_5(sort5_out_5));




assign	sel_0 = (mode[0])	?	id_0 : gm_0;
assign	sel_1 = (mode[0])	?	id_1 : gm_1;
assign	sel_2 = (mode[0])	?	id_2 : gm_2;
assign	sel_3 = (mode[0])	?	id_3 : gm_3;
assign	sel_4 = (mode[0])	?	id_4 : gm_4;
assign	sel_5 = (mode[0])	?	id_5 : gm_5;


//cal ans


assign	mulin_1 = mode[1]	?	sort5_out_0	:	sort5_out_3;
assign	mulin_2 = mode[1]	?	sort5_out_1	:	sort5_out_4;
assign	mulin_3 = mode[1]	?	sort5_out_2	:	sort5_out_5;

assign	secadd_1 = mode[0] ? 3 * mulin_1 : mulin_1;
assign	secadd_2 = mode[0] ? 4 * mulin_2 : mulin_2;
assign	secadd_3 = mode[0] ? 5 * mulin_3 : mulin_3;

always@(*) begin
	out_n = secadd_1 + secadd_2 + secadd_3;
end 




endmodule

//================================================================
//   SUB MODULE
//================================================================

// module BBQ (meat,vagetable,water,cost);
// input XXX;
// output XXX;
// 
// endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
// 	out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
// 	case(op)
// 		2'b00: output_reg = a + b;
// 		2'b10: output_reg = a - b;
// 		2'b01: output_reg = a * b;
// 		2'b11: output_reg = a / b;
// 		default: output_reg = 0;
// 	endcase
// end
// --------------------------------------------------

module	cal_id(		W_0, V_GS_0, V_DS_0,
					W_1, V_GS_1, V_DS_1,
					W_2, V_GS_2, V_DS_2,
					W_3, V_GS_3, V_DS_3,
					W_4, V_GS_4, V_DS_4,
					W_5, V_GS_5, V_DS_5,
					id_0, id_1, id_2, id_3, id_4, id_5
);

input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
output[6:0]	id_0, id_1, id_2, id_3, id_4, id_5;

assign id_0 = (V_GS_0  > (V_DS_0 + 1))	?	V_DS_0 * ((V_GS_0 * 2) - 2 - V_DS_0) : (V_GS_0 * V_GS_0 - V_GS_0 * 2 + 1);
assign id_1 = (V_GS_1  > (V_DS_1 + 1))	?	V_DS_1 * ((V_GS_1 * 2) - 2 - V_DS_1) : (V_GS_1 * V_GS_1 - V_GS_1 * 2 + 1);
assign id_2 = (V_GS_2  > (V_DS_2 + 1))	?	V_DS_2 * ((V_GS_2 * 2) - 2 - V_DS_2) : (V_GS_2 * V_GS_2 - V_GS_2 * 2 + 1);
assign id_3 = (V_GS_3  > (V_DS_3 + 1))	?	V_DS_3 * ((V_GS_3 * 2) - 2 - V_DS_3) : (V_GS_3 * V_GS_3 - V_GS_3 * 2 + 1);
assign id_4 = (V_GS_4  > (V_DS_4 + 1))	?	V_DS_4 * ((V_GS_4 * 2) - 2 - V_DS_4) : (V_GS_4 * V_GS_4 - V_GS_4 * 2 + 1);
assign id_5 = (V_GS_5  > (V_DS_5 + 1))	?	V_DS_5 * ((V_GS_5 * 2) - 2 - V_DS_5) : (V_GS_5 * V_GS_5 - V_GS_5 * 2 + 1);


endmodule
module cal_gm(		W_0, V_GS_0, V_DS_0,
					W_1, V_GS_1, V_DS_1,
					W_2, V_GS_2, V_DS_2,
					W_3, V_GS_3, V_DS_3,
					W_4, V_GS_4, V_DS_4,
					W_5, V_GS_5, V_DS_5,
					gm_0, gm_1, gm_2, gm_3, gm_4, gm_5
);

input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
output [3:0]	gm_0, gm_1, gm_2, gm_3, gm_4, gm_5;
wire  [2:0]	tmp_0, tmp_1, tmp_2, tmp_3, tmp_4, tmp_5;

assign tmp_0 = (V_GS_0  > (V_DS_0 + 1))	?  V_DS_0 : (V_GS_0 - 1) ;
assign tmp_1 = (V_GS_1  > (V_DS_1 + 1))	?  V_DS_1 : (V_GS_1 - 1) ;
assign tmp_2 = (V_GS_2  > (V_DS_2 + 1))	?  V_DS_2 : (V_GS_2 - 1) ;
assign tmp_3 = (V_GS_3  > (V_DS_3 + 1))	?  V_DS_3 : (V_GS_3 - 1) ;
assign tmp_4 = (V_GS_4  > (V_DS_4 + 1))	?  V_DS_4 : (V_GS_4 - 1) ;
assign tmp_5 = (V_GS_5  > (V_DS_5 + 1))	?  V_DS_5 : (V_GS_5 - 1) ;

assign gm_0 = tmp_0 * 2;
assign gm_1 = tmp_1 * 2;
assign gm_2 = tmp_2 * 2;
assign gm_3 = tmp_3 * 2;
assign gm_4 = tmp_4 * 2;
assign gm_5 = tmp_5 * 2;

endmodule


module cal(mode_0, W_0, W_1, W_2, W_3, W_4, W_5, in_0, in_1, in_2, in_3, in_4, in_5, cal_out_0, cal_out_1, cal_out_2, cal_out_3, cal_out_4, cal_out_5);

input	mode_0;
input	[2:0]	W_0, W_1, W_2, W_3, W_4, W_5;
input	[6:0]	in_0, in_1, in_2, in_3, in_4, in_5;
output	[9:0]	cal_out_0, cal_out_1, cal_out_2, cal_out_3, cal_out_4, cal_out_5;




assign	cal_out_0 = ((W_0 * in_0)) / 3;
assign	cal_out_1 = ((W_1 * in_1)) / 3;
assign	cal_out_2 = ((W_2 * in_2)) / 3;
assign	cal_out_3 = ((W_3 * in_3)) / 3;
assign	cal_out_4 = ((W_4 * in_4)) / 3;
assign	cal_out_5 = ((W_5 * in_5)) / 3;


endmodule




module sort_0(in_0, in_1, in_2, in_3, in_4, in_5, sort0_out_0, sort0_out_1, sort0_out_2, sort0_out_3, sort0_out_4, sort0_out_5);

input	[9:0]	in_0, in_1, in_2, in_3, in_4, in_5;
output	reg [9:0]	sort0_out_0, sort0_out_1, sort0_out_2, sort0_out_3, sort0_out_4, sort0_out_5;


always@(*) begin
 			if(in_0 > in_1) begin
				sort0_out_0 = in_0;
				sort0_out_1 = in_1;
			end
			else begin
				sort0_out_0 = in_1;
				sort0_out_1 = in_0;
			end
			if(in_2 > in_3) begin
				sort0_out_2 = in_2;
				sort0_out_3 = in_3;
			end
			else begin
				sort0_out_2 = in_3;
				sort0_out_3 = in_2;
			end
			if(in_4 > in_5) begin
				sort0_out_4 = in_4;
				sort0_out_5 = in_5;
			end
			else begin
				sort0_out_4 = in_5;
				sort0_out_5 = in_4;
			end
 end  
endmodule

module sort_1(in_0, in_1, in_2, in_3, in_4, in_5, sort1_out_0, sort1_out_1, sort1_out_2, sort1_out_3, sort1_out_4, sort1_out_5);

input	[9:0]	in_0, in_1, in_2, in_3, in_4, in_5;
output	reg [9:0]	sort1_out_0, sort1_out_1, sort1_out_2, sort1_out_3, sort1_out_4, sort1_out_5;

always@(*) begin
			sort1_out_0 = in_0;
			
 			if(in_1 > in_2) begin
				sort1_out_1 = in_1;
				sort1_out_2 = in_2;
			end
			else begin
				sort1_out_1 = in_2;
				sort1_out_2 = in_1;
			end
			if(in_3 > in_4) begin
				sort1_out_3 = in_3;
				sort1_out_4 = in_4;
			end
			else begin
				sort1_out_3 = in_4;
				sort1_out_4 = in_3;
			end 			
			
			sort1_out_5 = in_5;
end 
endmodule

























