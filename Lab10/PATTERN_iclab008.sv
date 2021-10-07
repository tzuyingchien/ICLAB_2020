
`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"
`include "success.sv"
program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;


//===================================================================
//	PARAMETER DECLARATION
//===================================================================
int 	PATCNT;
int 	PATNUM = 2600;
int 	dram;

parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
logic [7:0] golden_DRAM [((65536 + 256 * 4) - 1) : 65536];
int err_1, err_2, err_3, err_4;
logic [7:0] cnt_id[254:0];
int j;
int action;


//===================================================================
//	INITIAL
//===================================================================
initial begin
	//dram = $fopen("../00_TESTBED/DRAM/dram.dat", "w");
	//gen_data;
	//$finish;


	$readmemh(DRAM_p_r, golden_DRAM);

	inf.rst_n 		= 'b1;
    inf.act_valid   = 'd0;
    inf.id_valid    = 'd0;
    inf.cat_valid   = 'd0;
    inf.amnt_valid  = 'd0;
    inf.D           = 'dx;

	#1;	reset;
	//#1;
	
	err_1 = 0;
	err_2 = 0;
	err_3 = 0;
	err_4 = 0;
	for(j=0; j<255; j++)	cnt_id[j] = 0;
	
	//delay;
	
  	for(PATCNT = 0; PATCNT < PATNUM; PATCNT++)
		begin
			if(PATCNT < 197)						cyclic_group;
			else if (PATCNT > 196 && PATCNT < 207)	check_deposit;
			else if (PATCNT === 207)				steal_cyclic;
			else if (PATCNT === 208)				reap_cyclic;
			else if (PATCNT === 209)				water_cyclic;
			else if (PATCNT === 210)				seed;
			else if (PATCNT > 210 && PATCNT < 270)	seed_seq;
			else if ((PATCNT > 269 && PATCNT < 470)||(PATCNT > 489 && PATCNT < 650))	water_seq;
			else if ((PATCNT > 469 && PATCNT < 490) || (PATCNT > 660))	reap_seq;
			else if (PATCNT > 649 && PATCNT < 661)	steal_seq;
	
			reset_input_signal;
			wait_outvalid;
			cnt_error;
			check_id;
			//repeat(1)@(negedge clk);
			//$display("pattern %d pass ; action is %d; id is %d", PATCNT, action, id);
			//$display("err_msg:%d,%d,%d,%d", err_1, err_2, err_3, err_4);
		end
		
end

//===================================================================
//	TASK
//===================================================================
logic	[19:0]addr;
int 	i, water;


