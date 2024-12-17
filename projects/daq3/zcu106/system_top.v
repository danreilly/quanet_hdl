// ***************************************************************************
// ***************************************************************************
// Copyright (C) 2017-2023 Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/main/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (
  output 	j3_6, // trigger to scope
  		   
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

  output 	c0_ddr4_act_n,
  output [16:0] c0_ddr4_adr,
  output [ 1:0] c0_ddr4_ba,
  output 	c0_ddr4_bg,
  output 	c0_ddr4_ck_c,
  output 	c0_ddr4_ck_t,
  output 	c0_ddr4_cke,
  output 	c0_ddr4_cs_n,
  inout [ 7:0] c0_ddr4_dm_dbi_n,
  inout [63:0] 	c0_ddr4_dq,
  inout [ 7:0] 	c0_ddr4_dqs_c,
  inout [ 7:0] 	c0_ddr4_dqs_t,
  output 	c0_ddr4_odt,
  output 	c0_ddr4_reset_n,

//  inout iic_main_scl,
//  inout iic_main_sda,
		   
  // for switches, buttons and leds (which are different from board to board)
  input [12:0] 	gpio_bd_i,
  input [20:13] gpio_bd_o,

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


  // These control lines go out through FMC
  // to the chips on the DAQ3 board:
  inout 	adc_pd,
  inout 	dac_txen,
  inout 	adc_fdb,
  inout 	adc_fda,
  inout 	dac_irq,
  inout [ 1:0] 	clkd_status,

// Not using:		   
//  output 	sysref_p,
//  output 	sysref_n,
		   
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
  wire                    tx_sysref;
  wire                    tx_sync;

  wire 		  junk;
   
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
  IBUFDS_GTE4 i_ibufds_tx_ref_clk (
    .CEB (1'd0),
    .I (tx_ref_clk_p),
    .IB (tx_ref_clk_n),
    .O (tx_ref_clk),
    .ODIV2 ());

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
    .spi_csn (spi_csn),
    .spi_clk (spi_clk),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_miso),
		  
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir));

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
              junk, 
              clkd_status}));   // 32

  assign gpio_i[12:0]   = gpio_bd_i[12:0];
  assign gpio_bd_0 = gpio_o[20:13];
   
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

   


  system_wrapper i_system_wrapper (
    .dac_xfer_out_port (j3_6),

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
//    .spi1_sclk (spi1_clk),
//    .spi1_csn  (spi1_csn),
    .spi1_miso (0),
//    .spi1_mosi (spi1_mosi),
				   
    .sys_clk_clk_n (sys_clk_n),
    .sys_clk_clk_p (sys_clk_p),
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

endmodule
