module SD(
    //Input Port
    clk,
    rst_n,
	in_valid,
	in,

    //Output Port
    out_valid,
    out
    );

//-----------------------------------------------------------------------------------------------------------------
//   PORT DECLARATION                                                  
//-----------------------------------------------------------------------------------------------------------------
input            clk, rst_n, in_valid;
input [3:0]		 in;
output reg		 out_valid;
output reg [3:0] out;
    
//-----------------------------------------------------------------------------------------------------------------
//   PARAMETER DECLARATION                                             
//-----------------------------------------------------------------------------------------------------------------
parameter 	IDLE 			= 3'd0,
			INPUT			= 3'd1,
			IDLE2			= 3'd2,
			POSSIBLE_VALUE  = 3'd3,
			TRY		 		= 3'd4,
			BACK			= 3'd5, 
			OUTPUT 			= 3'd6;
//-----------------------------------------------------------------------------------------------------------------
//   LOGIC DECLARATION                                                 
//-----------------------------------------------------------------------------------------------------------------
reg [2:0] cs;
reg [8:0] row[8:0], col[8:0], box[8:0];
reg [11:0] space_pos[14:0];
reg [6:0] cnt_in;
reg [3:0] cnt_row, cnt_col, cnt_box, cnt_space;
reg [3:0] cnt_cal_poss;
reg [3:0] cnt_output;
reg [3:0] i, j;
reg wrong_grid_row, wrong_grid_col, wrong_grid_box, wrong_grid;
reg [3:0] space_ans[14:0];
reg [3:0] cnt_space_cur;
reg sol_or_not;
reg first_try;
reg back_done;
reg [3:0] cnt_back;
reg clear;
wire try_done;
reg wrong;
reg no_poss[14:0];

