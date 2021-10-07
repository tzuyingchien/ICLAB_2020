//============================================================================
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NCTU ED415
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 spring
//   Midterm Proejct            : AMBA (Cache & AXI-4)
//   Author                     : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : AMBA.v
//   Module Name : AMBA
//   Release version : V1.0 (Release Date: 2021-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//============================================================================

module AMBA(
				clk,	
			  rst_n,	
	
			  PADDR,
			 PRDATA,
			  PSELx, 
			PENABLE, 
			 PWRITE, 
			 PREADY,  
	

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
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32, DRAM_NUMBER=2, WRIT_NUMBER=1;
input			  clk,rst_n;



// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
	   therefore I declared output of AXI as wire in Poly_Ring
*/
   
// -----------------------------
// APB channel 
input   wire [ADDR_WIDTH-1:0] 	 	  PADDR;
output  reg [DATA_WIDTH-1:0]  	   	  PRDATA;
input   wire			 	  PSELx;
input   wire		         	  PENABLE;
input   wire 		         	  PWRITE;
output  reg 			 	  PREADY;
// -----------------------------


// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 4 -1:0]             awlen_m_inf;
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
output  wire [DRAM_NUMBER * 4 -1:0]            arlen_m_inf;
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


//====================================================
//               parameter
//====================================================
parameter		IDLE 			= 5'd0,
				G_ADDR 			= 5'd1,
				S_INSTR_ADDR	= 5'd3,
				G_INSTR_ADDR	= 5'd4,
				DATA_CACHE		= 5'd5,
				S_DATA_ADDR 	= 5'd6,
				G_DATA			= 5'd7,
				G_DRAM1_DATA 	= 5'd8,
				LOAD_CONV		= 5'd9,
				CONV			= 5'd10,
				MUL				= 5'd11,
				WAIT_WRITE		= 5'd12,
				LOAD_MUL		= 5'd13,
				WAIT_WRITE_CONV	= 5'd14,
				CAL				= 5'd18,
				OUTPUT 			= 5'd20;
//====================================================
//               reg & wire
//====================================================
reg	[4:0] 	cs;
reg	[31:0] 	addr_instr;
reg [5:0] 	cnt_input;
reg [5:0] 	cnt_input_r;
reg [31:0]  instr;
reg [5:0] 	instr_tag;
reg [63:0]	valid_d1;//the row is in cache or not
reg [63:0] 	valid_dr;

reg [31:0] 	dram1_addr;
reg [31:0]  dramr_addr;
reg 		d1_done, dr_done;
wire[5:0] 	d1_row, dr_row;
wire[3:0] 	d1_col, dr_col;
wire 		load_done;
reg [4:0] 	cur_row;
reg [4:0] 	cur_col;
reg [4:0]	cur_row_r;
reg [31:0]	ff_mul_1[15:0], ff_mul_2[15:0], ff_mul_3[15:0], ff_mul_4[15:0], ff_mul_5[15:0];
reg [31:0] 	ff_c1;//compensate cache1 faster 1 cycle
wire [6:0] write_row;
reg [31:0]	ff_conv_r[8:0];
reg [31:0] 	ff_tmp_conv[8:0];
reg 		ff_arready_0, ff_arready_1;
reg [1:0]	rst_arvalid;
reg 		rst_awvalid;
reg 		write_done;
//MEM
//DRAM1
wire[31:0] 	OUT_C1_0, OUT_C1_1, OUT_C1_2, OUT_C1_3, OUT_C1_4, OUT_C1_5, OUT_C1_6, OUT_C1_7, OUT_C1_8, OUT_C1_9, OUT_C1_10, OUT_C1_11, OUT_C1_12, OUT_C1_13, OUT_C1_14, OUT_C1_15;
reg [31:0] 	IN_C1_0, IN_C1_1, IN_C1_2, IN_C1_3, IN_C1_4, IN_C1_5, IN_C1_6, IN_C1_7, IN_C1_8, IN_C1_9, IN_C1_10, IN_C1_11, IN_C1_12, IN_C1_13, IN_C1_14, IN_C1_15;
reg [5:0]	ADDR_C1_0, ADDR_C1_1, ADDR_C1_2, ADDR_C1_3, ADDR_C1_4, ADDR_C1_5, ADDR_C1_6, ADDR_C1_7, ADDR_C1_8, ADDR_C1_9, ADDR_C1_10, ADDR_C1_11, ADDR_C1_12, ADDR_C1_13, ADDR_C1_14, ADDR_C1_15;
reg 		WEN_C1_0, WEN_C1_1, WEN_C1_2, WEN_C1_3, WEN_C1_4, WEN_C1_5, WEN_C1_6, WEN_C1_7, WEN_C1_8, WEN_C1_9, WEN_C1_10, WEN_C1_11, WEN_C1_12, WEN_C1_13, WEN_C1_14, WEN_C1_15;
//DRAM_read
wire[31:0] 	OUT_Cr_0, OUT_Cr_1, OUT_Cr_2, OUT_Cr_3, OUT_Cr_4, OUT_Cr_5, OUT_Cr_6, OUT_Cr_7, OUT_Cr_8, OUT_Cr_9, OUT_Cr_10, OUT_Cr_11, OUT_Cr_12, OUT_Cr_13, OUT_Cr_14, OUT_Cr_15;
reg [31:0] 	IN_Cr;
reg [5:0]	ADDR_Cr_0, ADDR_Cr_1, ADDR_Cr_2, ADDR_Cr_3, ADDR_Cr_4, ADDR_Cr_5, ADDR_Cr_6, ADDR_Cr_7, ADDR_Cr_8, ADDR_Cr_9, ADDR_Cr_10, ADDR_Cr_11, ADDR_Cr_12, ADDR_Cr_13, ADDR_Cr_14, ADDR_Cr_15;
reg 		WEN_Cr_0, WEN_Cr_1, WEN_Cr_2, WEN_Cr_3, WEN_Cr_4, WEN_Cr_5, WEN_Cr_6, WEN_Cr_7, WEN_Cr_8, WEN_Cr_9, WEN_Cr_10, WEN_Cr_11, WEN_Cr_12, WEN_Cr_13, WEN_Cr_14, WEN_Cr_15;
//MUL
reg [31:0] mul_in_0;
reg [31:0] mul_in_0_1 , add_in_0_0 , add_in_0_1 ;
reg [31:0] mul_in_1_1 , add_in_1_0 , add_in_1_1 ;
reg [31:0] mul_in_2_1 , add_in_2_0 , add_in_2_1 ;
reg [31:0] mul_in_3_1 , add_in_3_0 , add_in_3_1 ;
reg [31:0] mul_in_4_1 , add_in_4_0 , add_in_4_1 ;
reg [31:0] mul_in_5_1 , add_in_5_0 , add_in_5_1 ;
reg [31:0] mul_in_6_1 , add_in_6_0 , add_in_6_1 ;
reg [31:0] mul_in_7_1 , add_in_7_0 , add_in_7_1 ;
reg [31:0] mul_in_8_1 , add_in_8_0 , add_in_8_1 ;
reg [31:0] mul_in_9_1 , add_in_9_0 , add_in_9_1 ;
reg [31:0] mul_in_10_1, add_in_10_0, add_in_10_1;
reg [31:0] mul_in_11_1, add_in_11_0, add_in_11_1;
reg [31:0] mul_in_12_1, add_in_12_0, add_in_12_1;
reg [31:0] mul_in_13_1, add_in_13_0, add_in_13_1;
reg [31:0] mul_in_14_1, add_in_14_0, add_in_14_1;
reg [31:0] mul_in_15_1, add_in_15_0, add_in_15_1;

wire[31:0] mul_out_0  = mul_in_0 * mul_in_0_1 ;
wire[31:0] mul_out_1  = mul_in_0 * mul_in_1_1 ;
wire[31:0] mul_out_2  = mul_in_0 * mul_in_2_1 ;
wire[31:0] mul_out_3  = mul_in_0 * mul_in_3_1 ;
wire[31:0] mul_out_4  = mul_in_0 * mul_in_4_1 ;
wire[31:0] mul_out_5  = mul_in_0 * mul_in_5_1 ;
wire[31:0] mul_out_6  = mul_in_0 * mul_in_6_1 ;
wire[31:0] mul_out_7  = mul_in_0 * mul_in_7_1 ;
wire[31:0] mul_out_8  = mul_in_0 * mul_in_8_1 ;
wire[31:0] mul_out_9  = mul_in_0 * mul_in_9_1 ;
wire[31:0] mul_out_10 = mul_in_0 * mul_in_10_1;
wire[31:0] mul_out_11 = mul_in_0 * mul_in_11_1;
wire[31:0] mul_out_12 = mul_in_0 * mul_in_12_1;
wire[31:0] mul_out_13 = mul_in_0 * mul_in_13_1;
wire[31:0] mul_out_14 = mul_in_0 * mul_in_14_1;
wire[31:0] mul_out_15 = mul_in_0 * mul_in_15_1;
//=============================================
wire[31:0] add_out_0  = add_in_0_0  + add_in_0_1 ;
wire[31:0] add_out_1  = add_in_1_0  + add_in_1_1 ;
wire[31:0] add_out_2  = add_in_2_0  + add_in_2_1 ;
wire[31:0] add_out_3  = add_in_3_0  + add_in_3_1 ;
wire[31:0] add_out_4  = add_in_4_0  + add_in_4_1 ;
wire[31:0] add_out_5  = add_in_5_0  + add_in_5_1 ;
wire[31:0] add_out_6  = add_in_6_0  + add_in_6_1 ;
wire[31:0] add_out_7  = add_in_7_0  + add_in_7_1 ;
wire[31:0] add_out_8  = add_in_8_0  + add_in_8_1 ;
wire[31:0] add_out_9  = add_in_9_0  + add_in_9_1 ;
wire[31:0] add_out_10 = add_in_10_0 + add_in_10_1;
wire[31:0] add_out_11 = add_in_11_0 + add_in_11_1;
wire[31:0] add_out_12 = add_in_12_0 + add_in_12_1;
wire[31:0] add_out_13 = add_in_13_0 + add_in_13_1;
wire[31:0] add_out_14 = add_in_14_0 + add_in_14_1;
wire[31:0] add_out_15 = add_in_15_0 + add_in_15_1;

always@(*) begin
	case(cs)
		//MUL:	mul_in_0 <= ff_mul_3[(cur_col + 'd15) % 16];
		MUL:	mul_in_0 <= ff_mul_3[(cur_row_r + 'd15) % 16];
		CONV:	mul_in_0 <= ff_mul_3[(cur_col + 'd15) % 16];
		default:mul_in_0 <= 0;
	endcase
end
always@(*) begin
	case(cs)
		MUL:begin
/* 				mul_in_0_1  <= OUT_Cr_0 ;
			    mul_in_1_1  <= OUT_Cr_1 ;
			    mul_in_2_1  <= OUT_Cr_2 ;
			    mul_in_3_1  <= OUT_Cr_3 ;
			    mul_in_4_1  <= OUT_Cr_4 ;
			    mul_in_5_1  <= OUT_Cr_5 ;
			    mul_in_6_1  <= OUT_Cr_6 ;
			    mul_in_7_1  <= OUT_Cr_7 ;
			    mul_in_8_1  <= OUT_Cr_8 ;
			    mul_in_9_1  <= OUT_Cr_9 ;
			    mul_in_10_1 <= OUT_Cr_10;
			    mul_in_11_1 <= OUT_Cr_11;
			    mul_in_12_1 <= OUT_Cr_12;
			    mul_in_13_1 <= OUT_Cr_13;
			    mul_in_14_1 <= OUT_Cr_14;
			    mul_in_15_1 <= OUT_Cr_15;			
 */			
								case(dr_col)
											'd0:	begin
														mul_in_0_1  <= OUT_Cr_0;
														mul_in_1_1  <= OUT_Cr_1;
														mul_in_2_1  <= OUT_Cr_2;
														mul_in_3_1  <= OUT_Cr_3;
														mul_in_4_1  <= OUT_Cr_4;
														mul_in_5_1  <= OUT_Cr_5;
														mul_in_6_1  <= OUT_Cr_6;
														mul_in_7_1  <= OUT_Cr_7;
														mul_in_8_1  <= OUT_Cr_8;
														mul_in_9_1  <= OUT_Cr_9;
														mul_in_10_1 <= OUT_Cr_10;
														mul_in_11_1 <= OUT_Cr_11;
														mul_in_12_1 <= OUT_Cr_12;
														mul_in_13_1 <= OUT_Cr_13;
														mul_in_14_1 <= OUT_Cr_14;
														mul_in_15_1 <= OUT_Cr_15;
													end
											'd1:	begin
														mul_in_0_1  <= OUT_Cr_1 ;
														mul_in_1_1  <= OUT_Cr_2 ;
														mul_in_2_1  <= OUT_Cr_3 ;
														mul_in_3_1  <= OUT_Cr_4 ;
														mul_in_4_1  <= OUT_Cr_5 ;
														mul_in_5_1  <= OUT_Cr_6 ;
														mul_in_6_1  <= OUT_Cr_7 ;
														mul_in_7_1  <= OUT_Cr_8 ;
														mul_in_8_1  <= OUT_Cr_9 ;
														mul_in_9_1  <= OUT_Cr_10;
														mul_in_10_1 <= OUT_Cr_11;
														mul_in_11_1 <= OUT_Cr_12;
														mul_in_12_1 <= OUT_Cr_13;
														mul_in_13_1 <= OUT_Cr_14;
														mul_in_14_1 <= OUT_Cr_15;
														mul_in_15_1 <= OUT_Cr_0 ;
													end
											'd2:	begin
														mul_in_0_1  <= OUT_Cr_2 ;
														mul_in_1_1  <= OUT_Cr_3 ;
														mul_in_2_1  <= OUT_Cr_4 ;
														mul_in_3_1  <= OUT_Cr_5 ;
														mul_in_4_1  <= OUT_Cr_6 ;
														mul_in_5_1  <= OUT_Cr_7 ;
														mul_in_6_1  <= OUT_Cr_8 ;
														mul_in_7_1  <= OUT_Cr_9 ;
														mul_in_8_1  <= OUT_Cr_10;
														mul_in_9_1  <= OUT_Cr_11;
														mul_in_10_1 <= OUT_Cr_12;
														mul_in_11_1 <= OUT_Cr_13;
														mul_in_12_1 <= OUT_Cr_14;
														mul_in_13_1 <= OUT_Cr_15;
														mul_in_14_1 <= OUT_Cr_0 ;
														mul_in_15_1 <= OUT_Cr_1 ;
													end
											'd3:	begin
														mul_in_0_1  <= OUT_Cr_3 ;
														mul_in_1_1  <= OUT_Cr_4 ;
														mul_in_2_1  <= OUT_Cr_5 ;
														mul_in_3_1  <= OUT_Cr_6 ;
														mul_in_4_1  <= OUT_Cr_7 ;
														mul_in_5_1  <= OUT_Cr_8 ;
														mul_in_6_1  <= OUT_Cr_9 ;
														mul_in_7_1  <= OUT_Cr_10;
														mul_in_8_1  <= OUT_Cr_11;
														mul_in_9_1  <= OUT_Cr_12;
														mul_in_10_1 <= OUT_Cr_13;
														mul_in_11_1 <= OUT_Cr_14;
														mul_in_12_1 <= OUT_Cr_15;
														mul_in_13_1 <= OUT_Cr_0 ;
														mul_in_14_1 <= OUT_Cr_1 ;
														mul_in_15_1 <= OUT_Cr_2 ;
													end
											'd4:	begin
														mul_in_0_1  <= OUT_Cr_4 ;
														mul_in_1_1  <= OUT_Cr_5 ;
														mul_in_2_1  <= OUT_Cr_6 ;
														mul_in_3_1  <= OUT_Cr_7 ;
														mul_in_4_1  <= OUT_Cr_8 ;
														mul_in_5_1  <= OUT_Cr_9 ;
														mul_in_6_1  <= OUT_Cr_10;
														mul_in_7_1  <= OUT_Cr_11;
														mul_in_8_1  <= OUT_Cr_12;
														mul_in_9_1  <= OUT_Cr_13;
														mul_in_10_1 <= OUT_Cr_14;
														mul_in_11_1 <= OUT_Cr_15;
														mul_in_12_1 <= OUT_Cr_0 ;
														mul_in_13_1 <= OUT_Cr_1 ;
														mul_in_14_1 <= OUT_Cr_2 ;
														mul_in_15_1 <= OUT_Cr_3 ;
													end
											'd5:	begin
														mul_in_0_1  <= OUT_Cr_5 ;
														mul_in_1_1  <= OUT_Cr_6 ;
														mul_in_2_1  <= OUT_Cr_7 ;
														mul_in_3_1  <= OUT_Cr_8 ;
														mul_in_4_1  <= OUT_Cr_9 ;
														mul_in_5_1  <= OUT_Cr_10;
														mul_in_6_1  <= OUT_Cr_11;
														mul_in_7_1  <= OUT_Cr_12;
														mul_in_8_1  <= OUT_Cr_13;
														mul_in_9_1  <= OUT_Cr_14;
														mul_in_10_1 <= OUT_Cr_15;
														mul_in_11_1 <= OUT_Cr_0 ;
														mul_in_12_1 <= OUT_Cr_1 ;
														mul_in_13_1 <= OUT_Cr_2 ;
														mul_in_14_1 <= OUT_Cr_3 ;
														mul_in_15_1 <= OUT_Cr_4 ;
													end
											'd6:	begin
														mul_in_0_1  <= OUT_Cr_6 ;
														mul_in_1_1  <= OUT_Cr_7 ;
														mul_in_2_1  <= OUT_Cr_8 ;
														mul_in_3_1  <= OUT_Cr_9 ;
														mul_in_4_1  <= OUT_Cr_10;
														mul_in_5_1  <= OUT_Cr_11;
														mul_in_6_1  <= OUT_Cr_12;
														mul_in_7_1  <= OUT_Cr_13;
														mul_in_8_1  <= OUT_Cr_14;
														mul_in_9_1  <= OUT_Cr_15;
														mul_in_10_1 <= OUT_Cr_0 ;
														mul_in_11_1 <= OUT_Cr_1 ;
														mul_in_12_1 <= OUT_Cr_2 ;
														mul_in_13_1 <= OUT_Cr_3 ;
														mul_in_14_1 <= OUT_Cr_4 ;
														mul_in_15_1 <= OUT_Cr_5 ;
													end
											'd7:	begin
														mul_in_0_1  <= OUT_Cr_7 ;
														mul_in_1_1  <= OUT_Cr_8 ;
														mul_in_2_1  <= OUT_Cr_9 ;
														mul_in_3_1  <= OUT_Cr_10;
														mul_in_4_1  <= OUT_Cr_11;
														mul_in_5_1  <= OUT_Cr_12;
														mul_in_6_1  <= OUT_Cr_13;
														mul_in_7_1  <= OUT_Cr_14;
														mul_in_8_1  <= OUT_Cr_15;
														mul_in_9_1  <= OUT_Cr_0 ;
														mul_in_10_1 <= OUT_Cr_1 ;
														mul_in_11_1 <= OUT_Cr_2 ;
														mul_in_12_1 <= OUT_Cr_3 ;
														mul_in_13_1 <= OUT_Cr_4 ;
														mul_in_14_1 <= OUT_Cr_5 ;
														mul_in_15_1 <= OUT_Cr_6 ;
													end
											'd8:	begin
														mul_in_0_1  <= OUT_Cr_8 ;
														mul_in_1_1  <= OUT_Cr_9 ;
														mul_in_2_1  <= OUT_Cr_10;
														mul_in_3_1  <= OUT_Cr_11;
														mul_in_4_1  <= OUT_Cr_12;
														mul_in_5_1  <= OUT_Cr_13;
														mul_in_6_1  <= OUT_Cr_14;
														mul_in_7_1  <= OUT_Cr_15;
														mul_in_8_1  <= OUT_Cr_0 ;
														mul_in_9_1  <= OUT_Cr_1 ;
														mul_in_10_1 <= OUT_Cr_2 ;
														mul_in_11_1 <= OUT_Cr_3 ;
														mul_in_12_1 <= OUT_Cr_4 ;
														mul_in_13_1 <= OUT_Cr_5 ;
														mul_in_14_1 <= OUT_Cr_6 ;
														mul_in_15_1 <= OUT_Cr_7 ;
													end
											'd9:	begin
														mul_in_0_1  <= OUT_Cr_9 ;
														mul_in_1_1  <= OUT_Cr_10;
														mul_in_2_1  <= OUT_Cr_11;
														mul_in_3_1  <= OUT_Cr_12;
														mul_in_4_1  <= OUT_Cr_13;
														mul_in_5_1  <= OUT_Cr_14;
														mul_in_6_1  <= OUT_Cr_15;
														mul_in_7_1  <= OUT_Cr_0 ;
														mul_in_8_1  <= OUT_Cr_1 ;
														mul_in_9_1  <= OUT_Cr_2 ;
														mul_in_10_1 <= OUT_Cr_3 ;
														mul_in_11_1 <= OUT_Cr_4 ;
														mul_in_12_1 <= OUT_Cr_5 ;
														mul_in_13_1 <= OUT_Cr_6 ;
														mul_in_14_1 <= OUT_Cr_7 ;
														mul_in_15_1 <= OUT_Cr_8 ; 
													end
											'd10:	begin
														mul_in_0_1  <= OUT_Cr_10;
														mul_in_1_1  <= OUT_Cr_11;
														mul_in_2_1  <= OUT_Cr_12;
														mul_in_3_1  <= OUT_Cr_13;
														mul_in_4_1  <= OUT_Cr_14;
														mul_in_5_1  <= OUT_Cr_15;
														mul_in_6_1  <= OUT_Cr_0 ;
														mul_in_7_1  <= OUT_Cr_1 ;
														mul_in_8_1  <= OUT_Cr_2 ;
														mul_in_9_1  <= OUT_Cr_3 ;
														mul_in_10_1 <= OUT_Cr_4 ;
														mul_in_11_1 <= OUT_Cr_5 ;
														mul_in_12_1 <= OUT_Cr_6 ;
														mul_in_13_1 <= OUT_Cr_7 ;
														mul_in_14_1 <= OUT_Cr_8 ;
														mul_in_15_1 <= OUT_Cr_9 ; 
													end
											'd11:	begin
														mul_in_0_1  <= OUT_Cr_11;
														mul_in_1_1  <= OUT_Cr_12;
														mul_in_2_1  <= OUT_Cr_13;
														mul_in_3_1  <= OUT_Cr_14;
														mul_in_4_1  <= OUT_Cr_15;
														mul_in_5_1  <= OUT_Cr_0 ;
														mul_in_6_1  <= OUT_Cr_1 ;
														mul_in_7_1  <= OUT_Cr_2 ;
														mul_in_8_1  <= OUT_Cr_3 ;
														mul_in_9_1  <= OUT_Cr_4 ;
														mul_in_10_1 <= OUT_Cr_5 ;
														mul_in_11_1 <= OUT_Cr_6 ;
														mul_in_12_1 <= OUT_Cr_7 ;
														mul_in_13_1 <= OUT_Cr_8 ;
														mul_in_14_1 <= OUT_Cr_9 ;
														mul_in_15_1 <= OUT_Cr_10; 
													end
											'd12:	begin
														mul_in_0_1  <= OUT_Cr_12;
														mul_in_1_1  <= OUT_Cr_13;
														mul_in_2_1  <= OUT_Cr_14;
														mul_in_3_1  <= OUT_Cr_15;
														mul_in_4_1  <= OUT_Cr_0 ;
														mul_in_5_1  <= OUT_Cr_1 ;
														mul_in_6_1  <= OUT_Cr_2 ;
														mul_in_7_1  <= OUT_Cr_3 ;
														mul_in_8_1  <= OUT_Cr_4 ;
														mul_in_9_1  <= OUT_Cr_5 ;
														mul_in_10_1 <= OUT_Cr_6 ;
														mul_in_11_1 <= OUT_Cr_7 ;
														mul_in_12_1 <= OUT_Cr_8 ;
														mul_in_13_1 <= OUT_Cr_9 ;
														mul_in_14_1 <= OUT_Cr_10;
														mul_in_15_1 <= OUT_Cr_11; 
													end
											'd13:	begin
														mul_in_0_1  <= OUT_Cr_13;
														mul_in_1_1  <= OUT_Cr_14;
														mul_in_2_1  <= OUT_Cr_15;
														mul_in_3_1  <= OUT_Cr_0 ;
														mul_in_4_1  <= OUT_Cr_1 ;
														mul_in_5_1  <= OUT_Cr_2 ;
														mul_in_6_1  <= OUT_Cr_3 ;
														mul_in_7_1  <= OUT_Cr_4 ;
														mul_in_8_1  <= OUT_Cr_5 ;
														mul_in_9_1  <= OUT_Cr_6 ;
														mul_in_10_1 <= OUT_Cr_7 ;
														mul_in_11_1 <= OUT_Cr_8 ;
														mul_in_12_1 <= OUT_Cr_9 ;
														mul_in_13_1 <= OUT_Cr_10;
														mul_in_14_1 <= OUT_Cr_11;
														mul_in_15_1 <= OUT_Cr_12; 
													end
											'd14:	begin
														mul_in_0_1  <= OUT_Cr_14;
														mul_in_1_1  <= OUT_Cr_15;
														mul_in_2_1  <= OUT_Cr_0 ;
														mul_in_3_1  <= OUT_Cr_1 ;
														mul_in_4_1  <= OUT_Cr_2 ;
														mul_in_5_1  <= OUT_Cr_3 ;
														mul_in_6_1  <= OUT_Cr_4 ;
														mul_in_7_1  <= OUT_Cr_5 ;
														mul_in_8_1  <= OUT_Cr_6 ;
														mul_in_9_1  <= OUT_Cr_7 ;
														mul_in_10_1 <= OUT_Cr_8 ;
														mul_in_11_1 <= OUT_Cr_9 ;
														mul_in_12_1 <= OUT_Cr_10;
														mul_in_13_1 <= OUT_Cr_11;
														mul_in_14_1 <= OUT_Cr_12;
														mul_in_15_1 <= OUT_Cr_13; 
													end
											'd15:	begin
														mul_in_0_1  <= OUT_Cr_15;
														mul_in_1_1  <= OUT_Cr_0 ;
														mul_in_2_1  <= OUT_Cr_1 ;
														mul_in_3_1  <= OUT_Cr_2 ;
														mul_in_4_1  <= OUT_Cr_3 ;
														mul_in_5_1  <= OUT_Cr_4 ;
														mul_in_6_1  <= OUT_Cr_5 ;
														mul_in_7_1  <= OUT_Cr_6 ;
														mul_in_8_1  <= OUT_Cr_7 ;
														mul_in_9_1  <= OUT_Cr_8 ;
														mul_in_10_1 <= OUT_Cr_9 ;
														mul_in_11_1 <= OUT_Cr_10;
														mul_in_12_1 <= OUT_Cr_11;
														mul_in_13_1 <= OUT_Cr_12;
														mul_in_14_1 <= OUT_Cr_13;
														mul_in_15_1 <= OUT_Cr_14; 
													end
											default:begin
														mul_in_0_1  <= 0;
											            mul_in_1_1  <= 0;
											            mul_in_2_1  <= 0;
											            mul_in_3_1  <= 0;
											            mul_in_4_1  <= 0;
											            mul_in_5_1  <= 0;
											            mul_in_6_1  <= 0;
											            mul_in_7_1  <= 0;
											            mul_in_8_1  <= 0;
											            mul_in_9_1  <= 0;
											            mul_in_10_1 <= 0;
											            mul_in_11_1 <= 0;
											            mul_in_12_1 <= 0;
											            mul_in_13_1 <= 0;
											            mul_in_14_1 <= 0;
											            mul_in_15_1 <= 0;
													end
											
							endcase							
			end
		CONV:
			begin
				mul_in_0_1  <= cur_row == 'd1 ? 0 : ff_conv_r[8];
				mul_in_1_1  <= cur_row == 'd1 ? 0 : ff_conv_r[7];
				mul_in_2_1  <= cur_row == 'd1 ? 0 : ff_conv_r[6];
				mul_in_3_1  <= ff_conv_r[5];
				mul_in_4_1  <= ff_conv_r[4];
				mul_in_5_1  <= ff_conv_r[3];
				mul_in_6_1  <= cur_row == 'd16 ? 0 : ff_conv_r[2];
				mul_in_7_1  <= cur_row == 'd16 ? 0 : ff_conv_r[1];
				mul_in_8_1  <= cur_row == 'd16 ? 0 : ff_conv_r[0];
				mul_in_9_1  <= 0;
				mul_in_10_1 <= 0;
				mul_in_11_1 <= 0;
				mul_in_12_1 <= 0;
				mul_in_13_1 <= 0;
				mul_in_14_1 <= 0;
				mul_in_15_1 <= 0;
			end
		default:
			begin
				mul_in_0_1  <= 0;
				mul_in_1_1  <= 0;
				mul_in_2_1  <= 0;
				mul_in_3_1  <= 0;
				mul_in_4_1  <= 0;
				mul_in_5_1  <= 0;
				mul_in_6_1  <= 0;
				mul_in_7_1  <= 0;
				mul_in_8_1  <= 0;
				mul_in_9_1  <= 0;
				mul_in_10_1 <= 0;
				mul_in_11_1 <= 0;
				mul_in_12_1 <= 0;
				mul_in_13_1 <= 0;
				mul_in_14_1 <= 0;
				mul_in_15_1 <= 0;
			end
	endcase
end
//ADD
always@(*) begin
	case(cs)
		MUL:begin
				add_in_0_0  = mul_out_0 ;
				add_in_1_0  = mul_out_1 ;
				add_in_2_0  = mul_out_2 ;
				add_in_3_0  = mul_out_3 ;
				add_in_4_0  = mul_out_4 ;
				add_in_5_0  = mul_out_5 ;
				add_in_6_0  = mul_out_6 ;
				add_in_7_0  = mul_out_7 ;
				add_in_8_0  = mul_out_8 ;
				add_in_9_0  = mul_out_9 ;
				add_in_10_0 = mul_out_10;
				add_in_11_0 = mul_out_11;
				add_in_12_0 = mul_out_12;
				add_in_13_0 = mul_out_13;
				add_in_14_0 = mul_out_14;
				add_in_15_0 = mul_out_15;
				//-------------------------
				add_in_0_1  = ff_mul_2[0] ;
				add_in_1_1  = ff_mul_2[1] ;
				add_in_2_1  = ff_mul_2[2] ;
				add_in_3_1  = ff_mul_2[3] ;
				add_in_4_1  = ff_mul_2[4] ;
				add_in_5_1  = ff_mul_2[5] ;
				add_in_6_1  = ff_mul_2[6] ;
				add_in_7_1  = ff_mul_2[7] ;
				add_in_8_1  = ff_mul_2[8] ;
				add_in_9_1  = ff_mul_2[9] ;
				add_in_10_1 = ff_mul_2[10];
				add_in_11_1 = ff_mul_2[11];
				add_in_12_1 = ff_mul_2[12];
				add_in_13_1 = ff_mul_2[13];
				add_in_14_1 = ff_mul_2[14];
				add_in_15_1 = ff_mul_2[15];
			end
		CONV:
			begin
				case(cur_col)
					'd0:	begin
					        	add_in_0_0	= 0;
					        	add_in_1_0	= 0;
					        	add_in_2_0	= 0;
					        	add_in_3_0	= 0;
					        	add_in_4_0	= 0;
					        	add_in_5_0	= 0;
					        	add_in_6_0	= 0;
					        	add_in_7_0	= 0;
					        	add_in_8_0	= 0;
								add_in_9_0  = 0;
								add_in_10_0 = 0;
								add_in_11_0 = 0;
								add_in_12_0 = 0;
								add_in_13_0 = 0;
								add_in_14_0 = 0;
								add_in_15_0 = 0;
							end			
					'd1:	begin//col_0
								add_in_0_0	= 0;
								add_in_1_0	= ff_mul_2[0];
								add_in_2_0	= ff_mul_2[1];
								add_in_3_0  = 0 ;
								add_in_4_0  = ff_mul_4[0];
								add_in_5_0  = ff_mul_4[1];
								add_in_6_0  = 0 ;
								add_in_7_0  = ff_mul_5[0];
								add_in_8_0  = ff_mul_5[1];
								add_in_9_0  = 0;
								add_in_10_0 = 0;
								add_in_11_0 = 0;
								add_in_12_0 = 0;
								add_in_13_0 = 0;
								add_in_14_0 = 0;
								add_in_15_0 = 0;
							end
					'd16:	begin//col_15
								add_in_0_0	= ff_mul_2[14];
								add_in_1_0	= ff_mul_2[15];
								add_in_2_0	= 0;
								add_in_3_0	= ff_mul_4[14];
								add_in_4_0	= ff_mul_4[15];
								add_in_5_0	= 0;
								add_in_6_0	= ff_mul_5[14];
								add_in_7_0	= ff_mul_5[15];
								add_in_8_0	= 0;
								add_in_9_0  = 0;
								add_in_10_0 = 0;
								add_in_11_0 = 0;
								add_in_12_0 = 0;
								add_in_13_0 = 0;
								add_in_14_0 = 0;
								add_in_15_0 = 0;
							end
					default:begin
								add_in_0_0	= ff_mul_2[cur_col-2];
								add_in_1_0	= ff_mul_2[cur_col-1];
								add_in_2_0	= ff_mul_2[cur_col];
								add_in_3_0	= ff_mul_4[cur_col-2];
								add_in_4_0	= ff_mul_4[cur_col-1];
								add_in_5_0	= ff_mul_4[cur_col];
								add_in_6_0	= ff_mul_5[cur_col-2];
								add_in_7_0	= ff_mul_5[cur_col-1];
								add_in_8_0	= ff_mul_5[cur_col];
								add_in_9_0  = 0;
								add_in_10_0 = 0;
								add_in_11_0 = 0;
								add_in_12_0 = 0;
								add_in_13_0 = 0;
								add_in_14_0 = 0;
								add_in_15_0 = 0;
							end
				endcase
				//-------------------------------------------------
				add_in_0_1 	= mul_out_0;
				add_in_1_1 	= mul_out_1;
				add_in_2_1 	= mul_out_2;	
				add_in_3_1  = mul_out_3;
				add_in_4_1  = mul_out_4;
				add_in_5_1  = mul_out_5;
				add_in_6_1  = mul_out_6;
				add_in_7_1  = mul_out_7;
				add_in_8_1  = mul_out_8;
				add_in_9_1  = 0;
				add_in_10_1 = 0;
				add_in_11_1 = 0;
				add_in_12_1 = 0;
				add_in_13_1 = 0;
				add_in_14_1 = 0;
				add_in_15_1 = 0;
			end
		default:
			begin
				add_in_0_0  = 0;
				add_in_1_0  = 0;
				add_in_2_0  = 0;
				add_in_3_0  = 0;
				add_in_4_0  = 0;
				add_in_5_0  = 0;
				add_in_6_0  = 0;
				add_in_7_0  = 0;
				add_in_8_0  = 0;
				add_in_9_0  = 0;
				add_in_10_0 = 0;
				add_in_11_0 = 0;
				add_in_12_0 = 0;
				add_in_13_0 = 0;
				add_in_14_0 = 0;
				add_in_15_0 = 0;
				//-------------------------
				add_in_0_1  = 0;
				add_in_1_1  = 0;
				add_in_2_1  = 0;
				add_in_3_1  = 0;
				add_in_4_1  = 0;
				add_in_5_1  = 0;
				add_in_6_1  = 0;
				add_in_7_1  = 0;
				add_in_8_1  = 0;
				add_in_9_1  = 0;
				add_in_10_1 = 0;
				add_in_11_1 = 0;
				add_in_12_1 = 0;
				add_in_13_1 = 0;
				add_in_14_1 = 0;
				add_in_15_1 = 0;
			end
	endcase
end
//====================================================
//               FSM
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cs <= 'd0;
	end
	else begin
		case(cs)
			IDLE:				cs <= 	PSELx ? G_ADDR : cs;
			G_ADDR:				cs <= 	S_INSTR_ADDR;
			S_INSTR_ADDR:		cs <= 	arready_m_inf[1] ? 		G_INSTR_ADDR 	: cs;
			G_INSTR_ADDR:		cs <= 	rlast_m_inf ? 			S_DATA_ADDR		: cs;
			S_DATA_ADDR:		cs <= 	araddr_m_inf == 64'hffff_ffff_ffff_ffff ? (instr[1:0] == 2'b11 ? LOAD_CONV : LOAD_MUL) :
										(arready_m_inf == 2'b11 //ready at same time
										|| (arready_m_inf == 2'b01 && ff_arready_0) //0 ready first
										|| (arready_m_inf == 2'b10 && ff_arready_1) //1 ready first
										|| (arready_m_inf[0] && araddr_m_inf[63:32] == 32'hffff_ffff) //1 finished
										|| (arready_m_inf[1] && araddr_m_inf[31:0 ] == 32'hffff_ffff)) ? G_DATA : cs; // 0 finished
 			G_DATA:				cs <= 	(load_done 
										|| (rlast_m_inf[0] == 1'b1 && dramr_addr == 32'hffff_ffff) 
										|| (rlast_m_inf[1] == 1'b1 && dram1_addr == 32'hffff_ffff))	? S_DATA_ADDR : cs;
			LOAD_MUL:			cs <= 	MUL;
			LOAD_CONV:			cs <= 	CONV;//if not finished in 1 cycle, cur_row need to change!
			MUL:				cs <= 	(cur_row_r == 'd17 && write_done) || (cur_row_r == 'd16 && cur_row == 'd1)	?	
										(write_row == d1_row + 'd16 ? OUTPUT : WAIT_WRITE) : cs;
			//cur_row_r == 'd15 ? 	WAIT_WRITE : cs;
			WAIT_WRITE:			cs <= 	awready_m_inf ? 		LOAD_MUL : cs;//first row don't need to wait //unfinished
			CONV:				cs <= 	(cur_row < 'd3 && cur_col == 'd17) || (cur_col == 'd17 && write_done)	? 
										(write_row == d1_row + 'd16 ? OUTPUT : WAIT_WRITE_CONV): cs;
			//cur_col =='d15 ? WAIT_WRITE_CONV : cs;//unfinished
			WAIT_WRITE_CONV:	cs <= 	(cur_row < 'd2 || awready_m_inf )? LOAD_CONV : cs;
			OUTPUT:				cs <= 	IDLE;							
		endcase
	end
end

//====================================================
//               G_ADDR
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_instr <= 'd0;
	end
	else begin
		case(cs)
			G_ADDR:		addr_instr <= PADDR;
			default:	addr_instr <= addr_instr;
		endcase
	end
end

//====================================================
//              Read address channel : S_ADDR*
//====================================================
//master==========
assign arid_m_inf 			= 	0;//???????????
assign arsize_m_inf 	= 	cs == 6'b010010;//the specified type in this lab
assign arburst_m_inf	= 	4'b0101;//the specified type in thiss lab

//DRAM1
assign araddr_m_inf	[31:0]	= 	cs == S_DATA_ADDR 	? 	dram1_addr 	: 0;
assign arlen_m_inf	[3:0]	= 	cs == S_DATA_ADDR	? 	4'b1111 	: 0;
assign arvalid_m_inf[0] 	= 	rst_arvalid[0] 		?	0 :
								cs == S_DATA_ADDR && dram1_addr != 32'hffff_ffff  ? 1'b1 : 1'b0;

//DRAM_read
assign araddr_m_inf	[63:32] = 	cs == S_INSTR_ADDR	? 	addr_instr : 
								cs == S_DATA_ADDR	? 	dramr_addr : 0;
								//cs == S_DATA_ADDR 	? 	{16'd0, instr[31:18], 2'b00} : 0;
assign arlen_m_inf 	[7:4] 	= 	cs == S_INSTR_ADDR	?	4'd0 : 
								cs == S_DATA_ADDR	? 	4'b1111 : 0;
assign arvalid_m_inf[1] 	= 	rst_arvalid[1] 		? 	0 :
								cs == S_INSTR_ADDR 	? 	1'b1 : 
								cs == S_DATA_ADDR && dramr_addr != 32'hffff_ffff  ? 1'b1 : 1'b0;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	rst_arvalid <= 0;
	else 		rst_arvalid <= arready_m_inf ? 1'b1 : 1'b0;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	ff_arready_0 <= 0;
	else begin
		case(cs)
			S_DATA_ADDR:	ff_arready_0 <= arready_m_inf[0]	? 1 : ff_arready_0;
			G_DATA:			ff_arready_0 <= 0;
			default:		ff_arready_0 <= 0;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	ff_arready_1 <= 0;
	else begin
		case(cs)
			S_DATA_ADDR:	ff_arready_1 <= arready_m_inf[1]	? 1 : ff_arready_1;
			G_DATA:			ff_arready_1 <= 0;
			default:		ff_arready_1 <= 0;
		endcase
	end
end
//====================================================
//		      	dram1_addr
//====================================================
reg [31:0] ff_dram1_addr;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	ff_dram1_addr <= 0;
	else 		ff_dram1_addr <= dram1_addr;
end
always@(*) begin
	case(cs)
		S_DATA_ADDR:begin
						if		(!valid_d1[instr[27:22]]) 						dram1_addr <= {16'd0, instr[31:22]		 , 6'd0};//1000...
						else if	(!valid_d1[instr[27:22] + 'd1])					dram1_addr <= {16'd0, instr[31:22] + 'd1 , 6'd0};//1064
						else if	(!valid_d1[instr[27:22] + 'd2])					dram1_addr <= {16'd0, instr[31:22] + 'd2 , 6'd0};//1128
						else if	(!valid_d1[instr[27:22] + 'd3])					dram1_addr <= {16'd0, instr[31:22] + 'd3 , 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd4])					dram1_addr <= {16'd0, instr[31:22] + 'd4 , 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd5])					dram1_addr <= {16'd0, instr[31:22] + 'd5 , 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd6])					dram1_addr <= {16'd0, instr[31:22] + 'd6 , 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd7])					dram1_addr <= {16'd0, instr[31:22] + 'd7 , 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd8])					dram1_addr <= {16'd0, instr[31:22] + 'd8 , 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd9])					dram1_addr <= {16'd0, instr[31:22] + 'd9 , 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd10])				dram1_addr <= {16'd0, instr[31:22] + 'd10, 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd11])				dram1_addr <= {16'd0, instr[31:22] + 'd11, 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd12])				dram1_addr <= {16'd0, instr[31:22] + 'd12, 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd13])				dram1_addr <= {16'd0, instr[31:22] + 'd13, 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd14])				dram1_addr <= {16'd0, instr[31:22] + 'd14, 6'd0};
						else if	(!valid_d1[instr[27:22] + 'd15])				dram1_addr <= {16'd0, instr[31:22] + 'd15, 6'd0};
						else if (!valid_d1[instr[27:22] + 'd16] && d1_col !='d0)dram1_addr <= {16'd0, instr[31:22] + 'd16, 6'd0}; // need to load 17 rows
						else 													dram1_addr <= {32'hffff_ffff};//impossible addr (To identify loading is finished)						
					end
		default:		dram1_addr <= ff_dram1_addr;
	endcase
end
//====================================================
//		      	dram_read_addr
//====================================================
reg [31:0] ff_dramr_addr;
always@(negedge rst_n or posedge clk ) begin
	if(!rst_n) 	ff_dramr_addr <= 0;
	else 		ff_dramr_addr <= dramr_addr;
end
wire [6:0] instr_offset_0  = instr[11:6] 		;	
wire [6:0] instr_offset_1  = instr[11:6] + 'd1	;
wire [6:0] instr_offset_2  = instr[11:6] + 'd2	;
wire [6:0] instr_offset_3  = instr[11:6] + 'd3	;
wire [6:0] instr_offset_4  = instr[11:6] + 'd4	;
wire [6:0] instr_offset_5  = instr[11:6] + 'd5	;
wire [6:0] instr_offset_6  = instr[11:6] + 'd6	;
wire [6:0] instr_offset_7  = instr[11:6] + 'd7	;
wire [6:0] instr_offset_8  = instr[11:6] + 'd8	;
wire [6:0] instr_offset_9  = instr[11:6] + 'd9	;
wire [6:0] instr_offset_10 = instr[11:6] + 'd10 ;
wire [6:0] instr_offset_11 = instr[11:6] + 'd11 ;
wire [6:0] instr_offset_12 = instr[11:6] + 'd12 ;
wire [6:0] instr_offset_13 = instr[11:6] + 'd13 ;
wire [6:0] instr_offset_14 = instr[11:6] + 'd14 ;
wire [6:0] instr_offset_15 = instr[11:6] + 'd15 ;
wire [6:0] instr_offset_16 = instr[11:6] + 'd16 ;
always@(*) begin        
	case(cs)
/* 		S_DATA_ADDR:begin
						if		(!valid_dr[instr[11:6]]) 						dramr_addr <= {16'd0, instr[15:6]		, 6'd0};//1000...
						else if	(!valid_dr[instr[11:6] + 'd1])					dramr_addr <= {16'd0, instr[15:6] + 'd1 , 6'd0};//1064
						else if	(!valid_dr[instr[11:6] + 'd2])					dramr_addr <= {16'd0, instr[15:6] + 'd2 , 6'd0};//1128
						else if	(!valid_dr[instr[11:6] + 'd3])					dramr_addr <= {16'd0, instr[15:6] + 'd3 , 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd4])					dramr_addr <= {16'd0, instr[15:6] + 'd4 , 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd5])					dramr_addr <= {16'd0, instr[15:6] + 'd5 , 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd6])					dramr_addr <= {16'd0, instr[15:6] + 'd6 , 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd7])					dramr_addr <= {16'd0, instr[15:6] + 'd7 , 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd8])					dramr_addr <= {16'd0, instr[15:6] + 'd8 , 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd9])					dramr_addr <= {16'd0, instr[15:6] + 'd9 , 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd10])					dramr_addr <= {16'd0, instr[15:6] + 'd10, 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd11])					dramr_addr <= {16'd0, instr[15:6] + 'd11, 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd12])					dramr_addr <= {16'd0, instr[15:6] + 'd12, 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd13])					dramr_addr <= {16'd0, instr[15:6] + 'd13, 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd14])					dramr_addr <= {16'd0, instr[15:6] + 'd14, 6'd0};
						else if	(!valid_dr[instr[11:6] + 'd15])					dramr_addr <= {16'd0, instr[15:6] + 'd15, 6'd0};
						else if (!valid_dr[instr[11:6] + 'd16] && dr_col !='d0)	dramr_addr <= {16'd0, instr[15:6] + 'd16, 6'd0}; // need to load 17 rows
						else 													dramr_addr <= {32'hffff_ffff};//impossible addr (To identify loading is finished)						
					end
 */		
		S_DATA_ADDR:begin
						if(instr[15:0] > 16'h2fc0) begin
							if(!valid_dr[63]) 	dramr_addr <= {16'd0, 16'h2fc0};
							else 				dramr_addr <= 32'hffff_ffff;
/* 							
							if		(!valid_dr[instr_offset_0 [5:0]]) 					dramr_addr <= {16'd0, instr[15:12], instr_offset_0[5:0], 6'd0};//1000...
							else if	(!valid_dr[instr_offset_1 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_1[5:0], 6'd0};//1064
							else if	(!valid_dr[instr_offset_2 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_2[5:0], 6'd0};//1128
							else if	(!valid_dr[instr_offset_3 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_3[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_4 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_4[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_5 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_5[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_6 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_6[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_7 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_7[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_8 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_8[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_9 [5:0]] && dr_col !='d0)	dramr_addr <= {16'd0, instr[15:12], instr_offset_9[5:0], 6'd0};
							else 														dramr_addr <= {32'hffff_ffff};//impossible addr (To identify loading is finished)						
 */						end
						else begin
							if		(!valid_dr[instr_offset_0 [5:0]]) 					dramr_addr <= {16'd0, instr[15:12], instr_offset_0 [5:0], 6'd0};//1000...
							else if	(!valid_dr[instr_offset_1 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_1 [5:0], 6'd0};//1064
							else if	(!valid_dr[instr_offset_2 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_2 [5:0], 6'd0};//1128
							else if	(!valid_dr[instr_offset_3 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_3 [5:0], 6'd0};
							else if	(!valid_dr[instr_offset_4 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_4 [5:0], 6'd0};
							else if	(!valid_dr[instr_offset_5 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_5 [5:0], 6'd0};
							else if	(!valid_dr[instr_offset_6 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_6 [5:0], 6'd0};
							else if	(!valid_dr[instr_offset_7 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_7 [5:0], 6'd0};
							else if	(!valid_dr[instr_offset_8 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_8 [5:0], 6'd0};
							else if	(!valid_dr[instr_offset_9 [5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_9 [5:0], 6'd0};
							else if	(!valid_dr[instr_offset_10[5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_10[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_11[5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_11[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_12[5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_12[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_13[5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_13[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_14[5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_14[5:0], 6'd0};
							else if	(!valid_dr[instr_offset_15[5:0]])					dramr_addr <= {16'd0, instr[15:12], instr_offset_15[5:0], 6'd0};
							else if (!valid_dr[instr_offset_16[5:0]] && dr_col !='d0)	dramr_addr <= {16'd0, instr[15:12], instr_offset_16[5:0], 6'd0}; // need to load 17 rows
							else 														dramr_addr <= {32'hffff_ffff};//impossible addr (To identify loading is finished)						
						end
					end
		default:		dramr_addr <= ff_dramr_addr;
	endcase
end

//====================================================
//		      	Read data channel
//====================================================
//slave==========
//DRAM1
assign rready_m_inf[0] 	= 	cs == G_DATA 		? 1'b1 	: 0;
//DRAM_read
assign rready_m_inf[1]	=	cs == G_INSTR_ADDR		? 1'b1 	:
							cs == G_DATA 		? 1'b1 	: 0;
//====================================================
//              Write address channel : MUL
//====================================================
// axi write address channel 
assign awid_m_inf 		= 0;
assign awaddr_m_inf 	= {16'h0, 4'd1, write_row[5:0], d1_col, 2'b00}; 
assign awsize_m_inf		= 3'b010;//required in spec
assign awburst_m_inf	= 2'b01;// not sure
assign awlen_m_inf 		= 4'b1111;
assign awvalid_m_inf 	= 	cs == WAIT_WRITE && cur_row > 'd0 ? 1 :// cur_row != 1 : first multiplication has nothing to write
							cs == WAIT_WRITE_CONV && (cur_row > 'd1 && cur_row < 'd18) ? 1: 0;  //cur_row <= 'd2 :nothing to write(answer not cal done)

assign write_row 	= instr[1:0] == 2'b00 ? (d1_row + cur_row - 'd1) : (d1_row + cur_row - 'd2); // -1: read first write second

/*  always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 	rst_awvalid <= 0;
	else 		rst_awvalid <= awready_m_inf ? 1'b1 : 1'b0;
end
 *///====================================================
//              Write data channel : MUL
//====================================================
// axi write data channel 
reg [4:0] cnt_write;
wire[3:0] offset 	= 	instr[1:0] == 2'b00 ? dr_col : 0;
assign wdata_m_inf	=	ff_mul_1[cnt_write];
assign wlast_m_inf 	= 	cs == MUL										?	(cnt_write == 'd15	? 1 : 0) :
						cs == CONV && (cur_row > 'd2 && cur_row < 'd19) ?	(cnt_write == 'd15 	? 1 : 0) : 0;
assign wvalid_m_inf = 	(cs == MUL && cur_row != 'd1 && cnt_write != 'd16) || (cs == CONV && cur_row > 'd2 && cur_row < 'd19 && cnt_write != 'd16);//the first turn of multiplication has nothing to write
//====================================================
//              Write response channel : MUL
//====================================================
//// axi write response channel
//input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
//input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
//input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
//output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
assign bready_m_inf = 	cs == MUL ? 1 :
						cs == CONV && cur_row > 'd2 ? 1 : 0;

//write_done
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) write_done <= 0;
	else begin
		case(cs)
			IDLE: 				write_done <= 0;
			MUL:				write_done <= (bvalid_m_inf && bresp_m_inf == 2'b00) ? 1 : write_done;
			WAIT_WRITE:			write_done <= 0;
			CONV:				write_done <= (bvalid_m_inf && bresp_m_inf == 2'b00) ? 1 : write_done;
			WAIT_WRITE_CONV:	write_done <= 0;
			default:			write_done <= 0;
		endcase	
	end
end
//====================================================
//		      	G_INSTR_ADDR
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		instr <= 0;
	end
	else begin
		case(cs) 
			G_INSTR_ADDR:	instr <= rvalid_m_inf ? rdata_m_inf[63:32] : instr;
			default 	:	instr <= instr;
		endcase
	end
end


//set dram1 first address=============
//d1_row, d1_col
wire[11:0] first_addr = {instr[27:18], 2'b00};//ex. 1064 : first_addr = 064
assign d1_row = {first_addr[11:6]};// /4/16
assign d1_col = first_addr[5:2];// mod 16
wire[11:0] first_addr_r = {instr[11:2], 2'b00};
assign dr_row = {first_addr_r[11:6]};
assign dr_col = {first_addr_r[5:2]};
//====================================================
//		      	cur_row
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) cur_row <= 0;
	else begin
		case(cs)
			IDLE:		cur_row <= 0;
			LOAD_MUL:	cur_row <= cur_row + 'd1;
			LOAD_CONV:	cur_row <= cur_row + 'd1;
			default:	cur_row <= cur_row;
		endcase
	end
end
//====================================================
//		      	cur_row_r
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) cur_row_r <= 0;
	else begin
		case(cs)
			IDLE:		cur_row_r <= 0;
			LOAD_MUL:	cur_row_r <= 0;
			MUL:		cur_row_r <= cur_row_r == 'd17 ? cur_row_r : cur_row_r + 'd1;//'d17: multiplication already done
			default:	cur_row_r <= cur_row_r;
		endcase
	end
end
//====================================================
//		      	cur_col
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) cur_col <= 0;
	else begin
		case(cs)
			IDLE:				cur_col <= 0;
			LOAD_MUL:			cur_col <= d1_col;
			MUL:				cur_col <= cur_col == 'd16 ? 0 : cur_col + 'd1; //mod 16
			CONV:				cur_col <= cur_col == 'd17 ? cur_col : cur_col + 'd1; //mod 16  //unsure : unset boundary
			WAIT_WRITE_CONV:	cur_col <= 0;
			default:			cur_col <= cur_col;
		endcase
	end
end
//====================================================
//		      	ff_c1
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) ff_c1 <= 0;
	else begin
		case(cs)
			LOAD_MUL:		
				case(cur_col)
					'd0  : ff_c1 <= OUT_C1_0 ;
					'd1  : ff_c1 <= OUT_C1_1 ;
					'd2  : ff_c1 <= OUT_C1_2 ;
					'd3  : ff_c1 <= OUT_C1_3 ;
					'd4  : ff_c1 <= OUT_C1_4 ;
					'd5  : ff_c1 <= OUT_C1_5 ;
					'd6  : ff_c1 <= OUT_C1_6 ;
					'd7  : ff_c1 <= OUT_C1_7 ;
					'd8  : ff_c1 <= OUT_C1_8 ;
					'd9  : ff_c1 <= OUT_C1_9 ;
					'd10 : ff_c1 <= OUT_C1_10;
					'd11 : ff_c1 <= OUT_C1_11;
					'd12 : ff_c1 <= OUT_C1_12;
					'd13 : ff_c1 <= OUT_C1_13;
					'd14 : ff_c1 <= OUT_C1_14;
					'd15 : ff_c1 <= OUT_C1_15;
				endcase
			default:	ff_c1 <= ff_c1;
		endcase
	end
end
//====================================================
//		      	valid_d1
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_d1 <= 0;
	else begin
		case(cs)
			G_DATA:			begin
								valid_d1[dram1_addr[11:6]] <= ff_dram1_addr == 32'hffff_ffff ? valid_d1[dram1_addr[11:6]] : 1;
								//arvalid_m_inf  ? 1 : valid_d1[araddr_m_inf[11:6]];
							end
			default:		valid_d1 <= valid_d1;
		endcase
	end
end
//====================================================
//		      	valid_dr
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) valid_dr <= 0;
	else begin
		case(cs)
			G_DATA:			begin
								valid_dr[dramr_addr[11:6]] <= ff_dramr_addr == 32'hffff_ffff ? valid_dr[dramr_addr[11:6]] : 1;
							end
			default:		valid_dr <= valid_dr;
		endcase
	end
end
//====================================================
//		      	d1_done , dr_done
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		d1_done <= 0;
		dr_done <= 0;
	end
	else begin
		case(cs)
			IDLE:	begin
						d1_done <= 0;
						dr_done <= 0;
					end
			S_DATA_ADDR:
					begin
						d1_done <= 0;
						dr_done <= 0;
					end
			G_DATA:	begin
						d1_done <= rlast_m_inf[0] ? 1 : d1_done;
						dr_done <= rlast_m_inf[1] ? 1 : dr_done;
					end
			default:begin
						d1_done <= d1_done;
						dr_done <= dr_done;
					end
		endcase
	end
end

assign load_done = (d1_done && dr_done) || (d1_done && rlast_m_inf[1]) || (rlast_m_inf[0] && dr_done);
//====================================================
//		      	LOAD_MUL :ff_mul_1 (save ans for write back)
//====================================================
integer i;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i = i + 1) begin
			ff_mul_1[i] <= 0;
		end
	end
	else begin
		case(cs)
			IDLE:		begin
							for(i = 0; i < 16; i = i + 1) begin
								ff_mul_1[i] <= 0;
							end
						end
/* 			LOAD_MUL:	begin
							case(d1_col)
								'd0:	begin
											ff_mul_1[0]  <= OUT_C1_0;
											ff_mul_1[1]  <= OUT_C1_1;
											ff_mul_1[2]  <= OUT_C1_2;
											ff_mul_1[3]  <= OUT_C1_3;
											ff_mul_1[4]  <= OUT_C1_4;
											ff_mul_1[5]  <= OUT_C1_5;
											ff_mul_1[6]  <= OUT_C1_6;
											ff_mul_1[7]  <= OUT_C1_7;
											ff_mul_1[8]  <= OUT_C1_8;
											ff_mul_1[9]  <= OUT_C1_9;
											ff_mul_1[10] <= OUT_C1_10;
											ff_mul_1[11] <= OUT_C1_11;
											ff_mul_1[12] <= OUT_C1_12;
											ff_mul_1[13] <= OUT_C1_13;
											ff_mul_1[14] <= OUT_C1_14;
											ff_mul_1[15] <= OUT_C1_15;
										end
								'd1:	begin
											ff_mul_1[0]  <= OUT_C1_1 ;
											ff_mul_1[1]  <= OUT_C1_2 ;
											ff_mul_1[2]  <= OUT_C1_3 ;
											ff_mul_1[3]  <= OUT_C1_4 ;
											ff_mul_1[4]  <= OUT_C1_5 ;
											ff_mul_1[5]  <= OUT_C1_6 ;
											ff_mul_1[6]  <= OUT_C1_7 ;
											ff_mul_1[7]  <= OUT_C1_8 ;
											ff_mul_1[8]  <= OUT_C1_9 ;
											ff_mul_1[9]  <= OUT_C1_10;
											ff_mul_1[10] <= OUT_C1_11;
											ff_mul_1[11] <= OUT_C1_12;
											ff_mul_1[12] <= OUT_C1_13;
											ff_mul_1[13] <= OUT_C1_14;
											ff_mul_1[14] <= OUT_C1_15;
											ff_mul_1[15] <= OUT_C1_0 ;
										end
								'd2:	begin
											ff_mul_1[0]  <= OUT_C1_2 ;
											ff_mul_1[1]  <= OUT_C1_3 ;
											ff_mul_1[2]  <= OUT_C1_4 ;
											ff_mul_1[3]  <= OUT_C1_5 ;
											ff_mul_1[4]  <= OUT_C1_6 ;
											ff_mul_1[5]  <= OUT_C1_7 ;
											ff_mul_1[6]  <= OUT_C1_8 ;
											ff_mul_1[7]  <= OUT_C1_9 ;
											ff_mul_1[8]  <= OUT_C1_10;
											ff_mul_1[9]  <= OUT_C1_11;
											ff_mul_1[10] <= OUT_C1_12;
											ff_mul_1[11] <= OUT_C1_13;
											ff_mul_1[12] <= OUT_C1_14;
											ff_mul_1[13] <= OUT_C1_15;
											ff_mul_1[14] <= OUT_C1_0 ;
											ff_mul_1[15] <= OUT_C1_1 ;
										end
								'd3:	begin
											ff_mul_1[0]  <= OUT_C1_3 ;
											ff_mul_1[1]  <= OUT_C1_4 ;
											ff_mul_1[2]  <= OUT_C1_5 ;
											ff_mul_1[3]  <= OUT_C1_6 ;
											ff_mul_1[4]  <= OUT_C1_7 ;
											ff_mul_1[5]  <= OUT_C1_8 ;
											ff_mul_1[6]  <= OUT_C1_9 ;
											ff_mul_1[7]  <= OUT_C1_10;
											ff_mul_1[8]  <= OUT_C1_11;
											ff_mul_1[9]  <= OUT_C1_12;
											ff_mul_1[10] <= OUT_C1_13;
											ff_mul_1[11] <= OUT_C1_14;
											ff_mul_1[12] <= OUT_C1_15;
											ff_mul_1[13] <= OUT_C1_0 ;
											ff_mul_1[14] <= OUT_C1_1 ;
											ff_mul_1[15] <= OUT_C1_2 ;
										end
								'd4:	begin
											ff_mul_1[0]  <= OUT_C1_4 ;
											ff_mul_1[1]  <= OUT_C1_5 ;
											ff_mul_1[2]  <= OUT_C1_6 ;
											ff_mul_1[3]  <= OUT_C1_7 ;
											ff_mul_1[4]  <= OUT_C1_8 ;
											ff_mul_1[5]  <= OUT_C1_9 ;
											ff_mul_1[6]  <= OUT_C1_10;
											ff_mul_1[7]  <= OUT_C1_11;
											ff_mul_1[8]  <= OUT_C1_12;
											ff_mul_1[9]  <= OUT_C1_13;
											ff_mul_1[10] <= OUT_C1_14;
											ff_mul_1[11] <= OUT_C1_15;
											ff_mul_1[12] <= OUT_C1_0 ;
											ff_mul_1[13] <= OUT_C1_1 ;
											ff_mul_1[14] <= OUT_C1_2 ;
											ff_mul_1[15] <= OUT_C1_3 ;
										end
								'd5:	begin
											ff_mul_1[0]  <= OUT_C1_5 ;
											ff_mul_1[1]  <= OUT_C1_6 ;
											ff_mul_1[2]  <= OUT_C1_7 ;
											ff_mul_1[3]  <= OUT_C1_8 ;
											ff_mul_1[4]  <= OUT_C1_9 ;
											ff_mul_1[5]  <= OUT_C1_10;
											ff_mul_1[6]  <= OUT_C1_11;
											ff_mul_1[7]  <= OUT_C1_12;
											ff_mul_1[8]  <= OUT_C1_13;
											ff_mul_1[9]  <= OUT_C1_14;
											ff_mul_1[10] <= OUT_C1_15;
											ff_mul_1[11] <= OUT_C1_0 ;
											ff_mul_1[12] <= OUT_C1_1 ;
											ff_mul_1[13] <= OUT_C1_2 ;
											ff_mul_1[14] <= OUT_C1_3 ;
											ff_mul_1[15] <= OUT_C1_4 ;
										end
								'd6:	begin
											ff_mul_1[0]  <= OUT_C1_6 ;
											ff_mul_1[1]  <= OUT_C1_7 ;
											ff_mul_1[2]  <= OUT_C1_8 ;
											ff_mul_1[3]  <= OUT_C1_9 ;
											ff_mul_1[4]  <= OUT_C1_10;
											ff_mul_1[5]  <= OUT_C1_11;
											ff_mul_1[6]  <= OUT_C1_12;
											ff_mul_1[7]  <= OUT_C1_13;
											ff_mul_1[8]  <= OUT_C1_14;
											ff_mul_1[9]  <= OUT_C1_15;
											ff_mul_1[10] <= OUT_C1_0 ;
											ff_mul_1[11] <= OUT_C1_1 ;
											ff_mul_1[12] <= OUT_C1_2 ;
											ff_mul_1[13] <= OUT_C1_3 ;
											ff_mul_1[14] <= OUT_C1_4 ;
											ff_mul_1[15] <= OUT_C1_5 ;
										end
								'd7:	begin
											ff_mul_1[0]  <= OUT_C1_7 ;
											ff_mul_1[1]  <= OUT_C1_8 ;
											ff_mul_1[2]  <= OUT_C1_9 ;
											ff_mul_1[3]  <= OUT_C1_10;
											ff_mul_1[4]  <= OUT_C1_11;
											ff_mul_1[5]  <= OUT_C1_12;
											ff_mul_1[6]  <= OUT_C1_13;
											ff_mul_1[7]  <= OUT_C1_14;
											ff_mul_1[8]  <= OUT_C1_15;
											ff_mul_1[9]  <= OUT_C1_0 ;
											ff_mul_1[10] <= OUT_C1_1 ;
											ff_mul_1[11] <= OUT_C1_2 ;
											ff_mul_1[12] <= OUT_C1_3 ;
											ff_mul_1[13] <= OUT_C1_4 ;
											ff_mul_1[14] <= OUT_C1_5 ;
											ff_mul_1[15] <= OUT_C1_6 ;
										end
								'd8:	begin
											ff_mul_1[0]  <= OUT_C1_8 ;
											ff_mul_1[1]  <= OUT_C1_9 ;
											ff_mul_1[2]  <= OUT_C1_10;
											ff_mul_1[3]  <= OUT_C1_11;
											ff_mul_1[4]  <= OUT_C1_12;
											ff_mul_1[5]  <= OUT_C1_13;
											ff_mul_1[6]  <= OUT_C1_14;
											ff_mul_1[7]  <= OUT_C1_15;
											ff_mul_1[8]  <= OUT_C1_0 ;
											ff_mul_1[9]  <= OUT_C1_1 ;
											ff_mul_1[10] <= OUT_C1_2 ;
											ff_mul_1[11] <= OUT_C1_3 ;
											ff_mul_1[12] <= OUT_C1_4 ;
											ff_mul_1[13] <= OUT_C1_5 ;
											ff_mul_1[14] <= OUT_C1_6 ;
											ff_mul_1[15] <= OUT_C1_7 ;
										end
								'd9:	begin
											ff_mul_1[0]  <= OUT_C1_9 ;
											ff_mul_1[1]  <= OUT_C1_10;
											ff_mul_1[2]  <= OUT_C1_11;
											ff_mul_1[3]  <= OUT_C1_12;
											ff_mul_1[4]  <= OUT_C1_13;
											ff_mul_1[5]  <= OUT_C1_14;
											ff_mul_1[6]  <= OUT_C1_15;
											ff_mul_1[7]  <= OUT_C1_0 ;
											ff_mul_1[8]  <= OUT_C1_1 ;
											ff_mul_1[9]  <= OUT_C1_2 ;
											ff_mul_1[10] <= OUT_C1_3 ;
											ff_mul_1[11] <= OUT_C1_4 ;
											ff_mul_1[12] <= OUT_C1_5 ;
											ff_mul_1[13] <= OUT_C1_6 ;
											ff_mul_1[14] <= OUT_C1_7 ;
											ff_mul_1[15] <= OUT_C1_8 ; 
										end
								'd10:	begin
											ff_mul_1[0]  <= OUT_C1_10;
											ff_mul_1[1]  <= OUT_C1_11;
											ff_mul_1[2]  <= OUT_C1_12;
											ff_mul_1[3]  <= OUT_C1_13;
											ff_mul_1[4]  <= OUT_C1_14;
											ff_mul_1[5]  <= OUT_C1_15;
											ff_mul_1[6]  <= OUT_C1_0 ;
											ff_mul_1[7]  <= OUT_C1_1 ;
											ff_mul_1[8]  <= OUT_C1_2 ;
											ff_mul_1[9]  <= OUT_C1_3 ;
											ff_mul_1[10] <= OUT_C1_4 ;
											ff_mul_1[11] <= OUT_C1_5 ;
											ff_mul_1[12] <= OUT_C1_6 ;
											ff_mul_1[13] <= OUT_C1_7 ;
											ff_mul_1[14] <= OUT_C1_8 ;
											ff_mul_1[15] <= OUT_C1_9 ; 
										end
								'd11:	begin
											ff_mul_1[0]  <= OUT_C1_11;
											ff_mul_1[1]  <= OUT_C1_12;
											ff_mul_1[2]  <= OUT_C1_13;
											ff_mul_1[3]  <= OUT_C1_14;
											ff_mul_1[4]  <= OUT_C1_15;
											ff_mul_1[5]  <= OUT_C1_0 ;
											ff_mul_1[6]  <= OUT_C1_1 ;
											ff_mul_1[7]  <= OUT_C1_2 ;
											ff_mul_1[8]  <= OUT_C1_3 ;
											ff_mul_1[9]  <= OUT_C1_4 ;
											ff_mul_1[10] <= OUT_C1_5 ;
											ff_mul_1[11] <= OUT_C1_6 ;
											ff_mul_1[12] <= OUT_C1_7 ;
											ff_mul_1[13] <= OUT_C1_8 ;
											ff_mul_1[14] <= OUT_C1_9 ;
											ff_mul_1[15] <= OUT_C1_10; 
										end
								'd12:	begin
											ff_mul_1[0]  <= OUT_C1_12;
											ff_mul_1[1]  <= OUT_C1_13;
											ff_mul_1[2]  <= OUT_C1_14;
											ff_mul_1[3]  <= OUT_C1_15;
											ff_mul_1[4]  <= OUT_C1_0 ;
											ff_mul_1[5]  <= OUT_C1_1 ;
											ff_mul_1[6]  <= OUT_C1_2 ;
											ff_mul_1[7]  <= OUT_C1_3 ;
											ff_mul_1[8]  <= OUT_C1_4 ;
											ff_mul_1[9]  <= OUT_C1_5 ;
											ff_mul_1[10] <= OUT_C1_6 ;
											ff_mul_1[11] <= OUT_C1_7 ;
											ff_mul_1[12] <= OUT_C1_8 ;
											ff_mul_1[13] <= OUT_C1_9 ;
											ff_mul_1[14] <= OUT_C1_10;
											ff_mul_1[15] <= OUT_C1_11; 
										end
								'd13:	begin
											ff_mul_1[0]  <= OUT_C1_13;
											ff_mul_1[1]  <= OUT_C1_14;
											ff_mul_1[2]  <= OUT_C1_15;
											ff_mul_1[3]  <= OUT_C1_0 ;
											ff_mul_1[4]  <= OUT_C1_1 ;
											ff_mul_1[5]  <= OUT_C1_2 ;
											ff_mul_1[6]  <= OUT_C1_3 ;
											ff_mul_1[7]  <= OUT_C1_4 ;
											ff_mul_1[8]  <= OUT_C1_5 ;
											ff_mul_1[9]  <= OUT_C1_6 ;
											ff_mul_1[10] <= OUT_C1_7 ;
											ff_mul_1[11] <= OUT_C1_8 ;
											ff_mul_1[12] <= OUT_C1_9 ;
											ff_mul_1[13] <= OUT_C1_10;
											ff_mul_1[14] <= OUT_C1_11;
											ff_mul_1[15] <= OUT_C1_12; 
										end
								'd14:	begin
											ff_mul_1[0]  <= OUT_C1_14;
											ff_mul_1[1]  <= OUT_C1_15;
											ff_mul_1[2]  <= OUT_C1_0 ;
											ff_mul_1[3]  <= OUT_C1_1 ;
											ff_mul_1[4]  <= OUT_C1_2 ;
											ff_mul_1[5]  <= OUT_C1_3 ;
											ff_mul_1[6]  <= OUT_C1_4 ;
											ff_mul_1[7]  <= OUT_C1_5 ;
											ff_mul_1[8]  <= OUT_C1_6 ;
											ff_mul_1[9]  <= OUT_C1_7 ;
											ff_mul_1[10] <= OUT_C1_8 ;
											ff_mul_1[11] <= OUT_C1_9 ;
											ff_mul_1[12] <= OUT_C1_10;
											ff_mul_1[13] <= OUT_C1_11;
											ff_mul_1[14] <= OUT_C1_12;
											ff_mul_1[15] <= OUT_C1_13; 
										end
								'd15:	begin
											ff_mul_1[0]  <= OUT_C1_15;
											ff_mul_1[1]  <= OUT_C1_0 ;
											ff_mul_1[2]  <= OUT_C1_1 ;
											ff_mul_1[3]  <= OUT_C1_2 ;
											ff_mul_1[4]  <= OUT_C1_3 ;
											ff_mul_1[5]  <= OUT_C1_4 ;
											ff_mul_1[6]  <= OUT_C1_5 ;
											ff_mul_1[7]  <= OUT_C1_6 ;
											ff_mul_1[8]  <= OUT_C1_7 ;
											ff_mul_1[9]  <= OUT_C1_8 ;
											ff_mul_1[10] <= OUT_C1_9 ;
											ff_mul_1[11] <= OUT_C1_10;
											ff_mul_1[12] <= OUT_C1_11;
											ff_mul_1[13] <= OUT_C1_12;
											ff_mul_1[14] <= OUT_C1_13;
											ff_mul_1[15] <= OUT_C1_14; 
										end
								
							endcase							
						end
 */		
			WAIT_WRITE:	begin
							for(i = 0; i < 16; i = i + 1) begin
								ff_mul_1[i] <= ff_mul_2[i];
							end
						end
			WAIT_WRITE_CONV:
						begin
							if(cnt_input == 'd0) begin
								for(i = 0; i < 16; i = i + 1) begin
									ff_mul_1[i] <= ff_mul_2[i];
								end
							end
							else begin
								for(i = 0; i < 16; i = i + 1) begin
									ff_mul_1[i] <= ff_mul_1[i];
								end
							end
						end
		endcase
	end
end
//====================================================
//		      	MUL :ff_mul_2 (save tmp ans of multiplication)
//====================================================
//CONV : top row
integer j;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(j = 0; j < 16; j = j + 1) begin
			ff_mul_2[j] <= 0;
		end
	end
	else begin
		case(cs)
			IDLE:	begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_2[j] <= 0;
						end
					end
			LOAD_MUL:
					begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_2[j] <= 0;
						end
					end
			MUL:	begin
						if(cur_row_r > 'd0 && cur_row_r < 'd17) begin //memory latency : 1 cycle
							ff_mul_2[0]  <= add_out_0 ;
							ff_mul_2[1]  <= add_out_1 ;
							ff_mul_2[2]  <= add_out_2 ;
							ff_mul_2[3]  <= add_out_3 ;
							ff_mul_2[4]  <= add_out_4 ;
							ff_mul_2[5]  <= add_out_5 ;
							ff_mul_2[6]  <= add_out_6 ;
							ff_mul_2[7]  <= add_out_7 ;
							ff_mul_2[8]  <= add_out_8 ;
							ff_mul_2[9]  <= add_out_9 ;
							ff_mul_2[10] <= add_out_10;
							ff_mul_2[11] <= add_out_11;
							ff_mul_2[12] <= add_out_12;
							ff_mul_2[13] <= add_out_13;
							ff_mul_2[14] <= add_out_14;
							ff_mul_2[15] <= add_out_15;
						end
						else begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_2[j] <= ff_mul_2[j];
							end
						end
					end					
			CONV:	begin
						if(cur_row > 'd0 && cur_row < 'd17) begin
							if(cur_col > 'd0 && cur_col < 'd17) begin
								case(cur_col)
									'd1:	begin
												ff_mul_2[0]  <= add_out_1;
												ff_mul_2[1]  <= add_out_2;
											end
									'd16:	begin
												ff_mul_2[14] <= add_out_0;
												ff_mul_2[15] <= add_out_1;
											end
									default:begin
												ff_mul_2[cur_col-2] <= add_out_0;
												ff_mul_2[cur_col-1]	<= add_out_1;
												ff_mul_2[cur_col] 	<= add_out_2;
											end
								endcase
							end
							else begin
								for(j = 0; j < 16; j = j + 1) begin
									ff_mul_2[j] <= ff_mul_2[j];
								end
							end
						end
						else begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_2[j] <= ff_mul_2[j];
							end
						end
					end
			WAIT_WRITE_CONV:// shift
					begin
						if(cnt_input == 'd0) begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_2[j] <= ff_mul_4[j];
							end
						end
						else begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_2[j] <= ff_mul_2[j];
							end
						end
					end
			default:begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_2[j] <= ff_mul_2[j];
						end
					end
		endcase
	end
end
//====================================================
//		      	ff_mul_3
//====================================================
//in MUL : save the current row for calculation
//in CONV: save the current row for calculation
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(j = 0; j < 16; j = j + 1) begin
			ff_mul_3[j] <= 0;
		end
	end
	else begin
		case(cs)
			IDLE:		begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_3[j] <= 0;
							end
						end
			LOAD_MUL:	begin
								case(d1_col)
											'd0:	begin
														ff_mul_3[0]  <= OUT_C1_0;
														ff_mul_3[1]  <= OUT_C1_1;
														ff_mul_3[2]  <= OUT_C1_2;
														ff_mul_3[3]  <= OUT_C1_3;
														ff_mul_3[4]  <= OUT_C1_4;
														ff_mul_3[5]  <= OUT_C1_5;
														ff_mul_3[6]  <= OUT_C1_6;
														ff_mul_3[7]  <= OUT_C1_7;
														ff_mul_3[8]  <= OUT_C1_8;
														ff_mul_3[9]  <= OUT_C1_9;
														ff_mul_3[10] <= OUT_C1_10;
														ff_mul_3[11] <= OUT_C1_11;
														ff_mul_3[12] <= OUT_C1_12;
														ff_mul_3[13] <= OUT_C1_13;
														ff_mul_3[14] <= OUT_C1_14;
														ff_mul_3[15] <= OUT_C1_15;
													end
											'd1:	begin
														ff_mul_3[0]  <= OUT_C1_1 ;
														ff_mul_3[1]  <= OUT_C1_2 ;
														ff_mul_3[2]  <= OUT_C1_3 ;
														ff_mul_3[3]  <= OUT_C1_4 ;
														ff_mul_3[4]  <= OUT_C1_5 ;
														ff_mul_3[5]  <= OUT_C1_6 ;
														ff_mul_3[6]  <= OUT_C1_7 ;
														ff_mul_3[7]  <= OUT_C1_8 ;
														ff_mul_3[8]  <= OUT_C1_9 ;
														ff_mul_3[9]  <= OUT_C1_10;
														ff_mul_3[10] <= OUT_C1_11;
														ff_mul_3[11] <= OUT_C1_12;
														ff_mul_3[12] <= OUT_C1_13;
														ff_mul_3[13] <= OUT_C1_14;
														ff_mul_3[14] <= OUT_C1_15;
														ff_mul_3[15] <= OUT_C1_0 ;
													end
											'd2:	begin
														ff_mul_3[0]  <= OUT_C1_2 ;
														ff_mul_3[1]  <= OUT_C1_3 ;
														ff_mul_3[2]  <= OUT_C1_4 ;
														ff_mul_3[3]  <= OUT_C1_5 ;
														ff_mul_3[4]  <= OUT_C1_6 ;
														ff_mul_3[5]  <= OUT_C1_7 ;
														ff_mul_3[6]  <= OUT_C1_8 ;
														ff_mul_3[7]  <= OUT_C1_9 ;
														ff_mul_3[8]  <= OUT_C1_10;
														ff_mul_3[9]  <= OUT_C1_11;
														ff_mul_3[10] <= OUT_C1_12;
														ff_mul_3[11] <= OUT_C1_13;
														ff_mul_3[12] <= OUT_C1_14;
														ff_mul_3[13] <= OUT_C1_15;
														ff_mul_3[14] <= OUT_C1_0 ;
														ff_mul_3[15] <= OUT_C1_1 ;
													end
											'd3:	begin
														ff_mul_3[0]  <= OUT_C1_3 ;
														ff_mul_3[1]  <= OUT_C1_4 ;
														ff_mul_3[2]  <= OUT_C1_5 ;
														ff_mul_3[3]  <= OUT_C1_6 ;
														ff_mul_3[4]  <= OUT_C1_7 ;
														ff_mul_3[5]  <= OUT_C1_8 ;
														ff_mul_3[6]  <= OUT_C1_9 ;
														ff_mul_3[7]  <= OUT_C1_10;
														ff_mul_3[8]  <= OUT_C1_11;
														ff_mul_3[9]  <= OUT_C1_12;
														ff_mul_3[10] <= OUT_C1_13;
														ff_mul_3[11] <= OUT_C1_14;
														ff_mul_3[12] <= OUT_C1_15;
														ff_mul_3[13] <= OUT_C1_0 ;
														ff_mul_3[14] <= OUT_C1_1 ;
														ff_mul_3[15] <= OUT_C1_2 ;
													end
											'd4:	begin
														ff_mul_3[0]  <= OUT_C1_4 ;
														ff_mul_3[1]  <= OUT_C1_5 ;
														ff_mul_3[2]  <= OUT_C1_6 ;
														ff_mul_3[3]  <= OUT_C1_7 ;
														ff_mul_3[4]  <= OUT_C1_8 ;
														ff_mul_3[5]  <= OUT_C1_9 ;
														ff_mul_3[6]  <= OUT_C1_10;
														ff_mul_3[7]  <= OUT_C1_11;
														ff_mul_3[8]  <= OUT_C1_12;
														ff_mul_3[9]  <= OUT_C1_13;
														ff_mul_3[10] <= OUT_C1_14;
														ff_mul_3[11] <= OUT_C1_15;
														ff_mul_3[12] <= OUT_C1_0 ;
														ff_mul_3[13] <= OUT_C1_1 ;
														ff_mul_3[14] <= OUT_C1_2 ;
														ff_mul_3[15] <= OUT_C1_3 ;
													end
											'd5:	begin
														ff_mul_3[0]  <= OUT_C1_5 ;
														ff_mul_3[1]  <= OUT_C1_6 ;
														ff_mul_3[2]  <= OUT_C1_7 ;
														ff_mul_3[3]  <= OUT_C1_8 ;
														ff_mul_3[4]  <= OUT_C1_9 ;
														ff_mul_3[5]  <= OUT_C1_10;
														ff_mul_3[6]  <= OUT_C1_11;
														ff_mul_3[7]  <= OUT_C1_12;
														ff_mul_3[8]  <= OUT_C1_13;
														ff_mul_3[9]  <= OUT_C1_14;
														ff_mul_3[10] <= OUT_C1_15;
														ff_mul_3[11] <= OUT_C1_0 ;
														ff_mul_3[12] <= OUT_C1_1 ;
														ff_mul_3[13] <= OUT_C1_2 ;
														ff_mul_3[14] <= OUT_C1_3 ;
														ff_mul_3[15] <= OUT_C1_4 ;
													end
											'd6:	begin
														ff_mul_3[0]  <= OUT_C1_6 ;
														ff_mul_3[1]  <= OUT_C1_7 ;
														ff_mul_3[2]  <= OUT_C1_8 ;
														ff_mul_3[3]  <= OUT_C1_9 ;
														ff_mul_3[4]  <= OUT_C1_10;
														ff_mul_3[5]  <= OUT_C1_11;
														ff_mul_3[6]  <= OUT_C1_12;
														ff_mul_3[7]  <= OUT_C1_13;
														ff_mul_3[8]  <= OUT_C1_14;
														ff_mul_3[9]  <= OUT_C1_15;
														ff_mul_3[10] <= OUT_C1_0 ;
														ff_mul_3[11] <= OUT_C1_1 ;
														ff_mul_3[12] <= OUT_C1_2 ;
														ff_mul_3[13] <= OUT_C1_3 ;
														ff_mul_3[14] <= OUT_C1_4 ;
														ff_mul_3[15] <= OUT_C1_5 ;
													end
											'd7:	begin
														ff_mul_3[0]  <= OUT_C1_7 ;
														ff_mul_3[1]  <= OUT_C1_8 ;
														ff_mul_3[2]  <= OUT_C1_9 ;
														ff_mul_3[3]  <= OUT_C1_10;
														ff_mul_3[4]  <= OUT_C1_11;
														ff_mul_3[5]  <= OUT_C1_12;
														ff_mul_3[6]  <= OUT_C1_13;
														ff_mul_3[7]  <= OUT_C1_14;
														ff_mul_3[8]  <= OUT_C1_15;
														ff_mul_3[9]  <= OUT_C1_0 ;
														ff_mul_3[10] <= OUT_C1_1 ;
														ff_mul_3[11] <= OUT_C1_2 ;
														ff_mul_3[12] <= OUT_C1_3 ;
														ff_mul_3[13] <= OUT_C1_4 ;
														ff_mul_3[14] <= OUT_C1_5 ;
														ff_mul_3[15] <= OUT_C1_6 ;
													end
											'd8:	begin
														ff_mul_3[0]  <= OUT_C1_8 ;
														ff_mul_3[1]  <= OUT_C1_9 ;
														ff_mul_3[2]  <= OUT_C1_10;
														ff_mul_3[3]  <= OUT_C1_11;
														ff_mul_3[4]  <= OUT_C1_12;
														ff_mul_3[5]  <= OUT_C1_13;
														ff_mul_3[6]  <= OUT_C1_14;
														ff_mul_3[7]  <= OUT_C1_15;
														ff_mul_3[8]  <= OUT_C1_0 ;
														ff_mul_3[9]  <= OUT_C1_1 ;
														ff_mul_3[10] <= OUT_C1_2 ;
														ff_mul_3[11] <= OUT_C1_3 ;
														ff_mul_3[12] <= OUT_C1_4 ;
														ff_mul_3[13] <= OUT_C1_5 ;
														ff_mul_3[14] <= OUT_C1_6 ;
														ff_mul_3[15] <= OUT_C1_7 ;
													end
											'd9:	begin
														ff_mul_3[0]  <= OUT_C1_9 ;
														ff_mul_3[1]  <= OUT_C1_10;
														ff_mul_3[2]  <= OUT_C1_11;
														ff_mul_3[3]  <= OUT_C1_12;
														ff_mul_3[4]  <= OUT_C1_13;
														ff_mul_3[5]  <= OUT_C1_14;
														ff_mul_3[6]  <= OUT_C1_15;
														ff_mul_3[7]  <= OUT_C1_0 ;
														ff_mul_3[8]  <= OUT_C1_1 ;
														ff_mul_3[9]  <= OUT_C1_2 ;
														ff_mul_3[10] <= OUT_C1_3 ;
														ff_mul_3[11] <= OUT_C1_4 ;
														ff_mul_3[12] <= OUT_C1_5 ;
														ff_mul_3[13] <= OUT_C1_6 ;
														ff_mul_3[14] <= OUT_C1_7 ;
														ff_mul_3[15] <= OUT_C1_8 ; 
													end
											'd10:	begin
														ff_mul_3[0]  <= OUT_C1_10;
														ff_mul_3[1]  <= OUT_C1_11;
														ff_mul_3[2]  <= OUT_C1_12;
														ff_mul_3[3]  <= OUT_C1_13;
														ff_mul_3[4]  <= OUT_C1_14;
														ff_mul_3[5]  <= OUT_C1_15;
														ff_mul_3[6]  <= OUT_C1_0 ;
														ff_mul_3[7]  <= OUT_C1_1 ;
														ff_mul_3[8]  <= OUT_C1_2 ;
														ff_mul_3[9]  <= OUT_C1_3 ;
														ff_mul_3[10] <= OUT_C1_4 ;
														ff_mul_3[11] <= OUT_C1_5 ;
														ff_mul_3[12] <= OUT_C1_6 ;
														ff_mul_3[13] <= OUT_C1_7 ;
														ff_mul_3[14] <= OUT_C1_8 ;
														ff_mul_3[15] <= OUT_C1_9 ; 
													end
											'd11:	begin
														ff_mul_3[0]  <= OUT_C1_11;
														ff_mul_3[1]  <= OUT_C1_12;
														ff_mul_3[2]  <= OUT_C1_13;
														ff_mul_3[3]  <= OUT_C1_14;
														ff_mul_3[4]  <= OUT_C1_15;
														ff_mul_3[5]  <= OUT_C1_0 ;
														ff_mul_3[6]  <= OUT_C1_1 ;
														ff_mul_3[7]  <= OUT_C1_2 ;
														ff_mul_3[8]  <= OUT_C1_3 ;
														ff_mul_3[9]  <= OUT_C1_4 ;
														ff_mul_3[10] <= OUT_C1_5 ;
														ff_mul_3[11] <= OUT_C1_6 ;
														ff_mul_3[12] <= OUT_C1_7 ;
														ff_mul_3[13] <= OUT_C1_8 ;
														ff_mul_3[14] <= OUT_C1_9 ;
														ff_mul_3[15] <= OUT_C1_10; 
													end
											'd12:	begin
														ff_mul_3[0]  <= OUT_C1_12;
														ff_mul_3[1]  <= OUT_C1_13;
														ff_mul_3[2]  <= OUT_C1_14;
														ff_mul_3[3]  <= OUT_C1_15;
														ff_mul_3[4]  <= OUT_C1_0 ;
														ff_mul_3[5]  <= OUT_C1_1 ;
														ff_mul_3[6]  <= OUT_C1_2 ;
														ff_mul_3[7]  <= OUT_C1_3 ;
														ff_mul_3[8]  <= OUT_C1_4 ;
														ff_mul_3[9]  <= OUT_C1_5 ;
														ff_mul_3[10] <= OUT_C1_6 ;
														ff_mul_3[11] <= OUT_C1_7 ;
														ff_mul_3[12] <= OUT_C1_8 ;
														ff_mul_3[13] <= OUT_C1_9 ;
														ff_mul_3[14] <= OUT_C1_10;
														ff_mul_3[15] <= OUT_C1_11; 
													end
											'd13:	begin
														ff_mul_3[0]  <= OUT_C1_13;
														ff_mul_3[1]  <= OUT_C1_14;
														ff_mul_3[2]  <= OUT_C1_15;
														ff_mul_3[3]  <= OUT_C1_0 ;
														ff_mul_3[4]  <= OUT_C1_1 ;
														ff_mul_3[5]  <= OUT_C1_2 ;
														ff_mul_3[6]  <= OUT_C1_3 ;
														ff_mul_3[7]  <= OUT_C1_4 ;
														ff_mul_3[8]  <= OUT_C1_5 ;
														ff_mul_3[9]  <= OUT_C1_6 ;
														ff_mul_3[10] <= OUT_C1_7 ;
														ff_mul_3[11] <= OUT_C1_8 ;
														ff_mul_3[12] <= OUT_C1_9 ;
														ff_mul_3[13] <= OUT_C1_10;
														ff_mul_3[14] <= OUT_C1_11;
														ff_mul_3[15] <= OUT_C1_12; 
													end
											'd14:	begin
														ff_mul_3[0]  <= OUT_C1_14;
														ff_mul_3[1]  <= OUT_C1_15;
														ff_mul_3[2]  <= OUT_C1_0 ;
														ff_mul_3[3]  <= OUT_C1_1 ;
														ff_mul_3[4]  <= OUT_C1_2 ;
														ff_mul_3[5]  <= OUT_C1_3 ;
														ff_mul_3[6]  <= OUT_C1_4 ;
														ff_mul_3[7]  <= OUT_C1_5 ;
														ff_mul_3[8]  <= OUT_C1_6 ;
														ff_mul_3[9]  <= OUT_C1_7 ;
														ff_mul_3[10] <= OUT_C1_8 ;
														ff_mul_3[11] <= OUT_C1_9 ;
														ff_mul_3[12] <= OUT_C1_10;
														ff_mul_3[13] <= OUT_C1_11;
														ff_mul_3[14] <= OUT_C1_12;
														ff_mul_3[15] <= OUT_C1_13; 
													end
											'd15:	begin
														ff_mul_3[0]  <= OUT_C1_15;
														ff_mul_3[1]  <= OUT_C1_0 ;
														ff_mul_3[2]  <= OUT_C1_1 ;
														ff_mul_3[3]  <= OUT_C1_2 ;
														ff_mul_3[4]  <= OUT_C1_3 ;
														ff_mul_3[5]  <= OUT_C1_4 ;
														ff_mul_3[6]  <= OUT_C1_5 ;
														ff_mul_3[7]  <= OUT_C1_6 ;
														ff_mul_3[8]  <= OUT_C1_7 ;
														ff_mul_3[9]  <= OUT_C1_8 ;
														ff_mul_3[10] <= OUT_C1_9 ;
														ff_mul_3[11] <= OUT_C1_10;
														ff_mul_3[12] <= OUT_C1_11;
														ff_mul_3[13] <= OUT_C1_12;
														ff_mul_3[14] <= OUT_C1_13;
														ff_mul_3[15] <= OUT_C1_14; 
													end
											
							endcase							
						
						end		
			
			LOAD_CONV:	begin
								case(d1_col)
											'd0:	begin
														ff_mul_3[0]  <= OUT_C1_0;
														ff_mul_3[1]  <= OUT_C1_1;
														ff_mul_3[2]  <= OUT_C1_2;
														ff_mul_3[3]  <= OUT_C1_3;
														ff_mul_3[4]  <= OUT_C1_4;
														ff_mul_3[5]  <= OUT_C1_5;
														ff_mul_3[6]  <= OUT_C1_6;
														ff_mul_3[7]  <= OUT_C1_7;
														ff_mul_3[8]  <= OUT_C1_8;
														ff_mul_3[9]  <= OUT_C1_9;
														ff_mul_3[10] <= OUT_C1_10;
														ff_mul_3[11] <= OUT_C1_11;
														ff_mul_3[12] <= OUT_C1_12;
														ff_mul_3[13] <= OUT_C1_13;
														ff_mul_3[14] <= OUT_C1_14;
														ff_mul_3[15] <= OUT_C1_15;
													end
											'd1:	begin
														ff_mul_3[0]  <= OUT_C1_1 ;
														ff_mul_3[1]  <= OUT_C1_2 ;
														ff_mul_3[2]  <= OUT_C1_3 ;
														ff_mul_3[3]  <= OUT_C1_4 ;
														ff_mul_3[4]  <= OUT_C1_5 ;
														ff_mul_3[5]  <= OUT_C1_6 ;
														ff_mul_3[6]  <= OUT_C1_7 ;
														ff_mul_3[7]  <= OUT_C1_8 ;
														ff_mul_3[8]  <= OUT_C1_9 ;
														ff_mul_3[9]  <= OUT_C1_10;
														ff_mul_3[10] <= OUT_C1_11;
														ff_mul_3[11] <= OUT_C1_12;
														ff_mul_3[12] <= OUT_C1_13;
														ff_mul_3[13] <= OUT_C1_14;
														ff_mul_3[14] <= OUT_C1_15;
														ff_mul_3[15] <= OUT_C1_0 ;
													end
											'd2:	begin
														ff_mul_3[0]  <= OUT_C1_2 ;
														ff_mul_3[1]  <= OUT_C1_3 ;
														ff_mul_3[2]  <= OUT_C1_4 ;
														ff_mul_3[3]  <= OUT_C1_5 ;
														ff_mul_3[4]  <= OUT_C1_6 ;
														ff_mul_3[5]  <= OUT_C1_7 ;
														ff_mul_3[6]  <= OUT_C1_8 ;
														ff_mul_3[7]  <= OUT_C1_9 ;
														ff_mul_3[8]  <= OUT_C1_10;
														ff_mul_3[9]  <= OUT_C1_11;
														ff_mul_3[10] <= OUT_C1_12;
														ff_mul_3[11] <= OUT_C1_13;
														ff_mul_3[12] <= OUT_C1_14;
														ff_mul_3[13] <= OUT_C1_15;
														ff_mul_3[14] <= OUT_C1_0 ;
														ff_mul_3[15] <= OUT_C1_1 ;
													end
											'd3:	begin
														ff_mul_3[0]  <= OUT_C1_3 ;
														ff_mul_3[1]  <= OUT_C1_4 ;
														ff_mul_3[2]  <= OUT_C1_5 ;
														ff_mul_3[3]  <= OUT_C1_6 ;
														ff_mul_3[4]  <= OUT_C1_7 ;
														ff_mul_3[5]  <= OUT_C1_8 ;
														ff_mul_3[6]  <= OUT_C1_9 ;
														ff_mul_3[7]  <= OUT_C1_10;
														ff_mul_3[8]  <= OUT_C1_11;
														ff_mul_3[9]  <= OUT_C1_12;
														ff_mul_3[10] <= OUT_C1_13;
														ff_mul_3[11] <= OUT_C1_14;
														ff_mul_3[12] <= OUT_C1_15;
														ff_mul_3[13] <= OUT_C1_0 ;
														ff_mul_3[14] <= OUT_C1_1 ;
														ff_mul_3[15] <= OUT_C1_2 ;
													end
											'd4:	begin
														ff_mul_3[0]  <= OUT_C1_4 ;
														ff_mul_3[1]  <= OUT_C1_5 ;
														ff_mul_3[2]  <= OUT_C1_6 ;
														ff_mul_3[3]  <= OUT_C1_7 ;
														ff_mul_3[4]  <= OUT_C1_8 ;
														ff_mul_3[5]  <= OUT_C1_9 ;
														ff_mul_3[6]  <= OUT_C1_10;
														ff_mul_3[7]  <= OUT_C1_11;
														ff_mul_3[8]  <= OUT_C1_12;
														ff_mul_3[9]  <= OUT_C1_13;
														ff_mul_3[10] <= OUT_C1_14;
														ff_mul_3[11] <= OUT_C1_15;
														ff_mul_3[12] <= OUT_C1_0 ;
														ff_mul_3[13] <= OUT_C1_1 ;
														ff_mul_3[14] <= OUT_C1_2 ;
														ff_mul_3[15] <= OUT_C1_3 ;
													end
											'd5:	begin
														ff_mul_3[0]  <= OUT_C1_5 ;
														ff_mul_3[1]  <= OUT_C1_6 ;
														ff_mul_3[2]  <= OUT_C1_7 ;
														ff_mul_3[3]  <= OUT_C1_8 ;
														ff_mul_3[4]  <= OUT_C1_9 ;
														ff_mul_3[5]  <= OUT_C1_10;
														ff_mul_3[6]  <= OUT_C1_11;
														ff_mul_3[7]  <= OUT_C1_12;
														ff_mul_3[8]  <= OUT_C1_13;
														ff_mul_3[9]  <= OUT_C1_14;
														ff_mul_3[10] <= OUT_C1_15;
														ff_mul_3[11] <= OUT_C1_0 ;
														ff_mul_3[12] <= OUT_C1_1 ;
														ff_mul_3[13] <= OUT_C1_2 ;
														ff_mul_3[14] <= OUT_C1_3 ;
														ff_mul_3[15] <= OUT_C1_4 ;
													end
											'd6:	begin
														ff_mul_3[0]  <= OUT_C1_6 ;
														ff_mul_3[1]  <= OUT_C1_7 ;
														ff_mul_3[2]  <= OUT_C1_8 ;
														ff_mul_3[3]  <= OUT_C1_9 ;
														ff_mul_3[4]  <= OUT_C1_10;
														ff_mul_3[5]  <= OUT_C1_11;
														ff_mul_3[6]  <= OUT_C1_12;
														ff_mul_3[7]  <= OUT_C1_13;
														ff_mul_3[8]  <= OUT_C1_14;
														ff_mul_3[9]  <= OUT_C1_15;
														ff_mul_3[10] <= OUT_C1_0 ;
														ff_mul_3[11] <= OUT_C1_1 ;
														ff_mul_3[12] <= OUT_C1_2 ;
														ff_mul_3[13] <= OUT_C1_3 ;
														ff_mul_3[14] <= OUT_C1_4 ;
														ff_mul_3[15] <= OUT_C1_5 ;
													end
											'd7:	begin
														ff_mul_3[0]  <= OUT_C1_7 ;
														ff_mul_3[1]  <= OUT_C1_8 ;
														ff_mul_3[2]  <= OUT_C1_9 ;
														ff_mul_3[3]  <= OUT_C1_10;
														ff_mul_3[4]  <= OUT_C1_11;
														ff_mul_3[5]  <= OUT_C1_12;
														ff_mul_3[6]  <= OUT_C1_13;
														ff_mul_3[7]  <= OUT_C1_14;
														ff_mul_3[8]  <= OUT_C1_15;
														ff_mul_3[9]  <= OUT_C1_0 ;
														ff_mul_3[10] <= OUT_C1_1 ;
														ff_mul_3[11] <= OUT_C1_2 ;
														ff_mul_3[12] <= OUT_C1_3 ;
														ff_mul_3[13] <= OUT_C1_4 ;
														ff_mul_3[14] <= OUT_C1_5 ;
														ff_mul_3[15] <= OUT_C1_6 ;
													end
											'd8:	begin
														ff_mul_3[0]  <= OUT_C1_8 ;
														ff_mul_3[1]  <= OUT_C1_9 ;
														ff_mul_3[2]  <= OUT_C1_10;
														ff_mul_3[3]  <= OUT_C1_11;
														ff_mul_3[4]  <= OUT_C1_12;
														ff_mul_3[5]  <= OUT_C1_13;
														ff_mul_3[6]  <= OUT_C1_14;
														ff_mul_3[7]  <= OUT_C1_15;
														ff_mul_3[8]  <= OUT_C1_0 ;
														ff_mul_3[9]  <= OUT_C1_1 ;
														ff_mul_3[10] <= OUT_C1_2 ;
														ff_mul_3[11] <= OUT_C1_3 ;
														ff_mul_3[12] <= OUT_C1_4 ;
														ff_mul_3[13] <= OUT_C1_5 ;
														ff_mul_3[14] <= OUT_C1_6 ;
														ff_mul_3[15] <= OUT_C1_7 ;
													end
											'd9:	begin
														ff_mul_3[0]  <= OUT_C1_9 ;
														ff_mul_3[1]  <= OUT_C1_10;
														ff_mul_3[2]  <= OUT_C1_11;
														ff_mul_3[3]  <= OUT_C1_12;
														ff_mul_3[4]  <= OUT_C1_13;
														ff_mul_3[5]  <= OUT_C1_14;
														ff_mul_3[6]  <= OUT_C1_15;
														ff_mul_3[7]  <= OUT_C1_0 ;
														ff_mul_3[8]  <= OUT_C1_1 ;
														ff_mul_3[9]  <= OUT_C1_2 ;
														ff_mul_3[10] <= OUT_C1_3 ;
														ff_mul_3[11] <= OUT_C1_4 ;
														ff_mul_3[12] <= OUT_C1_5 ;
														ff_mul_3[13] <= OUT_C1_6 ;
														ff_mul_3[14] <= OUT_C1_7 ;
														ff_mul_3[15] <= OUT_C1_8 ; 
													end
											'd10:	begin
														ff_mul_3[0]  <= OUT_C1_10;
														ff_mul_3[1]  <= OUT_C1_11;
														ff_mul_3[2]  <= OUT_C1_12;
														ff_mul_3[3]  <= OUT_C1_13;
														ff_mul_3[4]  <= OUT_C1_14;
														ff_mul_3[5]  <= OUT_C1_15;
														ff_mul_3[6]  <= OUT_C1_0 ;
														ff_mul_3[7]  <= OUT_C1_1 ;
														ff_mul_3[8]  <= OUT_C1_2 ;
														ff_mul_3[9]  <= OUT_C1_3 ;
														ff_mul_3[10] <= OUT_C1_4 ;
														ff_mul_3[11] <= OUT_C1_5 ;
														ff_mul_3[12] <= OUT_C1_6 ;
														ff_mul_3[13] <= OUT_C1_7 ;
														ff_mul_3[14] <= OUT_C1_8 ;
														ff_mul_3[15] <= OUT_C1_9 ; 
													end
											'd11:	begin
														ff_mul_3[0]  <= OUT_C1_11;
														ff_mul_3[1]  <= OUT_C1_12;
														ff_mul_3[2]  <= OUT_C1_13;
														ff_mul_3[3]  <= OUT_C1_14;
														ff_mul_3[4]  <= OUT_C1_15;
														ff_mul_3[5]  <= OUT_C1_0 ;
														ff_mul_3[6]  <= OUT_C1_1 ;
														ff_mul_3[7]  <= OUT_C1_2 ;
														ff_mul_3[8]  <= OUT_C1_3 ;
														ff_mul_3[9]  <= OUT_C1_4 ;
														ff_mul_3[10] <= OUT_C1_5 ;
														ff_mul_3[11] <= OUT_C1_6 ;
														ff_mul_3[12] <= OUT_C1_7 ;
														ff_mul_3[13] <= OUT_C1_8 ;
														ff_mul_3[14] <= OUT_C1_9 ;
														ff_mul_3[15] <= OUT_C1_10; 
													end
											'd12:	begin
														ff_mul_3[0]  <= OUT_C1_12;
														ff_mul_3[1]  <= OUT_C1_13;
														ff_mul_3[2]  <= OUT_C1_14;
														ff_mul_3[3]  <= OUT_C1_15;
														ff_mul_3[4]  <= OUT_C1_0 ;
														ff_mul_3[5]  <= OUT_C1_1 ;
														ff_mul_3[6]  <= OUT_C1_2 ;
														ff_mul_3[7]  <= OUT_C1_3 ;
														ff_mul_3[8]  <= OUT_C1_4 ;
														ff_mul_3[9]  <= OUT_C1_5 ;
														ff_mul_3[10] <= OUT_C1_6 ;
														ff_mul_3[11] <= OUT_C1_7 ;
														ff_mul_3[12] <= OUT_C1_8 ;
														ff_mul_3[13] <= OUT_C1_9 ;
														ff_mul_3[14] <= OUT_C1_10;
														ff_mul_3[15] <= OUT_C1_11; 
													end
											'd13:	begin
														ff_mul_3[0]  <= OUT_C1_13;
														ff_mul_3[1]  <= OUT_C1_14;
														ff_mul_3[2]  <= OUT_C1_15;
														ff_mul_3[3]  <= OUT_C1_0 ;
														ff_mul_3[4]  <= OUT_C1_1 ;
														ff_mul_3[5]  <= OUT_C1_2 ;
														ff_mul_3[6]  <= OUT_C1_3 ;
														ff_mul_3[7]  <= OUT_C1_4 ;
														ff_mul_3[8]  <= OUT_C1_5 ;
														ff_mul_3[9]  <= OUT_C1_6 ;
														ff_mul_3[10] <= OUT_C1_7 ;
														ff_mul_3[11] <= OUT_C1_8 ;
														ff_mul_3[12] <= OUT_C1_9 ;
														ff_mul_3[13] <= OUT_C1_10;
														ff_mul_3[14] <= OUT_C1_11;
														ff_mul_3[15] <= OUT_C1_12; 
													end
											'd14:	begin
														ff_mul_3[0]  <= OUT_C1_14;
														ff_mul_3[1]  <= OUT_C1_15;
														ff_mul_3[2]  <= OUT_C1_0 ;
														ff_mul_3[3]  <= OUT_C1_1 ;
														ff_mul_3[4]  <= OUT_C1_2 ;
														ff_mul_3[5]  <= OUT_C1_3 ;
														ff_mul_3[6]  <= OUT_C1_4 ;
														ff_mul_3[7]  <= OUT_C1_5 ;
														ff_mul_3[8]  <= OUT_C1_6 ;
														ff_mul_3[9]  <= OUT_C1_7 ;
														ff_mul_3[10] <= OUT_C1_8 ;
														ff_mul_3[11] <= OUT_C1_9 ;
														ff_mul_3[12] <= OUT_C1_10;
														ff_mul_3[13] <= OUT_C1_11;
														ff_mul_3[14] <= OUT_C1_12;
														ff_mul_3[15] <= OUT_C1_13; 
													end
											'd15:	begin
														ff_mul_3[0]  <= OUT_C1_15;
														ff_mul_3[1]  <= OUT_C1_0 ;
														ff_mul_3[2]  <= OUT_C1_1 ;
														ff_mul_3[3]  <= OUT_C1_2 ;
														ff_mul_3[4]  <= OUT_C1_3 ;
														ff_mul_3[5]  <= OUT_C1_4 ;
														ff_mul_3[6]  <= OUT_C1_5 ;
														ff_mul_3[7]  <= OUT_C1_6 ;
														ff_mul_3[8]  <= OUT_C1_7 ;
														ff_mul_3[9]  <= OUT_C1_8 ;
														ff_mul_3[10] <= OUT_C1_9 ;
														ff_mul_3[11] <= OUT_C1_10;
														ff_mul_3[12] <= OUT_C1_11;
														ff_mul_3[13] <= OUT_C1_12;
														ff_mul_3[14] <= OUT_C1_13;
														ff_mul_3[15] <= OUT_C1_14; 
													end
											
							endcase							
						
						end		
			
			default:	begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_3[j] <= ff_mul_3[j];
							end
						end
		endcase
	end
end
//====================================================
//		      	MUL :ff_mul_4 (save tmp ans of multiplication)
//====================================================
//CONV : second row
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(j = 0; j < 16; j = j + 1) begin
			ff_mul_4[j] <= 0;
		end
	end
	else begin
		case(cs)
			IDLE:	begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_4[j] <= 0;
						end
					end
			CONV:	begin
						if(cur_row > 'd0 && cur_row < 'd17) begin
							if(cur_col > 'd0 && cur_col < 'd17) begin
								case(cur_col)
									'd1:	begin
												ff_mul_4[0] <= add_out_4;
												ff_mul_4[1] <= add_out_5;
											end
									'd16:	begin
												ff_mul_4[14] <= add_out_3;
												ff_mul_4[15] <= add_out_4;
											end
									default:begin
												ff_mul_4[cur_col-2] <= add_out_3;
												ff_mul_4[cur_col-1] <= add_out_4;
												ff_mul_4[cur_col] 	<= add_out_5;
											end
								endcase
							end
							else begin
								for(j = 0; j < 16; j = j + 1) begin
									ff_mul_4[j] <= ff_mul_4[j];
								end
							end
						end
						else begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_4[j] <= ff_mul_4[j];
							end
						end
					end
			WAIT_WRITE_CONV:// shift
					begin
						if(cnt_input == 'd0) begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_4[j] <= ff_mul_5[j];
							end
						end
						else begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_4[j] <= ff_mul_4[j];
							end			
						end
					end
			default:begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_4[j] <= ff_mul_4[j];
						end			
					end
		endcase
	end
end
//====================================================
//		      	ff_mul_5 : conv 3rd row
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(j = 0; j < 16; j = j + 1) begin
			ff_mul_5[j] <= 0;
		end
	end
	else begin
		case(cs)
			IDLE:	begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_5[j] <= 0;
						end
					end
			CONV:	begin
						if(cur_row > 'd0 && cur_row < 'd17) begin
							if(cur_col > 'd0 && cur_col < 'd17) begin
								case(cur_col)
									'd1:	begin
												ff_mul_5[0] <= add_out_7;
												ff_mul_5[1] <= add_out_8;
											end
									'd16:	begin
												ff_mul_5[14] <= add_out_6;
												ff_mul_5[15] <= add_out_7;
											end
									default:begin
												ff_mul_5[cur_col-2] <= add_out_6;
												ff_mul_5[cur_col-1] <= add_out_7;
												ff_mul_5[cur_col] 	<= add_out_8;
											end
								endcase
							end
							else begin
								for(j = 0; j < 16; j = j + 1) begin
									ff_mul_5[j] <= ff_mul_5[j];
								end
							end
						end
						else begin
							for(j = 0; j < 16; j = j + 1) begin
								ff_mul_5[j] <= ff_mul_5[j];
							end
						end
					end
			WAIT_WRITE_CONV:    //set to zero
					begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_5[j] <= 0;
						end
					end
			default:begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_mul_5[j] <= ff_mul_5[j];
						end			
					end
		endcase
	end
end
//====================================================
//		      	ff_conv_r : save 3*3 matrix
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(j = 0; j < 16; j = j + 1) begin
			ff_conv_r[j] <= 0;
		end
	end
	else begin
		case(cs)
			IDLE:	begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_conv_r[j] <= 0;
						end
					end
			LOAD_CONV:
						begin
							if(cur_row == 'd0) begin //only save once
								case(dr_col)
									'd0 :	begin
												ff_conv_r[0] <= OUT_Cr_0; 
												ff_conv_r[1] <= OUT_Cr_1; 
												ff_conv_r[2] <= OUT_Cr_2; 
												ff_conv_r[3] <= OUT_Cr_3; 
												ff_conv_r[4] <= OUT_Cr_4; 
												ff_conv_r[5] <= OUT_Cr_5; 
												ff_conv_r[6] <= OUT_Cr_6; 
												ff_conv_r[7] <= OUT_Cr_7; 
												ff_conv_r[8] <= OUT_Cr_8; 
											end
									'd1 :	begin
												ff_conv_r[0] <= OUT_Cr_1; 
												ff_conv_r[1] <= OUT_Cr_2; 
												ff_conv_r[2] <= OUT_Cr_3; 
												ff_conv_r[3] <= OUT_Cr_4; 
												ff_conv_r[4] <= OUT_Cr_5; 
												ff_conv_r[5] <= OUT_Cr_6; 
												ff_conv_r[6] <= OUT_Cr_7; 
												ff_conv_r[7] <= OUT_Cr_8; 
												ff_conv_r[8] <= OUT_Cr_9; 
											end
									'd2 :	begin
												ff_conv_r[0] <= OUT_Cr_2; 
												ff_conv_r[1] <= OUT_Cr_3; 
												ff_conv_r[2] <= OUT_Cr_4; 
												ff_conv_r[3] <= OUT_Cr_5; 
												ff_conv_r[4] <= OUT_Cr_6; 
												ff_conv_r[5] <= OUT_Cr_7; 
												ff_conv_r[6] <= OUT_Cr_8; 
												ff_conv_r[7] <= OUT_Cr_9; 
												ff_conv_r[8] <= OUT_Cr_10; 
											end
									'd3 :	begin
												ff_conv_r[0] <= OUT_Cr_3 ; 
												ff_conv_r[1] <= OUT_Cr_4 ; 
												ff_conv_r[2] <= OUT_Cr_5 ; 
												ff_conv_r[3] <= OUT_Cr_6 ; 
												ff_conv_r[4] <= OUT_Cr_7 ; 
												ff_conv_r[5] <= OUT_Cr_8 ; 
												ff_conv_r[6] <= OUT_Cr_9 ; 
												ff_conv_r[7] <= OUT_Cr_10; 
												ff_conv_r[8] <= OUT_Cr_11; 
											end
									'd4 :	begin
												ff_conv_r[0] <= OUT_Cr_4 ; 
												ff_conv_r[1] <= OUT_Cr_5 ; 
												ff_conv_r[2] <= OUT_Cr_6 ; 
												ff_conv_r[3] <= OUT_Cr_7 ; 
												ff_conv_r[4] <= OUT_Cr_8 ; 
												ff_conv_r[5] <= OUT_Cr_9 ; 
												ff_conv_r[6] <= OUT_Cr_10; 
												ff_conv_r[7] <= OUT_Cr_11; 
												ff_conv_r[8] <= OUT_Cr_12; 
											end
									'd5 :	begin
												ff_conv_r[0] <= OUT_Cr_5 ; 
												ff_conv_r[1] <= OUT_Cr_6 ; 
												ff_conv_r[2] <= OUT_Cr_7 ; 
												ff_conv_r[3] <= OUT_Cr_8 ; 
												ff_conv_r[4] <= OUT_Cr_9 ; 
												ff_conv_r[5] <= OUT_Cr_10; 
												ff_conv_r[6] <= OUT_Cr_11; 
												ff_conv_r[7] <= OUT_Cr_12; 
												ff_conv_r[8] <= OUT_Cr_13; 
											end
									'd6 :	begin
												ff_conv_r[0] <= OUT_Cr_6 ; 
												ff_conv_r[1] <= OUT_Cr_7 ; 
												ff_conv_r[2] <= OUT_Cr_8 ; 
												ff_conv_r[3] <= OUT_Cr_9 ; 
												ff_conv_r[4] <= OUT_Cr_10; 
												ff_conv_r[5] <= OUT_Cr_11; 
												ff_conv_r[6] <= OUT_Cr_12; 
												ff_conv_r[7] <= OUT_Cr_13; 
												ff_conv_r[8] <= OUT_Cr_14; 
											end
									'd7 :	begin
												ff_conv_r[0] <= OUT_Cr_7 ; 
												ff_conv_r[1] <= OUT_Cr_8 ; 
												ff_conv_r[2] <= OUT_Cr_9 ; 
												ff_conv_r[3] <= OUT_Cr_10; 
												ff_conv_r[4] <= OUT_Cr_11; 
												ff_conv_r[5] <= OUT_Cr_12; 
												ff_conv_r[6] <= OUT_Cr_13; 
												ff_conv_r[7] <= OUT_Cr_14; 
												ff_conv_r[8] <= OUT_Cr_15; 
											end
									'd8 :	begin
												ff_conv_r[0] <= OUT_Cr_8 ; 
												ff_conv_r[1] <= OUT_Cr_9 ; 
												ff_conv_r[2] <= OUT_Cr_10; 
												ff_conv_r[3] <= OUT_Cr_11; 
												ff_conv_r[4] <= OUT_Cr_12; 
												ff_conv_r[5] <= OUT_Cr_13; 
												ff_conv_r[6] <= OUT_Cr_14; 
												ff_conv_r[7] <= OUT_Cr_15; 
												ff_conv_r[8] <= OUT_Cr_0; 
											end
									'd9 :	begin
												ff_conv_r[0] <= OUT_Cr_9 ; 
												ff_conv_r[1] <= OUT_Cr_10; 
												ff_conv_r[2] <= OUT_Cr_11; 
												ff_conv_r[3] <= OUT_Cr_12; 
												ff_conv_r[4] <= OUT_Cr_13; 
												ff_conv_r[5] <= OUT_Cr_14; 
												ff_conv_r[6] <= OUT_Cr_15; 
												ff_conv_r[7] <= OUT_Cr_0; 
												ff_conv_r[8] <= OUT_Cr_1; 
											end
									'd10:	begin
												ff_conv_r[0] <= OUT_Cr_10; 
												ff_conv_r[1] <= OUT_Cr_11; 
												ff_conv_r[2] <= OUT_Cr_12; 
												ff_conv_r[3] <= OUT_Cr_13; 
												ff_conv_r[4] <= OUT_Cr_14; 
												ff_conv_r[5] <= OUT_Cr_15; 
												ff_conv_r[6] <= OUT_Cr_0; 
												ff_conv_r[7] <= OUT_Cr_1; 
												ff_conv_r[8] <= OUT_Cr_2; 
											end
									'd11:	begin
												ff_conv_r[0] <= OUT_Cr_11; 
												ff_conv_r[1] <= OUT_Cr_12; 
												ff_conv_r[2] <= OUT_Cr_13; 
												ff_conv_r[3] <= OUT_Cr_14; 
												ff_conv_r[4] <= OUT_Cr_15; 
												ff_conv_r[5] <= OUT_Cr_0; 
												ff_conv_r[6] <= OUT_Cr_1; 
												ff_conv_r[7] <= OUT_Cr_2; 
												ff_conv_r[8] <= OUT_Cr_3; 
											end
									'd12:	begin
												ff_conv_r[0] <= OUT_Cr_12; 
												ff_conv_r[1] <= OUT_Cr_13; 
												ff_conv_r[2] <= OUT_Cr_14; 
												ff_conv_r[3] <= OUT_Cr_15; 
												ff_conv_r[4] <= OUT_Cr_0; 
												ff_conv_r[5] <= OUT_Cr_1; 
												ff_conv_r[6] <= OUT_Cr_2; 
												ff_conv_r[7] <= OUT_Cr_3; 
												ff_conv_r[8] <= OUT_Cr_4; 
											end
									'd13:	begin
												ff_conv_r[0] <= OUT_Cr_13; 
												ff_conv_r[1] <= OUT_Cr_14; 
												ff_conv_r[2] <= OUT_Cr_15; 
												ff_conv_r[3] <= OUT_Cr_0 ; 
												ff_conv_r[4] <= OUT_Cr_1 ; 
												ff_conv_r[5] <= OUT_Cr_2 ; 
												ff_conv_r[6] <= OUT_Cr_3 ; 
												ff_conv_r[7] <= OUT_Cr_4 ; 
												ff_conv_r[8] <= OUT_Cr_5 ; 
											end
									'd14:	begin
												ff_conv_r[0] <= OUT_Cr_14; 
												ff_conv_r[1] <= OUT_Cr_15; 
												ff_conv_r[2] <= OUT_Cr_0 ; 
												ff_conv_r[3] <= OUT_Cr_1 ; 
												ff_conv_r[4] <= OUT_Cr_2 ; 
												ff_conv_r[5] <= OUT_Cr_3 ; 
												ff_conv_r[6] <= OUT_Cr_4 ; 
												ff_conv_r[7] <= OUT_Cr_5 ; 
												ff_conv_r[8] <= OUT_Cr_6 ; 
											end
									'd15:	begin
												ff_conv_r[0] <= OUT_Cr_15; 
												ff_conv_r[1] <= OUT_Cr_0 ; 
												ff_conv_r[2] <= OUT_Cr_1 ; 
												ff_conv_r[3] <= OUT_Cr_2 ; 
												ff_conv_r[4] <= OUT_Cr_3 ; 
												ff_conv_r[5] <= OUT_Cr_4 ; 
												ff_conv_r[6] <= OUT_Cr_5 ; 
												ff_conv_r[7] <= OUT_Cr_6 ; 
												ff_conv_r[8] <= OUT_Cr_7 ; 
											end
								endcase
													
							end
							else begin
								for(j = 0; j < 16; j = j + 1) begin
									ff_conv_r[j] <= ff_conv_r[j];
								end
							end
						end
			default:begin
						for(j = 0; j < 16; j = j + 1) begin
							ff_conv_r[j] <= ff_conv_r[j];
						end
					end
		endcase
	end
end
//====================================================
//		      	cnt_input
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_input <= 0;
	end
	else begin
		case(cs)
			IDLE: 				cnt_input <= 0;
			//G_INSTR_ADDR: 		cnt_input <= cnt_input + 'd1;
			//S_DATA_ADDR:		cnt_input <= arready_m_inf ? cnt_input + 'd1 : cnt_input;//record 1000, 1064, ...
			G_DATA:				cnt_input <= 	cnt_input == 'd15	? 'd0 : //set back to 0
												rvalid_m_inf[0]		? cnt_input + 'd1 : cnt_input;
			MUL:				cnt_input <= 0;
			CONV:				cnt_input <= 0;
			WAIT_WRITE:			cnt_input <= cnt_input + 'd1;
			WAIT_WRITE_CONV:	cnt_input <= cnt_input + 'd1;
			default:			cnt_input <= 0;
		endcase
	end
end

//====================================================
//		      	cnt_input_r : for dram_read
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_input_r <= 0;
	end
	else begin
		case(cs)
			IDLE: 			cnt_input_r <= 0;
			G_DATA:			cnt_input_r <= 	cnt_input_r == 'd15	? 'd0 : //set back to 0
											rvalid_m_inf[1]		? cnt_input_r + 'd1 : cnt_input_r;
			LOAD_CONV:		cnt_input_r <= cnt_input_r + 'd1;
			default:		cnt_input_r <= 0;
		endcase
	end
end
//====================================================
//		      	cnt_write
//====================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_write <= 0;
	end
	else begin
		case(cs)
			IDLE: 				cnt_write <= 0;
			MUL:				cnt_write <= wready_m_inf ? cnt_write + 'd1 : cnt_write;
			WAIT_WRITE:			cnt_write <= 0;
			CONV:				cnt_write <= wready_m_inf ? cnt_write + 'd1 : cnt_write;
			WAIT_WRITE_CONV:	cnt_write <= 0;
			default:			cnt_write <= cnt_write;
		endcase
	end
end
 
//====================================================
//		      	OUTPUT
//====================================================
always@(*) begin
	PRDATA = instr;
end
always@(*) begin
	PREADY = cs == OUTPUT ? 1 : 0 ;
end



//====================================================
//               cache : DRAM1
//====================================================

//address==================
always@(*) begin
	case(cs)
		G_DATA:		begin
						ADDR_C1_0  = dram1_addr[11:6]; // /4 : 000, 064, 128 -> 0, 16, 32;  /16: 0, 16, 32 -> 0, 1, 2
						ADDR_C1_1  = dram1_addr[11:6];
						ADDR_C1_2  = dram1_addr[11:6];
						ADDR_C1_3  = dram1_addr[11:6];
						ADDR_C1_4  = dram1_addr[11:6];
						ADDR_C1_5  = dram1_addr[11:6];					
						ADDR_C1_6  = dram1_addr[11:6];					
						ADDR_C1_7  = dram1_addr[11:6];					
						ADDR_C1_8  = dram1_addr[11:6];					
						ADDR_C1_9  = dram1_addr[11:6];					
						ADDR_C1_10 = dram1_addr[11:6];					
						ADDR_C1_11 = dram1_addr[11:6];					
						ADDR_C1_12 = dram1_addr[11:6];					
						ADDR_C1_13 = dram1_addr[11:6];					
						ADDR_C1_14 = dram1_addr[11:6];					
						ADDR_C1_15 = dram1_addr[11:6];					
						
					end
			//S_DATA_ADDR:		cs <= 	araddr_m_inf == 64'hffff_ffff_ffff_ffff ? (instr[1:0] == 2'b11 ? LOAD_CONV : LOAD_MUL) :
		S_DATA_ADDR:begin
						if(araddr_m_inf == 64'hffff_ffff_ffff_ffff ) begin//first load of MUL from d1 to ff_3
							if(instr[1:0] == 2'b00) begin //MUL
								ADDR_C1_0  = 'd0  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;  
								ADDR_C1_1  = 'd1  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_2  = 'd2  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_3  = 'd3  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_4  = 'd4  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_5  = 'd5  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_6  = 'd6  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_7  = 'd7  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_8  = 'd8  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_9  = 'd9  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_10 = 'd10 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_11 = 'd11 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_12 = 'd12 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_13 = 'd13 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_14 = 'd14 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_15 = 'd15 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
							end
							else begin // CONV
								ADDR_C1_0  = 'd0  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;  
								ADDR_C1_1  = 'd1  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_2  = 'd2  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_3  = 'd3  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_4  = 'd4  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
								ADDR_C1_5  = 'd5  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_6  = 'd6  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_7  = 'd7  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_8  = 'd8  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_9  = 'd9  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_10 = 'd10 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_11 = 'd11 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_12 = 'd12 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_13 = 'd13 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_14 = 'd14 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
								ADDR_C1_15 = 'd15 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
							end
						end
						else begin
							ADDR_C1_0  = 0; 
							ADDR_C1_1  = 0;
							ADDR_C1_2  = 0;
							ADDR_C1_3  = 0;
							ADDR_C1_4  = 0;
							ADDR_C1_5  = 0;					
							ADDR_C1_6  = 0;					
							ADDR_C1_7  = 0;					
							ADDR_C1_8  = 0;					
							ADDR_C1_9  = 0;					
							ADDR_C1_10 = 0;					
							ADDR_C1_11 = 0;					
							ADDR_C1_12 = 0;					
							ADDR_C1_13 = 0;					
							ADDR_C1_14 = 0;					
							ADDR_C1_15 = 0;					
						end
					end
 		WAIT_WRITE:	begin
						ADDR_C1_0  = 'd0  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;  
						ADDR_C1_1  = 'd1  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_2  = 'd2  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_3  = 'd3  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_4  = 'd4  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_5  = 'd5  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_6  = 'd6  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_7  = 'd7  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_8  = 'd8  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_9  = 'd9  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_10 = 'd10 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_11 = 'd11 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_12 = 'd12 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_13 = 'd13 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_14 = 'd14 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_15 = 'd15 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
					end
		
 		LOAD_MUL:	begin
						ADDR_C1_0  = 'd0  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;  
						ADDR_C1_1  = 'd1  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_2  = 'd2  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_3  = 'd3  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_4  = 'd4  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_5  = 'd5  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_6  = 'd6  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_7  = 'd7  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_8  = 'd8  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_9  = 'd9  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_10 = 'd10 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_11 = 'd11 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_12 = 'd12 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_13 = 'd13 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_14 = 'd14 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_15 = 'd15 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
					end
		
 		MUL:		begin
						//if(cur_row_r) begin//for 1 latency, otherwise will too soon 
							ADDR_C1_0  = 'd0  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;  
							ADDR_C1_1  = 'd1  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;
							ADDR_C1_2  = 'd2  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;
							ADDR_C1_3  = 'd3  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;
							ADDR_C1_4  = 'd4  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;
							ADDR_C1_5  = 'd5  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_6  = 'd6  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_7  = 'd7  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_8  = 'd8  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_9  = 'd9  < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_10 = 'd10 < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_11 = 'd11 < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_12 = 'd12 < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_13 = 'd13 < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_14 = 'd14 < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
							ADDR_C1_15 = 'd15 < d1_col ? cur_row + d1_row - 'd1: cur_row + d1_row - 'd2;					
 					end
		
 		LOAD_CONV:	begin
						ADDR_C1_0  = 'd0  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;  
						ADDR_C1_1  = 'd1  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_2  = 'd2  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_3  = 'd3  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_4  = 'd4  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_5  = 'd5  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_6  = 'd6  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_7  = 'd7  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_8  = 'd8  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_9  = 'd9  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_10 = 'd10 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_11 = 'd11 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_12 = 'd12 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_13 = 'd13 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_14 = 'd14 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_15 = 'd15 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
					end
 		
		WAIT_WRITE_CONV:	
					begin
						ADDR_C1_0  = 'd0  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;  
						ADDR_C1_1  = 'd1  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_2  = 'd2  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_3  = 'd3  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_4  = 'd4  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;
						ADDR_C1_5  = 'd5  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_6  = 'd6  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_7  = 'd7  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_8  = 'd8  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_9  = 'd9  < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_10 = 'd10 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_11 = 'd11 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_12 = 'd12 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_13 = 'd13 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_14 = 'd14 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
						ADDR_C1_15 = 'd15 < d1_col ? cur_row + 'd1 + d1_row : cur_row + d1_row ;					
					end
			CONV:	begin
						ADDR_C1_0  = 'd0  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;  
						ADDR_C1_1  = 'd1  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;
						ADDR_C1_2  = 'd2  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;
						ADDR_C1_3  = 'd3  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;
						ADDR_C1_4  = 'd4  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;
						ADDR_C1_5  = 'd5  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_6  = 'd6  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_7  = 'd7  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_8  = 'd8  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_9  = 'd9  < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_10 = 'd10 < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_11 = 'd11 < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_12 = 'd12 < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_13 = 'd13 < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_14 = 'd14 < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
						ADDR_C1_15 = 'd15 < d1_col ? cur_row - 'd2 + d1_row : cur_row + d1_row - 'd3;					
					end
		default:	begin
						ADDR_C1_0  = 0; 
						ADDR_C1_1  = 0;
						ADDR_C1_2  = 0;
						ADDR_C1_3  = 0;
						ADDR_C1_4  = 0;
						ADDR_C1_5  = 0;					
						ADDR_C1_6  = 0;					
						ADDR_C1_7  = 0;					
						ADDR_C1_8  = 0;					
						ADDR_C1_9  = 0;					
						ADDR_C1_10 = 0;					
						ADDR_C1_11 = 0;					
						ADDR_C1_12 = 0;					
						ADDR_C1_13 = 0;					
						ADDR_C1_14 = 0;					
						ADDR_C1_15 = 0;					
					end
	endcase	
end
//data=====================
always@(*) begin
	case(cs)
		G_DATA:		begin
						//IN_C1 	= rdata_m_inf[31:0];
						IN_C1_0  = rdata_m_inf[31:0];
					    IN_C1_1  = rdata_m_inf[31:0];
					    IN_C1_2  = rdata_m_inf[31:0];
					    IN_C1_3  = rdata_m_inf[31:0];
					    IN_C1_4  = rdata_m_inf[31:0];
					    IN_C1_5  = rdata_m_inf[31:0];
					    IN_C1_6  = rdata_m_inf[31:0];
					    IN_C1_7  = rdata_m_inf[31:0];
					    IN_C1_8  = rdata_m_inf[31:0];
					    IN_C1_9  = rdata_m_inf[31:0];
					    IN_C1_10 = rdata_m_inf[31:0];
					    IN_C1_11 = rdata_m_inf[31:0];
					    IN_C1_12 = rdata_m_inf[31:0];
					    IN_C1_13 = rdata_m_inf[31:0];
					    IN_C1_14 = rdata_m_inf[31:0];
					    IN_C1_15 = rdata_m_inf[31:0];
					end
		MUL:		begin//assign awaddr_m_inf 	= {16'h0, 4'd1, write_row, d1_col, 2'b00}; 
/* 						IN_C1_0  = ff_mul_1[(16 + dr_col) % 16];
						IN_C1_1  = ff_mul_1[(17 + dr_col) % 16]; 
						IN_C1_2  = ff_mul_1[(18 + dr_col) % 16]; 
						IN_C1_3  = ff_mul_1[(19 + dr_col) % 16]; 
						IN_C1_4  = ff_mul_1[(20 + dr_col) % 16]; 
						IN_C1_5  = ff_mul_1[(21 + dr_col) % 16]; 
						IN_C1_6  = ff_mul_1[(22 + dr_col) % 16]; 
						IN_C1_7  = ff_mul_1[(23 + dr_col) % 16]; 
						IN_C1_8  = ff_mul_1[(24 + dr_col) % 16]; 
						IN_C1_9  = ff_mul_1[(25 + dr_col) % 16]; 
						IN_C1_10 = ff_mul_1[(26 + dr_col) % 16]; 
						IN_C1_11 = ff_mul_1[(27 + dr_col) % 16]; 
						IN_C1_12 = ff_mul_1[(28 + dr_col) % 16]; 
						IN_C1_13 = ff_mul_1[(29 + dr_col) % 16]; 
						IN_C1_14 = ff_mul_1[(30 + dr_col) % 16]; 
						IN_C1_15 = ff_mul_1[(31 + dr_col) % 16]; 
*/					
						IN_C1_0  = ff_mul_1[(16 - d1_col) % 16];
						IN_C1_1  = ff_mul_1[(17 - d1_col) % 16]; 
						IN_C1_2  = ff_mul_1[(18 - d1_col) % 16]; 
						IN_C1_3  = ff_mul_1[(19 - d1_col) % 16]; 
						IN_C1_4  = ff_mul_1[(20 - d1_col) % 16]; 
						IN_C1_5  = ff_mul_1[(21 - d1_col) % 16]; 
						IN_C1_6  = ff_mul_1[(22 - d1_col) % 16]; 
						IN_C1_7  = ff_mul_1[(23 - d1_col) % 16]; 
						IN_C1_8  = ff_mul_1[(24 - d1_col) % 16]; 
						IN_C1_9  = ff_mul_1[(25 - d1_col) % 16]; 
						IN_C1_10 = ff_mul_1[(26 - d1_col) % 16]; 
						IN_C1_11 = ff_mul_1[(27 - d1_col) % 16]; 
						IN_C1_12 = ff_mul_1[(28 - d1_col) % 16]; 
						IN_C1_13 = ff_mul_1[(29 - d1_col) % 16]; 
						IN_C1_14 = ff_mul_1[(30 - d1_col) % 16]; 
						IN_C1_15 = ff_mul_1[(31 - d1_col) % 16]; 
					end
		CONV:		begin//assign awaddr_m_inf 	= {16'h0, 4'd1, write_row, d1_col, 2'b00}; 
						IN_C1_0  = ff_mul_1[(16 - d1_col) % 16];
						IN_C1_1  = ff_mul_1[(17 - d1_col) % 16]; 
						IN_C1_2  = ff_mul_1[(18 - d1_col) % 16]; 
						IN_C1_3  = ff_mul_1[(19 - d1_col) % 16]; 
						IN_C1_4  = ff_mul_1[(20 - d1_col) % 16]; 
						IN_C1_5  = ff_mul_1[(21 - d1_col) % 16]; 
						IN_C1_6  = ff_mul_1[(22 - d1_col) % 16]; 
						IN_C1_7  = ff_mul_1[(23 - d1_col) % 16]; 
						IN_C1_8  = ff_mul_1[(24 - d1_col) % 16]; 
						IN_C1_9  = ff_mul_1[(25 - d1_col) % 16]; 
						IN_C1_10 = ff_mul_1[(26 - d1_col) % 16]; 
						IN_C1_11 = ff_mul_1[(27 - d1_col) % 16]; 
						IN_C1_12 = ff_mul_1[(28 - d1_col) % 16]; 
						IN_C1_13 = ff_mul_1[(29 - d1_col) % 16]; 
						IN_C1_14 = ff_mul_1[(30 - d1_col) % 16]; 
						IN_C1_15 = ff_mul_1[(31 - d1_col) % 16]; 
					end
		default:	begin
						IN_C1_0  = 0;
					    IN_C1_1  = 0;
					    IN_C1_2  = 0;
					    IN_C1_3  = 0;
					    IN_C1_4  = 0;
					    IN_C1_5  = 0;
					    IN_C1_6  = 0;
					    IN_C1_7  = 0;
					    IN_C1_8  = 0;
					    IN_C1_9  = 0;
					    IN_C1_10 = 0;
					    IN_C1_11 = 0;
					    IN_C1_12 = 0;
					    IN_C1_13 = 0;
					    IN_C1_14 = 0;
					    IN_C1_15 = 0;
					end
	endcase	
end

//control==================
always@(*) begin
	case(cs)
		G_DATA:	begin
					WEN_C1_0	= rvalid_m_inf[0] && (cnt_input == 'd0)		?	'd0: 'd1;
					WEN_C1_1 	= rvalid_m_inf[0] && (cnt_input == 'd1 )	?	'd0: 'd1;
					WEN_C1_2 	= rvalid_m_inf[0] && (cnt_input == 'd2 )	?	'd0: 'd1;
					WEN_C1_3 	= rvalid_m_inf[0] && (cnt_input == 'd3 )	?	'd0: 'd1;
					WEN_C1_4 	= rvalid_m_inf[0] && (cnt_input == 'd4 )	?	'd0: 'd1;
					WEN_C1_5 	= rvalid_m_inf[0] && (cnt_input == 'd5 )	?	'd0: 'd1;
					WEN_C1_6 	= rvalid_m_inf[0] && (cnt_input == 'd6 )	?	'd0: 'd1;
					WEN_C1_7 	= rvalid_m_inf[0] && (cnt_input == 'd7 )	?	'd0: 'd1;
					WEN_C1_8 	= rvalid_m_inf[0] && (cnt_input == 'd8 )	?	'd0: 'd1;
					WEN_C1_9 	= rvalid_m_inf[0] && (cnt_input == 'd9 )	?	'd0: 'd1;
					WEN_C1_10	= rvalid_m_inf[0] && (cnt_input == 'd10)	?	'd0: 'd1;
					WEN_C1_11	= rvalid_m_inf[0] && (cnt_input == 'd11)	?	'd0: 'd1;
					WEN_C1_12	= rvalid_m_inf[0] && (cnt_input == 'd12)	?	'd0: 'd1;
					WEN_C1_13	= rvalid_m_inf[0] && (cnt_input == 'd13)	?	'd0: 'd1;
					WEN_C1_14	= rvalid_m_inf[0] && (cnt_input == 'd14)	?	'd0: 'd1;
					WEN_C1_15	= rvalid_m_inf[0] && (cnt_input == 'd15)	?	'd0: 'd1;		
				end
		MUL:	begin//write one cycle is enough
					if(cur_row > 'd1 && cur_row < 'd18) begin
						WEN_C1_0 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_1 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_2 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_3 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_4 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_5 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_6 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_7 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_8 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_9 	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_10	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_11	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_12	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_13	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_14	= cur_row_r == 'd0 ? 'd0 : 'd1;
						WEN_C1_15	= cur_row_r == 'd0 ? 'd0 : 'd1;		
					end
					else begin
						WEN_C1_0  = 'd1;
						WEN_C1_1  = 'd1;
						WEN_C1_2  = 'd1;
						WEN_C1_3  = 'd1;
						WEN_C1_4  = 'd1;
						WEN_C1_5  = 'd1;
						WEN_C1_6  = 'd1;
						WEN_C1_7  = 'd1;
						WEN_C1_8  = 'd1;
						WEN_C1_9  = 'd1;
						WEN_C1_10 = 'd1;
						WEN_C1_11 = 'd1;
						WEN_C1_12 = 'd1;
						WEN_C1_13 = 'd1;
						WEN_C1_14 = 'd1;
						WEN_C1_15 = 'd1;		
					end
				end
		CONV:	begin//write one cycle is enough
					if(cur_row > 'd2 && cur_row < 'd19) begin
						WEN_C1_0 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_1 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_2 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_3 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_4 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_5 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_6 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_7 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_8 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_9 	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_10	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_11	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_12	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_13	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_14	= cur_col == 'd0 ? 'd0 : 'd1;
						WEN_C1_15	= cur_col == 'd0 ? 'd0 : 'd1;		
					end
					else begin
						WEN_C1_0  = 'd1;
						WEN_C1_1  = 'd1;
						WEN_C1_2  = 'd1;
						WEN_C1_3  = 'd1;
						WEN_C1_4  = 'd1;
						WEN_C1_5  = 'd1;
						WEN_C1_6  = 'd1;
						WEN_C1_7  = 'd1;
						WEN_C1_8  = 'd1;
						WEN_C1_9  = 'd1;
						WEN_C1_10 = 'd1;
						WEN_C1_11 = 'd1;
						WEN_C1_12 = 'd1;
						WEN_C1_13 = 'd1;
						WEN_C1_14 = 'd1;
						WEN_C1_15 = 'd1;		
					end
				end
		default:begin//read
					WEN_C1_0  = 'd1;
					WEN_C1_1  = 'd1;
					WEN_C1_2  = 'd1;
					WEN_C1_3  = 'd1;
					WEN_C1_4  = 'd1;
					WEN_C1_5  = 'd1;
					WEN_C1_6  = 'd1;
					WEN_C1_7  = 'd1;
					WEN_C1_8  = 'd1;
					WEN_C1_9  = 'd1;
					WEN_C1_10 = 'd1;
					WEN_C1_11 = 'd1;
					WEN_C1_12 = 'd1;
					WEN_C1_13 = 'd1;
					WEN_C1_14 = 'd1;
					WEN_C1_15 = 'd1;		
				end
	endcase	
end
//====================================================
//               cache : DRAM_read
//====================================================
//address==================
always@(*) begin
	case(cs)
		G_DATA:		begin
						ADDR_Cr_0  = dramr_addr[11:6];// /4 : 000, 064, 128 -> 0, 16, 32;  /16: 0, 16, 32 -> 0, 1, 2
		                ADDR_Cr_1  = dramr_addr[11:6];
		                ADDR_Cr_2  = dramr_addr[11:6];
		                ADDR_Cr_3  = dramr_addr[11:6];
		                ADDR_Cr_4  = dramr_addr[11:6];
		                ADDR_Cr_5  = dramr_addr[11:6];
		                ADDR_Cr_6  = dramr_addr[11:6];
		                ADDR_Cr_7  = dramr_addr[11:6];
		                ADDR_Cr_8  = dramr_addr[11:6];
		                ADDR_Cr_9  = dramr_addr[11:6];
		                ADDR_Cr_10 = dramr_addr[11:6];
		                ADDR_Cr_11 = dramr_addr[11:6];
		                ADDR_Cr_12 = dramr_addr[11:6];
		                ADDR_Cr_13 = dramr_addr[11:6];
		                ADDR_Cr_14 = dramr_addr[11:6];
		                ADDR_Cr_15 = dramr_addr[11:6];
					end
		MUL:		begin
						ADDR_Cr_0  = 'd0  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;  
						ADDR_Cr_1  = 'd1  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;
						ADDR_Cr_2  = 'd2  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;
						ADDR_Cr_3  = 'd3  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;
						ADDR_Cr_4  = 'd4  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;
						ADDR_Cr_5  = 'd5  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_6  = 'd6  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_7  = 'd7  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_8  = 'd8  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_9  = 'd9  < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_10 = 'd10 < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_11 = 'd11 < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_12 = 'd12 < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_13 = 'd13 < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_14 = 'd14 < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
						ADDR_Cr_15 = 'd15 < dr_col ? cur_row_r + 'd1 + dr_row : cur_row_r + dr_row;					
					end
		//for LOAD_CONV
		S_DATA_ADDR:begin
						if(araddr_m_inf == 64'hffff_ffff_ffff_ffff && instr[1:0] == 2'b11) begin
							ADDR_Cr_0  = ('d0  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r; 
							ADDR_Cr_1  = ('d1  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
							ADDR_Cr_2  = ('d2  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
							ADDR_Cr_3  = ('d3  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
							ADDR_Cr_4  = ('d4  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
							ADDR_Cr_5  = ('d5  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_6  = ('d6  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_7  = ('d7  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_8  = ('d8  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_9  = ('d9  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_10 = ('d10 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_11 = ('d11 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_12 = ('d12 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_13 = ('d13 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_14 = ('d14 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
							ADDR_Cr_15 = ('d15 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						end
						else begin
							ADDR_Cr_0  = 0; 
							ADDR_Cr_1  = 0;
							ADDR_Cr_2  = 0;
							ADDR_Cr_3  = 0;
							ADDR_Cr_4  = 0;
							ADDR_Cr_5  = 0;
							ADDR_Cr_6  = 0;
							ADDR_Cr_7  = 0;
							ADDR_Cr_8  = 0;
							ADDR_Cr_9  = 0;
							ADDR_Cr_10 = 0;
							ADDR_Cr_11 = 0;
							ADDR_Cr_12 = 0;
							ADDR_Cr_13 = 0;
							ADDR_Cr_14 = 0;
							ADDR_Cr_15 = 0;	
						end
					end
/* 		LOAD_CONV:	begin
						ADDR_Cr_0  = ('d0  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r; 
						ADDR_Cr_1  = ('d1  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
						ADDR_Cr_2  = ('d2  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
						ADDR_Cr_3  = ('d3  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
						ADDR_Cr_4  = ('d4  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;
						ADDR_Cr_5  = ('d5  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_6  = ('d6  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_7  = ('d7  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_8  = ('d8  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_9  = ('d9  < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_10 = ('d10 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_11 = ('d11 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_12 = ('d12 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_13 = ('d13 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_14 = ('d14 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
						ADDR_Cr_15 = ('d15 < dr_col ? dr_row + 'd1 : dr_row) + cnt_input_r;	
					end
 */		default:	begin
						ADDR_Cr_0  = 0; 
		                ADDR_Cr_1  = 0;
		                ADDR_Cr_2  = 0;
		                ADDR_Cr_3  = 0;
		                ADDR_Cr_4  = 0;
		                ADDR_Cr_5  = 0;
		                ADDR_Cr_6  = 0;
		                ADDR_Cr_7  = 0;
		                ADDR_Cr_8  = 0;
		                ADDR_Cr_9  = 0;
		                ADDR_Cr_10 = 0;
		                ADDR_Cr_11 = 0;
		                ADDR_Cr_12 = 0;
		                ADDR_Cr_13 = 0;
		                ADDR_Cr_14 = 0;
		                ADDR_Cr_15 = 0;	
					end
	endcase	
end
//data=====================
always@(*) begin
	case(cs)
		G_DATA:		IN_Cr 	= rdata_m_inf[63:32];
		default:	IN_Cr 	= 0;
	endcase	
end
//control==================
always@(*) begin
	case(cs)
		G_DATA:	begin
					WEN_Cr_0	= rvalid_m_inf[1] && (cnt_input_r == 'd0)	?	'd0: 'd1;
					WEN_Cr_1 	= rvalid_m_inf[1] && (cnt_input_r == 'd1 )	?	'd0: 'd1;
					WEN_Cr_2 	= rvalid_m_inf[1] && (cnt_input_r == 'd2 )	?	'd0: 'd1;
					WEN_Cr_3 	= rvalid_m_inf[1] && (cnt_input_r == 'd3 )	?	'd0: 'd1;
					WEN_Cr_4 	= rvalid_m_inf[1] && (cnt_input_r == 'd4 )	?	'd0: 'd1;
					WEN_Cr_5 	= rvalid_m_inf[1] && (cnt_input_r == 'd5 )	?	'd0: 'd1;
					WEN_Cr_6 	= rvalid_m_inf[1] && (cnt_input_r == 'd6 )	?	'd0: 'd1;
					WEN_Cr_7 	= rvalid_m_inf[1] && (cnt_input_r == 'd7 )	?	'd0: 'd1;
					WEN_Cr_8 	= rvalid_m_inf[1] && (cnt_input_r == 'd8 )	?	'd0: 'd1;
					WEN_Cr_9 	= rvalid_m_inf[1] && (cnt_input_r == 'd9 )	?	'd0: 'd1;
					WEN_Cr_10	= rvalid_m_inf[1] && (cnt_input_r == 'd10)	?	'd0: 'd1;
					WEN_Cr_11	= rvalid_m_inf[1] && (cnt_input_r == 'd11)	?	'd0: 'd1;
					WEN_Cr_12	= rvalid_m_inf[1] && (cnt_input_r == 'd12)	?	'd0: 'd1;
					WEN_Cr_13	= rvalid_m_inf[1] && (cnt_input_r == 'd13)	?	'd0: 'd1;
					WEN_Cr_14	= rvalid_m_inf[1] && (cnt_input_r == 'd14)	?	'd0: 'd1;
					WEN_Cr_15	= rvalid_m_inf[1] && (cnt_input_r == 'd15)	?	'd0: 'd1;		
				end
		default:begin//read
					WEN_Cr_0  = 'd1;
					WEN_Cr_1  = 'd1;
					WEN_Cr_2  = 'd1;
					WEN_Cr_3  = 'd1;
					WEN_Cr_4  = 'd1;
					WEN_Cr_5  = 'd1;
					WEN_Cr_6  = 'd1;
					WEN_Cr_7  = 'd1;
					WEN_Cr_8  = 'd1;
					WEN_Cr_9  = 'd1;
					WEN_Cr_10 = 'd1;
					WEN_Cr_11 = 'd1;
					WEN_Cr_12 = 'd1;
					WEN_Cr_13 = 'd1;
					WEN_Cr_14 = 'd1;
					WEN_Cr_15 = 'd1;		
				end
	endcase	
end
DRAM C1_0 ( .Q(OUT_C1_0),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_0 ),  .A(ADDR_C1_0 ),  .D(IN_C1_0 ),  .OEN(1'd0));
DRAM C1_1 ( .Q(OUT_C1_1),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_1 ),  .A(ADDR_C1_1 ),  .D(IN_C1_1 ),  .OEN(1'd0));
DRAM C1_2 ( .Q(OUT_C1_2),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_2 ),  .A(ADDR_C1_2 ),  .D(IN_C1_2 ),  .OEN(1'd0));
DRAM C1_3 ( .Q(OUT_C1_3),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_3 ),  .A(ADDR_C1_3 ),  .D(IN_C1_3 ),  .OEN(1'd0));
DRAM C1_4 ( .Q(OUT_C1_4),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_4 ),  .A(ADDR_C1_4 ),  .D(IN_C1_4 ),  .OEN(1'd0));
DRAM C1_5 ( .Q(OUT_C1_5),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_5 ),  .A(ADDR_C1_5 ),  .D(IN_C1_5 ),  .OEN(1'd0));
DRAM C1_6 ( .Q(OUT_C1_6),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_6 ),  .A(ADDR_C1_6 ),  .D(IN_C1_6 ),  .OEN(1'd0));
DRAM C1_7 ( .Q(OUT_C1_7),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_7 ),  .A(ADDR_C1_7 ),  .D(IN_C1_7 ),  .OEN(1'd0));
DRAM C1_8 ( .Q(OUT_C1_8),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_8 ),  .A(ADDR_C1_8 ),  .D(IN_C1_8 ),  .OEN(1'd0));
DRAM C1_9 ( .Q(OUT_C1_9),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_9 ),  .A(ADDR_C1_9 ),  .D(IN_C1_9 ),  .OEN(1'd0));
DRAM C1_10( .Q(OUT_C1_10), .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_10),  .A(ADDR_C1_10),  .D(IN_C1_10),  .OEN(1'd0));
DRAM C1_11( .Q(OUT_C1_11), .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_11),  .A(ADDR_C1_11),  .D(IN_C1_11),  .OEN(1'd0));
DRAM C1_12( .Q(OUT_C1_12), .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_12),  .A(ADDR_C1_12),  .D(IN_C1_12),  .OEN(1'd0));
DRAM C1_13( .Q(OUT_C1_13), .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_13),  .A(ADDR_C1_13),  .D(IN_C1_13),  .OEN(1'd0));
DRAM C1_14( .Q(OUT_C1_14), .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_14),  .A(ADDR_C1_14),  .D(IN_C1_14),  .OEN(1'd0));
DRAM C1_15( .Q(OUT_C1_15), .CLK(clk), .CEN(1'd0),  .WEN(WEN_C1_15),  .A(ADDR_C1_15),  .D(IN_C1_15),  .OEN(1'd0));

DRAM Cr_0 ( .Q(OUT_Cr_0),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_0 ),  .A(ADDR_Cr_0 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_1 ( .Q(OUT_Cr_1),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_1 ),  .A(ADDR_Cr_1 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_2 ( .Q(OUT_Cr_2),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_2 ),  .A(ADDR_Cr_2 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_3 ( .Q(OUT_Cr_3),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_3 ),  .A(ADDR_Cr_3 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_4 ( .Q(OUT_Cr_4),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_4 ),  .A(ADDR_Cr_4 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_5 ( .Q(OUT_Cr_5),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_5 ),  .A(ADDR_Cr_5 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_6 ( .Q(OUT_Cr_6),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_6 ),  .A(ADDR_Cr_6 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_7 ( .Q(OUT_Cr_7),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_7 ),  .A(ADDR_Cr_7 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_8 ( .Q(OUT_Cr_8),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_8 ),  .A(ADDR_Cr_8 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_9 ( .Q(OUT_Cr_9),  .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_9 ),  .A(ADDR_Cr_9 ),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_10( .Q(OUT_Cr_10), .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_10),  .A(ADDR_Cr_10),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_11( .Q(OUT_Cr_11), .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_11),  .A(ADDR_Cr_11),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_12( .Q(OUT_Cr_12), .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_12),  .A(ADDR_Cr_12),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_13( .Q(OUT_Cr_13), .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_13),  .A(ADDR_Cr_13),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_14( .Q(OUT_Cr_14), .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_14),  .A(ADDR_Cr_14),  .D(IN_Cr),  .OEN(1'd0));
DRAM Cr_15( .Q(OUT_Cr_15), .CLK(clk), .CEN(1'd0),  .WEN(WEN_Cr_15),  .A(ADDR_Cr_15),  .D(IN_Cr),  .OEN(1'd0));



endmodule