task gen_data; begin
	for(i = 0; i < 256; i++)
		begin
			addr = 17'h10000 + (i<<2);
			$fwrite(dram, "@%h\n", addr);
			
			//deposit
			if(i === 255)	$fwrite(dram, "%h %h %h %h \n", 8'h0, 8'h0, 8'hf0, 8'h0);
			
			//seed
			else if(i === 0 || i === 4 || i === 8 || i === 12 || i === 16 || i === 17 || i === 18 || i === 19 || i === 20 || i === 21)
				$fwrite(dram, "%h %h %h %h \n", i[7:0], 8'h22, 8'h0, 8'h2);//doesn't matter
			
			//water
			else if (i === 1 || i === 6 || i ===  10 || i === 15)
				$fwrite(dram, "%h %h %h %h \n", i[7:0], 8'h21, 8'h0, 8'h2);//doesn't matter
			
			//water : land is empty
			else if(i > 21 && i < 32)
				$fwrite(dram, "%h %h %h %h \n", i[7:0], 8'h10, 8'h0, 8'h0);
			
			//water : needs no more water
			else if (i > 31 && i < 42)	
				$fwrite(dram, "%h %h %h %h \n", i[7:0], 8'h84, 8'h22, 8'h00);//bigger than 16'h2000
				
			//reap : hasn't grown up
			else if (i === 2 || i === 3 || i === 5 || i === 7 || i === 9 || i === 11 || i === 13 || i === 14 || i === 42 || i === 43)
				$fwrite(dram, "%h %h %h %h \n", i[7:0], 8'h21, 8'h00, 8'h01);
				
			//water : land is empty
			else if (i > 43 && i < 60)
				$fwrite(dram, "%h %h %h %h \n", i[7:0], 8'h10, 8'h0, 8'h0);
			
			//reap or steal : land is empty
			else 
				$fwrite(dram, "%h %h %h %h \n", i[7:0], 8'h10, 8'h0, 8'h0);
		end
end endtask


task cyclic_group; begin
	if(PATCNT % 5 === 0)		
		seed;
 	else if(PATCNT % 20 === 1 || PATCNT % 20 === 8 || PATCNT % 20 === 12 || PATCNT % 20 === 19)
		water_cyclic;
	else if(PATCNT % 20 === 2 || PATCNT % 20 === 6 || PATCNT % 20 === 14 || PATCNT % 20 === 18)
		reap_cyclic;
	else if(PATCNT % 20 === 3 || PATCNT % 20 === 9 || PATCNT % 20 === 11 || PATCNT % 20 === 17)
		steal_cyclic;
	else 
		check_deposit;
	





end endtask
integer id, tmp;
task seed; begin
	action = 4'b0001;
	if(PATCNT === 210)			id = 'd16;
	else if(PATCNT % 20 === 0)	id = 'd0;
	else if(PATCNT % 20 === 5)	id = 'd4;
	else if(PATCNT % 20 === 10) id = 'd8;
	else if(PATCNT % 20 === 15) id = 'd12;

	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= 16'd1;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd1;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= 16'd4;
	reset_input_signal;
	
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd1;
	tmp 			= $urandom_range(24001,36000);
	inf.D		 	= tmp[15:0];
end endtask


task water_cyclic; begin
	action = 4'b0011;
	if(PATCNT === 209)			id = 'd15;
	else if(PATCNT % 20 === 1)	id = 'd1;
	else if(PATCNT % 20 === 8)	id = 'd6;
	else if(PATCNT % 20 === 12) id = 'd10;
	else if(PATCNT % 20 === 19) id = 'd15;
	
	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= {12'd0, 4'b0011};
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd1;
	tmp				= $urandom_range(12001,24000);
	inf.D		 	= tmp[15:0];
end endtask

task reap_cyclic; begin
	action = 4'b0010;
	if(PATCNT === 208)			id = 'd14;
	else if(PATCNT % 20 === 2)	id = 'd2;
	else if(PATCNT % 20 === 6)	id = 'd5;
	else if(PATCNT % 20 === 14) id = 'd11;
	else if(PATCNT % 20 === 18) id = 'd14;

	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= {12'd0, 4'b0010};
end endtask

task steal_cyclic; begin
	action = 4'b0100;
	if(PATCNT === 207)			id = 'd13;
	else if(PATCNT % 20 === 3)	id = 'd3;
	else if(PATCNT % 20 === 9)	id = 'd7;
	else if(PATCNT % 20 === 11) id = 'd9;
	else if(PATCNT % 20 === 17) id = 'd13;

	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= {12'd0, 4'b0100};
end endtask

task check_deposit; begin
	action = 4'b1000;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= {12'd0, 4'b1000};
end endtask


//================================================================
task seed_seq; begin
	action = 4'b0001;
	if(PATCNT % 6 === 0)		id = 'd16;
	else if(PATCNT % 6 === 1)	id = 'd17;
	else if(PATCNT % 6 === 2) 	id = 'd18;
	else if(PATCNT % 6 === 3) 	id = 'd19;
	else if(PATCNT % 6 === 4) 	id = 'd20;
	else if(PATCNT % 6 === 5) 	id = 'd21;

	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= 16'd1;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd1;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= 16'd4;
	reset_input_signal;
	
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd1;
	tmp 			= $urandom_range(24001,36000);
	inf.D		 	= tmp[15:0];
end endtask

task water_seq; begin
	action = 4'b0011;
	if(PATCNT > 369 && PATCNT < 470) 		id = PATCNT % 10 + 'd22;
	else if(PATCNT > 269 && PATCNT < 370)	id = PATCNT % 10 + 'd32;
	else if(PATCNT > 489 && PATCNT < 650)	id = PATCNT % 16 + 'd44;
	
	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= {12'd0, 4'b0011};
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd1;
	if(PATCNT > 369 && PATCNT < 470) 				tmp	= $urandom_range(36001,48000);
	else if(PATCNT > 269 && PATCNT < 370)			tmp	= $urandom_range(48001,60000);
	else if(PATCNT > 489 && PATCNT < 550)			tmp	= $urandom_range(12001,24000);
	else if(PATCNT > 549 && PATCNT < 650)			tmp	= $urandom_range(0,12000);
	inf.D		 	= tmp[15:0];
end endtask

task reap_seq; begin
	action = 4'b0010;
	if(PATCNT < 490)
		begin
			if(PATCNT[0] === 0)	id = 'd42;
			else 				id = 'd43;
		end
	else 
		begin
			if (PATCNT % 194 < 78) 	id = PATCNT % 194 + 'd177;
			else					id = PATCNT % 194 - 'd17;
		end

	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= {12'd0, 4'b0010};
end endtask

task steal_seq; begin
	action = 4'b0100;
	if(PATCNT === 660)	id = 'd61;
	else 				id = 'd60;
	
	@(negedge clk);
	inf.id_valid   	= 'd1;
	inf.act_valid  	= 'd0;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D			= id[15:0];
	reset_input_signal;
	@(negedge clk);
	inf.id_valid   	= 'd0;
	inf.act_valid  	= 'd1;
	inf.cat_valid  	= 'd0;
	inf.amnt_valid 	= 'd0;
	inf.D		 	= {12'd0, 4'b0100};
end endtask
//================================================================
integer lat, total_lat;
task wait_outvalid; begin
	lat = -1;
	while(inf.out_valid !== 'd1) begin
		//lat = lat + 1;
		//if(lat === 1200) begin
		//	$display("------------------------------------------------------------------------");				
		//	$display("                       latency over 1200 cycles                         ");
		//	$display("*                          PATTERN NO.%4d 	                          ",PATCNT);
		//	$display("------------------------------------------------------------------------");
		//	repeat(2) @(negedge clk);
		//	$finish;
		//end
		@(negedge clk);
	end
	total_lat = total_lat + lat;
end endtask
//================================================================
task cnt_error; begin
	if(inf.err_msg === 4'b0001)	err_1 = err_1 + 'd1;
	if(inf.err_msg === 4'b0010)	err_2 = err_2 + 'd1;
	if(inf.err_msg === 4'b0011)	err_3 = err_3 + 'd1;
	if(inf.err_msg === 4'b0100)	err_4 = err_4 + 'd1;
	@(negedge clk);
end endtask


task check_id; begin
	cnt_id[id[7:0]] = cnt_id[id[7:0]] + 'd1;
end endtask



//================================================================
task reset_input_signal; begin 
	@(negedge clk);
	inf.id_valid   <= 'd0;
	inf.act_valid  <= 'd0;
	inf.cat_valid  <= 'd0;
	inf.amnt_valid <= 'd0;
	inf.D <= 16'hx;
end endtask
//================================================================
task reset; begin
		inf.rst_n 		<= 0;
		#7.5;
/* 		#1;
		if(inf.out_valid !== 0 || inf.err_msg !== 'd0 || inf.complete !== 'd0 || inf.out_info !== 'd0 || inf.out_deposit !== 'd0)
			begin
				$display("------------------------------------------------------------------------");
				$display("                       Output signals should be reset                   ");
				$display("------------------------------------------------------------------------");
				$finish;
			
			end
 */		#7.5;	inf.rst_n <= 1;
end endtask
//================================================================
integer gap;
task delay; begin
	gap = $urandom_range(1, 3);
	repeat(gap)@(negedge clk);
end endtask






































endprogram