//-----------------------------------------------------------------------------------------------------------------
//   POSSIBLE_VALUE                                                           
//-----------------------------------------------------------------------------------------------------------------
reg[4:0] cnt_poss_cur[14:0], cnt_poss_cur_sec[14:0];//how many possible number (index), prepare to fill in next possible number
reg[3:0] cnt_poss[14:0];
reg[27:0] poss_value[14:0];//not sure 28 bits is enough!!!!!!!!!!!!!!!!!!!!!!!!
reg[3:0] k, idx, idy, idz, idk, ida;
assign try_done = (!space_ans[14]) ? 0:1;
//-----------------------------------------------------------------------------------------------------------------
//   POSSIBLE_VALUE : no_poss                                                       
//-----------------------------------------------------------------------------------------------------------------
/* wire wrong_no_poss;
assign wrong_no_poss = 	(cnt_cal_poss == 'd9) && (!(no_poss[0] && no_poss[1] && no_poss[2] && no_poss[3] && no_poss[4] && no_poss[5] && no_poss[6] && no_poss[7] &&
						no_poss[8] && no_poss[9] && no_poss[10] && no_poss[11] && no_poss[12] && no_poss[13] && no_poss[14]));
*/
reg wrong_no_poss;
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		wrong_no_poss <= 0;
	end
	else begin
		if((cs == POSSIBLE_VALUE) && (cnt_cal_poss == 'd9)) begin
			wrong_no_poss <= 	(!(no_poss[0] && no_poss[1] && no_poss[2] && no_poss[3] && no_poss[4] && no_poss[5] && no_poss[6] && no_poss[7] &&
								no_poss[8] && no_poss[9] && no_poss[10] && no_poss[11] && no_poss[12] && no_poss[13] && no_poss[14]));
		end
		else if (cs == OUTPUT) wrong_no_poss <= 0;
		else wrong_no_poss <= wrong_no_poss;
	end
end 
//-----------------------------------------------------------------------------------------------------------------
//   FSM                                                            
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cs <= 0;
	end
	else begin
		case(cs) 
			IDLE:	cs <= (in_valid) ? INPUT : cs;
			INPUT: cs <= (cnt_in == 'd81) ? IDLE2 : cs;
			IDLE2: cs <= (wrong_grid == 'd0) ? POSSIBLE_VALUE : OUTPUT;
			POSSIBLE_VALUE: cs <= (cnt_cal_poss == 'd9) ? TRY : cs;
			
			
							/* begin
								if(cnt_cal_poss == 'd9) begin
									if(wrong_no_poss) begin
										cs <= OUTPUT;
									end
									else begin
										cs <= TRY;
									end
								end
								else begin
									cs <= cs;
								end
							end */
			TRY: cs <= 	wrong_no_poss ? OUTPUT : (wrong ? OUTPUT : 
						(try_done ? OUTPUT :
						(!sol_or_not && !first_try) ? BACK : TRY));
			BACK: cs <= back_done ? TRY : cs;
			OUTPUT: begin
				if(wrong_grid) begin
					cs <= IDLE;
				end
				else if (wrong_no_poss) begin
					cs <= IDLE;
				end
				else if(wrong) begin
					cs <= IDLE;
				end
				else if(cnt_output == 'd14) begin
					cs <= IDLE;
				end
				else cs <= cs;
			end
		endcase
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   row, col, box                                                           
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_space <= 0;
		for(i = 0; i < 9; i = i + 1) begin
			row[i] <= 0;
			col[i] <= 0;
			box[i] <= 0;
		end
		for(j = 0; j < 15; j = j + 1) begin
			space_pos[j] <= 0;
		end
	end
	else begin
		if(in_valid) begin
			case(in)
				4'd0: begin
					cnt_space <= cnt_space + 'd1;
					space_pos [cnt_space] <= {cnt_row, cnt_col,cnt_box};
				end
				default:begin
					row[cnt_row][in-1] <= 1; 
					col[cnt_col][in-1] <= 1;
					box[cnt_box][in-1] <= 1;
				end
			endcase
		end
		else if ((cs == TRY) && sol_or_not) begin
			case(cnt_poss_cur_sec[cnt_space_cur])
				5'd0:begin
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][3:0] - 'd1] <= 1;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][3:0] - 'd1] <= 1;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][3:0] - 'd1] <= 1;
					end          
				5'd4:begin       
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][7:4] - 'd1] <= 1;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][7:4] - 'd1] <= 1;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][7:4] - 'd1] <= 1;
					end          
				5'd8:begin       
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][11:8] - 'd1] <= 1;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][11:8] - 'd1] <= 1;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][11:8] - 'd1] <= 1;
					end          
				5'd12:begin      
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][15:12] - 'd1] <= 1;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][15:12] - 'd1] <= 1;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][15:12] - 'd1] <= 1;
					end          
				5'd16:begin      
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][19:16] - 'd1] <= 1;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][19:16] - 'd1] <= 1;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][19:16] - 'd1] <= 1;
					end
				5'd20:begin
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][23:20] - 'd1] <= 1;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][23:20] - 'd1] <= 1;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][23:20] - 'd1] <= 1;
					end          
				5'd24:begin       
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][27:24] - 'd1] <= 1;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][27:24] - 'd1] <= 1;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][27:24] - 'd1] <= 1;
					end          
			endcase
		end
 		else if ((cs == BACK) && (cnt_back != 1) && clear) begin
			case(cnt_poss_cur_sec[cnt_space_cur])
				5'd0:begin
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][3:0] - 'd1] <= 0;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][3:0] - 'd1] <= 0;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][3:0] - 'd1] <= 0;
					end                                                            
				5'd4:begin                                                         
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][7:4] - 'd1] <= 0;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][7:4] - 'd1] <= 0;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][7:4] - 'd1] <= 0;
					end
				5'd8:begin
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][11:8] - 'd1] <= 0;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][11:8] - 'd1] <= 0;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][11:8] - 'd1] <= 0;
					end
				5'd12:begin
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][15:12] - 'd1] <= 0;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][15:12] - 'd1] <= 0;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][15:12] - 'd1] <= 0;
					end
				5'd16:begin
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][19:16] - 'd1] <= 0;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][19:16] - 'd1] <= 0;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][19:16] - 'd1] <= 0;
					end
				5'd20:begin
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][23:20] - 'd1] <= 0;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][23:20] - 'd1] <= 0;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][23:20] - 'd1] <= 0;
					end          
				5'd24:begin       
						row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][27:24] - 'd1] <= 0;
						col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][27:24] - 'd1] <= 0;
						box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][27:24] - 'd1] <= 0;
					end          
			endcase
		end
 		else if (cs == OUTPUT) begin
			cnt_space <= 0;
			for(i = 0; i < 9; i = i + 1) begin
				row[i] <= 0;
				col[i] <= 0;
				box[i] <= 0;
			end
			for(j = 0; j < 15; j = j + 1) begin
				space_pos[j] <= 0;
			end
		end
		else begin
			for(i = 0; i < 9; i = i + 1) begin
				row[i] <= row[i] ;
				col[i] <= col[i] ;
				box[i] <= box[i] ;
			end
			for(j = 0; j < 15; j = j + 1) begin
				space_pos[j] <= space_pos[j];
			end
		end
	end
