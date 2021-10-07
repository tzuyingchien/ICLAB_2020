module farm(input clk, INF.farm_inf inf);
import usertype::*;


//---------------------------------------------------------------------
//   DECLARATION                             
//---------------------------------------------------------------------
logic [1:0] 	cnt;
logic [1:0]		cnt_id;//the first input have nothing to write back 
logic 			input_finish;
logic			get_deposit;
logic 			check_deposit;
logic			wait_read;
logic [31:0]	ff_deposit;
logic [7:0]		ff_id;
logic [15:0]	ff_water, ff_water_dram;
logic 			ff_clear;//Success Reap or Steal (set to 1 in OUTPUT stage , set to 0 in IDLE stage)
logic [31:0]	ff_write_data; 
Crop_cat		ff_crop, ff_crop_dram;
Crop_sta		ff_state_dram;
Action			ff_act;
Error_Msg		ff_error;
enum logic [3:0] {IDLE, INPUT, S_DEPOSIT, WR, ERR_CHECK, SEED, WATER, OUTPUT, OUTPUT_0} cs;
//---------------------------------------------------------------------
//   FSM                             
//---------------------------------------------------------------------
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) cs <= IDLE;
	else 
		begin
			case(cs)
				IDLE:
					begin
						if(inf.act_valid && inf.D[3:0] == Check_dep)	cs <= get_deposit ? S_DEPOSIT : OUTPUT_0;//action is CHECK DEPOSIT
						else if (inf.id_valid || inf.act_valid)			cs <= INPUT;
						else											cs <= cs;
					end
				INPUT:		
					begin
						if(input_finish && !wait_read) begin
							if(cnt_id == 'd2) 	cs <= WR;//have last action to store (need to write back) 
							else begin
								if(get_deposit)	cs <= S_DEPOSIT;//never get deposit before
								else 			cs <= ERR_CHECK;								
							end
						end
						else cs <= cs;
					end
				WR:	cs <= inf.C_out_valid ? ERR_CHECK : cs;					
				ERR_CHECK:
					begin
						if(cnt == 'd1) begin
							if(ff_error == No_Err)
								begin
									case(ff_act)
											//No_action //?????????????????/ what situation???
											Seed	 : cs <= SEED;
											Water    : cs <= WATER;
											Reap     : cs <= OUTPUT;
											Steal    : cs <= OUTPUT;
											default:   cs <= OUTPUT;//theorectically, will not happen	
									endcase
								end
							else cs <= OUTPUT;	
						end
						else cs <= cs;
					end
				SEED, WATER: cs <= OUTPUT;
				S_DEPOSIT:	cs <= inf.C_out_valid ? (ff_act == Check_dep ? OUTPUT : ERR_CHECK) : cs;
				OUTPUT_0:	cs <= OUTPUT;
				OUTPUT:		cs <= IDLE;
			endcase
		end
end

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) input_finish <= 0;
	else begin	
		if(inf.act_valid && (inf.D[3:0] == Reap || inf.D[3:0] == Steal)) 	input_finish <= 1;//reap,steal			
		else if (inf.amnt_valid) 											input_finish <= 1;
		else if (cs == OUTPUT)												input_finish <= 0;
		else 																input_finish <= input_finish;
	end
end


always_comb begin
	if(inf.act_valid && inf.D[3:0] == Check_dep)	check_deposit = 1;//check
	else 											check_deposit = 0;
end

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) 				get_deposit <= 1;
	else
		begin
			if(cs == S_DEPOSIT)	get_deposit <= 0;
			else 				get_deposit <= get_deposit;
		end
end

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) 	wait_read <= 0;
	else
		begin
			if(inf.id_valid) 							wait_read <= 1;
			else if (cs == INPUT && inf.C_out_valid)	wait_read <= 0;
			//else if (cs == OUTPUT)						wait_read <= 1;
			else 										wait_read <= wait_read;	
		end
end


//---------------------------------------------------------------------
//   INPUT                             
//---------------------------------------------------------------------
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) 
		begin
			ff_id	 <= 8'd0;
			ff_act	 <= No_action;
			ff_crop	 <= No_cat;
			ff_water <= 0;
		end
	else 
		begin
			ff_id	 	<= inf.id_valid 	? inf.D.d_id[0] 	: ff_id;
			ff_act		<= inf.act_valid 	? inf.D.d_act[0]	: ff_act;
			ff_crop		<= inf.cat_valid 	? inf.D.d_cat[0]	: ff_crop;
			ff_water 	<= inf.amnt_valid 	? inf.D.d_amnt 	: ff_water;		
		end
