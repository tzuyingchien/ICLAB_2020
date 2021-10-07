//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################
reg [3:0]			cs;
reg [15:0]			addr_instr;
reg [7:0]			cnt;
reg [3:0]			cnt_instr;
//wire[3:0]			cnt_instr;
reg [1:0] 			valid_sram_I;//recording sram has already accessed twice or not 
reg [1:0] 			valid_sram_D;//recording sram has already accessed twice or not 
reg [1:0] 			ff_valid_match_I, ff_valid_match_D;
reg [1:0] 			ff_valid_unmatch_I, ff_valid_unmatch_D;
reg [1:0]			mod_bit_D;//sram_I has been modified or not, deciding need to write back or not
reg 				i;
reg [3:0]			tag_I[1:0];
reg [3:0]			tag_D[1:0];
reg 				lru_I;
reg 				lru_D;
reg signed [15:0]	rs, rt, rd;
reg 				block_index;//which block of sram_D is matched
wire signed [15:0] 	add_out, sub_out, mul_out, cmp_out;
wire signed [31:0]	tmp_mul_out;
reg  signed [15:0] 	ans;
reg [15:0]			instr;
reg [15:0] 			addr_instr_soon;
reg [11:0]			offset;//sign(rs+imme) * 2
reg [6:0]			first_mod[1:0];
reg 				output_from_M;
//valid
//Data sram
wire valid_match_0 		= offset[11:8] == tag_D[0] && valid_sram_D[0]; 
wire valid_match_1 		= offset[11:8] == tag_D[1] && valid_sram_D[1];
wire valid_unmatch_0	= offset[11:8] != tag_D[0] && valid_sram_D[0]; 
wire valid_unmatch_1    = offset[11:8] != tag_D[1] && valid_sram_D[1];
//Instr sram
wire valid_match_0_I 		= addr_instr_soon[11:8] == tag_I[0] && valid_sram_I[0]; 
wire valid_match_1_I 		= addr_instr_soon[11:8] == tag_I[1] && valid_sram_I[1];
wire valid_unmatch_0_I		= addr_instr_soon[11:8] != tag_I[0] && valid_sram_I[0]; 
wire valid_unmatch_1_I  	= addr_instr_soon[11:8] != tag_I[1] && valid_sram_I[1];

//MEM
//SRAM_I
wire[15:0]	SRAM_I_out;
reg [15:0]	SRAM_I_in;
reg [7:0]	SRAM_I_addr;
reg			SRAM_I_CEN, SRAM_I_OEN, SRAM_I_WEN;
//SRAM_D
wire signed [15:0]	SRAM_D_out;
reg [15:0]	SRAM_D_in;
reg [7:0]	SRAM_D_addr;
reg			SRAM_D_CEN, SRAM_D_OEN, SRAM_D_WEN;

//AXI
reg rst_arvalid_0;
reg rst_arvalid_1;
reg ff_arready_0;
reg ff_arready_1;


parameter	S_ADDR_I		= 4'd0,
			LOAD_I			= 4'd1,
			S_ADDR_pc		= 4'd8,
			READ_INSTR		= 4'd2,
			S_ADDR_D		= 4'd3,
			LOAD_D			= 4'd4,
			WB_S_ADDR_D_1	= 4'd5,
			BEQ_or_J		= 4'd9,
			LOAD			= 4'd10,
			STORE			= 4'd11,
			WB				= 4'd6,
			OUTPUT			= 4'd7,
			OUTPUT_M		= 4'd12,
			WB_S_ADDR_D		= 4'd13,
			WB_1			= 4'd14,
			S_ADDR_LOAD		= 4'd15;
//####################################################
//               FSM	
//####################################################
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		cs <= 4'd0;
	else
		begin
			case(cs)
				S_ADDR_I:		cs <= arready_m_inf[1] 	? LOAD_I : cs;
				LOAD_I:			cs <= cnt == 'd127	? S_ADDR_pc : cs;
				S_ADDR_pc:		cs <= READ_INSTR;
