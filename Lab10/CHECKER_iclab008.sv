//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

logic[15:0]	water_range;
//covergroup Spec1 @();
//	
//       finish your covergroup here
//	
//	
//endgroup

//declare other cover group



//declare the cover group 
//Spec1 cov_inst_1 = new();


covergroup Spec1 @(posedge clk && inf.amnt_valid);
	coverpoint inf.D.d_amnt{
		option.at_least = 100;
		bins s0 = {[0:12000]};
		bins s1 = {[12001:24000]};
		bins s2 = {[24001:36000]};
		bins s3 = {[36001:48000]};
		bins s4 = {[48001:60000]};
	}
endgroup

covergroup Spec2 @(posedge clk && inf.id_valid);
	coverpoint inf.D.d_id[0]{
		option.at_least = 10;
		option.auto_bin_max = 255;
	}
endgroup
covergroup Spec3 @(posedge clk && inf.act_valid);
	coverpoint inf.D.d_act[0]{
		option.at_least = 10;
		bins s0 = (Seed => Seed);
		bins s1 = (Seed => Water);
		bins s2 = (Seed => Reap);
		bins s3 = (Seed => Steal);
		bins s4 = (Seed => Check_dep);
		
		bins s5 = (Water => Seed);
		bins s6 = (Water => Water);
		bins s7 = (Water => Reap);
		bins s8 = (Water => Steal);
		bins s9 = (Water => Check_dep);
		
		bins s10 = (Reap => Seed);
		bins s11 = (Reap => Water);
		bins s12 = (Reap => Reap);
		bins s13 = (Reap => Steal);
		bins s14 = (Reap => Check_dep);

		bins s15 = (Steal => Seed);
		bins s16 = (Steal => Water);
		bins s17 = (Steal => Reap);
		bins s18 = (Steal => Steal);
		bins s19 = (Steal => Check_dep);

		bins s20 = (Check_dep => Seed);
		bins s21 = (Check_dep => Water);
		bins s22 = (Check_dep => Reap);
		bins s23 = (Check_dep => Steal);
		bins s24 = (Check_dep => Check_dep);
	}
endgroup
covergroup Spec4 @(posedge clk && inf.out_valid);
	coverpoint inf.err_msg{
		option.at_least = 100;
		bins s0 = {Is_Empty};
		bins s1 = {Not_Empty};
		bins s2 = {Has_Grown};
		bins s3 = {Not_Grown};
	}
endgroup

Spec1 spec1_inst = new();
Spec2 spec2_inst = new();
Spec3 spec3_inst = new();
Spec4 spec4_inst = new();
//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0)
// else
// begin
// 	$display("Assertion X is violated");
// 	$fatal; 
// end

//write other assertions
//=====================================
logic clk_0;
always@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)		clk_0 <= 0;
	else if(inf.rst_n)	clk_0 <= 1;
end

rule_1 : assert property (property_1) 
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end

property property_1;
	@(posedge clk_0) 	(inf.out_valid == 1'b0 && inf.err_msg == 4'b0 && inf.complete == 1'b0
							&& inf.out_info == 32'b0 && inf.out_deposit == 32'b0);
endproperty : property_1

 
//=====================================
rule_2 : assert property (property_2) 
else
begin
	$display("Assertion 2 is violated");
	$fatal; 
end

property property_2;
	@(negedge clk) 	(inf.complete |-> inf.err_msg == 4'b0);
endproperty : property_2
 
//=====================================
rule_3 : assert property (property_3) 
else
begin
	$display("Assertion 3 is violated");
	$fatal; 
end

/* property property_3;
	@(negedge clk) 	( (inf.act_valid && inf.D.d_act[0] == Check_dep) |-> (##[1:$] inf.out_valid |-> (inf.out_info == 32'b0)));
endproperty : property_3
 */


property property_3;
	@(negedge clk) 	( (inf.act_valid && inf.D.d_act[0] == Check_dep)|-> inf.out_valid[->1] |-> (inf.out_info == 32'b0));
endproperty : property_3

//=====================================
rule_4 : assert property (property_4) 
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

property property_4;
	@(negedge clk) 	( (inf.act_valid && inf.D.d_act[0] != Check_dep)|-> inf.out_valid[->1] |-> (inf.out_deposit == 32'b0));
endproperty : property_4

//=====================================
rule_5 : assert property (property_5) 
else
begin
	$display("Assertion 5 is violated");
	$fatal; 
end

property property_5;
	@(negedge clk)  inf.out_valid |=> !inf.out_valid;
endproperty : property_5

//=====================================
rule_6 : assert property (property_6) 
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

property property_6;
	@(negedge clk)  inf.id_valid |=> !inf.act_valid;
endproperty : property_6

//=====================================
rule_7 : assert property (property_7) 
else
begin
	$display("Assertion 7 is violated");
	$fatal; 
end

property property_7;
	@(posedge clk)  inf.act_valid && inf.D.d_act[0] == Seed |-> inf.cat_valid[->1] |=> !inf.amnt_valid;
endproperty : property_7

//=====================================
rule_8_1 : assert property (property_8_1) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

property property_8_1;
	@(posedge clk)  inf.id_valid |-> (!inf.act_valid && !inf.cat_valid && !inf.amnt_valid);
endproperty : property_8_1

//
rule_8_2 : assert property (property_8_2) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

property property_8_2;
	@(posedge clk)  inf.act_valid |-> (!inf.id_valid && !inf.cat_valid && !inf.amnt_valid);
endproperty : property_8_2

//
rule_8_3 : assert property (property_8_3) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

property property_8_3;
	@(posedge clk)  inf.cat_valid |-> (!inf.act_valid && !inf.id_valid && !inf.amnt_valid);
endproperty : property_8_3

//
rule_8_4 : assert property (property_8_4) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

property property_8_4;
	@(posedge clk)  inf.amnt_valid |-> (!inf.act_valid && !inf.cat_valid && !inf.id_valid);
endproperty : property_8_4

//=====================================
rule_9_1 : assert property (property_9_1) 
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

property property_9_1;
	@(posedge clk)  inf.out_valid |-> ##[2:10] (inf.id_valid || inf.act_valid );
endproperty : property_9_1

rule_9_2 : assert property (property_9_2) 
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

property property_9_2;
	@(posedge clk)  inf.out_valid |-> ##1 (!inf.id_valid && !inf.act_valid );
endproperty : property_9_2
//=====================================
rule_10_1 : assert property (property_10_1) 
else
begin
	$display("Assertion 10 is violated");
	$fatal; 
end

property property_10_1;
	@(negedge clk)  inf.act_valid && (inf.D.d_act[0] == Seed || inf.D.d_act[0] == Water) |-> inf.amnt_valid[->1] |-> ##[1:1199] inf.out_valid;
endproperty : property_10_1
//
rule_10_2 : assert property (property_10_2) 
else
begin
	$display("Assertion 10 is violated");
	$fatal; 
end

property property_10_2;
	@(negedge clk)  inf.act_valid && (inf.D.d_act[0] == Reap || inf.D.d_act[0] == Steal || inf.D.d_act[0] == Check_dep) |-> ##[1:1199] inf.out_valid;
endproperty : property_10_2
//

endmodule