end
//---------------------------------------------------------------------
//   REAP or STEAL                             
//---------------------------------------------------------------------
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) ff_clear <= 0;
	else begin
		case(cs)
			ERR_CHECK:	ff_clear <= ff_error == No_Err && (ff_act == Reap || ff_act == Steal) ? 1 : 0;
			IDLE:		ff_clear <= 0;
			default:	ff_clear <= ff_clear;
		endcase
	end
end
//---------------------------------------------------------------------
//   info from dram (ff_state_dram, ff_crop_dram, ff_water_dram)                             
//---------------------------------------------------------------------
logic [15:0] 	add_water;
always_comb begin
	add_water = ff_water + ff_water_dram;
end

//ff_state_dram
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) ff_state_dram 	<= No_sta;		
	else begin
		case(cs)
			OUTPUT:	ff_state_dram <= ff_clear? No_sta : ff_state_dram;//Reap or steal //wait save write_data and then clear
			INPUT:
				begin
					if(inf.C_out_valid) 
						begin
							if(ff_id == ff_write_data[31:24] && cnt_id >1)	begin
								case(ff_write_data[23:20])
									4'd1: ff_state_dram <= No_sta;  
									4'd2: ff_state_dram <= Zer_sta; 
									4'd4: ff_state_dram <= Fst_sta;
									4'd8: ff_state_dram <= Snd_sta;
								endcase
							end
							else begin
								case(inf.C_data_r[23:20])
									4'd1: ff_state_dram <= No_sta;  
									4'd2: ff_state_dram <= Zer_sta; 
									4'd4: ff_state_dram <= Fst_sta;
									4'd8: ff_state_dram <= Snd_sta;
								endcase
							end
						end					
					//ff_state_dram 	<= inf.C_data_r[23:20];
					else 				ff_state_dram 	<= ff_state_dram;
				end
			SEED:	
				begin
					case(ff_crop)
						Potato:	ff_state_dram <= 	add_water >= 16'h0080 ?	Snd_sta :
													add_water >= 16'h0010 ? Fst_sta : Zer_sta;
						Corn:	ff_state_dram <= 	add_water >= 16'h0200 ?	Snd_sta :
													add_water >= 16'h0040 ? Fst_sta : Zer_sta;	
						Tomato:	ff_state_dram <= 	add_water >= 16'h0800 ?	Snd_sta :
													add_water >= 16'h0100 ? Fst_sta : Zer_sta; 
						Wheat:	ff_state_dram <= 	add_water >= 16'h2000 ?	Snd_sta :
													add_water >= 16'h0400 ? Fst_sta : Zer_sta;  
						default:ff_state_dram <= No_sta;//theorectically will not happen	
					endcase
				end
			WATER: //depend on dram_crop.....
				begin
					case(ff_crop_dram)
						Potato:	ff_state_dram <= 	add_water >= 16'h0080 ?	Snd_sta :
													add_water >= 16'h0010 ? Fst_sta : Zer_sta;
						Corn:	ff_state_dram <= 	add_water >= 16'h0200 ?	Snd_sta :
													add_water >= 16'h0040 ? Fst_sta : Zer_sta;	
						Tomato:	ff_state_dram <= 	add_water >= 16'h0800 ?	Snd_sta :
													add_water >= 16'h0100 ? Fst_sta : Zer_sta; 
						Wheat:	ff_state_dram <= 	add_water >= 16'h2000 ?	Snd_sta :
													add_water >= 16'h0400 ? Fst_sta : Zer_sta;  
						default:ff_state_dram <= No_sta;//theorectically will not happen	
					endcase
				end
/* 			OUTPUT:	
				begin
					if(ff_act == Steal) 
				end
 */			default:	ff_state_dram 	<= ff_state_dram;
		endcase
	end
end

