module SME(
    clk,
    rst_n,
    chardata,
    isstring,
    ispattern,
    out_valid,
    match,
    match_index
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk;
input rst_n;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg out_valid;


//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter	IDLE	= 3'b000,
			INPUT_S	= 3'b001,
			IDLE_2	= 3'b010,
			INPUT_P	= 3'b011,
			EX		= 3'b100,
			OUTPUT	= 3'b101;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION                             
//---------------------------------------------------------------------

reg [7:0]	strings[33:0];
reg [7:0]	patterns[7:0];
reg [2:0]	cs;
reg [5:0]	cnt_string;
reg [3:0]	cnt_pattern;
reg	[1:0]	cnt_output;//unsetting
reg [5:0]	idx;//check if too large (waste
reg [3:0]	idy;//same as idx
reg [3:0]	case_4;//there is a * in patterns
reg [5:0]	index_string;
wire		EX_finish;
reg			case4_part1, case4_part2;
reg[3:0]	idz,ida;
reg[7:0]	tmp_match;
reg[5:0]	search_finish;
reg[5:0]	tmp_match_index;
reg[4:0]	ans_match_index;
reg			ans_match;
wire		case4_match;
assign		case4_match = case4_part1 & case4_part2;
reg all_match;
reg cnt_secpart;

assign		EX_finish = (cs == EX) && (index_string != 0) && ((case_4[0] ? case4_match : all_match) || ((!case4_match) && (!all_match || ((case_4[0] && all_match && !case4_part1 ))) && (index_string >= search_finish + 2)) );
			//	(case_4[0] && all_match && !case4_part1 ) : the condition to set cnt_secpart to 1

//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------

always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cs <= IDLE;
	end
	else begin
		case(cs)
			IDLE: 	 cs <= 	isstring	? INPUT_S 	:
							ispattern	? INPUT_P	: cs;						
			INPUT_S:cs <= !isstring	? IDLE_2	: cs;
			IDLE_2: cs <= ispattern	? INPUT_P	: cs;
			INPUT_P:cs <= !ispattern ? EX		: cs;
			EX:		cs <= EX_finish	? OUTPUT	: cs;//unfinished
			OUTPUT: cs <= (cnt_output=='d2) ? IDLE		: cs;
		endcase
	end
end

//============INPUT_S
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(idx = 1; idx <= 'd33; idx = idx + 1) begin
			strings[idx] <= 0;
		end
		strings[0] <= 8'h20;
		
	end
	else begin	
		if(isstring) begin
			if(cs == IDLE)
				case(chardata)
					8'h20:	begin
								strings[1] <= 8'h20;
							end
					8'h5e:	begin
								strings[1] <= 8'h20; // case ^
							end
					8'h24:	begin
								strings[1] <= 8'h20; // case $
							end	
					8'h2e:	begin
								strings[1] <= 8'h0; // case .
							end	
					default:begin
								strings[1] <= chardata;
							end
				endcase
			else begin			
				case(chardata)
					8'h20:	begin
								strings[cnt_string + 1] <= 8'h20;
							end
					8'h5e:	begin
								strings[cnt_string + 1] <= 8'h20; // case ^
							end
					8'h24:	begin
								strings[cnt_string + 1] <= 8'h20; // case $
							end	
					8'h2e:	begin
								strings[cnt_string + 1] <= 8'h0; // case .
							end	
					default:begin
								strings[cnt_string + 1] <= chardata;
							end
				endcase
			end
		end
		else if(cs == IDLE_2) begin
			strings[cnt_string + 1] <= 8'h20;
		end
		else begin
			for(idx = 1; idx <= 'd32; idx = idx + 1) begin
				strings[idx] <= strings[idx];
			end
		end
	end
end


always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_string <= 1;
	end
	else begin
		if((cs==IDLE) && (isstring)) begin
			cnt_string <= 1;
		end
		else if (isstring) begin
			cnt_string <= cnt_string + 1;
		end
		else begin
			cnt_string <= cnt_string;
		end
	end
end







reg first_space, first_space_fake;
reg former_space, former_space_fake;
reg first_dot;
reg[3:0] last_check, last_dot; //check if the last char of pattern is space(last_check) or dot(last_dot)

//============INPUT_P
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		for(idy = 0; idy <= 'd7; idy = idy + 1) begin
			patterns[idy] <= 0;
		end
		//cnt_pattern <= 0;
		first_space <= 0;
		former_space <= 0;
		first_space_fake <= 0;
		first_dot <= 0;
		case_4 <= 0;
		last_check <= 0;
		last_dot <= 0;
	end
	else begin
		if(cs==OUTPUT) begin 
			//cnt_pattern <= 0;
			case_4 <= 0;
			first_space <= 0;
			former_space <= 0;
			first_space_fake <= 0;
			first_dot <= 0;
			last_check <= 0;
			last_dot <= 0;
		//end
		//else if (cs == OUTPUT) begin //clear
			for(idy = 0; idy <= 'd7; idy = idy + 1) begin
				patterns[idy] <= 0;
			end
		end
		else if(ispattern) begin
			case(chardata)
				8'h20:	begin
							patterns[cnt_pattern] <= 8'h20;
							first_space <= (!cnt_pattern ? 1 : first_space);//first char in pattern is space
							last_check <= cnt_pattern;							
							if(!cnt_pattern) begin //the first char is space
								former_space <= 1;
							end
							else if(former_space) begin
								former_space <= 1;							
							end
							else begin
								former_space <= 0;
							end
						end	
				8'h5e:	begin
							patterns[cnt_pattern] <= 8'h20; // case ^
							former_space <= 0;
							first_space_fake <= 1;
						end
				8'h24:	begin
							patterns[cnt_pattern] <= 8'h20; // case $
							former_space <= 0;
						end
				8'h2e:	begin
							patterns[cnt_pattern] <= 8'h0; // case .
							former_space <= 0;
							if(!cnt_pattern) begin //the first char is dot
								first_dot <= 1;
							end
							last_dot <= cnt_pattern;
						end
				8'h2a:	begin
							patterns[cnt_pattern] <= chardata;
							case_4 <= {cnt_pattern , 1'b1};//first 3 bit : which bit in pattern is *, last bit : * exists or not
							former_space <= 0;
						end
				default:begin
							patterns[cnt_pattern] <= chardata;
							former_space <= 0;
						end	
			endcase
			//cnt_pattern <= cnt_pattern + 1;
		end
		else begin
			for(idy = 0; idy <= 'd7; idy = idy + 1) begin
				patterns[idy] <= patterns[idy];
			end
			//cnt_pattern <= cnt_pattern;
			case_4 <= case_4;
			first_space <= first_space;
			former_space <= former_space;
			first_space_fake <= first_space_fake;
			first_dot <= first_dot;
		end
	end
end

//cnt_pattern
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_pattern <= 0;
	end
	else begin
		if(ispattern) begin
			cnt_pattern <= cnt_pattern + 1;
		end
		else if(cs == OUTPUT) begin
			cnt_pattern <= 0;
		end
		else begin
			cnt_pattern <= cnt_pattern;
		end
	end
end



//============EX
reg [3:0]idb;
reg	last_input_p, keep_ex;


always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		last_input_p <= 0;
		keep_ex <= 0;
	end
	else begin
		last_input_p <= ((cs == INPUT_P) && (!ispattern));	
		keep_ex <= ((cs==EX) && (!EX_finish));
	end
end





reg			case_4_middle;
reg last_space;

//the last char of pattern is space
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		last_space <= 0;
	end
	else begin
		if((cs == INPUT_P) && (!ispattern)) begin
			if(last_check + 1== cnt_pattern) begin
				last_space <= 1;
			end
			else if (last_dot + 1== cnt_pattern) begin
				last_space <= 1;
			end
			else begin
				last_space <= 0;
			end
		end
		else begin
			last_space <= last_space;
		end
	end
end


always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		case4_part1 <= 0;
		case4_part2 <= 0;
		case_4_middle <= 0;
		search_finish <= 0;
		tmp_match_index <= 0;
		for(idz = 0; idz < 'd8; idz = idz + 1) begin
			tmp_match[idz] <= 0;
		end
	end
	else begin
		if(cs==IDLE) begin
			case4_part1 <= 0;
			case4_part2 <= 0;
			case_4_middle <= 0;
			tmp_match_index <= 0;		
			for(idz = 0; idz < 'd8; idz = idz + 1) begin
				tmp_match[idz] <= 0;
			end
		end
		else if(last_input_p || keep_ex) begin
//-------------
		
			case(cnt_pattern) 
				'd1:begin
						for(idz = 'd1; idz < 'd8; idz = idz + 1) begin // setting empty char's tmp_match to 1 @when input pattern is finished
							tmp_match[idz] <= 1;
						end
					end
				'd2:begin
						for(idz = 'd2; idz < 'd8; idz = idz + 1) begin // setting empty char's tmp_match to 1 @when input pattern is finished
							tmp_match[idz] <= 1;
						end
					end
				'd3:begin
						for(idz = 'd3; idz < 'd8; idz = idz + 1) begin // setting empty char's tmp_match to 1 @when input pattern is finished
							tmp_match[idz] <= 1;
						end
					end
				'd4:begin
						for(idz = 'd4; idz < 'd8; idz = idz + 1) begin // setting empty char's tmp_match to 1 @when input pattern is finished
							tmp_match[idz] <= 1;
						end
					end
				'd5:begin
						for(idz = 'd5; idz < 'd8; idz = idz + 1) begin // setting empty char's tmp_match to 1 @when input pattern is finished
							tmp_match[idz] <= 1;
						end
					end
				'd6:begin
						for(idz = 'd6; idz < 'd8; idz = idz + 1) begin // setting empty char's tmp_match to 1 @when input pattern is finished
							tmp_match[idz] <= 1;
						end
					end
				'd7:begin
						for(idz = 'd7; idz < 'd8; idz = idz + 1) begin // setting empty char's tmp_match to 1 @when input pattern is finished
							tmp_match[idz] <= 1;
						end
					end
				'd8:begin
					end
			endcase

//--------------		
			if(case_4[0]) begin
				case(case_4[3:1]) 
					3'b000:	begin// * at first
								tmp_match[0] <= 1;
								case4_part1 <= 1;
								search_finish <= ((last_space) ? 1 : 3) + (cnt_string - cnt_pattern);
								for(idb = 1; idb < 'd9; idb = idb + 1) begin
									if(idb < cnt_pattern) begin
										if(strings[index_string + idb] == patterns[idb]) begin
											tmp_match[idb] <= 1;
										end
										else if (!patterns[idb]) begin // the char is . -> always true
											tmp_match[idb] <= 1;
										end
										else begin
											tmp_match[idb] <= 0;
										end
									end
								end
								if(all_match) begin
									case4_part2 <= 1;
									tmp_match_index <= 1;//index when all tmp are true(w/o consider the first space added by myself
								end
							end
					(cnt_pattern-1):begin// * at last
										tmp_match[cnt_pattern-1] <= 1;
										case4_part2 <= 1;
										//search_finish <= cnt_string - cnt_pattern + 3;
										search_finish <= ((last_space) ? 1 : 3) + (cnt_string - cnt_pattern);
										for(idb = 0; idb < 'd7; idb = idb + 1) begin
											if(idb < cnt_pattern - 1) begin
												if(strings[index_string + idb] == patterns[idb]) begin
													tmp_match[idb] <= 1;
												end
												else if (!patterns[idb]) begin // the char is . -> always true
													tmp_match[idb] <= 1;
												end
												else begin
													tmp_match[idb] <= 0;
												end
											end
										end
										if(all_match) begin
											case4_part1 <= 1;
											tmp_match_index <= index_string - 2;
										end
									end
					default:begin // * at middle
								if(!case4_part1 ) begin //first part cmp
									case_4_middle <= 1;
									search_finish <= ((last_space) ? 2 : 3) + cnt_string - cnt_pattern + case_4[3:1];
									for(ida = 0; ida < 'd8; ida = ida + 1) begin
										if(ida >= case_4[3:1]) begin
											if(ida < cnt_pattern) begin
												tmp_match[ida] <= 1;
											end
										end
									end
									for(idb = 0; idb < 'd7; idb = idb + 1) begin
										if(idb < case_4[3:1]) begin
											if(strings[index_string + idb] == patterns[idb]) begin
												tmp_match[idb] <= 1;
											end
											else if (!patterns[idb]) begin // the char is . -> always true
												tmp_match[idb] <= 1;
											end
											else begin
												tmp_match[idb] <= 0;
											end
										end
									end
									if(case_4_middle && all_match && !cnt_secpart) begin
										for(idb = 1; idb < 'd9; idb = idb + 1) begin
											if(idb < cnt_pattern) begin
												tmp_match <= 0;
											end
										end
									end
									if(all_match) begin
										tmp_match_index <= index_string - 2;
										case4_part1 <= 1;
									end	
								end
								else begin //2nd part map
									case_4_middle <= 0;
									for(ida = 0; ida < 'd8; ida = ida + 1) begin
										if(ida < case_4[3:1] + 1) begin
											tmp_match[ida] <= 1;
										end
									end
									for(idb = 0; idb < 'd7; idb = idb + 1) begin
										if(idb < (cnt_pattern - case_4[3:1] - 1)) begin
											if(strings[index_string + idb] == patterns[idb + case_4[3:1] + 1]) begin
												tmp_match[idb + case_4[3:1] + 1] <= 1;
											end
											else if (!patterns[case_4[3:1] + idb + 1]) begin // the char is . -> always true
												tmp_match[idb + case_4[3:1] + 1] <= 1;
											end
											else begin
												tmp_match[idb + case_4[3:1] + 1] <= 0;
											end
										end
									end
									if(all_match &&  !cnt_secpart) begin
										case4_part2 <= 1;
									end
									
								end
								
							end
				
			
			
				endcase
			end
			else begin //there is no * in pattern
					search_finish <= (last_space ? 1 : 2) + cnt_string - cnt_pattern;
					for(idb = 0; idb < 'd8; idb = idb + 1) begin
						if(idb < cnt_pattern) begin
							if(strings[index_string + idb] == patterns[idb]) begin
								tmp_match[idb] <= 1;
							end
							else if (!patterns[idb] && ((index_string + idb) != (cnt_string + 1))) begin // the char is . -> always true
								tmp_match[idb] <= 1;
							end
							else begin
								tmp_match[idb] <= 0;
							end
						end
					end
				//end
			end
		end

		else begin 
			for(idz = 0; idz < 'd8; idz = idz + 1) begin
				if(idz < cnt_pattern) begin
					tmp_match[idz] <= tmp_match[idz];
					case4_part1 <= case4_part1;
					case4_part2 <= case4_part2;
					case_4_middle <= 0;
					search_finish <= search_finish;
					tmp_match_index <= tmp_match_index;
				end
			end	
		end
	
	end
end


always@(negedge rst_n or posedge clk)begin
	if(!rst_n) begin
		cnt_secpart <= 0;
	end
	else begin
		if(case_4[0] && all_match && !case4_part1 ) begin
			cnt_secpart <= 1;
		end
		else if(case_4_middle) begin
			cnt_secpart <= 0;
		end
		else begin
			cnt_secpart <= cnt_secpart;
		end
	end
end

reg set_boundary;
wire set_special_head;//"^" or "." is the first char in pattern
assign set_special_head = ((cs == INPUT_P) && (!ispattern));



//index_string
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		index_string <= 0;
		set_boundary <= 1;
	end
	else begin
		if(cs == IDLE) begin
			index_string <= 0;
			set_boundary <= 1;
		end
		else if ((cs == INPUT_P) && (!ispattern)) begin
			if((first_space || first_dot)&& set_boundary) begin
				index_string <= 1;
				set_boundary <= 0;
			end
		end
		else if(last_input_p || keep_ex) begin
			if(case_4[0]) begin
				if(case_4_middle && all_match && !cnt_secpart) begin // * in middle
					index_string <= index_string + case_4[3:1] - 2;
				end
				else if(!case4_match) begin
					index_string <= index_string + 1;
				end
			end
			else if(!all_match) begin
				index_string <= index_string + 1;
			end
		end
		
		
		else begin
			index_string <= index_string;
			set_boundary <= set_boundary;
		end
	end
end

//all_match
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		all_match <= 0;
	end
	else begin
		if(cs == IDLE) begin
			all_match <= 0;
		end
		else if(case_4_middle && all_match && !cnt_secpart) begin
			all_match <= 0;
		end
		else if ((cs == EX) )begin
			all_match <= &tmp_match;
		end
		else begin
			all_match <= all_match;
		end
	end
end

//-----------------SAVE ANS

always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		ans_match <= 0;
		ans_match_index <= 0;
	end
	else begin
		if(cs == IDLE) begin
			ans_match <= 0;
			ans_match_index <= 0;
		end
		else if(cs == EX) begin
			if(case_4[0]) begin //case_4
				ans_match <= case4_part1 && case4_part2;
				if(!(case4_part1 && case4_part2)) begin //not match
					ans_match_index <= 0;
				end
				else begin //match
					if(first_space_fake) begin
						ans_match_index <= tmp_match_index;
					end
					else begin
						ans_match_index <= tmp_match_index - 1;
					end
				end
			end
			else begin //not case_4
				ans_match <= all_match;
				if(all_match) begin
					if(index_string == 2) begin
						ans_match_index <= 0;
						
												// the difference between added two space and original : 1; 
												// after tmp_match is true, the index will plus one again : 1;
												// the start of index is 1 not 0 : 1; 
												// => the correct index need to minus 3
					end
					
					else if (first_space_fake) begin //e.g. ^is
						ans_match_index <= index_string - 2;//the correct index plus one (because the answer should be the index of "i" not "^"
					end
					else begin
						ans_match_index <= index_string - 3;
					end
				end
				else begin
					ans_match_index <= 0;
				end
			end
		end
		else begin
			ans_match <= ans_match;
			ans_match_index <= ans_match_index;
		end
		
		
		
	end
end





//-----------------OUTPUT
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		out_valid <= 0;
		match <= 0;
		match_index <= 0;
	end
	else begin
		if((cs == OUTPUT) && (cnt_output==1) ) begin
			out_valid <= 1;
			match <= ans_match ;
			match_index <= ans_match_index;
		end
		else begin
			out_valid <= 0;
			match <= 0;
			match_index <= 0;		
		end
	end
end

//cnt_output
always@(negedge rst_n or posedge clk) begin
	if(!rst_n) begin
		cnt_output <= 0;
	end
	else begin
		if((cs == OUTPUT) && (cnt_output < 'd2))begin
			cnt_output <= cnt_output + 'd1;
		end
		else begin
			cnt_output <= 0;
		end
	
	end
end

endmodule