end

//-----------------------------------------------------------------------------------------------------------------
//   wrong_grid
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		wrong_grid_row <= 0;
		wrong_grid_col <= 0;
		wrong_grid_box <= 0;
	end
	else begin
		if(in_valid) begin
			if(in) begin
				wrong_grid_row <= row[cnt_row][in-1];
				wrong_grid_col <= col[cnt_col][in-1];
				wrong_grid_box <= box[cnt_box][in-1];
			end
		end
		else if (cs == IDLE) begin
			wrong_grid_row <= 0;
			wrong_grid_col <= 0;
			wrong_grid_box <= 0;
		end
		else begin
			wrong_grid_row <= wrong_grid_row;
			wrong_grid_col <= wrong_grid_col;
			wrong_grid_box <= wrong_grid_box;
		end
	end
end

always@(*) begin
	wrong_grid = (cs == IDLE) ? 0 : ((wrong_grid_row || wrong_grid_col || wrong_grid_box) || wrong_grid);
end
//-----------------------------------------------------------------------------------------------------------------
//   cnt_row, cnt_col, cnt_box, cnt_in
//-----------------------------------------------------------------------------------------------------------------
//cnt_row===============================
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_row <= 0;
	end
	else begin
		if(in_valid) begin
			case(cnt_in) 
				'd8, 'd17, 'd26, 'd35, 'd44, 'd53, 'd62, 'd71: cnt_row <= cnt_row + 1;
				default : cnt_row <= cnt_row;
			endcase
			
		end
		else cnt_row <= 0;
	end
