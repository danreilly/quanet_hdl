
`timescale 1ns/100ps

module system_top #(
    // FW and board IDs
    parameter FPGA_ID = 32'h4730093,
    parameter FW_ID = 32'h00000000,
    parameter FW_VER = 32'h00_00_01_00,
    parameter BOARD_ID = 32'h10ee_906a,
    parameter BOARD_VER = 32'h01_00_00_00,
    parameter BUILD_DATE = 32'd602976000,
    parameter GIT_HASH = 32'hdce357bf,
    parameter RELEASE_INFO = 32'h00000000,

    // Board configuration
    parameter TDMA_BER_ENABLE = 0,

    // Structural configuration
    parameter IF_COUNT = 2,
    parameter PORTS_PER_IF = 1,
    parameter SCHED_PER_IF = PORTS_PER_IF,
    parameter PORT_MASK = 0,

    // Clock configuration
    parameter CLK_PERIOD_NS_NUM = 4,
    parameter CLK_PERIOD_NS_DENOM = 1,

    // PTP configuration
    parameter PTP_CLOCK_PIPELINE = 0,
    parameter PTP_CLOCK_CDC_PIPELINE = 0,
    parameter PTP_PORT_CDC_PIPELINE = 0,
    parameter PTP_PEROUT_ENABLE = 1,
    parameter PTP_PEROUT_COUNT = 1,

    // Queue manager configuration
    parameter EVENT_QUEUE_OP_TABLE_SIZE = 32,
    parameter TX_QUEUE_OP_TABLE_SIZE = 32,
    parameter RX_QUEUE_OP_TABLE_SIZE = 32,
    parameter CQ_OP_TABLE_SIZE = 32,
    parameter EQN_WIDTH = 5,
    parameter TX_QUEUE_INDEX_WIDTH = 13,
    parameter RX_QUEUE_INDEX_WIDTH = 8,
    parameter CQN_WIDTH = (TX_QUEUE_INDEX_WIDTH > RX_QUEUE_INDEX_WIDTH ? TX_QUEUE_INDEX_WIDTH : RX_QUEUE_INDEX_WIDTH) + 1,
    parameter EQ_PIPELINE = 3,
    parameter TX_QUEUE_PIPELINE = 3+(TX_QUEUE_INDEX_WIDTH > 12 ? TX_QUEUE_INDEX_WIDTH-12 : 0),
    parameter RX_QUEUE_PIPELINE = 3+(RX_QUEUE_INDEX_WIDTH > 12 ? RX_QUEUE_INDEX_WIDTH-12 : 0),
    parameter CQ_PIPELINE = 3+(CQN_WIDTH > 12 ? CQN_WIDTH-12 : 0),

    // TX and RX engine configuration
    parameter TX_DESC_TABLE_SIZE = 32,
    parameter RX_DESC_TABLE_SIZE = 32,
    parameter RX_INDIR_TBL_ADDR_WIDTH = RX_QUEUE_INDEX_WIDTH > 8 ? 8 : RX_QUEUE_INDEX_WIDTH,

    // Scheduler configuration
    parameter TX_SCHEDULER_OP_TABLE_SIZE = TX_DESC_TABLE_SIZE,
    parameter TX_SCHEDULER_PIPELINE = TX_QUEUE_PIPELINE,
    parameter TDMA_INDEX_WIDTH = 6,

    // Interface configuration
    parameter PTP_TS_ENABLE = 1,
    parameter TX_CPL_FIFO_DEPTH = 32,
    parameter TX_CHECKSUM_ENABLE = 1,
    parameter RX_HASH_ENABLE = 1,
    parameter RX_CHECKSUM_ENABLE = 1,
    parameter ENABLE_PADDING = 1,
    parameter ENABLE_DIC = 1,
    parameter MIN_FRAME_LENGTH = 64,
    parameter TX_FIFO_DEPTH = 32768,
    parameter RX_FIFO_DEPTH = 32768,
    parameter MAX_TX_SIZE = 9214,
    parameter MAX_RX_SIZE = 9214,
    parameter TX_RAM_SIZE = 32768,
    parameter RX_RAM_SIZE = 32768,

    // RAM configuration
    parameter DDR_CH = 1,
    parameter DDR_ENABLE = 0,
    parameter AXI_DDR_DATA_WIDTH = 512,
    parameter AXI_DDR_ADDR_WIDTH = 31,
    parameter AXI_DDR_ID_WIDTH = 8,
    parameter AXI_DDR_MAX_BURST_LEN = 256,
    parameter AXI_DDR_NARROW_BURST = 0,

    // Application block configuration
    parameter APP_ID = 32'h00000000,
    parameter APP_ENABLE = 0,
    parameter APP_CTRL_ENABLE = 1,
    parameter APP_DMA_ENABLE = 1,
    parameter APP_AXIS_DIRECT_ENABLE = 1,
    parameter APP_AXIS_SYNC_ENABLE = 1,
    parameter APP_AXIS_IF_ENABLE = 1,
    parameter APP_STAT_ENABLE = 1,

    // DMA interface configuration
    parameter DMA_IMM_ENABLE = 0,
    parameter DMA_IMM_WIDTH = 32,
    parameter DMA_LEN_WIDTH = 16,
    parameter DMA_TAG_WIDTH = 16,
    parameter RAM_ADDR_WIDTH = $clog2(TX_RAM_SIZE > RX_RAM_SIZE ? TX_RAM_SIZE : RX_RAM_SIZE),
    parameter RAM_PIPELINE = 2,

    // PCIe interface configuration
    parameter AXIS_PCIE_DATA_WIDTH = 128,
    parameter PF_COUNT = 1,
    parameter VF_COUNT = 0,

    // Interrupt configuration
    parameter IRQ_INDEX_WIDTH = EQN_WIDTH,

    // AXI lite interface configuration (control)
    parameter AXIL_CTRL_DATA_WIDTH = 32,
    parameter AXIL_CTRL_ADDR_WIDTH = 24,

    // AXI lite interface configuration (application control)
    parameter AXIL_APP_CTRL_DATA_WIDTH = AXIL_CTRL_DATA_WIDTH,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 24,

    // Ethernet interface configuration
    parameter AXIS_ETH_TX_PIPELINE = 0,
    parameter AXIS_ETH_TX_FIFO_PIPELINE = 2,
    parameter AXIS_ETH_TX_TS_PIPELINE = 0,
    parameter AXIS_ETH_RX_PIPELINE = 0,
    parameter AXIS_ETH_RX_FIFO_PIPELINE = 2,

    // Statistics counter subsystem
    parameter STAT_ENABLE = 1,
    parameter STAT_DMA_ENABLE = 1,
    parameter STAT_PCIE_ENABLE = 1,
    parameter STAT_INC_WIDTH = 24,
    parameter STAT_ID_WIDTH = 12
)
(
		   
  output 	     j3_6, // trigger to scope
  output 	     j3_8, // fast switch ctl
  output 	     j3_24, // debug
		   
//  output 	 sfp0_tx_p,
//  output 	 sfp0_tx_n,
//  input 	 sfp0_rx_p,
//  input 	 sfp0_rx_n,
//  output 	 sfp0_tx_dis, 
//  input 	 si5328_out_c_p,
//  input 	 si5328_out_c_n,

//  output rec_clock_p,
//  output rec_clock_n,
		   
//  inout [14:0] 	ddr_addr,
//  inout [ 2:0] 	ddr_ba,
//  inout 	ddr_cas_n,
//  inout 	ddr_ck_n,
//  inout 	ddr_ck_p,
//  inout 	ddr_cke,
//  inout 	ddr_cs_n,
//  inout [ 3:0] 	ddr_dm,
//  inout [31:0] 	ddr_dq,
//  inout [ 3:0] 	ddr_dqs_n,
//  inout [ 3:0] 	ddr_dqs_p,
//  inout 	ddr_odt,
//  inout 	ddr_ras_n,
//  inout 	ddr_reset_n,
//  inout 	ddr_we_n,

//  output 	 c0_ddr4_act_n,
//  output [16:0]  c0_ddr4_adr,
//  output [ 1:0]  c0_ddr4_ba,
//  output 	 c0_ddr4_bg,
//  output 	 c0_ddr4_ck_c,
//  output 	 c0_ddr4_ck_t,
//  output 	 c0_ddr4_cke,
//  output 	 c0_ddr4_cs_n,
//  inout [ 7:0] 	 c0_ddr4_dm_dbi_n,
//  inout [63:0] 	 c0_ddr4_dq,
//  inout [ 7:0] 	 c0_ddr4_dqs_c,
//  inout [ 7:0] 	 c0_ddr4_dqs_t,
//  output 	 c0_ddr4_odt,
//  output 	 c0_ddr4_reset_n,

//  inout iic_main_scl,
//  inout iic_main_sda,
		   
  // for switches, buttons and leds (which are different from board to board)
  input [12:0] 	     gpio_bd_i,
  output [20:13]     gpio_bd_o,

  input 	     rx_ref_clk_p,
  input 	     rx_ref_clk_n,
  input 	     rx_sysref_p,
  input 	     rx_sysref_n,
  output 	     rx_sync_p,
  output 	     rx_sync_n,
  input [ 3:0] 	     rx_data_p,
  input [ 3:0] 	     rx_data_n,

  input 	     tx_ref_clk_p,
  input 	     tx_ref_clk_n,
  input 	     tx_sysref_p,
  input 	     tx_sysref_n,
  input 	     tx_sync_p,
  input 	     tx_sync_n,
  output [ 3:0]      tx_data_p,
  output [ 3:0]      tx_data_n,

  input 	     trig_p,
  input 	     trig_n,


  // These control lines go out through FMC
  // to the chips on the DAQ3 board:
  inout 	     adc_pd,
  inout 	     dac_txen,
  inout 	     adc_fdb,
  inout 	     adc_fda,
  inout 	     dac_irq,
  inout [ 1:0] 	     clkd_status,

// Not using:		   
//  output 	sysref_p,
//  output 	sysref_n,
		   
  output 	     spi_csn_clk,
  output 	     spi_csn_dac,
  output 	     spi_csn_adc,
  output 	     spi_clk,
  inout 	     spi_sdio,
  output 	     spi_dir,

//  input 	 sys_clk_p,
//  input 	 sys_clk_n



// Corundum stuff below		   

    /*
     * Clock: 125MHz LVDS
     */
  input wire 	     clk_125mhz_p,
  input wire 	     clk_125mhz_n,
  input wire 	     clk_user_si570_p,
  input wire 	     clk_user_si570_n,

    /*
     * I2C for board management
     */
//  inout wire 	     i2c1_scl,
//  inout wire 	     i2c1_sda,

    /*
     * PCI express
     */
  input wire [3:0]   pcie_rx_p,
  input wire [3:0]   pcie_rx_n,
  output wire [3:0]  pcie_tx_p,
  output wire [3:0]  pcie_tx_n,
  input wire 	     pcie_mgt_refclk_p,
  input wire 	     pcie_mgt_refclk_n,
  input wire 	     pcie_reset_n,

    /*
     * Ethernet: SFP+
     */
  input wire 	     sfp0_rx_p,
  input wire 	     sfp0_rx_n,
  output wire 	     sfp0_tx_p,
  output wire 	     sfp0_tx_n,
  input wire 	     sfp1_rx_p,
  input wire 	     sfp1_rx_n,
  output wire 	     sfp1_tx_p,
  output wire 	     sfp1_tx_n,
  input wire 	     sfp_mgt_refclk_0_p,
  input wire 	     sfp_mgt_refclk_0_n,
  output wire 	     sfp0_tx_disable_b,
  output wire 	     sfp1_tx_disable_b,

    /*
     * DDR4
     */
  output wire [16:0] ddr4_adr,
  output wire [1:0]  ddr4_ba,
  output wire [0:0]  ddr4_bg,
  output wire [0:0]  ddr4_ck_t,
  output wire [0:0]  ddr4_ck_c,
  output wire [0:0]  ddr4_cke,
  output wire [0:0]  ddr4_cs_n,
  output wire 	     ddr4_act_n,
  output wire [0:0]  ddr4_odt,
  output wire 	     ddr4_par,
  output wire 	     ddr4_reset_n,
  inout wire [63:0]  ddr4_dq,
  inout wire [7:0]   ddr4_dqs_t,
  inout wire [7:0]   ddr4_dqs_c,
  inout wire [7:0]   ddr4_dm_dbi_n
		   
);

  // internal signals

  wire        [38:0]      gpio_i;
  wire        [38:0]      gpio_o;
  wire        [38:0]      gpio_t;
//  wire        [20:0]      gpio_bd;
   
  wire        [ 2:0]      spi_csn;
  wire                    spi_mosi;
  wire                    spi_miso;
  wire                    trig;
  wire                    rx_ref_clk;
  wire                    rx_sysref;
  wire                    rx_sync;
  wire                    tx_ref_clk;
//  wire                    tx_ref_clk_d2;
  wire                    tx_sysref;
  wire                    tx_sync;

  wire   si5328_out_c, rec_clk_out;
  wire 	  dbg_clk, axi_clk, sfp_txclk, gth_rst;
  wire [3:0] gth_status;



// Corundum sigs
// PTP configuration
parameter PTP_CLK_PERIOD_NS_NUM = 32;
parameter PTP_CLK_PERIOD_NS_DENOM = 5;
parameter PTP_TS_WIDTH = 96;
parameter IF_PTP_PERIOD_NS = 6'h6;
parameter IF_PTP_PERIOD_FNS = 16'h6666;

// Interface configuration
parameter TX_TAG_WIDTH = 16;

// RAM configuration
parameter AXI_DDR_STRB_WIDTH = (AXI_DDR_DATA_WIDTH/8);

// PCIe interface configuration
parameter AXIS_PCIE_KEEP_WIDTH = (AXIS_PCIE_DATA_WIDTH/32);
parameter AXIS_PCIE_RC_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 75 : 161;
parameter AXIS_PCIE_RQ_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 62 : 137;
parameter AXIS_PCIE_CQ_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 85 : 183;
parameter AXIS_PCIE_CC_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 33 : 81;
parameter RC_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 256;
parameter RQ_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter CQ_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter CC_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter RQ_SEQ_NUM_WIDTH = 6;
parameter PCIE_TAG_COUNT = 256;

// Ethernet interface configuration
parameter XGMII_DATA_WIDTH = 64;
parameter XGMII_CTRL_WIDTH = XGMII_DATA_WIDTH/8;
parameter AXIS_ETH_DATA_WIDTH = XGMII_DATA_WIDTH;
parameter AXIS_ETH_KEEP_WIDTH = AXIS_ETH_DATA_WIDTH/8;
parameter AXIS_ETH_SYNC_DATA_WIDTH = AXIS_ETH_DATA_WIDTH;
parameter AXIS_ETH_TX_USER_WIDTH = TX_TAG_WIDTH + 1;
parameter AXIS_ETH_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1;

   // Clock and reset
   wire      pcie_user_clk;
   wire      pcie_user_reset;

   wire      clk_125mhz_ibufg;
   wire      clk_125mhz_mmcm_out;

   // Internal 125 MHz clock
   wire clk_125mhz_int;
   wire rst_125mhz_int;

   wire mmcm_rst = pcie_user_reset;
   wire mmcm_locked;
   wire mmcm_clkfb;
   
   
   
  // spi
  assign spi_csn_adc = spi_csn[2];
  assign spi_csn_dac = spi_csn[1];
  assign spi_csn_clk = spi_csn[0];

  // instantiations

  // OK
  IBUFDS_GTE4 i_ibufds_rx_ref_clk (
    .CEB (1'd0),
    .I (rx_ref_clk_p),
    .IB (rx_ref_clk_n),
    .O (rx_ref_clk),
    .ODIV2 ());

  // OK
  IBUFDS i_ibufds_rx_sysref (
    .I (rx_sysref_p),
    .IB (rx_sysref_n),
    .O (rx_sysref));

  // OK
  OBUFDS i_obufds_rx_sync (
    .I (rx_sync),
    .O (rx_sync_p),
    .OB (rx_sync_n));

   // OK
  IBUFDS_GTE4 #(
    .REFCLK_HROW_CK_SEL (1)
  ) i_ibufds_tx_ref_clk (
    .CEB (1'd0),
    .I (tx_ref_clk_p),
    .IB (tx_ref_clk_n),
    .O (tx_ref_clk));
//    .ODIV2 (tx_ref_clk_d2));

//  BUFG_GT i_dbg_clk_buf (/
//    .I (tx_ref_clk_d2),
//    .O (dbg_clk));
   assign j3_24 = 0; // dbg_clk; // dbg
   
   
  // OK
  IBUFDS i_ibufds_tx_sysref (
    .I (tx_sysref_p),
    .IB (tx_sysref_n),
    .O (tx_sysref));

  // OK
  IBUFDS i_ibufds_tx_sync (
    .I (tx_sync_p),
    .IB (tx_sync_n),
    .O (tx_sync));


  // Note: in the zc706 design, spi1 is not used. We do not bother to instantiate it.
  daq3_spi i_spi (
    .spi_csn (spi_csn), // in
    .spi_clk (spi_clk), // in
    .spi_mosi (spi_mosi), // in
    .spi_miso (spi_miso), // out
		  
    .spi_sdio (spi_sdio), // in
    .spi_dir (spi_dir));  // out

  // went out to fmc la13 p&n
  // OK   
//  OBUFDS i_obufds_sysref (
//    .I (gpio_o[40]),
//    .O (sysref_p),
//    .OB (sysref_n));
   
  // OK
  IBUFDS i_ibufds_trig (
    .I (trig_p),
    .IB (trig_n),
    .O (trig));

//  assign gpio_i[94:40] = gpio_o[94:40];
//  assign gpio_i[39] = trig;

  ad_iobuf #(
    .DATA_WIDTH(7)
  ) i_iobuf (
    .dio_t (gpio_t[38:32]),
    .dio_i (gpio_o[38:32]),
    .dio_o (gpio_i[38:32]),
    .dio_p ({ adc_pd,           // 38
              dac_txen,         // 37
              adc_fdb,          // 36
              adc_fda,          // 35
              dac_irq,          // 34
              clkd_status}));   // 32 and 33

  assign gpio_i[12:0]   = gpio_bd_i[12:0];
  assign gpio_bd_o = gpio_o[20:13];
   
//  assign gpio_i[31:21] = gpio_o[31:21];
//  assign gpio_i = gpio_bd_i;
//  assign gpio_bd_o = gpio_o;


  // for zc706, ad instantiated an iic IP in the BD in the PL,
  // and in zc706_system_constr set loc of scl and sda.
  // The linux driver must use the AD IP.

  // The zcu106 board has two IICs which are connected to MIO pins,
  // and those are routed and loc'd by the Zync system (C28,A28,E27,A27) and we don't
  // need to do it explicitly in this file.
  // Both of them connect to IIC muxes to control various board-specific stuff.

  // This emits an LFSR pattern out SFP0.
  // Could be used for testing the system without the classical NIC.
  // in bank 225
   /*
  IBUFDS_GTE4 gtrefclk_ibuf (
      .CEB(0),
      .I(si5328_out_c_p),
      .IB(si5328_out_c_n),
      .O(si5328_out_c));
  gth_driver i_gthdrv (
    .tx_p(sfp0_tx_p),
    .tx_n(sfp0_tx_n),
    .rx_p(sfp0_rx_p),
    .rx_n(sfp0_rx_n),
    .rst(gth_rst),		       
    .status(gth_status),
    .axi_clk(axi_clk),
    .txclk_out(sfp_txclk),
    .gtrefclk(si5328_out_c));
    */
//  assign j3_6=sfp_txclk;

/*   
  // Note: ODDR in ultrascale vs 7series is different
  ODDRE1 recclk_oddr(
     .C(axi_clk), // 250MHz
     .D1(0),
     .D2(1),
     .SR(0),
     .Q(rec_clk_out));
  OBUFDS tojitattn_obuf (
     .I(rec_clk_out),
     .O (rec_clock_p),
     .OB(rec_clock_n));
*/   
   

  system_wrapper i_system_wrapper (
    .dac_xfer_out_port (j3_6),
    .rxq_sw_ctl (j3_8),
    .axi_clk_out(axi_clk), // 250MHz I think

//    .tx_p(sfp0_tx_p),
//    .tx_n(sfp0_tx_n),
//    .rx_p(sfp0_rx_p),
//    .rx_n(sfp0_rx_n),
//    .gtrefclk(si5328_out_c),
//    .txclk_out(sfp_txclk),
				   
//    .ddr4_act_n(c0_ddr4_act_n),
//    .ddr4_adr (c0_ddr4_adr),
//    .ddr4_ba (c0_ddr4_ba),
//    .ddr4_bg (c0_ddr4_bg),
//    .ddr4_ck_c (c0_ddr4_ck_c),
//    .ddr4_ck_t (c0_ddr4_ck_t),
//    .ddr4_cke (c0_ddr4_cke),
//    .ddr4_cs_n (c0_ddr4_cs_n),
//    .ddr4_dm_n (c0_ddr4_dm_dbi_n),
//    .ddr4_dq (c0_ddr4_dq),
//    .ddr4_dqs_c (c0_ddr4_dqs_c),
//    .ddr4_dqs_t (c0_ddr4_dqs_t),
//    .ddr4_odt (c0_ddr4_odt),
//    .ddr4_reset_n (c0_ddr4_reset_n),

    .gth_status(gth_status),
    .gth_rst(gth_rst),
				   
//    .ddr_addr (ddr_addr),
//    .ddr_ba (ddr_ba),
//    .ddr_cas_n (ddr_cas_n),
//    .ddr_ck_n (ddr_ck_n),
//    .ddr_ck_p (ddr_ck_p),
//    .ddr_cke (ddr_cke),
//    .ddr_cs_n (ddr_cs_n),
//    .ddr_dm (ddr_dm),
//    .ddr_dq (ddr_dq),
//    .ddr_dqs_n (ddr_dqs_n),
//    .ddr_dqs_p (ddr_dqs_p),
//    .ddr_odt (ddr_odt),
//    .ddr_ras_n (ddr_ras_n),
//    .ddr_reset_n (ddr_reset_n),
//    .ddr_we_n (ddr_we_n),
				   
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),

    // "main" iic is for daq3 board stuff
//    .iic_main_scl_io (iic_main_scl),
//    .iic_main_sda_io (iic_main_sda),
				   
    .rx_data_0_n (rx_data_n[0]),
    .rx_data_0_p (rx_data_p[0]),
    .rx_data_1_n (rx_data_n[1]),
    .rx_data_1_p (rx_data_p[1]),
    .rx_data_2_n (rx_data_n[2]),
    .rx_data_2_p (rx_data_p[2]),
    .rx_data_3_n (rx_data_n[3]),
    .rx_data_3_p (rx_data_p[3]),
    .rx_ref_clk_0 (rx_ref_clk),
    .rx_sync_0 (rx_sync),      // to ADC's SYNCIN
    .rx_sysref_0 (rx_sysref),

    .spi0_sclk (spi_clk),
    .spi0_csn  (spi_csn),
    .spi0_miso (spi_miso),
    .spi0_mosi (spi_mosi),

     // spi1 was unused for the zc706 target				   
    .spi1_sclk (),
    .spi1_csn  (),
    .spi1_miso (0),
    .spi1_mosi (),
				   
//    .sys_clk_clk_n (sys_clk_n),
//    .sys_clk_clk_p (sys_clk_p),
				   
//    .dac_fifo_bypass(0),
    .tx_data_0_n (tx_data_n[0]),
    .tx_data_0_p (tx_data_p[0]),
    .tx_data_1_n (tx_data_n[1]),
    .tx_data_1_p (tx_data_p[1]),
    .tx_data_2_n (tx_data_n[2]),
    .tx_data_2_p (tx_data_p[2]),
    .tx_data_3_n (tx_data_n[3]),
    .tx_data_3_p (tx_data_p[3]),
    .tx_ref_clk_0 (tx_ref_clk),
    .tx_sync_0 (tx_sync),       // to DAC's SYNCIN
    .tx_sysref_0 (tx_sysref));


   // Corundum
   IBUFGDS #(
	     .DIFF_TERM("FALSE"),
	     .IBUF_LOW_PWR("FALSE")   
	     )
   clk_125mhz_ibufg_inst (
			  .O   (clk_125mhz_ibufg),
			  .I   (clk_125mhz_p),
			  .IB  (clk_125mhz_n) 
			  );

   // MMCM instance
   // 125 MHz in, 125 MHz out
   // PFD range: 10 MHz to 500 MHz
   // VCO range: 800 MHz to 1600 MHz
   // M = 8, D = 1 sets Fvco = 1000 MHz (in range)
   // Divide by 8 to get output frequency of 125 MHz
   MMCME3_BASE #(
		 .BANDWIDTH("OPTIMIZED"),
		 .CLKOUT0_DIVIDE_F(8),
		 .CLKOUT0_DUTY_CYCLE(0.5),
		 .CLKOUT0_PHASE(0),
		 .CLKOUT1_DIVIDE(1),
		 .CLKOUT1_DUTY_CYCLE(0.5),
		 .CLKOUT1_PHASE(0),
		 .CLKOUT2_DIVIDE(1),
		 .CLKOUT2_DUTY_CYCLE(0.5),
		 .CLKOUT2_PHASE(0),
		 .CLKOUT3_DIVIDE(1),
		 .CLKOUT3_DUTY_CYCLE(0.5),
		 .CLKOUT3_PHASE(0),
		 .CLKOUT4_DIVIDE(1),
		 .CLKOUT4_DUTY_CYCLE(0.5),
		 .CLKOUT4_PHASE(0),
		 .CLKOUT5_DIVIDE(1),
		 .CLKOUT5_DUTY_CYCLE(0.5),
		 .CLKOUT5_PHASE(0),
		 .CLKOUT6_DIVIDE(1),
		 .CLKOUT6_DUTY_CYCLE(0.5),
		 .CLKOUT6_PHASE(0),
		 .CLKFBOUT_MULT_F(8),
		 .CLKFBOUT_PHASE(0),
		 .DIVCLK_DIVIDE(1),
		 .REF_JITTER1(0.010),
		 .CLKIN1_PERIOD(8.0),
		 .STARTUP_WAIT("FALSE"),
		 .CLKOUT4_CASCADE("FALSE")
		 )
   clk_mmcm_inst (
		  .CLKIN1(clk_125mhz_ibufg),
		  .CLKFBIN(mmcm_clkfb),
		  .RST(mmcm_rst),
		  .PWRDWN(1'b0),
		  .CLKOUT0(clk_125mhz_mmcm_out),
		  .CLKOUT0B(),
		  .CLKOUT1(),
		  .CLKOUT1B(),
		  .CLKOUT2(),
		  .CLKOUT2B(),
		  .CLKOUT3(),
		  .CLKOUT3B(),
		  .CLKOUT4(),
		  .CLKOUT5(),
		  .CLKOUT6(),
		  .CLKFBOUT(mmcm_clkfb),
		  .CLKFBOUTB(),
		  .LOCKED(mmcm_locked)
		  );

   BUFG
     clk_125mhz_bufg_inst (
			   .I(clk_125mhz_mmcm_out),
			   .O(clk_125mhz_int)
			   );

   sync_reset #(
		.N(4)
		)
   sync_reset_125mhz_inst (
			   .clk(clk_125mhz_int),
			   .rst(~mmcm_locked),
			   .out(rst_125mhz_int)
			   );
   // GPIO
   wire btnu_int;
   wire btnl_int;
   wire btnd_int;
   wire btnr_int;
   wire btnc_int;
   wire [7:0] sw_int;
   wire       i2c1_scl_i;
   wire       i2c1_scl_o;
   wire       i2c1_scl_t;
   wire       i2c1_sda_i;
   wire       i2c1_sda_o;
   wire       i2c1_sda_t;

   
   
   reg 	      i2c1_scl_o_reg;
   reg 	      i2c1_scl_t_reg;
   reg 	      i2c1_sda_o_reg;
   reg 	      i2c1_sda_t_reg;

   always @(posedge pcie_user_clk) begin
      i2c1_scl_o_reg <= i2c1_scl_o;
      i2c1_scl_t_reg <= i2c1_scl_t;
      i2c1_sda_o_reg <= i2c1_sda_o;
      i2c1_sda_t_reg <= i2c1_sda_t;
   end


   // This corundum module does nothing wityh gpio or switchs.
   // It does seem to send a ptp_pps_str out to an LED.
   // So the debounce stuff is useless.

/*   debounce_switch #(
		     .WIDTH(13),
		     .N(4),
		     .RATE(250000)
		     )
   debounce_switch_inst (
			 .clk(pcie_user_clk),
			 .rst(pcie_user_reset),
			 .in({btnu,
			      btnl,
			      btnd,
			      btnr,
			      btnc,
			      sw}),
			 .out({btnu_int,
			       btnl_int,
			       btnd_int,
			       btnr_int,
			       btnc_int,
			       sw_int})
			 ); */
   wire [7:0] led; // not used

/*
   For now not using Corundum's I2c because
   AD HDL has a few already.  But it would allow
   i2c control from the host.
 
    sync_signal #(
		 .WIDTH(2),
		 .N(2)
		 )
   sync_signal_inst (
		     .clk(pcie_user_clk),
		     .in({i2c1_scl, i2c1_sda}),
		     .out({i2c1_scl_i, i2c1_sda_i})
		     );
   assign i2c1_scl = i2c1_scl_t_reg ? 1'bz : i2c1_scl_o_reg;
   assign i2c1_sda = i2c1_sda_t_reg ? 1'bz : i2c1_sda_o_reg;
  */
   assign i2c1_scl_i = 1'b1;
   assign i2c1_sda_i = 1'b1;


   // PCIe
   wire pcie_sys_clk;
   wire pcie_sys_clk_gt;

   IBUFDS_GTE4 #(
		 .REFCLK_HROW_CK_SEL(2'b00)
		 )
   ibufds_gte4_pcie_mgt_refclk_inst (
				     .I             (pcie_mgt_refclk_p),
				     .IB            (pcie_mgt_refclk_n),
				     .CEB           (1'b0),
				     .O             (pcie_sys_clk_gt),
				     .ODIV2         (pcie_sys_clk)
				     );

   wire [AXIS_PCIE_DATA_WIDTH-1:0] axis_rq_tdata;
   wire [AXIS_PCIE_KEEP_WIDTH-1:0] axis_rq_tkeep;
   wire 			   axis_rq_tlast;
   wire 			   axis_rq_tready;
   wire [AXIS_PCIE_RQ_USER_WIDTH-1:0] axis_rq_tuser;
   wire                               axis_rq_tvalid;

   wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_rc_tdata;
   wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_rc_tkeep;
   wire                               axis_rc_tlast;
   wire                               axis_rc_tready;
   wire [AXIS_PCIE_RC_USER_WIDTH-1:0] axis_rc_tuser;
   wire                               axis_rc_tvalid;

   wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_cq_tdata;
   wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_cq_tkeep;
   wire                               axis_cq_tlast;
   wire                               axis_cq_tready;
   wire [AXIS_PCIE_CQ_USER_WIDTH-1:0] axis_cq_tuser;
   wire                               axis_cq_tvalid;

   wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_cc_tdata;
   wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_cc_tkeep;
   wire                               axis_cc_tlast;
   wire                               axis_cc_tready;
   wire [AXIS_PCIE_CC_USER_WIDTH-1:0] axis_cc_tuser;
   wire                               axis_cc_tvalid;

   wire [RQ_SEQ_NUM_WIDTH-1:0] 	      pcie_rq_seq_num0;
   wire                               pcie_rq_seq_num_vld0;
   wire [RQ_SEQ_NUM_WIDTH-1:0] 	      pcie_rq_seq_num1;
   wire                               pcie_rq_seq_num_vld1;

   wire [3:0] 			      pcie_tfc_nph_av;
   wire [3:0] 			      pcie_tfc_npd_av;

   wire [2:0] 			      cfg_max_payload;
   wire [2:0] 			      cfg_max_read_req;
   wire [3:0] 			      cfg_rcb_status;

   wire [9:0] 			      cfg_mgmt_addr;
   wire [7:0] 			      cfg_mgmt_function_number;
   wire 			      cfg_mgmt_write;
   wire [31:0] 			      cfg_mgmt_write_data;
   wire [3:0] 			      cfg_mgmt_byte_enable;
   wire 			      cfg_mgmt_read;
   wire [31:0] 			      cfg_mgmt_read_data;
   wire 			      cfg_mgmt_read_write_done;

   wire [7:0] 			      cfg_fc_ph;
   wire [11:0] 			      cfg_fc_pd;
   wire [7:0] 			      cfg_fc_nph;
   wire [11:0] 			      cfg_fc_npd;
   wire [7:0] 			      cfg_fc_cplh;
   wire [11:0] 			      cfg_fc_cpld;
   wire [2:0] 			      cfg_fc_sel;

   wire [3:0] 			      cfg_interrupt_msix_enable;
   wire [3:0] 			      cfg_interrupt_msix_mask;
   wire [251:0] 		      cfg_interrupt_msix_vf_enable;
   wire [251:0] 		      cfg_interrupt_msix_vf_mask;
   wire [63:0] 			      cfg_interrupt_msix_address;
   wire [31:0] 			      cfg_interrupt_msix_data;
   wire 			      cfg_interrupt_msix_int;
   wire [1:0] 			      cfg_interrupt_msix_vec_pending;
   wire 			      cfg_interrupt_msix_vec_pending_status;
   wire 			      cfg_interrupt_msix_sent;
   wire 			      cfg_interrupt_msix_fail;
   wire [7:0] 			      cfg_interrupt_msi_function_number;

   wire 			      status_error_cor;
   wire 			      status_error_uncor;

   // extra register for pcie_user_reset signal
   wire 			      pcie_user_reset_int;
   (* shreg_extract = "no" *)
   reg 				      pcie_user_reset_reg_1 = 1'b1;
   (* shreg_extract = "no" *)
   reg 				      pcie_user_reset_reg_2 = 1'b1;

   always @(posedge pcie_user_clk) begin
      pcie_user_reset_reg_1 <= pcie_user_reset_int;
      pcie_user_reset_reg_2 <= pcie_user_reset_reg_1;
   end

   BUFG
     pcie_user_reset_bufg_inst (
				.I(pcie_user_reset_reg_2),
				.O(pcie_user_reset)
				);

   pcie4_uscale_plus_0
     pcie4_uscale_plus_inst (
			     .pci_exp_txn(pcie_tx_n),
			     .pci_exp_txp(pcie_tx_p),
			     .pci_exp_rxn(pcie_rx_n),
			     .pci_exp_rxp(pcie_rx_p),
			     .user_clk(pcie_user_clk),
			     .user_reset(pcie_user_reset_int),
			     .user_lnk_up(),

			     .s_axis_rq_tdata(axis_rq_tdata),
			     .s_axis_rq_tkeep(axis_rq_tkeep),
			     .s_axis_rq_tlast(axis_rq_tlast),
			     .s_axis_rq_tready(axis_rq_tready),
			     .s_axis_rq_tuser(axis_rq_tuser),
			     .s_axis_rq_tvalid(axis_rq_tvalid),

			     .m_axis_rc_tdata(axis_rc_tdata),
			     .m_axis_rc_tkeep(axis_rc_tkeep),
			     .m_axis_rc_tlast(axis_rc_tlast),
			     .m_axis_rc_tready(axis_rc_tready),
			     .m_axis_rc_tuser(axis_rc_tuser),
			     .m_axis_rc_tvalid(axis_rc_tvalid),

			     .m_axis_cq_tdata(axis_cq_tdata),
			     .m_axis_cq_tkeep(axis_cq_tkeep),
			     .m_axis_cq_tlast(axis_cq_tlast),
			     .m_axis_cq_tready(axis_cq_tready),
			     .m_axis_cq_tuser(axis_cq_tuser),
			     .m_axis_cq_tvalid(axis_cq_tvalid),

			     .s_axis_cc_tdata(axis_cc_tdata),
			     .s_axis_cc_tkeep(axis_cc_tkeep),
			     .s_axis_cc_tlast(axis_cc_tlast),
			     .s_axis_cc_tready(axis_cc_tready),
			     .s_axis_cc_tuser(axis_cc_tuser),
			     .s_axis_cc_tvalid(axis_cc_tvalid),

			     .pcie_rq_seq_num0(pcie_rq_seq_num0),
			     .pcie_rq_seq_num_vld0(pcie_rq_seq_num_vld0),
			     .pcie_rq_seq_num1(pcie_rq_seq_num1),
			     .pcie_rq_seq_num_vld1(pcie_rq_seq_num_vld1),
			     .pcie_rq_tag0(),
			     .pcie_rq_tag1(),
			     .pcie_rq_tag_av(),
			     .pcie_rq_tag_vld0(),
			     .pcie_rq_tag_vld1(),

			     .pcie_tfc_nph_av(pcie_tfc_nph_av),
			     .pcie_tfc_npd_av(pcie_tfc_npd_av),

			     .pcie_cq_np_req(1'b1),
			     .pcie_cq_np_req_count(),

			     .cfg_phy_link_down(),
			     .cfg_phy_link_status(),
			     .cfg_negotiated_width(),
			     .cfg_current_speed(),
			     .cfg_max_payload(cfg_max_payload),
			     .cfg_max_read_req(cfg_max_read_req),
			     .cfg_function_status(),
			     .cfg_function_power_state(),
			     .cfg_vf_status(),
			     .cfg_vf_power_state(),
			     .cfg_link_power_state(),

			     .cfg_mgmt_addr(cfg_mgmt_addr),
			     .cfg_mgmt_function_number(cfg_mgmt_function_number),
			     .cfg_mgmt_write(cfg_mgmt_write),
			     .cfg_mgmt_write_data(cfg_mgmt_write_data),
			     .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),
			     .cfg_mgmt_read(cfg_mgmt_read),
			     .cfg_mgmt_read_data(cfg_mgmt_read_data),
			     .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),
			     .cfg_mgmt_debug_access(1'b0),

			     .cfg_err_cor_out(),
			     .cfg_err_nonfatal_out(),
			     .cfg_err_fatal_out(),
			     .cfg_local_error_valid(),
			     .cfg_local_error_out(),
			     .cfg_ltssm_state(),
			     .cfg_rx_pm_state(),
			     .cfg_tx_pm_state(),
			     .cfg_rcb_status(cfg_rcb_status),
			     .cfg_obff_enable(),
			     .cfg_pl_status_change(),
			     .cfg_tph_requester_enable(),
			     .cfg_tph_st_mode(),
			     .cfg_vf_tph_requester_enable(),
			     .cfg_vf_tph_st_mode(),

			     .cfg_msg_received(),
			     .cfg_msg_received_data(),
			     .cfg_msg_received_type(),
			     .cfg_msg_transmit(1'b0),
			     .cfg_msg_transmit_type(3'd0),
			     .cfg_msg_transmit_data(32'd0),
			     .cfg_msg_transmit_done(),

			     .cfg_fc_ph(cfg_fc_ph),
			     .cfg_fc_pd(cfg_fc_pd),
			     .cfg_fc_nph(cfg_fc_nph),
			     .cfg_fc_npd(cfg_fc_npd),
			     .cfg_fc_cplh(cfg_fc_cplh),
			     .cfg_fc_cpld(cfg_fc_cpld),
			     .cfg_fc_sel(cfg_fc_sel),

			     .cfg_dsn(64'd0),

			     .cfg_power_state_change_ack(1'b1),
			     .cfg_power_state_change_interrupt(),

			     .cfg_err_cor_in(status_error_cor),
			     .cfg_err_uncor_in(status_error_uncor),
			     .cfg_flr_in_process(),
			     .cfg_flr_done(4'd0),
			     .cfg_vf_flr_in_process(),
			     .cfg_vf_flr_func_num(8'd0),
			     .cfg_vf_flr_done(8'd0),

			     .cfg_link_training_enable(1'b1),

			     .cfg_interrupt_int(4'd0),
			     .cfg_interrupt_pending(4'd0),
			     .cfg_interrupt_sent(),
			     .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),
			     .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),
			     .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),
			     .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),
			     .cfg_interrupt_msix_address(cfg_interrupt_msix_address),
			     .cfg_interrupt_msix_data(cfg_interrupt_msix_data),
			     .cfg_interrupt_msix_int(cfg_interrupt_msix_int),
			     .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),
			     .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),
			     .cfg_interrupt_msi_sent(cfg_interrupt_msix_sent),
			     .cfg_interrupt_msi_fail(cfg_interrupt_msix_fail),
			     .cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number),

			     .cfg_pm_aspm_l1_entry_reject(1'b0),
			     .cfg_pm_aspm_tx_l0s_entry_disable(1'b0),

			     .cfg_hot_reset_out(),

			     .cfg_config_space_enable(1'b1),
			     .cfg_req_pm_transition_l23_ready(1'b0),
			     .cfg_hot_reset_in(1'b0),

			     .cfg_ds_port_number(8'd0),
			     .cfg_ds_bus_number(8'd0),
			     .cfg_ds_device_number(5'd0),

			     .sys_clk(pcie_sys_clk),
			     .sys_clk_gt(pcie_sys_clk_gt),
			     .sys_reset(pcie_reset_n),

			     .phy_rdy_out()
			     );

   // XGMII 10G PHY
   wire                         sfp0_tx_clk_int;
   wire                         sfp0_tx_rst_int;
   wire [XGMII_DATA_WIDTH-1:0] 	sfp0_txd_int;
   wire [XGMII_CTRL_WIDTH-1:0] 	sfp0_txc_int;
   wire                         sfp0_cfg_tx_prbs31_enable_int;
   wire                         sfp0_rx_clk_int;
   wire                         sfp0_rx_rst_int;
   wire [XGMII_DATA_WIDTH-1:0] 	sfp0_rxd_int;
   wire [XGMII_CTRL_WIDTH-1:0] 	sfp0_rxc_int;
   wire                         sfp0_cfg_rx_prbs31_enable_int;
   wire [6:0] 			sfp0_rx_error_count_int;

   wire                         sfp1_tx_clk_int;
   wire                         sfp1_tx_rst_int;
   wire [XGMII_DATA_WIDTH-1:0] 	sfp1_txd_int;
   wire [XGMII_CTRL_WIDTH-1:0] 	sfp1_txc_int;
   wire                         sfp1_cfg_tx_prbs31_enable_int;
   wire                         sfp1_rx_clk_int;
   wire                         sfp1_rx_rst_int;
   wire [XGMII_DATA_WIDTH-1:0] 	sfp1_rxd_int;
   wire [XGMII_CTRL_WIDTH-1:0] 	sfp1_rxc_int;
   wire                         sfp1_cfg_rx_prbs31_enable_int;
   wire [6:0] 			sfp1_rx_error_count_int;

   wire 			sfp_drp_clk = clk_125mhz_int;
   wire 			sfp_drp_rst = rst_125mhz_int;
   wire [23:0] 			sfp_drp_addr;
   wire [15:0] 			sfp_drp_di;
   wire 			sfp_drp_en;
   wire 			sfp_drp_we;
   wire [15:0] 			sfp_drp_do;
   wire 			sfp_drp_rdy;

   wire 			sfp0_rx_block_lock;
   wire 			sfp0_rx_status;
   wire 			sfp1_rx_block_lock;
   wire 			sfp1_rx_status;

   wire 			sfp_gtpowergood;

   wire 			sfp_mgt_refclk_0;
   wire 			sfp_mgt_refclk_0_int;
   wire 			sfp_mgt_refclk_0_bufg;

   IBUFDS_GTE4 ibufds_gte4_sfp_mgt_refclk_0_inst (
						  .I     (sfp_mgt_refclk_0_p),
						  .IB    (sfp_mgt_refclk_0_n),
						  .CEB   (1'b0),
						  .O     (sfp_mgt_refclk_0),
						  .ODIV2 (sfp_mgt_refclk_0_int)
						  );

   BUFG_GT bufg_gt_sfp_mgt_refclk_0_inst (
					  .CE      (sfp_gtpowergood),
					  .CEMASK  (1'b1),
					  .CLR     (1'b0),
					  .CLRMASK (1'b1),
					  .DIV     (3'd0),
					  .I       (sfp_mgt_refclk_0_int),
					  .O       (sfp_mgt_refclk_0_bufg)
					  );

   wire 			sfp_rst;

   sync_reset #(
		.N(4)
		)
   sfp_sync_reset_inst (
			.clk(sfp_mgt_refclk_0_bufg),
			.rst(rst_125mhz_int),
			.out(sfp_rst)
			);

   eth_xcvr_phy_10g_gty_quad_wrapper #(
				       .COUNT(2),
				       .GT_GTH(1),
				       .PRBS31_ENABLE(1)
				       )
   sfp_phy_quad_inst (
		      .xcvr_ctrl_clk(clk_125mhz_int),
		      .xcvr_ctrl_rst(sfp_rst),

		      /*
		       * Common
		       */
		      .xcvr_gtpowergood_out(sfp_gtpowergood),
		      .xcvr_gtrefclk00_in(sfp_mgt_refclk_0),
		      .xcvr_qpll0pd_in(1'b0),
		      .xcvr_qpll0reset_in(1'b0),
		      .xcvr_qpll0pcierate_in(3'd0),
		      .xcvr_qpll0lock_out(),
		      .xcvr_qpll0clk_out(),
		      .xcvr_qpll0refclk_out(),
		      .xcvr_gtrefclk01_in(sfp_mgt_refclk_0),
		      .xcvr_qpll1pd_in(1'b0),
		      .xcvr_qpll1reset_in(1'b0),
		      .xcvr_qpll1pcierate_in(3'd0),
		      .xcvr_qpll1lock_out(),
		      .xcvr_qpll1clk_out(),
		      .xcvr_qpll1refclk_out(),

		      /*
		       * DRP
		       */
		      .drp_clk(sfp_drp_clk),
		      .drp_rst(sfp_drp_rst),
		      .drp_addr(sfp_drp_addr),
		      .drp_di(sfp_drp_di),
		      .drp_en(sfp_drp_en),
		      .drp_we(sfp_drp_we),
		      .drp_do(sfp_drp_do),
		      .drp_rdy(sfp_drp_rdy),

		      /*
		       * Serial data
		       */
		      .xcvr_txp({sfp1_tx_p, sfp0_tx_p}),
		      .xcvr_txn({sfp1_tx_n, sfp0_tx_n}),
		      .xcvr_rxp({sfp1_rx_p, sfp0_rx_p}),
		      .xcvr_rxn({sfp1_rx_n, sfp0_rx_n}),

		      /*
		       * PHY connections
		       */
		      .phy_1_tx_clk(sfp0_tx_clk_int),
		      .phy_1_tx_rst(sfp0_tx_rst_int),
		      .phy_1_xgmii_txd(sfp0_txd_int),
		      .phy_1_xgmii_txc(sfp0_txc_int),
		      .phy_1_rx_clk(sfp0_rx_clk_int),
		      .phy_1_rx_rst(sfp0_rx_rst_int),
		      .phy_1_xgmii_rxd(sfp0_rxd_int),
		      .phy_1_xgmii_rxc(sfp0_rxc_int),
		      .phy_1_tx_bad_block(),
		      .phy_1_rx_error_count(sfp0_rx_error_count_int),
		      .phy_1_rx_bad_block(),
		      .phy_1_rx_sequence_error(),
		      .phy_1_rx_block_lock(sfp0_rx_block_lock),
		      .phy_1_rx_high_ber(),
		      .phy_1_rx_status(sfp0_rx_status),
		      .phy_1_cfg_tx_prbs31_enable(sfp0_cfg_tx_prbs31_enable_int),
		      .phy_1_cfg_rx_prbs31_enable(sfp0_cfg_rx_prbs31_enable_int),

		      .phy_2_tx_clk(sfp1_tx_clk_int),
		      .phy_2_tx_rst(sfp1_tx_rst_int),
		      .phy_2_xgmii_txd(sfp1_txd_int),
		      .phy_2_xgmii_txc(sfp1_txc_int),
		      .phy_2_rx_clk(sfp1_rx_clk_int),
		      .phy_2_rx_rst(sfp1_rx_rst_int),
		      .phy_2_xgmii_rxd(sfp1_rxd_int),
		      .phy_2_xgmii_rxc(sfp1_rxc_int),
		      .phy_2_tx_bad_block(),
		      .phy_2_rx_error_count(sfp1_rx_error_count_int),
		      .phy_2_rx_bad_block(),
		      .phy_2_rx_sequence_error(),
		      .phy_2_rx_block_lock(sfp1_rx_block_lock),
		      .phy_2_rx_high_ber(),
		      .phy_2_rx_status(sfp1_rx_status),
		      .phy_2_cfg_tx_prbs31_enable(sfp1_cfg_tx_prbs31_enable_int),
		      .phy_2_cfg_rx_prbs31_enable(sfp1_cfg_rx_prbs31_enable_int)
		      );

   wire 			ptp_clk;
   wire 			ptp_rst;
   wire 			ptp_sample_clk;

   assign ptp_clk = sfp_mgt_refclk_0_bufg;
   assign ptp_rst = sfp_rst;
   assign ptp_sample_clk = clk_125mhz_int;

   // DDR4
   wire [DDR_CH-1:0] 		ddr_clk;
   wire [DDR_CH-1:0] 		ddr_rst;

   wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0] m_axi_ddr_awid;
   wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0] m_axi_ddr_awaddr;
   wire [DDR_CH*8-1:0] 			m_axi_ddr_awlen;
   wire [DDR_CH*3-1:0] 			m_axi_ddr_awsize;
   wire [DDR_CH*2-1:0] 			m_axi_ddr_awburst;
   wire [DDR_CH-1:0] 			m_axi_ddr_awlock;
   wire [DDR_CH*4-1:0] 			m_axi_ddr_awcache;
   wire [DDR_CH*3-1:0] 			m_axi_ddr_awprot;
   wire [DDR_CH*4-1:0] 			m_axi_ddr_awqos;
   wire [DDR_CH-1:0] 			m_axi_ddr_awvalid;
   wire [DDR_CH-1:0] 			m_axi_ddr_awready;
   wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0] m_axi_ddr_wdata;
   wire [DDR_CH*AXI_DDR_STRB_WIDTH-1:0] m_axi_ddr_wstrb;
   wire [DDR_CH-1:0] 			m_axi_ddr_wlast;
   wire [DDR_CH-1:0] 			m_axi_ddr_wvalid;
   wire [DDR_CH-1:0] 			m_axi_ddr_wready;
   wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0] 	m_axi_ddr_bid;
   wire [DDR_CH*2-1:0] 			m_axi_ddr_bresp;
   wire [DDR_CH-1:0] 			m_axi_ddr_bvalid;
   wire [DDR_CH-1:0] 			m_axi_ddr_bready;
   wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0] 	m_axi_ddr_arid;
   wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0] m_axi_ddr_araddr;
   wire [DDR_CH*8-1:0] 			m_axi_ddr_arlen;
   wire [DDR_CH*3-1:0] 			m_axi_ddr_arsize;
   wire [DDR_CH*2-1:0] 			m_axi_ddr_arburst;
   wire [DDR_CH-1:0] 			m_axi_ddr_arlock;
   wire [DDR_CH*4-1:0] 			m_axi_ddr_arcache;
   wire [DDR_CH*3-1:0] 			m_axi_ddr_arprot;
   wire [DDR_CH*4-1:0] 			m_axi_ddr_arqos;
   wire [DDR_CH-1:0] 			m_axi_ddr_arvalid;
   wire [DDR_CH-1:0] 			m_axi_ddr_arready;
   wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0] 	m_axi_ddr_rid;
   wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0] m_axi_ddr_rdata;
   wire [DDR_CH*2-1:0] 			m_axi_ddr_rresp;
   wire [DDR_CH-1:0] 			m_axi_ddr_rlast;
   wire [DDR_CH-1:0] 			m_axi_ddr_rvalid;
   wire [DDR_CH-1:0] 			m_axi_ddr_rready;

   wire [DDR_CH-1:0] 			ddr_status;

   generate

      if (DDR_ENABLE && DDR_CH > 0) begin

	 reg ddr4_rst_reg = 1'b1;

	 always @(posedge pcie_user_clk or posedge pcie_user_reset) begin
	    if (pcie_user_reset) begin
               ddr4_rst_reg <= 1'b1;
	    end else begin
               ddr4_rst_reg <= 1'b0;
	    end
	 end

	 ddr4_0 ddr4_inst (
			   .c0_sys_clk_p(clk_user_si570_p),
			   .c0_sys_clk_n(clk_user_si570_n),
			   .sys_rst(ddr4_rst_reg),

			   .c0_init_calib_complete(ddr_status[0 +: 1]),
			   .dbg_clk(),
			   .dbg_bus(),

			   .c0_ddr4_adr(ddr4_adr),
			   .c0_ddr4_ba(ddr4_ba),
			   .c0_ddr4_cke(ddr4_cke),
			   .c0_ddr4_cs_n(ddr4_cs_n),
			   .c0_ddr4_dq(ddr4_dq),
			   .c0_ddr4_dqs_t(ddr4_dqs_t),
			   .c0_ddr4_dqs_c(ddr4_dqs_c),
			   .c0_ddr4_dm_dbi_n(ddr4_dm_dbi_n),
			   .c0_ddr4_odt(ddr4_odt),
			   .c0_ddr4_bg(ddr4_bg),
			   .c0_ddr4_reset_n(ddr4_reset_n),
			   .c0_ddr4_act_n(ddr4_act_n),
			   .c0_ddr4_ck_t(ddr4_ck_t),
			   .c0_ddr4_ck_c(ddr4_ck_c),

			   .c0_ddr4_ui_clk(ddr_clk[0 +: 1]),
			   .c0_ddr4_ui_clk_sync_rst(ddr_rst[0 +: 1]),

			   .c0_ddr4_aresetn(!ddr_rst[0 +: 1]),

			   .c0_ddr4_s_axi_awid(m_axi_ddr_awid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
			   .c0_ddr4_s_axi_awaddr(m_axi_ddr_awaddr[0*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
			   .c0_ddr4_s_axi_awlen(m_axi_ddr_awlen[0*8 +: 8]),
			   .c0_ddr4_s_axi_awsize(m_axi_ddr_awsize[0*3 +: 3]),
			   .c0_ddr4_s_axi_awburst(m_axi_ddr_awburst[0*2 +: 2]),
			   .c0_ddr4_s_axi_awlock(m_axi_ddr_awlock[0 +: 1]),
			   .c0_ddr4_s_axi_awcache(m_axi_ddr_awcache[0*4 +: 4]),
			   .c0_ddr4_s_axi_awprot(m_axi_ddr_awprot[0*3 +: 3]),
			   .c0_ddr4_s_axi_awqos(m_axi_ddr_awqos[0*4 +: 4]),
			   .c0_ddr4_s_axi_awvalid(m_axi_ddr_awvalid[0 +: 1]),
			   .c0_ddr4_s_axi_awready(m_axi_ddr_awready[0 +: 1]),
			   .c0_ddr4_s_axi_wdata(m_axi_ddr_wdata[0*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
			   .c0_ddr4_s_axi_wstrb(m_axi_ddr_wstrb[0*AXI_DDR_STRB_WIDTH +: AXI_DDR_STRB_WIDTH]),
			   .c0_ddr4_s_axi_wlast(m_axi_ddr_wlast[0 +: 1]),
			   .c0_ddr4_s_axi_wvalid(m_axi_ddr_wvalid[0 +: 1]),
			   .c0_ddr4_s_axi_wready(m_axi_ddr_wready[0 +: 1]),
			   .c0_ddr4_s_axi_bready(m_axi_ddr_bready[0 +: 1]),
			   .c0_ddr4_s_axi_bid(m_axi_ddr_bid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
			   .c0_ddr4_s_axi_bresp(m_axi_ddr_bresp[0*2 +: 2]),
			   .c0_ddr4_s_axi_bvalid(m_axi_ddr_bvalid[0 +: 1]),
			   .c0_ddr4_s_axi_arid(m_axi_ddr_arid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
			   .c0_ddr4_s_axi_araddr(m_axi_ddr_araddr[0*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
			   .c0_ddr4_s_axi_arlen(m_axi_ddr_arlen[0*8 +: 8]),
			   .c0_ddr4_s_axi_arsize(m_axi_ddr_arsize[0*3 +: 3]),
			   .c0_ddr4_s_axi_arburst(m_axi_ddr_arburst[0*2 +: 2]),
			   .c0_ddr4_s_axi_arlock(m_axi_ddr_arlock[0 +: 1]),
			   .c0_ddr4_s_axi_arcache(m_axi_ddr_arcache[0*4 +: 4]),
			   .c0_ddr4_s_axi_arprot(m_axi_ddr_arprot[0*3 +: 3]),
			   .c0_ddr4_s_axi_arqos(m_axi_ddr_arqos[0*4 +: 4]),
			   .c0_ddr4_s_axi_arvalid(m_axi_ddr_arvalid[0 +: 1]),
			   .c0_ddr4_s_axi_arready(m_axi_ddr_arready[0 +: 1]),
			   .c0_ddr4_s_axi_rready(m_axi_ddr_rready[0 +: 1]),
			   .c0_ddr4_s_axi_rlast(m_axi_ddr_rlast[0 +: 1]),
			   .c0_ddr4_s_axi_rvalid(m_axi_ddr_rvalid[0 +: 1]),
			   .c0_ddr4_s_axi_rresp(m_axi_ddr_rresp[0*2 +: 2]),
			   .c0_ddr4_s_axi_rid(m_axi_ddr_rid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
			   .c0_ddr4_s_axi_rdata(m_axi_ddr_rdata[0*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH])
			   );

      end else begin

	 assign ddr4_adr = {17{1'bz}};
	 assign ddr4_ba = {2{1'bz}};
	 assign ddr4_bg = {1{1'bz}};
	 assign ddr4_cke = 1'bz;
	 assign ddr4_cs_n = 1'bz;
	 assign ddr4_act_n = 1'bz;
	 assign ddr4_odt = 1'bz;
	 assign ddr4_par = 1'bz;
	 assign ddr4_reset_n = 1'b0;
	 assign ddr4_dq = {64{1'bz}};
	 assign ddr4_dqs_t = {8{1'bz}};
	 assign ddr4_dqs_c = {8{1'bz}};

	 OBUFTDS ddr4_ck_obuftds_inst (
				       .I(1'b0),
				       .T(1'b1),
				       .O(ddr4_ck_t),
				       .OB(ddr4_ck_c)
				       );

	 assign ddr_clk = 0;
	 assign ddr_rst = 0;

	 assign m_axi_ddr_awready = 0;
	 assign m_axi_ddr_wready = 0;
	 assign m_axi_ddr_bid = 0;
	 assign m_axi_ddr_bresp = 0;
	 assign m_axi_ddr_bvalid = 0;
	 assign m_axi_ddr_arready = 0;
	 assign m_axi_ddr_rid = 0;
	 assign m_axi_ddr_rdata = 0;
	 assign m_axi_ddr_rresp = 0;
	 assign m_axi_ddr_rlast = 0;
	 assign m_axi_ddr_rvalid = 0;

	 assign ddr_status = 0;

      end

   endgenerate

   fpga_core #(
	       // FW and board IDs
	       .FPGA_ID(FPGA_ID),
	       .FW_ID(FW_ID),
	       .FW_VER(FW_VER),
	       .BOARD_ID(BOARD_ID),
	       .BOARD_VER(BOARD_VER),
	       .BUILD_DATE(BUILD_DATE),
	       .GIT_HASH(GIT_HASH),
	       .RELEASE_INFO(RELEASE_INFO),

	       // Board configuration
	       .TDMA_BER_ENABLE(TDMA_BER_ENABLE),

	       // Structural configuration
	       .IF_COUNT(IF_COUNT),
	       .PORTS_PER_IF(PORTS_PER_IF),
	       .SCHED_PER_IF(SCHED_PER_IF),
	       .PORT_MASK(PORT_MASK),

	       // Clock configuration
	       .CLK_PERIOD_NS_NUM(CLK_PERIOD_NS_NUM),
	       .CLK_PERIOD_NS_DENOM(CLK_PERIOD_NS_DENOM),

	       // PTP configuration
	       .PTP_CLK_PERIOD_NS_NUM(PTP_CLK_PERIOD_NS_NUM),
	       .PTP_CLK_PERIOD_NS_DENOM(PTP_CLK_PERIOD_NS_DENOM),
	       .PTP_TS_WIDTH(PTP_TS_WIDTH),
	       .PTP_CLOCK_PIPELINE(PTP_CLOCK_PIPELINE),
	       .PTP_CLOCK_CDC_PIPELINE(PTP_CLOCK_CDC_PIPELINE),
	       .PTP_PORT_CDC_PIPELINE(PTP_PORT_CDC_PIPELINE),
	       .PTP_PEROUT_ENABLE(PTP_PEROUT_ENABLE),
	       .PTP_PEROUT_COUNT(PTP_PEROUT_COUNT),

	       // Queue manager configuration
	       .EVENT_QUEUE_OP_TABLE_SIZE(EVENT_QUEUE_OP_TABLE_SIZE),
	       .TX_QUEUE_OP_TABLE_SIZE(TX_QUEUE_OP_TABLE_SIZE),
	       .RX_QUEUE_OP_TABLE_SIZE(RX_QUEUE_OP_TABLE_SIZE),
	       .CQ_OP_TABLE_SIZE(CQ_OP_TABLE_SIZE),
	       .EQN_WIDTH(EQN_WIDTH),
	       .TX_QUEUE_INDEX_WIDTH(TX_QUEUE_INDEX_WIDTH),
	       .RX_QUEUE_INDEX_WIDTH(RX_QUEUE_INDEX_WIDTH),
	       .CQN_WIDTH(CQN_WIDTH),
	       .EQ_PIPELINE(EQ_PIPELINE),
	       .TX_QUEUE_PIPELINE(TX_QUEUE_PIPELINE),
	       .RX_QUEUE_PIPELINE(RX_QUEUE_PIPELINE),
	       .CQ_PIPELINE(CQ_PIPELINE),

	       // TX and RX engine configuration
	       .TX_DESC_TABLE_SIZE(TX_DESC_TABLE_SIZE),
	       .RX_DESC_TABLE_SIZE(RX_DESC_TABLE_SIZE),
	       .RX_INDIR_TBL_ADDR_WIDTH(RX_INDIR_TBL_ADDR_WIDTH),

	       // Scheduler configuration
	       .TX_SCHEDULER_OP_TABLE_SIZE(TX_SCHEDULER_OP_TABLE_SIZE),
	       .TX_SCHEDULER_PIPELINE(TX_SCHEDULER_PIPELINE),
	       .TDMA_INDEX_WIDTH(TDMA_INDEX_WIDTH),

	       // Interface configuration
	       .PTP_TS_ENABLE(PTP_TS_ENABLE),
	       .TX_CPL_FIFO_DEPTH(TX_CPL_FIFO_DEPTH),
	       .TX_TAG_WIDTH(TX_TAG_WIDTH),
	       .TX_CHECKSUM_ENABLE(TX_CHECKSUM_ENABLE),
	       .RX_HASH_ENABLE(RX_HASH_ENABLE),
	       .RX_CHECKSUM_ENABLE(RX_CHECKSUM_ENABLE),
	       .ENABLE_PADDING(ENABLE_PADDING),
	       .ENABLE_DIC(ENABLE_DIC),
	       .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH),
	       .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
	       .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
	       .MAX_TX_SIZE(MAX_TX_SIZE),
	       .MAX_RX_SIZE(MAX_RX_SIZE),
	       .TX_RAM_SIZE(TX_RAM_SIZE),
	       .RX_RAM_SIZE(RX_RAM_SIZE),

	       // RAM configuration
	       .DDR_CH(DDR_CH),
	       .DDR_ENABLE(DDR_ENABLE),
	       .AXI_DDR_DATA_WIDTH(AXI_DDR_DATA_WIDTH),
	       .AXI_DDR_ADDR_WIDTH(AXI_DDR_ADDR_WIDTH),
	       .AXI_DDR_STRB_WIDTH(AXI_DDR_STRB_WIDTH),
	       .AXI_DDR_ID_WIDTH(AXI_DDR_ID_WIDTH),
	       .AXI_DDR_MAX_BURST_LEN(AXI_DDR_MAX_BURST_LEN),
	       .AXI_DDR_NARROW_BURST(AXI_DDR_NARROW_BURST),

	       // Application block configuration
	       .APP_ID(APP_ID),
	       .APP_ENABLE(APP_ENABLE),
	       .APP_CTRL_ENABLE(APP_CTRL_ENABLE),
	       .APP_DMA_ENABLE(APP_DMA_ENABLE),
	       .APP_AXIS_DIRECT_ENABLE(APP_AXIS_DIRECT_ENABLE),
	       .APP_AXIS_SYNC_ENABLE(APP_AXIS_SYNC_ENABLE),
	       .APP_AXIS_IF_ENABLE(APP_AXIS_IF_ENABLE),
	       .APP_STAT_ENABLE(APP_STAT_ENABLE),

	       // DMA interface configuration
	       .DMA_IMM_ENABLE(DMA_IMM_ENABLE),
	       .DMA_IMM_WIDTH(DMA_IMM_WIDTH),
	       .DMA_LEN_WIDTH(DMA_LEN_WIDTH),
	       .DMA_TAG_WIDTH(DMA_TAG_WIDTH),
	       .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
	       .RAM_PIPELINE(RAM_PIPELINE),

	       // PCIe interface configuration
	       .AXIS_PCIE_DATA_WIDTH(AXIS_PCIE_DATA_WIDTH),
	       .AXIS_PCIE_KEEP_WIDTH(AXIS_PCIE_KEEP_WIDTH),
	       .AXIS_PCIE_RC_USER_WIDTH(AXIS_PCIE_RC_USER_WIDTH),
	       .AXIS_PCIE_RQ_USER_WIDTH(AXIS_PCIE_RQ_USER_WIDTH),
	       .AXIS_PCIE_CQ_USER_WIDTH(AXIS_PCIE_CQ_USER_WIDTH),
	       .AXIS_PCIE_CC_USER_WIDTH(AXIS_PCIE_CC_USER_WIDTH),
	       .RC_STRADDLE(RC_STRADDLE),
	       .RQ_STRADDLE(RQ_STRADDLE),
	       .CQ_STRADDLE(CQ_STRADDLE),
	       .CC_STRADDLE(CC_STRADDLE),
	       .RQ_SEQ_NUM_WIDTH(RQ_SEQ_NUM_WIDTH),
	       .PF_COUNT(PF_COUNT),
	       .VF_COUNT(VF_COUNT),
	       .PCIE_TAG_COUNT(PCIE_TAG_COUNT),

	       // Interrupt configuration
	       .IRQ_INDEX_WIDTH(IRQ_INDEX_WIDTH),

	       // AXI lite interface configuration (control)
	       .AXIL_CTRL_DATA_WIDTH(AXIL_CTRL_DATA_WIDTH),
	       .AXIL_CTRL_ADDR_WIDTH(AXIL_CTRL_ADDR_WIDTH),

	       // AXI lite interface configuration (application control)
	       .AXIL_APP_CTRL_DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
	       .AXIL_APP_CTRL_ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),

	       // Ethernet interface configuration
	       .XGMII_DATA_WIDTH(XGMII_DATA_WIDTH),
	       .XGMII_CTRL_WIDTH(XGMII_CTRL_WIDTH),
	       .AXIS_ETH_DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
	       .AXIS_ETH_KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
	       .AXIS_ETH_SYNC_DATA_WIDTH(AXIS_ETH_SYNC_DATA_WIDTH),
	       .AXIS_ETH_TX_USER_WIDTH(AXIS_ETH_TX_USER_WIDTH),
	       .AXIS_ETH_RX_USER_WIDTH(AXIS_ETH_RX_USER_WIDTH),
	       .AXIS_ETH_TX_PIPELINE(AXIS_ETH_TX_PIPELINE),
	       .AXIS_ETH_TX_FIFO_PIPELINE(AXIS_ETH_TX_FIFO_PIPELINE),
	       .AXIS_ETH_TX_TS_PIPELINE(AXIS_ETH_TX_TS_PIPELINE),
	       .AXIS_ETH_RX_PIPELINE(AXIS_ETH_RX_PIPELINE),
	       .AXIS_ETH_RX_FIFO_PIPELINE(AXIS_ETH_RX_FIFO_PIPELINE),

	       // Statistics counter subsystem
	       .STAT_ENABLE(STAT_ENABLE),
	       .STAT_DMA_ENABLE(STAT_DMA_ENABLE),
	       .STAT_PCIE_ENABLE(STAT_PCIE_ENABLE),
	       .STAT_INC_WIDTH(STAT_INC_WIDTH),
	       .STAT_ID_WIDTH(STAT_ID_WIDTH)
	       )
   core_inst (
	      /*
	       * Clock: 250 MHz
	       * Synchronous reset
	       */
	      .clk_250mhz(pcie_user_clk),
	      .rst_250mhz(pcie_user_reset),

	      /*
	       * PTP clock
	       */
	      .ptp_clk(ptp_clk),
	      .ptp_rst(ptp_rst),
	      .ptp_sample_clk(ptp_sample_clk),

	      /*
	       * GPIO -- not used
	       */
	      .btnu(1'b0),
	      .btnl(1'b0),
	      .btnd(1'b0),
	      .btnr(1'b0),
	      .btnc(1'b0),
	      .sw(1'b0),
	      .led(led),

	      /*
	       * I2C
	       */
	      .i2c_scl_i(i2c1_scl_i),
	      .i2c_scl_o(i2c1_scl_o),
	      .i2c_scl_t(i2c1_scl_t),
	      .i2c_sda_i(i2c1_sda_i),
	      .i2c_sda_o(i2c1_sda_o),
	      .i2c_sda_t(i2c1_sda_t),

	      /*
	       * PCIe
	       */
	      .m_axis_rq_tdata(axis_rq_tdata),
	      .m_axis_rq_tkeep(axis_rq_tkeep),
	      .m_axis_rq_tlast(axis_rq_tlast),
	      .m_axis_rq_tready(axis_rq_tready),
	      .m_axis_rq_tuser(axis_rq_tuser),
	      .m_axis_rq_tvalid(axis_rq_tvalid),

	      .s_axis_rc_tdata(axis_rc_tdata),
	      .s_axis_rc_tkeep(axis_rc_tkeep),
	      .s_axis_rc_tlast(axis_rc_tlast),
	      .s_axis_rc_tready(axis_rc_tready),
	      .s_axis_rc_tuser(axis_rc_tuser),
	      .s_axis_rc_tvalid(axis_rc_tvalid),

	      .s_axis_cq_tdata(axis_cq_tdata),
	      .s_axis_cq_tkeep(axis_cq_tkeep),
	      .s_axis_cq_tlast(axis_cq_tlast),
	      .s_axis_cq_tready(axis_cq_tready),
	      .s_axis_cq_tuser(axis_cq_tuser),
	      .s_axis_cq_tvalid(axis_cq_tvalid),

	      .m_axis_cc_tdata(axis_cc_tdata),
	      .m_axis_cc_tkeep(axis_cc_tkeep),
	      .m_axis_cc_tlast(axis_cc_tlast),
	      .m_axis_cc_tready(axis_cc_tready),
	      .m_axis_cc_tuser(axis_cc_tuser),
	      .m_axis_cc_tvalid(axis_cc_tvalid),

	      .s_axis_rq_seq_num_0(pcie_rq_seq_num0),
	      .s_axis_rq_seq_num_valid_0(pcie_rq_seq_num_vld0),
	      .s_axis_rq_seq_num_1(pcie_rq_seq_num1),
	      .s_axis_rq_seq_num_valid_1(pcie_rq_seq_num_vld1),

	      .pcie_tfc_nph_av(pcie_tfc_nph_av),
	      .pcie_tfc_npd_av(pcie_tfc_npd_av),

	      .cfg_max_payload(cfg_max_payload),
	      .cfg_max_read_req(cfg_max_read_req),
	      .cfg_rcb_status(cfg_rcb_status),

	      .cfg_mgmt_addr(cfg_mgmt_addr),
	      .cfg_mgmt_function_number(cfg_mgmt_function_number),
	      .cfg_mgmt_write(cfg_mgmt_write),
	      .cfg_mgmt_write_data(cfg_mgmt_write_data),
	      .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),
	      .cfg_mgmt_read(cfg_mgmt_read),
	      .cfg_mgmt_read_data(cfg_mgmt_read_data),
	      .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),

	      .cfg_fc_ph(cfg_fc_ph),
	      .cfg_fc_pd(cfg_fc_pd),
	      .cfg_fc_nph(cfg_fc_nph),
	      .cfg_fc_npd(cfg_fc_npd),
	      .cfg_fc_cplh(cfg_fc_cplh),
	      .cfg_fc_cpld(cfg_fc_cpld),
	      .cfg_fc_sel(cfg_fc_sel),

	      .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),
	      .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),
	      .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),
	      .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),
	      .cfg_interrupt_msix_address(cfg_interrupt_msix_address),
	      .cfg_interrupt_msix_data(cfg_interrupt_msix_data),
	      .cfg_interrupt_msix_int(cfg_interrupt_msix_int),
	      .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),
	      .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),
	      .cfg_interrupt_msix_sent(cfg_interrupt_msix_sent),
	      .cfg_interrupt_msix_fail(cfg_interrupt_msix_fail),
	      .cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number),

	      .status_error_cor(status_error_cor),
	      .status_error_uncor(status_error_uncor),

	      /*
	       * Ethernet: SFP+
	       */
	      .sfp0_tx_clk(sfp0_tx_clk_int),
	      .sfp0_tx_rst(sfp0_tx_rst_int),
	      .sfp0_txd(sfp0_txd_int),
	      .sfp0_txc(sfp0_txc_int),
	      .sfp0_cfg_tx_prbs31_enable(sfp0_cfg_tx_prbs31_enable_int),
	      .sfp0_rx_clk(sfp0_rx_clk_int),
	      .sfp0_rx_rst(sfp0_rx_rst_int),
	      .sfp0_rxd(sfp0_rxd_int),
	      .sfp0_rxc(sfp0_rxc_int),
	      .sfp0_cfg_rx_prbs31_enable(sfp0_cfg_rx_prbs31_enable_int),
	      .sfp0_rx_error_count(sfp0_rx_error_count_int),
	      .sfp0_rx_status(sfp0_rx_status),
	      .sfp0_tx_disable_b(sfp0_tx_disable_b),

	      .sfp1_tx_clk(sfp1_tx_clk_int),
	      .sfp1_tx_rst(sfp1_tx_rst_int),
	      .sfp1_txd(sfp1_txd_int),
	      .sfp1_txc(sfp1_txc_int),
	      .sfp1_cfg_tx_prbs31_enable(sfp1_cfg_tx_prbs31_enable_int),
	      .sfp1_rx_clk(sfp1_rx_clk_int),
	      .sfp1_rx_rst(sfp1_rx_rst_int),
	      .sfp1_rxd(sfp1_rxd_int),
	      .sfp1_rxc(sfp1_rxc_int),
	      .sfp1_cfg_rx_prbs31_enable(sfp1_cfg_rx_prbs31_enable_int),
	      .sfp1_rx_error_count(sfp1_rx_error_count_int),
	      .sfp1_rx_status(sfp1_rx_status),
	      .sfp1_tx_disable_b(sfp1_tx_disable_b),

	      .sfp_drp_clk(sfp_drp_clk),
	      .sfp_drp_rst(sfp_drp_rst),
	      .sfp_drp_addr(sfp_drp_addr),
	      .sfp_drp_di(sfp_drp_di),
	      .sfp_drp_en(sfp_drp_en),
	      .sfp_drp_we(sfp_drp_we),
	      .sfp_drp_do(sfp_drp_do),
	      .sfp_drp_rdy(sfp_drp_rdy),

	      /*
	       * DDR
	       */
	      .ddr_clk(ddr_clk),
	      .ddr_rst(ddr_rst),

	      .m_axi_ddr_awid(m_axi_ddr_awid),
	      .m_axi_ddr_awaddr(m_axi_ddr_awaddr),
	      .m_axi_ddr_awlen(m_axi_ddr_awlen),
	      .m_axi_ddr_awsize(m_axi_ddr_awsize),
	      .m_axi_ddr_awburst(m_axi_ddr_awburst),
	      .m_axi_ddr_awlock(m_axi_ddr_awlock),
	      .m_axi_ddr_awcache(m_axi_ddr_awcache),
	      .m_axi_ddr_awprot(m_axi_ddr_awprot),
	      .m_axi_ddr_awqos(m_axi_ddr_awqos),
	      .m_axi_ddr_awvalid(m_axi_ddr_awvalid),
	      .m_axi_ddr_awready(m_axi_ddr_awready),
	      .m_axi_ddr_wdata(m_axi_ddr_wdata),
	      .m_axi_ddr_wstrb(m_axi_ddr_wstrb),
	      .m_axi_ddr_wlast(m_axi_ddr_wlast),
	      .m_axi_ddr_wvalid(m_axi_ddr_wvalid),
	      .m_axi_ddr_wready(m_axi_ddr_wready),
	      .m_axi_ddr_bid(m_axi_ddr_bid),
	      .m_axi_ddr_bresp(m_axi_ddr_bresp),
	      .m_axi_ddr_bvalid(m_axi_ddr_bvalid),
	      .m_axi_ddr_bready(m_axi_ddr_bready),
	      .m_axi_ddr_arid(m_axi_ddr_arid),
	      .m_axi_ddr_araddr(m_axi_ddr_araddr),
	      .m_axi_ddr_arlen(m_axi_ddr_arlen),
	      .m_axi_ddr_arsize(m_axi_ddr_arsize),
	      .m_axi_ddr_arburst(m_axi_ddr_arburst),
	      .m_axi_ddr_arlock(m_axi_ddr_arlock),
	      .m_axi_ddr_arcache(m_axi_ddr_arcache),
	      .m_axi_ddr_arprot(m_axi_ddr_arprot),
	      .m_axi_ddr_arqos(m_axi_ddr_arqos),
	      .m_axi_ddr_arvalid(m_axi_ddr_arvalid),
	      .m_axi_ddr_arready(m_axi_ddr_arready),
	      .m_axi_ddr_rid(m_axi_ddr_rid),
	      .m_axi_ddr_rdata(m_axi_ddr_rdata),
	      .m_axi_ddr_rresp(m_axi_ddr_rresp),
	      .m_axi_ddr_rlast(m_axi_ddr_rlast),
	      .m_axi_ddr_rvalid(m_axi_ddr_rvalid),
	      .m_axi_ddr_rready(m_axi_ddr_rready),

	      .ddr_status(ddr_status)
	      );
   
   
endmodule // system_top