//ff_crop_dram
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) ff_crop_dram 	<= No_cat;
	else begin
		case(cs)
			OUTPUT:	ff_crop_dram <= ff_clear ? No_cat : ff_crop_dram;//Reap or Steal//wait save write_data and then clear
			INPUT:
				begin
					if(inf.C_out_valid) begin
						if(ff_id == ff_write_data[31:24] && cnt_id >1) begin//have new id but is the same id as last time
							case(ff_write_data[19:16])
								4'd0: ff_crop_dram <= No_cat; 
								4'd1: ff_crop_dram <= Potato; 
								4'd2: ff_crop_dram <= Corn;	
								4'd4: ff_crop_dram <= Tomato;
								4'd8: ff_crop_dram <= Wheat; 
							endcase
						end
						else begin
							case(inf.C_data_r[19:16])
								4'd0: ff_crop_dram <= No_cat; 
								4'd1: ff_crop_dram <= Potato; 
								4'd2: ff_crop_dram <= Corn;	
								4'd4: ff_crop_dram <= Tomato;
								4'd8: ff_crop_dram <= Wheat; 
							endcase
						end
					end
					//ff_crop_dram 	<= inf.C_data_r[19:16];
					else 				ff_crop_dram 	<= ff_crop_dram;
				end
			SEED:		ff_crop_dram <= ff_crop;
			default: 	ff_crop_dram 	<= ff_crop_dram;
		endcase
	end
end
//ff_water_dram
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) ff_water_dram 	<= 0;
	else begin
		case(cs)
			OUTPUT:	ff_water_dram <= ff_clear ? 0 : ff_water_dram;//Reap or Steal//wait save write_data and then clear
			INPUT:
				begin
					if(inf.C_out_valid) begin
						if(ff_id == ff_write_data[31:24] && cnt_id >1)	ff_water_dram <= ff_water_dram[15:0];
						else 								ff_water_dram 	<= inf.C_data_r[15:0];
					end
					else 				ff_water_dram 	<= ff_water_dram;
				end
			SEED, WATER:	ff_water_dram <= add_water;
			default: 		ff_water_dram 	<= ff_water_dram;
		endcase
	end
end
//---------------------------------------------------------------------
//   ERR_CHECK                             
//---------------------------------------------------------------------
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) ff_error <= No_Err;
	else begin
		case(cs)
			ERR_CHECK:
				begin
					case(ff_act)
						//No_action :
						Seed:		ff_error <= ff_state_dram != No_sta 	? Not_Empty: No_Err;
						Water:		ff_error <= ff_state_dram == No_sta 	? Is_Empty :
												ff_state_dram == Snd_sta	? Has_Grown: No_Err;
						Reap, Steal:ff_error <= ff_state_dram == No_sta 	? Is_Empty : 
												ff_state_dram == Zer_sta	? Not_Grown: No_Err;
						default:	ff_error <= No_Err;		
					endcase
				end
			OUTPUT:	ff_error <= No_Err;
		endcase
	end
end
//---------------------------------------------------------------------
//   save write data                             
//---------------------------------------------------------------------
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) 	ff_write_data <= 0;
	else 			ff_write_data <= cs == IDLE && cnt == 'd0 ? {ff_id, ff_state_dram, ff_crop_dram, ff_water_dram} : ff_write_data;
end
//---------------------------------------------------------------------
//   deposit                             
//---------------------------------------------------------------------
logic[31:0] add_in_0, sub_in_0;
logic[6:0] 	add_in_1, sub_in_1;
logic[31:0]	add_out, sub_out;

always_comb begin
	add_out = add_in_0 + add_in_1;
	sub_out = sub_in_0 - sub_in_1;
end

always_comb begin
	add_in_0 = ff_deposit;
	sub_in_0 = ff_deposit;
end

always_comb begin//sale price
	if(ff_state_dram == Fst_sta) begin
		case(ff_crop_dram)
			Potato:		add_in_1 = 'd10;
			Corn:		add_in_1 = 'd20;
			Tomato:		add_in_1 = 'd30;
			Wheat: 		add_in_1 = 'd40;
			default:	add_in_1 = 0;
		endcase
	end
	else if (ff_state_dram == Snd_sta) begin
		case(ff_crop_dram)
			Potato:		add_in_1 = 'd25;
			Corn:	    add_in_1 = 'd50;
			Tomato:     add_in_1 = 'd75;
			Wheat:      add_in_1 = 'd100;
			default:    add_in_1 = 0;
		endcase
	end
	else add_in_1 = 0;
end

always_comb begin//cost
	case(ff_crop)
		Potato:		sub_in_1 = 'd5;
		Corn:		sub_in_1 = 'd10;
		Tomato:		sub_in_1 = 'd15;
		Wheat: 		sub_in_1 = 'd20;
		default:	sub_in_1 = 0;
	endcase
