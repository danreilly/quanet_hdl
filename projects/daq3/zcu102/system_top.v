
`timescale 1ns/100ps

module system_top (
  output 	j3_6, // hdr vld
  input 	j3_10, // ser0 rx
  output 	j3_12, // ser0 tx
  input 	j3_14, // ser1 rx
  output 	j3_16, // ser1 tx

  output 	 sfp0_tx_p,
  output 	 sfp0_tx_n,
  input 	 sfp0_rx_p,
  input 	 sfp0_rx_n,
  output 	 sfp0_tx_dis, 
  input 	 si5328_out_c_p,
  input 	 si5328_out_c_n,

  output rec_clock_p,
  output rec_clock_n,
		   
  output 	c0_ddr4_act_n,
  output [16:0] c0_ddr4_adr,
  output [ 1:0] c0_ddr4_ba,
  output 	c0_ddr4_bg,
  output 	c0_ddr4_ck_c,
  output 	c0_ddr4_ck_t,
  output 	c0_ddr4_cke,
  output 	c0_ddr4_cs_n,
  inout [ 1:0] 	c0_ddr4_dm_dbi_n,
  inout [15:0] 	c0_ddr4_dq,
  inout [ 1:0] 	c0_ddr4_dqs_c,
  inout [ 1:0] 	c0_ddr4_dqs_t,
  output 	c0_ddr4_odt,
  output 	c0_ddr4_reset_n,
		   
  input [12:0] 	gpio_bd_i,
  output [ 7:0] gpio_bd_o,

  input 	rx_ref_clk_p,
  input 	rx_ref_clk_n,
  input 	rx_sysref_p,
  input 	rx_sysref_n,
  output 	rx_sync_p,
  output 	rx_sync_n,
  input [ 3:0] 	rx_data_p,
  input [ 3:0] 	rx_data_n,

  input 	tx_ref_clk_p,
  input 	tx_ref_clk_n,
  input 	tx_sysref_p,
  input 	tx_sysref_n,
  input 	tx_sync_p,
  input 	tx_sync_n,
  output [ 3:0] tx_data_p,
  output [ 3:0] tx_data_n,

  input 	trig_p,
  input 	trig_n,

  inout 	adc_fdb,
  inout 	adc_fda,
  inout 	dac_irq,
  inout [ 1:0] 	clkd_status,

  inout 	adc_pd,
  inout 	dac_txen,
  output 	sysref_p,
  output 	sysref_n,

  output 	spi_csn_clk,
  output 	spi_csn_dac,
  output 	spi_csn_adc,
  output 	spi_clk,
  inout 	spi_sdio,
  output 	spi_dir,

  input 	sys_clk_p,
  input 	sys_clk_n
		   
);

  // internal signals
  wire   mgt_clkref, rec_clk_out, rxq_sw_ctl, si570_half;
  wire 	  dbg_clk, dbg_clk_sel, dac_clk, dma_clk, sfp_txclk,
	  sfp_rxclk_out,sfp_rxclk_vld, ser0_tx, ser1_tx,
    sfp_rxclk, gth_rst;
  wire [3:0] gth_status;

  wire        [94:0]      gpio_i;
  wire        [94:0]      gpio_o;
  wire        [94:0]      gpio_t;
  wire        [20:0]      gpio_bd;
  wire        [ 2:0]      spi_csn;
  wire                    spi_mosi;
  wire                    spi_miso;
  wire                    trig;
  wire                    rx_ref_clk;
  wire                    rx_sysref;
  wire                    rx_sync;
  wire                    tx_ref_clk;
  wire                    tx_sysref;
  wire                    tx_sync;

  // spi

  assign spi_csn_adc = spi_csn[2];
  assign spi_csn_dac = spi_csn[1];
  assign spi_csn_clk = spi_csn[0];

  // instantiations

  IBUFDS_GTE4 i_ibufds_rx_ref_clk (
    .CEB (1'd0),
    .I (rx_ref_clk_p),
    .IB (rx_ref_clk_n),
    .O (rx_ref_clk),
    .ODIV2 ());

  IBUFDS i_ibufds_rx_sysref (
    .I (rx_sysref_p),
    .IB (rx_sysref_n),
    .O (rx_sysref));

  OBUFDS i_obufds_rx_sync (
    .I (rx_sync),
    .O (rx_sync_p),
    .OB (rx_sync_n));

  IBUFDS_GTE4 i_ibufds_tx_ref_clk (
    .CEB (1'd0),
    .I (tx_ref_clk_p),
    .IB (tx_ref_clk_n),
    .O (tx_ref_clk),
    .ODIV2 ());

  IBUFDS i_ibufds_tx_sysref (
    .I (tx_sysref_p),
    .IB (tx_sysref_n),
    .O (tx_sysref));

  IBUFDS i_ibufds_tx_sync (
    .I (tx_sync_p),
    .IB (tx_sync_n),
    .O (tx_sync));

  daq3_spi i_spi (
    .spi_csn (spi_csn),
    .spi_clk (spi_clk),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_miso),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir));

  OBUFDS i_obufds_sysref (
    .I (gpio_o[40]),
    .O (sysref_p),
    .OB (sysref_n));

  IBUFDS i_ibufds_trig (
    .I (trig_p),
    .IB (trig_n),
    .O (trig));

  assign gpio_i[94:40] = gpio_o[94:40];
  assign gpio_i[39] = trig;

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
              clkd_status}));   // 32

  assign gpio_i[31:21] = gpio_o[31:21];

  /* Board GPIOS. Buttons, LEDs, etc... */
  assign gpio_i[20: 8] = gpio_bd_i;
  assign gpio_bd_o = gpio_o[7:0];




  // This emits an LFSR pattern out SFP0.
  // Could be used for testing the system without the classical NIC.
  // in bank 225
  IBUFDS_GTE4 #(
      .REFCLK_HROW_CK_SEL(1)
    ) gtrefclk_ibuf (
      .CEB(0),
      .I(si5328_out_c_p),
      .IB(si5328_out_c_n),
//      .ODIV2(si570_half),
      .O(mgt_clkref));
  gth_driver i_gthdrv (
    .tx_p(sfp0_tx_p),
    .tx_n(sfp0_tx_n),
    .rx_p(sfp0_rx_p),
    .rx_n(sfp0_rx_n),
    .rst(gth_rst),		       
    .status(gth_status),
    .dma_clk(dma_clk),
    .rxclk_out(sfp_rxclk),
    .rxclk_vld(sfp_rxclk_vld),
    .txclk_out(sfp_txclk),
    .gtrefclk(mgt_clkref));

   
  // Note: ODDR in ultrascale vs 7series is different
  ODDRE1 recclk_oddr(
     .C(dac_clk),
     .D1(0),
     .D2(1),
     .SR(0),
     .Q(rec_clk_out));
  OBUFDS tojitattn_obuf (
     .I(rec_clk_out),
     .O (rec_clock_p),
     .OB(rec_clock_n));
  assign sfp_tx_dis = 0;

   
  // inverted because of inverting level translator on zcucon board
  assign j3_12 = ~ser0_tx;
  assign j3_16 = ~ser1_tx;
   
  system_wrapper i_system_wrapper (
    .ser0_rx (j3_10),
    .ser0_tx (ser0_tx),
    .ser1_rx (j3_14),
    .ser1_tx (ser1_tx),
    .hdr_vld    (j3_6),				   
    .dac_clk_out(dac_clk), // 302MHz
    .sfp_rxclk_in(sfp_rxclk),
    .sfp_rxclk_vld(sfp_rxclk_vld),

    .ddr4_act_n(c0_ddr4_act_n),
    .ddr4_adr (c0_ddr4_adr),
    .ddr4_ba (c0_ddr4_ba),
    .ddr4_bg (c0_ddr4_bg),
    .ddr4_ck_c (c0_ddr4_ck_c),
    .ddr4_ck_t (c0_ddr4_ck_t),
    .ddr4_cke (c0_ddr4_cke),
    .ddr4_cs_n (c0_ddr4_cs_n),
    .ddr4_dm_n (c0_ddr4_dm_dbi_n),
    .ddr4_dq (c0_ddr4_dq),
    .ddr4_dqs_c (c0_ddr4_dqs_c),
    .ddr4_dqs_t (c0_ddr4_dqs_t),
    .ddr4_odt (c0_ddr4_odt),
    .ddr4_reset_n (c0_ddr4_reset_n),

    .gth_status(gth_status),
    .gth_rst(gth_rst),
				   
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .rx_data_0_n (rx_data_n[0]),
    .rx_data_0_p (rx_data_p[0]),
    .rx_data_1_n (rx_data_n[1]),
    .rx_data_1_p (rx_data_p[1]),
    .rx_data_2_n (rx_data_n[2]),
    .rx_data_2_p (rx_data_p[2]),
    .rx_data_3_n (rx_data_n[3]),
    .rx_data_3_p (rx_data_p[3]),
    .rx_ref_clk_0 (rx_ref_clk),
    .rx_sync_0 (rx_sync),
    .rx_sysref_0 (rx_sysref),
    .spi0_csn (spi_csn),
    .spi0_miso (spi_miso),
    .spi0_mosi (spi_mosi),
    .spi0_sclk (spi_clk),
    .spi1_csn (),
    .spi1_miso (1'd0),
    .spi1_mosi (),
    .spi1_sclk (),

    .sys_clk_clk_n (sys_clk_n),
    .sys_clk_clk_p (sys_clk_p),
				   
    .dac_fifo_bypass(gpio_o[41]),
    .tx_data_0_n (tx_data_n[0]),
    .tx_data_0_p (tx_data_p[0]),
    .tx_data_1_n (tx_data_n[1]),
    .tx_data_1_p (tx_data_p[1]),
    .tx_data_2_n (tx_data_n[2]),
    .tx_data_2_p (tx_data_p[2]),
    .tx_data_3_n (tx_data_n[3]),
    .tx_data_3_p (tx_data_p[3]),
    .tx_ref_clk_0 (tx_ref_clk),
    .tx_sync_0 (tx_sync),
    .tx_sysref_0 (tx_sysref));

endmodule
