
`timescale 1ns/100ps

module system_top (
  output 	j67,
  output 	j68,

  output 	sfp_tx_p,
  output 	sfp_tx_n,
  input 	sfp_rx_p,
  input 	sfp_rx_n,
  output        sfp_tx_dis,		   
  input 	si5324_out_c_p,
  input 	si5324_out_c_n,
		   
  inout [14:0] 	ddr_addr,
  inout [ 2:0] 	ddr_ba,
  inout 	ddr_cas_n,
  inout 	ddr_ck_n,
  inout 	ddr_ck_p,
  inout 	ddr_cke,
  inout 	ddr_cs_n,
  inout [ 3:0] 	ddr_dm,
  inout [31:0] 	ddr_dq,
  inout [ 3:0] 	ddr_dqs_n,
  inout [ 3:0] 	ddr_dqs_p,
  inout 	ddr_odt,
  inout 	ddr_ras_n,
  inout 	ddr_reset_n,
  inout 	ddr_we_n,

  inout 	fixed_io_ddr_vrn,
  inout 	fixed_io_ddr_vrp,
  inout [53:0] 	fixed_io_mio,
  inout 	fixed_io_ps_clk,
  inout 	fixed_io_ps_porb,
  inout 	fixed_io_ps_srstb,

  inout [14:0] 	gpio_bd,

  output 	hdmi_out_clk,
  output 	hdmi_vsync,
  output 	hdmi_hsync,
  output 	hdmi_data_e,
  output [23:0] hdmi_data,

  output 	spdif,

  input 	sys_rst,
  input 	sys_clk_p,
  input 	sys_clk_n,

  output [13:0] ddr3_addr,
  output [ 2:0] ddr3_ba,
  output 	ddr3_cas_n,
  output [ 0:0] ddr3_ck_n,
  output [ 0:0] ddr3_ck_p,
  output [ 0:0] ddr3_cke,
  output [ 0:0] ddr3_cs_n,
  output [ 7:0] ddr3_dm,
  inout [63:0] 	ddr3_dq,
  inout [ 7:0] 	ddr3_dqs_n,
  inout [ 7:0] 	ddr3_dqs_p,
  output [ 0:0] ddr3_odt,
  output 	ddr3_ras_n,
  output 	ddr3_reset_n,
  output 	ddr3_we_n,

  inout 	iic_scl,
  inout 	iic_sda,

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

//  output [3:0] 	leds, 
		   
  output 	spi_csn_clk,
  output 	spi_csn_dac,
  output 	spi_csn_adc,
  output 	spi_clk,
  inout 	spi_sdio,
  output 	spi_dir
);

  // internal signals

  wire            sysref;
  wire    [63:0]  gpio_i;
  wire    [63:0]  gpio_o;
  wire    [63:0]  gpio_t;
  wire    [ 2:0]  spi0_csn;
  wire            spi0_clk;
  wire            spi0_mosi;
  wire            spi0_miso;
  wire    [ 2:0]  spi1_csn;
  wire            spi1_clk;
  wire            spi1_mosi;
  wire            spi1_miso;
  wire            trig;
  wire            rx_ref_clk;
  wire            rx_sysref;
  wire            rx_sync;
  wire            tx_ref_clk;
  wire            tx_sysref;
  wire            tx_sync;
  wire 	  led1;
//  wire [3:0] leds;
   wire   scopetrig;
   wire   si5324_out_c;

 

  // spi

  assign spi_csn_adc = spi0_csn[2];
  assign spi_csn_dac = spi0_csn[1];
  assign spi_csn_clk = spi0_csn[0];

  // instantiations

  IBUFDS_GTE2 i_ibufds_rx_ref_clk (
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

  IBUFDS_GTE2 i_ibufds_tx_ref_clk (
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
    .spi_csn (spi0_csn),
    .spi_clk (spi_clk),
    .spi_mosi (spi0_mosi),
    .spi_miso (spi0_miso),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir));

  // Dan: This connects to FMC LA15, which is the sysref input to the daq3 board,
  // but I don't understand how the processor could possibly operate GPIO
  // precisely enough to generate the sysref to the DAQ3 board's AD9528 clk chip.
  // However, use of the sysref input is optional.  Perhaps it isnt used.
  OBUFDS i_obufds_sysref (
    .I (gpio_o[40]),
    .O (sysref_p),
    .OB (sysref_n));

  // trig comes from FMC LA07, from the J1 SMA of the DAQ3 board.
  IBUFDS i_ibufds_trig (
    .I (trig_p),
    .IB (trig_n),
    .O (trig));

  assign gpio_i[39] = trig;
  assign spi_clk = spi0_clk;

  // This widh is not seven!
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

  ad_iobuf #(
    .DATA_WIDTH(15)
  ) i_iobuf_bd (
    .dio_t (gpio_t[14:0]),
    .dio_i (gpio_o[14:0]),
    .dio_o (gpio_i[14:0]),
    .dio_p (gpio_bd[14:0]));

  // in quad 110
  IBUFDS_GTE2 gtrefclk_ibuf (
      .CEB(0),
      .I(si5324_out_c_p),
      .IB(si5324_out_c_n),
      .O(si5324_out_c));
   
  // in quad 111   
  gtx_driver i_gtxdrv (
    .tx_p(sfp_tx_p),
    .tx_n(sfp_tx_n),
    .rx_p(sfp_rx_p),
    .rx_n(sfp_rx_n),
    .gtrefclk(si5324_out_c));
   

	     
   

   
// assign gpio_bd[10:7] = leds;
   assign sfp_tx_dis = 0;
   
   

  assign gpio_i[63:40] = gpio_o[63:40];
  assign gpio_i[31:15] = gpio_o[31:15];


   
  system_wrapper i_system_wrapper (
    .dac_xfer_out_port (j67),
    .rxq_sw_ctl (j68),				   
//    .led0 (leds[0]),
//    .led1 (led1),
//    .led2 (leds[2]),
    .ddr3_addr (ddr3_addr),
    .ddr3_ba (ddr3_ba),
    .ddr3_cas_n (ddr3_cas_n),
    .ddr3_ck_n (ddr3_ck_n),
    .ddr3_ck_p (ddr3_ck_p),
    .ddr3_cke (ddr3_cke),
    .ddr3_cs_n (ddr3_cs_n),
    .ddr3_dm (ddr3_dm),
    .ddr3_dq (ddr3_dq),
    .ddr3_dqs_n (ddr3_dqs_n),
    .ddr3_dqs_p (ddr3_dqs_p),
    .ddr3_odt (ddr3_odt),
    .ddr3_ras_n (ddr3_ras_n),
    .ddr3_reset_n (ddr3_reset_n),
    .ddr3_we_n (ddr3_we_n),
    .ddr_addr (ddr_addr),
    .ddr_ba (ddr_ba),
    .ddr_cas_n (ddr_cas_n),
    .ddr_ck_n (ddr_ck_n),
    .ddr_ck_p (ddr_ck_p),
    .ddr_cke (ddr_cke),
    .ddr_cs_n (ddr_cs_n),
    .ddr_dm (ddr_dm),
    .ddr_dq (ddr_dq),
    .ddr_dqs_n (ddr_dqs_n),
    .ddr_dqs_p (ddr_dqs_p),
    .ddr_odt (ddr_odt),
    .ddr_ras_n (ddr_ras_n),
    .ddr_reset_n (ddr_reset_n),
    .ddr_we_n (ddr_we_n),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .hdmi_data (hdmi_data),
    .hdmi_data_e (hdmi_data_e),
    .hdmi_hsync (hdmi_hsync),
    .hdmi_out_clk (hdmi_out_clk),
    .hdmi_vsync (hdmi_vsync),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),
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
    .spdif (spdif),
				   
    .spi0_clk_i (spi0_clk),
    .spi0_clk_o (spi0_clk),
    .spi0_csn_0_o (spi0_csn[0]),
    .spi0_csn_1_o (spi0_csn[1]),
    .spi0_csn_2_o (spi0_csn[2]),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (spi0_miso),
    .spi0_sdo_i (spi0_mosi),
    .spi0_sdo_o (spi0_mosi),
				   
    .spi1_clk_i (spi1_clk),
    .spi1_clk_o (spi1_clk),
    .spi1_csn_0_o (spi1_csn[0]),
    .spi1_csn_1_o (spi1_csn[1]),
    .spi1_csn_2_o (spi1_csn[2]),
    .spi1_csn_i (1'b1),
    .spi1_sdi_i (1'b1),
    .spi1_sdo_i (spi1_mosi),
    .spi1_sdo_o (spi1_mosi),
				   
    .sys_clk_clk_n (sys_clk_n),
    .sys_clk_clk_p (sys_clk_p),
    .sys_rst (sys_rst),
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