end

always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) ff_deposit <= 0;
	else begin
		case(cs)
			S_DEPOSIT:	ff_deposit <= inf.C_out_valid ? inf.C_data_r : ff_deposit;
			ERR_CHECK:	ff_deposit <= ff_error == No_Err && cnt == 'd1 && ff_act == Reap ? add_out : ff_deposit;//Reap
			SEED:		ff_deposit <= sub_out;
			default:	ff_deposit <= ff_deposit;
		endcase
	end
	//ff_deposit <= cs == S_DEPOSIT && inf.C_out_valid ? inf.C_data_r : ff_deposit;
end


//---------------------------------------------------------------------
//   BRIDGE                             
//---------------------------------------------------------------------
/* always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n)
		begin
			inf.C_in_valid 	= 'd0;
			inf.C_addr		= 'd0;
			inf.C_r_wb		= 'd0;
			inf.C_data_w	= 'd0;
		end
	else 
		begin
 */
logic ff_get_dram;
always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) ff_get_dram <= 'd0;
	else begin
		ff_get_dram <= inf.id_valid ? 1 : 0;
	end
end

always_comb begin
			case(cs)
/* 				IDLE:
					begin
						inf.C_in_valid	= inf.id_valid;
						inf.C_addr 		= inf.D[7:0];
						inf.C_r_wb		= 1'b1;//read
						inf.C_data_w 	= 32'd0;//don't care
					end
 */				INPUT:	
					begin
						inf.C_in_valid	= ff_get_dram;
						inf.C_addr 		= ff_id;
						inf.C_r_wb		= 1'b1;//read
						inf.C_data_w 	= 32'd0;//don't care
					end
				S_DEPOSIT:
					begin
						inf.C_in_valid 	= cnt == 'd0 ? 1'd1 : 1'd0;
						inf.C_addr		= 8'hff;
						inf.C_r_wb		= 1'b1;//read
						inf.C_data_w	= 32'd0;//don't care
					end
				WR:
					begin
						inf.C_in_valid 	= cnt == 'd0 ? 1'd1 : 1'd0;
						inf.C_addr 		= ff_write_data[31:24];
						inf.C_r_wb		= 1'b0;//write
						inf.C_data_w 	= ff_write_data;
					end
				default:
					begin
						inf.C_in_valid 	= 1'd0;
						inf.C_addr		= 'd0;
						inf.C_r_wb		= 'd0;
						inf.C_data_w	= 'd0;
					end
			endcase
		//end
end


















always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) cnt_id <= 0;
	else 
		begin
			if(inf.id_valid)
				begin
					cnt_id <= 	cnt_id == 'd0 ? 1 : 2;//if  cnt_id == 2, need to write back
				end
			else if(cs == OUTPUT && ff_act != Check_dep)	cnt_id <= 'd3;
		end
end




always_ff@(negedge inf.rst_n or posedge clk)begin
	if(!inf.rst_n) cnt <= 0;
	else 
		begin
			case(cs)
				IDLE:				cnt <= 0;
				S_DEPOSIT:			cnt <= 'd1; 
				WR:					cnt <= inf.C_out_valid ? 'd0 : 'd1;
				ERR_CHECK:			cnt <= 'd1;
				default:			cnt <= 0;
			endcase
		end
end


//---------------------------------------------------------------------
//   OUTPUT                             
//---------------------------------------------------------------------
always_comb begin
	inf.out_valid 	= cs == OUTPUT ? 1 : 0;
end

always_comb begin
	inf.out_deposit = cs == OUTPUT && ff_act == 4'b1000 ? ff_deposit : 0;
end

always_comb begin
	if(cs == OUTPUT && ff_error == No_Err) begin
		case(ff_act)
			Seed, Water, Reap, Steal:		inf.out_info = {ff_id, ff_state_dram, ff_crop_dram, ff_water_dram};
			Check_dep:						inf.out_info = 0;
			default:						inf.out_info = 0;
		endcase
	end
	else inf.out_info = 0;
end

always_comb begin
	inf.complete 	= cs == OUTPUT ? !ff_error : 0;//unfinished
end

always_comb begin
	inf.err_msg 	= cs == OUTPUT ? ff_error : No_Err;//unfinished
end




endmodule