end
//cnt_col===============================
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_col <= 0;
	end
	else begin
		if(in_valid) begin
			cnt_col <= (cnt_col == 'd8) ? 0 : cnt_col + 1;
		end
		else cnt_col <= 0;
	end
end
//cnt_box===============================
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_box <= 0;
	end
	else begin
		if(in_valid) begin
			case(cnt_in)
				    'd0,'d1,    'd8,'d9,'d10,   'd17,'d18,'d19: cnt_box <= 0; 
				'd2,'d3,'d4,    'd11,'d12,'d13, 'd20,'d21,'d22: cnt_box <= 1; 
				'd5,'d6,'d7,    'd14,'d15,'d16, 'd23,'d24,'d25: cnt_box <= 2; 
				'd26,'d27,'d28, 'd35,'d36,'d37, 'd44,'d45,'d46: cnt_box <= 3; 
				'd29,'d30,'d31, 'd38,'d39,'d40, 'd47,'d48,'d49: cnt_box <= 4; 
				'd32,'d33,'d34, 'd41,'d42,'d43, 'd50,'d51,'d52: cnt_box <= 5; 
				'd53,'d54,'d55,	'd62,'d63,'d64,	'd71,'d72,'d73: cnt_box <= 6; 
				'd56,'d57,'d58,	'd65,'d66,'d67,	'd74,'d75,'d76: cnt_box <= 7;
				'd59,'d60,'d61,	'd68,'d69,'d70,	'd77,'d78,'d79: cnt_box <= 8; 				
			endcase
		end
		else cnt_box <= 0;
	end
end
//cnt_in================================
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_in <= 0;
	end
	else begin
		if(in_valid) begin
			cnt_in <= cnt_in + 1;
		end
		else if(cs == OUTPUT) begin
			cnt_in <= 0;
		end
		else begin
			cnt_in <= cnt_in;
		end
	end
end


//-----------------------------------------------------------------------------------------------------------------
//   poss_or_not                                                           
//-----------------------------------------------------------------------------------------------------------------
reg[8:0] poss_or_not[14:0];

always@(*) begin
		for(idx = 0; idx < 15; idx = idx + 1) begin
			poss_or_not[idx][0] = !(row[space_pos[idx][11:8]][0] || col[space_pos[idx][7:4]][0] || box[space_pos[idx][3:0]][0]);
			poss_or_not[idx][1] = !(row[space_pos[idx][11:8]][1] || col[space_pos[idx][7:4]][1] || box[space_pos[idx][3:0]][1]);
			poss_or_not[idx][2] = !(row[space_pos[idx][11:8]][2] || col[space_pos[idx][7:4]][2] || box[space_pos[idx][3:0]][2]);
			poss_or_not[idx][3] = !(row[space_pos[idx][11:8]][3] || col[space_pos[idx][7:4]][3] || box[space_pos[idx][3:0]][3]);
			poss_or_not[idx][4] = !(row[space_pos[idx][11:8]][4] || col[space_pos[idx][7:4]][4] || box[space_pos[idx][3:0]][4]);
			poss_or_not[idx][5] = !(row[space_pos[idx][11:8]][5] || col[space_pos[idx][7:4]][5] || box[space_pos[idx][3:0]][5]);
			poss_or_not[idx][6] = !(row[space_pos[idx][11:8]][6] || col[space_pos[idx][7:4]][6] || box[space_pos[idx][3:0]][6]);
			poss_or_not[idx][7] = !(row[space_pos[idx][11:8]][7] || col[space_pos[idx][7:4]][7] || box[space_pos[idx][3:0]][7]);
			poss_or_not[idx][8] = !(row[space_pos[idx][11:8]][8] || col[space_pos[idx][7:4]][8] || box[space_pos[idx][3:0]][8]);
		end
	
end
//-----------------------------------------------------------------------------------------------------------------
//   poss_value                                                          
//-----------------------------------------------------------------------------------------------------------------

always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(k = 0; k < 15; k = k + 1) begin
			poss_value[k] <= 0;
			cnt_poss_cur[k] <= 0;
			cnt_poss[k] <= 0;
			no_poss[k] <= 0;
		end
	end
	else begin
		if(cs == POSSIBLE_VALUE) begin
			for(k = 0; k < 15; k = k + 1) begin
				if(cnt_cal_poss != 'd9) begin	
					if(poss_or_not[k][cnt_cal_poss]) begin
						no_poss[k] <= 1;
						case(cnt_poss_cur[k])
							'd0:poss_value[k][3:0] <= cnt_cal_poss + 'd1;
							'd4:poss_value[k][7:4] <= cnt_cal_poss + 'd1;
							'd8:poss_value[k][11:8] <= cnt_cal_poss + 'd1;
							'd12:poss_value[k][15:12] <= cnt_cal_poss + 'd1;
							'd16:poss_value[k][19:16] <= cnt_cal_poss + 'd1;
							'd20:poss_value[k][23:20] <= cnt_cal_poss + 'd1;
							'd24:poss_value[k][27:24] <= cnt_cal_poss + 'd1;
						endcase					
						cnt_poss_cur[k] <= cnt_poss_cur[k] + 'd4;//each index has 4 bits(1~9 need 4 bits)
						cnt_poss[k] <= cnt_poss[k] + 'd1;
					end
				end
				else begin//clear cnt_poss_cur for the next stage
					for(idz = 0; idz < 15; idz = idz + 1) begin
						cnt_poss_cur[idz] <= 0;
					end
				end
			end
		end
 		else if(cs == OUTPUT) begin
			for(k = 0; k < 15; k = k + 1) begin
				poss_value[k] <= 0;
				cnt_poss_cur[k] <= 0;
				cnt_poss[k] <= 0;
				no_poss[k] <= 0;
			end
		end
		else begin
			for(k = 0; k < 15; k = k + 1) begin
				poss_value[k] <= poss_value[k];
				cnt_poss_cur[k] <= cnt_poss_cur[k];			
				cnt_poss[k] <= cnt_poss[k];
				no_poss[k] <= no_poss[k];
			end
		end
	end
end

//-----------------------------------------------------------------------------------------------------------------
//   TRY & BACK : cnt_poss_cur_sec, cnt_space_cur, clear
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(idk = 0; idk < 15; idk = idk + 1) begin
			cnt_poss_cur_sec[idk] <= 0;
		end
		cnt_space_cur <= 0;
		clear <= 0;
		//wrong <= 0;
	end
	else begin
		if((cs == TRY) && sol_or_not)begin
			cnt_space_cur <= cnt_space_cur + 'd1;
		end
		else if(cs == BACK) begin
			if(cnt_poss_cur_sec[cnt_space_cur] != ((cnt_poss[cnt_space_cur] - 1) << 2)) begin	//still have possible value //cnt_poss : 1,2... so -1
				cnt_poss_cur_sec[cnt_space_cur] <= cnt_poss_cur_sec[cnt_space_cur] + 'd4;//point to the same space's next possible value
				clear <= 0;
			end
			else begin// back to the last space
					  //do not set back_done to 1, so this always block will do one more time, to check if last space also cnt to the last space
					clear <= 1;
					cnt_poss_cur_sec[cnt_space_cur] <= 'd0;
					cnt_space_cur <= cnt_space_cur - 'd1;//back to last space
					/* if((cnt_space_cur == 1) && (((cnt_poss[0] - 1) << 2) == cnt_poss_cur_sec[0])) begin //already back to the space 0 and in its last poss position
						wrong <= 1;
					end */
			end
		end
		else if (cs == OUTPUT) begin
			clear <= 0;
			//wrong <= 0;
			for(idk = 0; idk < 15; idk = idk + 1) begin
				cnt_poss_cur_sec[idk] <= 0;
			end
			cnt_space_cur <= 0;
		end
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   wrong
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		wrong <= 0;
	end
	else begin
		if(cs == TRY) begin
			for(ida = 0; ida < 15; ida = ida + 1) begin
				wrong <= ((poss_value[ida] == 0) || wrong);
			end
		end
		else if(cs == BACK) begin
			if(cnt_poss_cur_sec[cnt_space_cur] == ((cnt_poss[cnt_space_cur] - 1) << 2)) begin	//still have possible value //cnt_poss : 1,2... so -1
				if((cnt_space_cur == 1) && (((cnt_poss[0] - 1) << 2) == cnt_poss_cur_sec[0])) begin //already back to the space 0 and in its last poss position
					wrong <= 1;
				end
			end
		end
		else if (cs == OUTPUT) begin
			wrong <= 0;
		end
		else wrong <= wrong;
		
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   BACK : back_done
//-----------------------------------------------------------------------------------------------------------------
always@(*) begin
	if((cs == BACK) && (cnt_poss_cur_sec[cnt_space_cur] != ((cnt_poss[cnt_space_cur] - 1) << 2))) begin
		back_done = 1;
	end
	else begin
		back_done = 0;
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   BACK : cnt_back
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_back <= 0;
	end
	else begin
		if((((cs == TRY) && (!sol_or_not) && (!first_try))) || (cs == BACK))begin
			cnt_back <= back_done ? 0 : (cnt_back + 'd1);
		end
		else begin
			cnt_back <= cnt_back;
		end
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   TRY : first_try
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		first_try <= 0;
	end
	else begin
		if(cs == POSSIBLE_VALUE && (cnt_cal_poss == 'd9)) first_try <= 1;
		else first_try <= 0;
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   TRY : space_ans
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(idy = 0; idy < 15; idy = idy + 1) begin
			space_ans[idy] <= 0;
		end
	end
	else begin
		if(wrong_no_poss) begin
			space_ans[0] <= 4'd10;
		end
		if((cs == TRY) && (sol_or_not)) begin
			case(cnt_poss_cur_sec[cnt_space_cur])
				5'd0: space_ans[cnt_space_cur] <= poss_value[cnt_space_cur][3:0];
				5'd4: space_ans[cnt_space_cur] <= poss_value[cnt_space_cur][7:4];
				5'd8: space_ans[cnt_space_cur] <= poss_value[cnt_space_cur][11:8];
				5'd12:space_ans[cnt_space_cur] <= poss_value[cnt_space_cur][15:12];
				5'd16:space_ans[cnt_space_cur] <= poss_value[cnt_space_cur][19:16];
				5'd20:space_ans[cnt_space_cur] <= poss_value[cnt_space_cur][23:20];
				5'd24:space_ans[cnt_space_cur] <= poss_value[cnt_space_cur][27:24];
			endcase
		end
		else if (cs == BACK) begin
			case(cnt_poss_cur_sec[cnt_space_cur])
				5'd0: space_ans[cnt_space_cur] <= 0;
				5'd4: space_ans[cnt_space_cur] <= 0;
				5'd8: space_ans[cnt_space_cur] <= 0;
				5'd12:space_ans[cnt_space_cur] <= 0;
				5'd16:space_ans[cnt_space_cur] <= 0;
				5'd20:space_ans[cnt_space_cur] <= 0;
				5'd24:space_ans[cnt_space_cur] <= 0;
			endcase
		end
		else if (cs == IDLE) begin
			for(idy = 0; idy < 15; idy = idy + 1) begin
				space_ans[idy] <= 0;
			end
		end
	end
end

//-----------------------------------------------------------------------------------------------------------------
//   TRY : sol_or_not
//-----------------------------------------------------------------------------------------------------------------
always@(*) begin
	case(cnt_poss_cur_sec[cnt_space_cur])
		5'd0:begin
			sol_or_not = 	(!row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][3:0] - 'd1]) &&
							(!col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][3:0] - 'd1]) &&
							(!box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][3:0] - 'd1]);
			end 
		5'd4:begin
			sol_or_not = 	!row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][7:4] - 'd1]  &&
							!col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][7:4] - 'd1]  &&
							!box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][7:4] - 'd1] ;
			end                                                                      
		5'd8:begin                                                                   
			sol_or_not = 	!row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][11:8] - 'd1] &&
							!col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][11:8] - 'd1] &&
							!box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][11:8] - 'd1];
			end                                                                      
		5'd12:begin                                                                  
			sol_or_not =	!row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][15:12] - 'd1] &&
							!col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][15:12] - 'd1] &&
							!box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][15:12] - 'd1];
			end                                                                      
		5'd16:begin                                                                  
			sol_or_not = 	!row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][19:16] - 'd1] &&
							!col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][19:16] - 'd1] &&
							!box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][19:16] - 'd1];
			end 
		5'd20:begin
			sol_or_not = 	(!row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][23:20] - 'd1]) &&
							(!col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][23:20] - 'd1]) &&
							(!box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][23:20] - 'd1]);
			end          
		5'd24:begin       
			sol_or_not = 	!row[space_pos[cnt_space_cur][11:8]][poss_value[cnt_space_cur][27:24] - 'd1]  &&
							!col[space_pos[cnt_space_cur][7:4]] [poss_value[cnt_space_cur][27:24] - 'd1]  &&
							!box[space_pos[cnt_space_cur][3:0]] [poss_value[cnt_space_cur][27:24] - 'd1] ;
			end          
		default : sol_or_not = 0;
	endcase
end

//cnt_cal_poss------------------------------------------------- 
//	 cnt for number 1(0) ~ 9(8) (possible value for each space)
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_cal_poss <= 0;
	end
	else begin
		if(cs == POSSIBLE_VALUE)begin
			cnt_cal_poss <= (cnt_cal_poss == 'd9) ? 0 : cnt_cal_poss + 1;
		end
		else cnt_cal_poss <= 0;
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   OUTPUT  : out, out_valid                                                       
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		out <= 0;
		out_valid <= 0;
	end
	else begin
		if(cs == OUTPUT) begin
			out_valid <= 1;
			if(wrong_grid) begin
				out <= 'd10;
			end
			else if(wrong_no_poss) begin
				out <= 'd10;
			end
			else if (wrong) begin
				out <= 'd10;
			end
			else begin
				out <= space_ans[cnt_output];
			end	
		end
		else begin	
			out <= 0;
			out_valid <= 0;
		end
	end
end
//-----------------------------------------------------------------------------------------------------------------
//   OUTPUT  : cnt_output                                                       
//-----------------------------------------------------------------------------------------------------------------
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_output <= 0;
	end
	else begin
		if(cs == OUTPUT) begin
			cnt_output <= cnt_output + 'd1;
		end
		else begin
			cnt_output <= 0;
		end
	end
end




endmodule