/* 				READ_INSTR:
					begin
						case(SRAM_I_out[15:13])
							3'b000, 3'b001:		cs <= OUTPUT;
							//3'b100, 3'b101:		cs <= BEQ_or_J;
							3'b010:				cs <= S_ADDR_LOAD;
							3'b011:	
								begin
									if(valid_sram_D[0] && offset[11:8] == tag_D[0])
										cs <= STORE;
									else if(valid_sram_D[1] && offset[11:8] == tag_D[1])
										cs <= STORE;
									else
										cs <= S_ADDR_D;									
								end
						endcase
					end
 */				S_ADDR_D:		cs <= arready_m_inf[0] 	? LOAD_D : cs;
				LOAD_D:			cs <= cnt == 'd127		? 
								(instr[15:13] == 3'b010 ? S_ADDR_LOAD : STORE) : cs;
				STORE:			
					begin
						if(cnt_instr == 4'd9)
							begin
								if(mod_bit_D[0] || valid_match_0)//since the last instr is store, it must write back
									cs <= WB_S_ADDR_D;
								else if (mod_bit_D[1] || valid_match_1)
									cs <= WB_S_ADDR_D_1;
								//else
								//	cs <= OUTPUT_M;
							end
						else 
							begin
								cs <= OUTPUT_M;
							end
					end
				S_ADDR_LOAD:	cs <= LOAD;
				LOAD:	
					begin
						if(cnt_instr == 4'd9)
							begin
								if(mod_bit_D[0])
									cs <= WB_S_ADDR_D;
								else if (mod_bit_D[1])
									cs <= WB_S_ADDR_D_1;
								else
									cs <= OUTPUT_M;
							end
						else 
							begin
								cs <= OUTPUT_M;
							end
					end
				READ_INSTR:			
					begin
						if(cnt_instr == 4'd9 || (cnt_instr == 4'd8 && IO_stall == 1'b0))//which means the current processing instr is the tenth
							begin
								case(SRAM_I_out[15:13])
									//3'b000, 3'b001: 
									//	begin
									//		if(mod_bit_D[0])
									//			cs <= WB_S_ADDR_D;
									//		else if (mod_bit_D[1])
									//			cs <= WB_S_ADDR_D_1;
									//		else
									//			cs <= OUTPUT;
									//	end
									3'b000, 3'b001, 3'b100, 3'b101: 
										begin
											if(mod_bit_D[0])
												cs <= WB_S_ADDR_D;
											else if (mod_bit_D[1])
												cs <= WB_S_ADDR_D_1;
											else
												begin
													if(valid_match_0_I || valid_match_1_I)
														cs <= OUTPUT;
													else if(valid_unmatch_0_I && valid_unmatch_1_I)//need to load instr from DRAM
														cs <= S_ADDR_I;
													else //invalid
														cs <= S_ADDR_I;
												end
										end
									3'b011://store
										begin
											if(valid_match_0 || valid_match_1)
												cs <= STORE;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else
												cs <= S_ADDR_D;										
										end
									3'b010://load
										begin
											if(valid_match_0 || valid_match_1)
												cs <= S_ADDR_LOAD;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else
												cs <= S_ADDR_D;										
										end
									//default:	cs <= TMP;//unfinished
								endcase						
							end
						else 
							begin
								//***copy to above***
								case(SRAM_I_out[15:13])
									//3'b000, 3'b001: cs <= OUTPUT;
									3'b000, 3'b001, 3'b100, 3'b101:
										begin
											if(valid_match_0_I || valid_match_1_I)
												cs <= OUTPUT;
											else if(valid_unmatch_0_I && valid_unmatch_1_I)//need to load instr from DRAM
												cs <= S_ADDR_I;
											else //invalid
												cs <= S_ADDR_I;
										end
									3'b011://store
										begin
											if(valid_match_0 || valid_match_1)
												cs <= STORE;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else //invalid
												cs <= S_ADDR_D;												
										end
									3'b010://load
										begin
											if(valid_match_0 || valid_match_1)
												cs <= S_ADDR_LOAD;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else
												cs <= S_ADDR_D;										
										end

									//unfinished(remember to modify both place!!!!!
									//default: cs <= TMP;
								endcase
							end
					end
				OUTPUT:
					begin
						if(cnt_instr == 4'd9 || (cnt_instr == 4'd8 && IO_stall == 1'b0))//which means the current processing instr is the tenth
							begin
								case(SRAM_I_out[15:13])
									//3'b000, 3'b001:
									//	begin
									//		if(mod_bit_D[0])
									//			cs <= WB_S_ADDR_D;
									//		else if (mod_bit_D[1])
									//			cs <= WB_S_ADDR_D_1;
									//		else
									//			cs <= OUTPUT;
									//	end
									3'b000, 3'b001, 3'b100, 3'b101: 
										begin
											if(mod_bit_D[0])
												cs <= WB_S_ADDR_D;
											else if (mod_bit_D[1])
												cs <= WB_S_ADDR_D_1;
											else
												begin
													if(valid_match_0_I || valid_match_1_I)
														cs <= OUTPUT;
													else if(valid_unmatch_0_I && valid_unmatch_1_I)//need to load instr from DRAM
														cs <= S_ADDR_I;
													else //invalid
														cs <= S_ADDR_I;
												end
										end
									3'b011://store
										begin
											if(valid_match_0 || valid_match_1)
												cs <= STORE;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else
												cs <= S_ADDR_D;										
										end
									3'b010://load
										begin
											if(valid_match_0 || valid_match_1)
												cs <= S_ADDR_LOAD;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else
												cs <= S_ADDR_D;										
										end
									//default:	cs <= TMP;//unfinished
								endcase						
							end
						else 
							begin
								//***copy to above***
								case(SRAM_I_out[15:13])
									//3'b000, 3'b001:
									//	cs <= OUTPUT;
									3'b000, 3'b001, 3'b100, 3'b101: 
										begin
											if(valid_match_0_I || valid_match_1_I)
												cs <= OUTPUT;
											else if(valid_unmatch_0_I && valid_unmatch_1_I)//need to load instr from DRAM
												cs <= S_ADDR_I;
											else //invalid
												cs <= S_ADDR_I;
										end
									3'b011://store
										begin
											if(valid_match_0 || valid_match_1)
												cs <= STORE;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else //invalid
												cs <= S_ADDR_D;												
										end
									3'b010://load
										begin
											if(valid_match_0 || valid_match_1)
												cs <= S_ADDR_LOAD;
											else if(valid_unmatch_0 && valid_unmatch_1)	
												begin
													if(mod_bit_D[lru_D])
														begin
															if(lru_D == 1'b0)
																cs <= WB_S_ADDR_D;
															else 
																cs <= WB_S_ADDR_D_1;
														end
													else 
														cs <= S_ADDR_D;
												end
											else
												cs <= S_ADDR_D;										
										end

									//unfinished(remember to modify both place!!!!!
									//default: cs <= TMP;
								endcase
							end
					end
				OUTPUT_M:
					begin
						if(ff_valid_match_I[0] || ff_valid_match_I[1])
							cs <= S_ADDR_pc;
						else if(ff_valid_unmatch_I[0] && ff_valid_unmatch_I[1])//need to load instr from DRAM
							cs <= S_ADDR_I;
						else //invalid
							cs <= S_ADDR_I;
					end
				WB_S_ADDR_D:	cs <= 	awready_m_inf ? WB : cs;
				WB_S_ADDR_D_1:	cs <= 	awready_m_inf ? WB_1 : cs;
				WB:				
					begin
						//if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && valid_unmatch_0 && valid_unmatch_1)
						if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && ff_valid_unmatch_D[0] && ff_valid_unmatch_D[1])
							//load/store unmatch
							cs <= 	(bvalid_m_inf && bresp_m_inf == 2'b00) ? S_ADDR_D : cs;
						else if(cnt_instr == 4'd9)
							begin
								if(bvalid_m_inf && bresp_m_inf == 2'b00)
									if(mod_bit_D[1])								cs <= WB_S_ADDR_D_1;
									//else if(valid_match_0_I || valid_match_1_I)		cs <= S_ADDR_pc;
									else if(ff_valid_match_I[0] || ff_valid_match_I[1])		cs <= S_ADDR_pc;
									//else if(valid_unmatch_0_I && valid_unmatch_1_I)	cs <= S_ADDR_I;
									else if(ff_valid_unmatch_I[0] && ff_valid_unmatch_I[1])	cs <= S_ADDR_I;
									else 											cs <= S_ADDR_I;
									
							end
						
							//cs <= 	(bvalid_m_inf && bresp_m_inf == 2'b00) ?
							//		(mod_bit_D[1] ? WB_S_ADDR_D_1 : S_ADDR_pc) : cs;
					end										
				WB_1:			
					begin
						//if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && valid_unmatch_0 && valid_unmatch_1)
						if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && ff_valid_unmatch_D[0] && ff_valid_unmatch_D[1])
							cs <= 	(bvalid_m_inf && bresp_m_inf == 2'b00) ? S_ADDR_D : cs;
						else if(cnt_instr == 4'd9)
							begin
								if(bvalid_m_inf && bresp_m_inf == 2'b00)
									//if(valid_match_0_I || valid_match_1_I)			cs <= S_ADDR_pc;
									if(ff_valid_match_I[0] || ff_valid_match_I[1])			cs <= S_ADDR_pc;
									//else if(valid_unmatch_0_I && valid_unmatch_1_I)	cs <= S_ADDR_I;
									else if(ff_valid_unmatch_I[0] && ff_valid_unmatch_I[1])	cs <= S_ADDR_I;
									else 											cs <= S_ADDR_I;
							end
							//cs <= 	(bvalid_m_inf && bresp_m_inf == 2'b00) ? S_ADDR_pc : cs;
					end										
			endcase
		end
end


//####################################################
//               addr_instr
//####################################################
wire [15:0] next_instr 	= addr_instr + 'd2;
wire [15:0] addr_beq	= next_instr + $signed ($signed(SRAM_I_out[4:0]) * 2);
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		addr_instr <= 16'h1000;
	else 
		begin
			if(cs == READ_INSTR || cs == OUTPUT)
				begin
					if	(SRAM_I_out[15:13] == 3'b000 ||
						 SRAM_I_out[15:13] == 3'b001 ||
						 SRAM_I_out[15:13] == 3'b010 ||
						 SRAM_I_out[15:13] == 3'b011)
							addr_instr <= next_instr;
					else if (SRAM_I_out[15:13] == 3'b100)
						addr_instr <= sub_out == 0 ?  addr_beq : next_instr;
					else if (SRAM_I_out[15:13] == 3'b101)
						addr_instr <= {3'b000, SRAM_I_out[12:0]};
					//else 	
					//	addr_instr <= addr_instr;
				end
			//else 
			//	addr_instr <= addr_instr;
		
		
			//case(cs)
			//	READ_INSTR, OUTPUT:
			//		begin
			//			case(SRAM_I_out[15:13])
			//				3'b000, 3'b001, 3'b010, 3'b011:		addr_instr <= next_instr;
			//				3'b100:								addr_instr <= sub_out == 0 ?  addr_beq : next_instr;
			//				3'b101:								addr_instr <= {3'b000, SRAM_I_out[12:0]};
			//				default:							addr_instr <= addr_instr;
			//			endcase
			//		end
			//	default:	addr_instr <= addr_instr;
			//	//OUTPUT:
			//	//	begin
			//	//		if(cnt_instr == 4'd8 && mod_bit_D != 2'b00) //need to write back to dram
			//	//			addr_instr <= addr_instr;
			//	//		else
			//	//			begin
			//	//				case(SRAM_I_out[15:13])
			//	//					3'b000, 3'b001, 3'b010, 3'b011:		addr_instr <= next_instr;
			//	//					3'b100:	addr_instr <= sub_out == 0 ? next_instr + SRAM_I_out[4:0] : next_instr;
			//	//					3'b101:	addr_instr <= {3'b000, SRAM_I_out[12:0]};
			//	//				endcase
			//	//			end
			//	//	end
			//endcase
		end
end

always@(*) begin
	case(cs)
		READ_INSTR, OUTPUT:
			begin
				case(SRAM_I_out[15:13])
					3'b000, 3'b001, 3'b010, 3'b011:	addr_instr_soon = next_instr;
					3'b100:							addr_instr_soon = sub_out == 0 ? addr_beq : next_instr;
					3'b101:							addr_instr_soon = {3'b000, SRAM_I_out[12:0]};
					default:						addr_instr_soon = addr_instr;
				endcase
			end
		default:	
			addr_instr_soon = addr_instr;
	endcase
end
//####################################################
//               Read address channel : S_ADDR
//####################################################
//INSTR SRAM
assign arid_m_inf	 [7:4]		= 	0;
assign araddr_m_inf	 [63:32]	= 	{16'd0, 4'b0001, addr_instr[11:8], 8'd0};
assign arlen_m_inf	 [13:7]		= 	7'd127;
assign arsize_m_inf	 [5:3]		= 	3'b001;//specification
assign arburst_m_inf [3:2]		= 	2'b01;//specification
//assign arvalid_m_inf [1]		= 	rst_arvalid_1 	? 0 	: 
//									cs == S_ADDR_I 	? 1'b1 	: 1'b0;
assign arvalid_m_inf [1]		= 	cs == S_ADDR_I 	? 1'b1 	: 1'b0;

//DATA SRAM
assign arid_m_inf	 [3:0]		= 	0;
assign araddr_m_inf	 [31:0]		= 	{16'd0, 4'b0001, offset[11:8], 8'd0};
assign arlen_m_inf	 [6:0]		= 	7'd127;
assign arsize_m_inf	 [2:0]		= 	3'b001;//specification
assign arburst_m_inf [1:0]		= 	2'b01;//specification
//assign arvalid_m_inf [0]		= 	rst_arvalid_0 	? 0 	: 
//									cs == S_ADDR_D 	? 1'b1 	: 1'b0;
assign arvalid_m_inf [0]		= 	cs == S_ADDR_D 	? 1'b1 	: 1'b0;



always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	rst_arvalid_0 <= 0;
	else 		rst_arvalid_0 <= (arready_m_inf[0] == 1'b1) ? 1'b1 : 1'b0;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	rst_arvalid_1 <= 0;
	else 		rst_arvalid_1 <= (arready_m_inf[1] == 1'b1) ? 1'b1 : 1'b0;
	//else 		rst_arvalid_1 <= arready_m_inf[1] == 1'b1 ? 1'b1 : 1'b0;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	ff_arready_0 <= 0;
	else begin
		case(cs)
			S_ADDR_D:	ff_arready_0 <= arready_m_inf[0]	? 1 : ff_arready_0;
			default:	ff_arready_0 <= 0;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	ff_arready_1 <= 0;
	else begin
		case(cs)
			S_ADDR_I:	ff_arready_1 <= arready_m_inf[1]	? 1 : ff_arready_1;
			default:	ff_arready_1 <= 0;
		endcase
	end
end
//####################################################
//               Read data channel : LOAD
//####################################################
//INSTR SRAM
assign rready_m_inf[1] 	= cs == LOAD_I	? 1'b1 : 1'b0;
//DATA SRAM
assign rready_m_inf[0] 	= cs == LOAD_D 	? 1'b1 : 1'b0;


//####################################################
//               Write address channel : WB_S_ADDR_D, WB_S_ADDR_D_1
//####################################################
//DATA DRAM
assign awid_m_inf 		= 	0;
assign awaddr_m_inf 	= 	cs == WB_S_ADDR_D ? 	{16'd0, 4'b0001, tag_D[0], first_mod[0], 1'b0} :
							cs == WB_S_ADDR_D_1 ?	{16'd0, 4'b0001, tag_D[1], first_mod[1], 1'b0} : 32'd0;
assign awlen_m_inf 		= 	cs == WB_S_ADDR_D ? 	(~first_mod[0]) : 
							cs == WB_S_ADDR_D_1 ? 	(~first_mod[1]) : 7'd0;
assign awsize_m_inf		= 	3'b001;//specification
assign awburst_m_inf	= 	2'b01;//specification
assign awvalid_m_inf 	= 	(cs == WB_S_ADDR_D || cs == WB_S_ADDR_D_1) ? 1'b1 : 1'b0;

//####################################################
//               Write data channel : WB, WB_1
//####################################################
//DATA DRAM
assign wdata_m_inf	= 	SRAM_D_out;
assign wlast_m_inf 	= 	(cs == WB && first_mod[0] == 7'd127) ||
						(cs == WB_1 && first_mod[1] == 7'd127);
assign wvalid_m_inf = 	cs == WB || cs == WB_1;

//####################################################
//               Write response channel : WB, WB_1
//####################################################
//DATA DRAM
assign bready_m_inf = 	cs == WB || cs == WB_1;

//####################################################
//               core register
//####################################################
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		begin
			core_r0 	<= 16'd0;
			core_r1 	<= 16'd0;
			core_r2 	<= 16'd0;
			core_r3 	<= 16'd0;
			core_r4 	<= 16'd0;
			core_r5 	<= 16'd0;
			core_r6 	<= 16'd0;
			core_r7 	<= 16'd0;
			core_r8 	<= 16'd0;
			core_r9 	<= 16'd0;
			core_r10 	<= 16'd0;
			core_r11 	<= 16'd0;
			core_r12 	<= 16'd0;
			core_r13 	<= 16'd0;
			core_r14 	<= 16'd0;
			core_r15 	<= 16'd0;
		end
	else
		begin
			if(cs == OUTPUT  || cs == READ_INSTR)
				begin
					if(SRAM_I_out[15:13] == 3'b000 || SRAM_I_out[15:13] == 3'b001)
						begin
							case(SRAM_I_out[4:1])
								4'd0 :	core_r0  <= ans;
								4'd1 :	core_r1  <= ans;
								4'd2 :	core_r2  <= ans;
								4'd3 :	core_r3  <= ans;
								4'd4 :	core_r4  <= ans;
								4'd5 :	core_r5  <= ans;
								4'd6 :	core_r6  <= ans;
								4'd7 :	core_r7  <= ans;
								4'd8 :	core_r8  <= ans;
								4'd9 :	core_r9  <= ans;
								4'd10:	core_r10 <= ans;
								4'd11:	core_r11 <= ans;
								4'd12:	core_r12 <= ans;
								4'd13:	core_r13 <= ans;
								4'd14:	core_r14 <= ans;
								4'd15:	core_r15 <= ans;
							endcase
						end
				
				end
			else if(cs == LOAD)
				begin
					case(instr[8:5])
						4'd0 :	core_r0  <= SRAM_D_out;
						4'd1 :	core_r1  <= SRAM_D_out;
						4'd2 :	core_r2  <= SRAM_D_out;
						4'd3 :	core_r3  <= SRAM_D_out;
						4'd4 :	core_r4  <= SRAM_D_out;
						4'd5 :	core_r5  <= SRAM_D_out;
						4'd6 :	core_r6  <= SRAM_D_out;
						4'd7 :	core_r7  <= SRAM_D_out;
						4'd8 :	core_r8  <= SRAM_D_out;
						4'd9 :	core_r9  <= SRAM_D_out;
						4'd10:	core_r10 <= SRAM_D_out;
						4'd11:	core_r11 <= SRAM_D_out;
						4'd12:	core_r12 <= SRAM_D_out;
						4'd13:	core_r13 <= SRAM_D_out;
						4'd14:	core_r14 <= SRAM_D_out;
						4'd15:	core_r15 <= SRAM_D_out;
					endcase
				end
		end
end

wire [15:0]	instr_src = (cs == READ_INSTR || cs == OUTPUT) ? SRAM_I_out : instr;

always@(*) begin
	case(cs)
		READ_INSTR, OUTPUT:	
			begin
				case({instr_src[15:13], instr_src[0]})
					4'b0000: ans = add_out;//add
					4'b0001: ans = sub_out;//sub
					4'b0010: ans = cmp_out;//slt
					4'b0011: ans = mul_out;//mul
					default: ans = 16'hffff;
				endcase
			end
		default:
			ans = 16'hffff;
	endcase
end

reg [3:0] 	tmp_rs, tmp_rt, tmp_rd;
//rs
always@(*) begin
	case(instr_src[12:9])
		4'd0 :	rs = core_r0 ;
		4'd1 :	rs = core_r1 ;
		4'd2 :	rs = core_r2 ;
		4'd3 :	rs = core_r3 ;
		4'd4 :	rs = core_r4 ;
		4'd5 :	rs = core_r5 ;
		4'd6 :	rs = core_r6 ;
		4'd7 :	rs = core_r7 ;
		4'd8 :	rs = core_r8 ;
		4'd9 :	rs = core_r9 ;
		4'd10:	rs = core_r10;
		4'd11:	rs = core_r11;
		4'd12:	rs = core_r12;
		4'd13:	rs = core_r13;
		4'd14:	rs = core_r14;
		4'd15:	rs = core_r15;
	endcase
end
always@(*) begin
	case(instr_src[12:9])
		4'd0 :	tmp_rs = 4'd0 ;
		4'd1 :	tmp_rs = 4'd1 ;
		4'd2 :	tmp_rs = 4'd2 ;
		4'd3 :	tmp_rs = 4'd3 ;
		4'd4 :	tmp_rs = 4'd4 ;
		4'd5 :	tmp_rs = 4'd5 ;
		4'd6 :	tmp_rs = 4'd6 ;
		4'd7 :	tmp_rs = 4'd7 ;
		4'd8 :	tmp_rs = 4'd8 ;
		4'd9 :	tmp_rs = 4'd9 ;
		4'd10:	tmp_rs = 4'd10;
		4'd11:	tmp_rs = 4'd11;
		4'd12:	tmp_rs = 4'd12;
		4'd13:	tmp_rs = 4'd13;
		4'd14:	tmp_rs = 4'd14;
		4'd15:	tmp_rs = 4'd15;
	endcase
end
//rt
always@(*) begin
	case(instr_src[8:5])
		4'd0 :	rt = core_r0 ;
		4'd1 :	rt = core_r1 ;
		4'd2 :	rt = core_r2 ;
		4'd3 :	rt = core_r3 ;
		4'd4 :	rt = core_r4 ;
		4'd5 :	rt = core_r5 ;
		4'd6 :	rt = core_r6 ;
		4'd7 :	rt = core_r7 ;
		4'd8 :	rt = core_r8 ;
		4'd9 :	rt = core_r9 ;
		4'd10:	rt = core_r10;
		4'd11:	rt = core_r11;
		4'd12:	rt = core_r12;
		4'd13:	rt = core_r13;
		4'd14:	rt = core_r14;
		4'd15:	rt = core_r15;
	endcase
end
always@(*) begin
	case(instr_src[8:5])
		4'd0 :	tmp_rt = 4'd0 ;
		4'd1 :	tmp_rt = 4'd1 ;
		4'd2 :	tmp_rt = 4'd2 ;
		4'd3 :	tmp_rt = 4'd3 ;
		4'd4 :	tmp_rt = 4'd4 ;
		4'd5 :	tmp_rt = 4'd5 ;
		4'd6 :	tmp_rt = 4'd6 ;
		4'd7 :	tmp_rt = 4'd7 ;
		4'd8 :	tmp_rt = 4'd8 ;
		4'd9 :	tmp_rt = 4'd9 ;
		4'd10:	tmp_rt = 4'd10;
		4'd11:	tmp_rt = 4'd11;
		4'd12:	tmp_rt = 4'd12;
		4'd13:	tmp_rt = 4'd13;
		4'd14:	tmp_rt = 4'd14;
		4'd15:	tmp_rt = 4'd15;
	endcase
end
//rd
always@(*) begin
	case(instr_src[4:1])
		4'd0 :	rd = core_r0 ;
		4'd1 :	rd = core_r1 ;
		4'd2 :	rd = core_r2 ;
		4'd3 :	rd = core_r3 ;
		4'd4 :	rd = core_r4 ;
		4'd5 :	rd = core_r5 ;
		4'd6 :	rd = core_r6 ;
		4'd7 :	rd = core_r7 ;
		4'd8 :	rd = core_r8 ;
		4'd9 :	rd = core_r9 ;
		4'd10:	rd = core_r10;
		4'd11:	rd = core_r11;
		4'd12:	rd = core_r12;
		4'd13:	rd = core_r13;
		4'd14:	rd = core_r14;
		4'd15:	rd = core_r15;
	endcase
end
always@(*) begin
	case(instr_src[4:1])
		4'd0 :	tmp_rd = 4'd0 ;
		4'd1 :	tmp_rd = 4'd1 ;
		4'd2 :	tmp_rd = 4'd2 ;
		4'd3 :	tmp_rd = 4'd3 ;
		4'd4 :	tmp_rd = 4'd4 ;
		4'd5 :	tmp_rd = 4'd5 ;
		4'd6 :	tmp_rd = 4'd6 ;
		4'd7 :	tmp_rd = 4'd7 ;
		4'd8 :	tmp_rd = 4'd8 ;
		4'd9 :	tmp_rd = 4'd9 ;
		4'd10:	tmp_rd = 4'd10;
		4'd11:	tmp_rd = 4'd11;
		4'd12:	tmp_rd = 4'd12;
		4'd13:	tmp_rd = 4'd13;
		4'd14:	tmp_rd = 4'd14;
		4'd15:	tmp_rd = 4'd15;
	endcase
end
//####################################################
//               IO_stall
//####################################################
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		IO_stall <= 1;
	else
		begin
			case(cs)
				READ_INSTR, OUTPUT:		
					begin
						if(cnt_instr == 4'd9  || (cnt_instr == 4'd8 && IO_stall == 1'b0))
							begin
								if(mod_bit_D != 2'd0)	
									IO_stall <= 1;
								else if (SRAM_I_out[15:13] == 3'b000 || SRAM_I_out[15:13] == 3'b001) begin
									IO_stall <= 0;
								end
								else if (SRAM_I_out[15:13] == 3'b100 || SRAM_I_out[15:13] == 3'b101) begin
									IO_stall <= 0;
								end
								else 
									IO_stall <= 1;
							end
						else if	(SRAM_I_out[15:13] == 3'b000 || SRAM_I_out[15:13] == 3'b001 || 
								 SRAM_I_out[15:13] == 3'b100 || SRAM_I_out[15:13] == 3'b101)
								//(SRAM_I_out[15:13] == 3'b100 && (valid_match_0_I || valid_match_1_I)) || //beq
								//(SRAM_I_out[15:13] == 3'b101 && (SRAM_I_out[11:8] == tag_I[0] || SRAM_I_out[11:8] == tag_I[1]))) //jump
							begin
								IO_stall <= 0;
							end
						else
							IO_stall <= 1;
					end
				OUTPUT_M:	
					begin
						IO_stall <= 0;
					end
				WB:		
					begin
						//if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && valid_unmatch_0 && valid_unmatch_1)//WB -> LOAD_D -> LOAD/STORE -> WB
						if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && ff_valid_unmatch_D[0] && ff_valid_unmatch_D[1])//WB -> LOAD_D -> LOAD/STORE -> WB
							IO_stall <= 1;
						else 
							begin
								if(mod_bit_D[1])
									IO_stall <= 1;
								else
									begin
										//IO_stall <= (bvalid_m_inf && bresp_m_inf == 2'b00) ? 0 : 1;
										if(bvalid_m_inf && bresp_m_inf == 2'b00)
											begin
												IO_stall <= 0;
											end
										else
											IO_stall <= 1;
									end
							end
					end
				WB_1:	
					begin
						//if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && valid_unmatch_0 && valid_unmatch_1)//WB -> LOAD_D -> LOAD/STORE -> WB
						if((instr[15:13] == 3'b010 || instr[15:13] == 3'b011) && ff_valid_unmatch_D[0] && ff_valid_unmatch_D[1])//WB -> LOAD_D -> LOAD/STORE -> WB
							IO_stall <= 1;
						else 
							begin
								//IO_stall <= (bvalid_m_inf && bresp_m_inf == 2'b00) ? 0 : 1;
								if(bvalid_m_inf && bresp_m_inf == 2'b00)
									begin
										IO_stall <= 0;
									end
								else IO_stall <= 1;
							end	
					end
				default:	IO_stall <= 1;
			endcase
		end
end

//####################################################
//               LRU
//####################################################
//replace 0~127 or 128~255 in INSTR_SRAM
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		lru_I <= 0;
	else
		if(rlast_m_inf[1])	lru_I <= !lru_I;//each access will change once
end
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		lru_D <= 0;
	else
		if(rlast_m_inf[0])	lru_D <= !lru_D;//each access will change once
end
//####################################################
//               cnt
//####################################################
//cnt
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		cnt <= 0;
	else 
		begin
			case(cs)
				LOAD_I:		cnt <= rvalid_m_inf[1] ? cnt + 1 : cnt;
				LOAD_D:		cnt <= rvalid_m_inf[0] ? cnt + 1 : cnt;
				default:	cnt <= 0;
			endcase
		end
end
//cnt_instr
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		cnt_instr <= 0;
	else 
		cnt_instr <= 	IO_stall == 1'b0 ? 
						(cnt_instr == 4'd9 ? 4'd0 : cnt_instr + 'd1) : cnt_instr;
end
/* always@(posedge clk or negedge rst_n) begin	if(!rst_n)
		ff_cnt_instr <= 0;
	else 
		ff_cnt_instr <= 	IO_stall == 1'b0 ? 
							(ff_cnt_instr == 4'd9 ? 4'd0 : ff_cnt_instr + 'd1) : ff_cnt_instr;
end
assign cnt_instr = 	IO_stall == 1'b0 ? 
					(ff_cnt_instr == 4'd9 ? 4'd0 : ff_cnt_instr + 'd1) : ff_cnt_instr;
 *///####################################################
//               tag
//####################################################
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		begin
			tag_I[0] <= 0;
			tag_I[1] <= 0;
		end
	else 
		begin
			case(cs)
				LOAD_I:		tag_I[lru_I] <= addr_instr[11:8];
				default:
					begin
						tag_I[0] <= tag_I[0];
						tag_I[1] <= tag_I[1];
					end
			endcase
		end
end
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		begin
			tag_D[0] <= 0;
			tag_D[1] <= 0;
		end
	else 
		begin
			case(cs)
				LOAD_D:		
					begin
						if(!valid_sram_D[0])//invalid_0
							begin
								tag_D[lru_D]  <= offset[11:8];
								tag_D[!lru_D] <= tag_D[!lru_D];
							end	
						else if(!valid_sram_D[1] && offset[11:8] != tag_D[0])//invalid_1 and block 0 doesn't match
							begin
								tag_D[lru_D] <= offset[11:8];
								tag_D[!lru_D] <= tag_D[!lru_D];
							end	
						else if(tag_D[lru_D] != offset[11:8]) //valid but not match
							begin
								tag_D[lru_D] <= offset[11:8];						
								tag_D[!lru_D] <= tag_D[!lru_D];
							end
						else
							begin
								tag_D[0] <= tag_D[0];
								tag_D[1] <= tag_D[1];
							end
					end
				default:
					begin
						tag_D[0] <= tag_D[0];
						tag_D[1] <= tag_D[1];
					end
			endcase
		end
end
//####################################################
//               valid
//####################################################
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		valid_sram_I <= 0;
	else
		begin
			if(valid_sram_I[0] == 1'b0)
				begin
					if(cs == S_ADDR_I)
						valid_sram_I[0] <= 1'b1;
				end
			else if(valid_sram_I[1] == 1'b0)
				begin	
					if(cs == S_ADDR_I)
						valid_sram_I[1] <= 1'b1;
				end
			else
				valid_sram_I <= valid_sram_I;
		end
end
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		valid_sram_D <= 0;
	else
		begin
			if(valid_sram_D[0] == 1'b0)
				begin
					if(cs == S_ADDR_D)
						valid_sram_D[0] <= 1'b1;
				end
			else if(valid_sram_D[1] == 1'b0)
				begin	
					if(cs == S_ADDR_D)
						valid_sram_D[1] <= 1'b1;
				end
			else
				valid_sram_D <= valid_sram_D;
		end
end


always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		begin
			ff_valid_match_I 	<= 2'b00;
			ff_valid_unmatch_I	<= 2'b00;
		end
	else
		begin
			case(cs)
				READ_INSTR, OUTPUT:	
					begin
						ff_valid_match_I 	<= {valid_match_1_I, valid_match_0_I};
						ff_valid_unmatch_I 	<= {valid_unmatch_1_I, valid_unmatch_0_I};
					end
				default:
					begin
						ff_valid_match_I 	<= ff_valid_match_I;
						ff_valid_unmatch_I 	<= ff_valid_unmatch_I;
					end
			endcase
		end
end
//try!!!
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		begin
			ff_valid_match_D 	<= 2'b00;
			ff_valid_unmatch_D	<= 2'b00;
		end
	else
		begin
			case(cs)
				READ_INSTR, OUTPUT:	
					begin
						ff_valid_match_D 	<= {valid_match_1, valid_match_0};
						ff_valid_unmatch_D 	<= {valid_unmatch_1, valid_unmatch_0};
					end
				default:
					begin
						ff_valid_match_D 	<= ff_valid_match_D;
						ff_valid_unmatch_D 	<= ff_valid_unmatch_D;
					end
			endcase
		end
end
//####################################################
//               mod_bit_D
//####################################################
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		mod_bit_D <= 0;
	else
		begin
			case(cs)
				//LOAD_D:	mod_bit_D[
				STORE:		mod_bit_D[block_index] 	<= 1;
				WB:			mod_bit_D[0]			<= 0;
				WB_1:		mod_bit_D[1] 			<= 0;
				default:	mod_bit_D 				<= mod_bit_D;
			endcase
		end
end

//first_mod
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		begin
			first_mod[0] <= 7'd127;
			first_mod[1] <= 7'd127;
		end
	else
		begin
			case(cs)
				STORE:	first_mod[block_index] <= 	offset[7:1] < first_mod[block_index] ? 
													offset[7:1] : first_mod[block_index];
				WB:		first_mod[0] <= wready_m_inf ? 
										(first_mod[0] == 7'd127 ? 7'd0 : first_mod[0] + 'd1) : first_mod[0];
				WB_1:	first_mod[1] <= wready_m_inf ? 
										(first_mod[1] == 7'd127 ? 7'd0 : first_mod[1] + 'd1) : first_mod[1];
				default:
					begin
						first_mod[0] <= first_mod[0];
						first_mod[1] <= first_mod[1];
					end
			endcase
		end
end

reg [6:0]	first_mod_soon[1:0];
always@(*) begin
	case(cs)
		WB_S_ADDR_D, WB_S_ADDR_D_1:	
			begin
				first_mod_soon[0] = first_mod[0];
				first_mod_soon[1] = first_mod[1];
			end			
		WB, WB_1:	
			begin
				first_mod_soon[0] = wready_m_inf ? 
									(first_mod[0] == 7'd127 ? 7'd0 : first_mod[0] + 'd1) : first_mod[0];
				first_mod_soon[1] = wready_m_inf ? 
									(first_mod[1] == 7'd127 ? 7'd0 : first_mod[1] + 'd1) : first_mod[1];
			end	
		default:
			begin
				first_mod_soon[0] = first_mod[0];
				first_mod_soon[1] = first_mod[1];
			end			
	endcase
end 
//####################################################
//               block_index
//####################################################
always@(*) begin
	if(offset[11:8] == tag_D[0])
		block_index = 0;
	else
		block_index = 1;
end

reg block_index_I;
always@(*) begin
	if(addr_instr_soon[11:8] == tag_I[0])
		block_index_I = 0;
	else
		block_index_I = 1;
end
//####################################################
//               instr
//####################################################
always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		instr <= 0;
	else
		begin
			case(cs)
				READ_INSTR:	instr <= SRAM_I_out[15:0];
				OUTPUT:		instr <= SRAM_I_out[15:0];
			endcase
		end
end

always@(*) begin
	case(cs)
		READ_INSTR, OUTPUT:	offset = $signed (rs + $signed(SRAM_I_out[4:0])) * 2;
		default:			offset = $signed (rs + $signed(instr[4:0])) * 2 ;
	endcase
end
//wire [11:0] offset_dram = offset * 2;


always@(posedge clk or negedge rst_n) begin	
	if(!rst_n)
		output_from_M <= 0;
	else
		begin
			if(cs == OUTPUT_M)
				output_from_M <= 1;
			else if (cs == OUTPUT)
				output_from_M <= output_from_M;
			else 
				output_from_M <= 0;
		end
end
//####################################################
//               operation
//####################################################
assign	add_out 	= rs + rt;
assign 	sub_out 	= $signed(rs) - $signed(rt);
assign	cmp_out		= rs < rt;
assign 	tmp_mul_out = rs * rt;
assign 	mul_out 	= tmp_mul_out[15:0];
//####################################################
//               MEM
//####################################################
//INSTR SRAM
RA1SH SRAM_I(.Q(SRAM_I_out),
   .CLK(clk),
   .CEN(1'd0),
   .WEN(SRAM_I_WEN),
   .A(SRAM_I_addr),
   .D(SRAM_I_in),
   .OEN(1'd0));

//data
always@(*) begin
	case(cs)
		LOAD_I:	SRAM_I_in = rdata_m_inf[31:16];
		default:SRAM_I_in = 0;
	endcase
end

//address
always@(*) begin
	case(cs)
		READ_INSTR:	SRAM_I_addr = {block_index_I, addr_instr_soon[7:1]};
		LOAD_I:		SRAM_I_addr = {lru_I, cnt[6:0]};
		S_ADDR_pc:	SRAM_I_addr = {block_index_I, addr_instr[7:1]};
		OUTPUT:		SRAM_I_addr = output_from_M ? {block_index_I, addr_instr[7:1]} : {block_index_I, addr_instr_soon[7:1]};		
		default:	SRAM_I_addr = 8'h0;
		
		//READ_INSTR:	SRAM_I_addr = addr_instr_soon;
		//READ_INSTR:	SRAM_I_addr = {block_index_I, addr_instr[7:1]};
		//OUTPUT:		SRAM_I_addr = output_from_M ? addr_instr : addr_instr_soon;
		//OUTPUT_M:	SRAM_I_addr = addr_instr;
		//default:	SRAM_I_addr = {block_index_I, addr_instr[7:1]};
	endcase
end

//control
//WEN
always@(*) begin
	case(cs)
		LOAD_I:		SRAM_I_WEN = rvalid_m_inf[1] ? 1'b0 : 1'b1;
		default:	SRAM_I_WEN = 1'b1;//read
	endcase
end


//DATA SRAM
RA1SH SRAM_D(.Q(SRAM_D_out),
   .CLK(clk),
   .CEN(1'd0),
   .WEN(SRAM_D_WEN),
   .A(SRAM_D_addr),
   .D(SRAM_D_in),
   .OEN(1'd0));

//data
always@(*) begin
	case(cs)
		LOAD_D:		SRAM_D_in = rdata_m_inf[15:0];
		STORE:		SRAM_D_in = rt;
		default:	SRAM_D_in = 0;
	endcase
end

//address
always@(*) begin
	case(cs)
		LOAD_D:					SRAM_D_addr = {lru_D, cnt[6:0]};
		//S_ADDR_LOAD:			SRAM_D_addr = {block_index, 1'b0, offset[11:1]};//don't need to * 2
		S_ADDR_LOAD:			SRAM_D_addr = {block_index, offset[7:1]};//don't need to * 2
		//STORE:					SRAM_D_addr = {block_index, 1'b0, offset[11:1]};//don't need to * 2
		STORE:					SRAM_D_addr = {block_index, offset[7:1]};//don't need to * 2
		WB_S_ADDR_D:			SRAM_D_addr = {1'b0, first_mod[0]};
		WB:						SRAM_D_addr = {1'b0, first_mod_soon[0]};
		WB_S_ADDR_D_1:			SRAM_D_addr = {1'b1, first_mod[1]};
		WB_1:					SRAM_D_addr = {1'b1, first_mod_soon[1]};
		default:				SRAM_D_addr = 8'h0;
	endcase
end

//control
//WEN
always@(*) begin
	case(cs)
		LOAD_D:		SRAM_D_WEN = rvalid_m_inf[0] ? 1'b0 : 1'b1;
		STORE:		SRAM_D_WEN = 1'b0;
		default:	SRAM_D_WEN = 1'b1;//read
	endcase
end


//tmp
reg [15:0] IO_cnt;
always@(posedge clk or negedge rst_n) begin	if(!rst_n)
		IO_cnt <= 0;
	else
		IO_cnt <= !IO_stall ? IO_cnt + 'd1 : IO_cnt;
end

endmodule



















