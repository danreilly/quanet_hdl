// ***************************************************************************
// ***************************************************************************
// Copyright (C) 2014-2023 Analog Devices, Inc. All rights reserved.
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

module axi_adcfifo #(

  parameter   ADC_DATA_WIDTH = 128,
  parameter   DMA_DATA_WIDTH = 64,
  parameter   AXI_DATA_WIDTH = 512,
  parameter   DMA_READY_ENABLE = 1,
  parameter   AXI_SIZE = 2,
  parameter   AXI_LENGTH = 16,
  parameter   AXI_ADDRESS = 32'h00000000,
  parameter   AXI_ADDRESS_LIMIT = 32'hffffffff
) (
   
  // NuCrypt additions
  output reg 			  rxq_sw_ctl,
  input 			  dac_clk,
  output 			  dac_tx,
  input 			  dac_tx_in,

  // NuCrypt added this slave axi iface for regs.
  // Slave AXI interface
  input 			  s_axi_aclk,
  input 			  s_axi_aresetn,
  input 			  s_axi_awvalid,
  input [10:0] 			  s_axi_awaddr,
  output 			  s_axi_awready,
  input [2:0] 			  s_axi_awprot,
  input 			  s_axi_wvalid,
  input [31:0] 			  s_axi_wdata,
  input [ 3:0] 			  s_axi_wstrb,
  output 			  s_axi_wready,
  output 			  s_axi_bvalid,
  output [ 1:0] 		  s_axi_bresp,
  input 			  s_axi_bready,
  input 			  s_axi_arvalid,
  input [10:0] 			  s_axi_araddr,
  output 			  s_axi_arready,
  input [2:0] 			  s_axi_arprot,
  output 			  s_axi_rvalid,
  input 			  s_axi_rready,
  output [ 1:0] 		  s_axi_rresp,
  output [31:0] 		  s_axi_rdata,

   
  // fifo interface
  input 			  adc_rst,
  input 			  adc_clk,
  input 			  adc_wr,
  input [ADC_DATA_WIDTH-1:0] 	  adc_wdata,
  output 			  adc_wovf,

   
  // dma interface
  input 			  dma_clk,
  output 			  dma_wr, // to dmac s_axis_valid
  output [DMA_DATA_WIDTH-1:0] 	  dma_wdata,
  input 			  dma_wready, // from dmac s_axis_ready
  input 			  dma_xfer_req,
  output [ 3:0] 		  dma_xfer_status,

   
  // axi interface to DDR
  input 			  axi_clk,
  input 			  axi_resetn,
  output 			  axi_awvalid,
  output [ 3:0] 		  axi_awid,
  output [ 1:0] 		  axi_awburst,
  output 			  axi_awlock,
  output [ 3:0] 		  axi_awcache,
  output [ 2:0] 		  axi_awprot,
  output [ 3:0] 		  axi_awqos,
  output [ 3:0] 		  axi_awuser,
  output [ 7:0] 		  axi_awlen,
  output [ 2:0] 		  axi_awsize,
  output [ 31:0] 		  axi_awaddr,
  input 			  axi_awready,
  output 			  axi_wvalid,
  output [AXI_DATA_WIDTH-1:0] 	  axi_wdata,
  output [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb,
  output 			  axi_wlast,
  output [ 3:0] 		  axi_wuser,
  input 			  axi_wready,
  input 			  axi_bvalid,
  input [ 3:0] 			  axi_bid,
  input [ 1:0] 			  axi_bresp,
  input [ 3:0] 			  axi_buser,
  output 			  axi_bready,
  output 			  axi_arvalid,
  output [ 3:0] 		  axi_arid,
  output [ 1:0] 		  axi_arburst,
  output 			  axi_arlock,
  output [ 3:0] 		  axi_arcache,
  output [ 2:0] 		  axi_arprot,
  output [ 3:0] 		  axi_arqos,
  output [ 3:0] 		  axi_aruser,
  output [ 7:0] 		  axi_arlen,
  output [ 2:0] 		  axi_arsize,
  output [ 31:0] 		  axi_araddr,
  input 			  axi_arready,
  input 			  axi_rvalid,
  input [ 3:0] 			  axi_rid,
  input [ 3:0] 			  axi_ruser,
  input [ 1:0] 			  axi_rresp,
  input 			  axi_rlast,
  input [AXI_DATA_WIDTH-1:0] 	  axi_rdata,
  output 			  axi_rready
);

  // internal signals

  wire                            adc_dwr_s;
  wire    [AXI_DATA_WIDTH-1:0]    adc_ddata_s;
  wire                            axi_rd_req_s;
  wire    [ 31:0]                 axi_rd_addr_s;
  wire    [  3:0]                 axi_xfer_status_s;
  wire                            axi_drst_s;
  wire                            axi_dvalid_s;
  wire    [AXI_DATA_WIDTH-1:0]    axi_ddata_s;
  wire                            axi_dready_s;

  // NuCrypt sigs
  wire meas_noise, meas_noise_adc, dma_xfer_req_rc, s_axi_rst,
       txrx_en, txrx_en_adc;
  wire [31:0] reg_ctl_w;
  reg [31:0] reg_samp_r, reg_stat_r;
  reg noise_ctr_en=0, dma_xfer_req_d, xfer_req_event, dma_wready_d, dma_wready_pulse;
  reg noise_ctr_go=0;
  reg noise_ctr_is0=0, noise_trig=0;
  reg [10:0] noise_ctr=0;
   wire    dac_tx_in_adc;
  wire      dma_xfer_req_adc;
  reg  [  2:0]           adc_xfer_req_m = 'd0;
  reg adc_xfer_req, adc_xfer_req_d;
  reg 	adc_go, adc_go_d, adc_go_pulse;
  wire  new_go_en, new_go_en_adc, clr_ctrs, adc_go_dma;
  wire [3:0] core_vld_cnt, xfer_req_cnt, charisk_cnt, adc_wr_cnt, adc_go_cnt,
   txrx_cnt,  dma_wready_cnt;

  wire [7:0] adcfifo_ver = 'h01;


   
  // NuCrypt stuff
  // reg 3





  assign s_axi_rst = ~s_axi_aresetn;
  axi_regs #(
    .A_W(11)
  ) regs (
    .aclk(s_axi_aclk),
    .arstn(s_axi_aresetn),
	  
    // wr addr chan
    .awaddr(s_axi_awaddr),
    .awvalid(s_axi_awvalid),
    .awready(s_axi_awready),

    // wr data chan
    .wdata(s_axi_wdata),
    .wvalid(s_axi_wvalid),
    .wstrb(s_axi_wstrb),
    .wready(s_axi_wready),

    // wr rsp chan
    .bresp(s_axi_bresp),
    .bvalid(s_axi_bvalid),
    .bready(s_axi_bready),
 
    .araddr(s_axi_araddr),
    .arvalid(s_axi_arvalid),
    .arready(s_axi_arready),

    .rdata(s_axi_rdata),
    .rresp(s_axi_rresp),
    .rvalid(s_axi_rvalid),
    .rready(s_axi_rready),
			  
//    .arprot(s_axi_arprot),
//    .awprot(s_axi_awprot),

    .reg0_w(reg_ctl_w),

    .reg0_r(reg_ctl_w),	  
    .reg1_r(reg_stat_r),
    .reg2_r(reg_samp_r),
    .reg3_r(0));
   
      
      
 
    
  // This sends a signal to DAC fifo every time ADC xfer starts ( or restarts)

  cdc_sync_cross #(
     .W(1)
  ) xfer_req_cross (
    .clk_in_bad (adc_rst),
    .clk_in (adc_clk),
    .d_in (adc_xfer_req_m[2]),
    .clk_out_bad (0),
    .clk_out (dac_clk),
    .d_out ( dac_tx ));
   
  cdc_sync_cross #(
     .W(1)
  ) dac_tx_in_cross (
    .clk_in_bad (0),
    .clk_in (dac_clk),
    .d_in (dac_tx_in),
    .clk_out_bad (adc_rst),
    .clk_out (adc_clk),
    .d_out ( dac_tx_in_adc ));

  cdc_samp #(
     .W(1)
  ) cdc_meas_noise (
     .in_data(reg_meas_noise),
     .out_data(meas_noise_adc),
     .out_clk (adc_clk));

  pulse_ctr #(
    .W(4)
  ) dma_wready_ctr (
    .pulse (dma_wready_pulse),
    .pulse_clk   (dma_clk),
    .clk   (s_axi_clk),
    .clr   (clr_ctrs),
    .ctr   (dma_wready_cnt));

   
  pulse_ctr #(
    .W(4)
  ) adc_go_ctr (
    .pulse (adc_go_pulse),
    .pulse_clk   (adc_clk),
    .clk   (s_axi_clk),
    .clr   (clr_ctrs),
    .ctr   (adc_go_cnt));
   
  pulse_ctr #(
    .W(4)
  ) i_xfer_req_ctr (
    .pulse (xfer_req_event),
    .pulse_clk   (dma_clk),
    .clk   (s_axi_clk),
    .clr   (clr_ctrs),
    .ctr   (xfer_req_cnt));

  pulse_ctr #(
    .W(4)
  ) txrx_ctr (
    .pulse (tx_rx_en),
    .pulse_clk   (s_axi_aclk),
    .clk   (s_axi_clk),
    .clr   (clr_ctrs),
    .ctr   (txrx_cnt));
   
  // for dbg
  cdc_samp #(
     .W(1)
  ) cdc_samp_req (
     .in_data(dma_xfer_req_d),
     .out_data(dma_xfer_req_rc),
     .out_clk (s_axi_clk));
   
  always @(posedge s_axi_aclk) begin
    reg_stat_r[31:24] <= adcfifo_ver;
    reg_stat_r[23:20] <= 0; // reserved
    reg_stat_r[19:16] <= txrx_cnt;
    reg_stat_r[15:12] <= xfer_req_cnt;
    reg_stat_r[11:8]  <= adc_go_cnt;
    reg_stat_r[7:4]   <= dma_wready_cnt;
    reg_stat_r[3:1]   <= 0;
    reg_stat_r[0]     <= dma_xfer_req_rc;
     
    reg_samp_r <= 'h5a5a5a5a; // placeholder     
  end // always @(posedge s_axi_aclk)

  assign clr_ctrs   = reg_ctl_w[0];
  assign meas_noise = reg_ctl_w[1];
  assign txrx_en    = reg_ctl_w[2];
  assign new_go_en  = reg_ctl_w[3];

  cdc_samp #(
     .W(1)
  ) cdc_samp_to_adcclk (
     .in_data( {txrx_en     , new_go_en    }),
     .out_data({txrx_en_adc , new_go_en_adc}),
     .out_clk (adc_clk));

   
  always @(posedge adc_clk) begin
     // mimicing ADC's cdc methodology
     adc_xfer_req_m <= {adc_xfer_req_m[1:0], dma_xfer_req};

     // We only take samples while txrx_en_adc is high.
     // When dma req goes high, we signal the dac, and when it acks that,
     // that is when we start taking samples.
     // After that, dma request can go up and down, but we ignore it,
     // and keep taking samples.  This is in case software can't keep up,
     // in which case we keep cramming data into the DDR so we don't
     // loose any consecutive data.
     if (new_go_en_adc)
       adc_go <= txrx_en_adc & ((dac_tx_in_adc & adc_xfer_req_m[2]) | adc_go);
     else // older method
       adc_go <= adc_xfer_req_m[2] & (dac_tx_in_adc | adc_go);
     adc_go_d <= adc_go;
     adc_go_pulse <= adc_go & ~adc_go_d;
     
     noise_ctr_go <= meas_noise_adc && adc_go;
     if (!noise_ctr_go || noise_ctr_is0)
       noise_ctr <= (6100/4-1);
     else
       noise_ctr <= noise_ctr-1;
     noise_ctr_is0 <= (noise_ctr==1);
     if (!noise_ctr_go)
       rxq_sw_ctl <= 0;
     else if (noise_ctr_is0)
       rxq_sw_ctl <= ~rxq_sw_ctl;

     adc_xfer_req   <= adc_xfer_req_m[2];
     adc_xfer_req_d <= adc_xfer_req;


     
  end // always @ (posedge adc_clk)

   
  // instantiations
  // This widens the data from "adc" to "axi" width.
  // operates continuously but maybe it should not.
  axi_adcfifo_adc #(
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .ADC_DATA_WIDTH (ADC_DATA_WIDTH)
  ) i_adc_if (
    .adc_rst (adc_rst),
    .adc_clk (adc_clk),
    .adc_wr (adc_wr),
    .adc_wdata (adc_wdata), // adc data in
    .adc_wovf (adc_wovf),

    .adc_dwr (adc_dwr_s), // out
    .adc_ddata (adc_ddata_s), // axi data out
    .axi_drst (axi_drst_s),
    .axi_clk (axi_clk),
    .axi_xfer_status (axi_xfer_status_s));

  // This contains a shallow buffer for bursting into ddr
  // 
  axi_adcfifo_wr #(
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_SIZE (AXI_SIZE),
    .AXI_LENGTH (AXI_LENGTH),
    .AXI_ADDRESS (AXI_ADDRESS),
    .AXI_ADDRESS_LIMIT (AXI_ADDRESS_LIMIT)
  ) i_wr (

    // When this goes low, it resets the fifo in ddr.
    .dma_xfer_req (adc_go),
	  
    .axi_rd_req (axi_rd_req_s),   // pulses at end of each burst to ddr3
    .axi_rd_addr (axi_rd_addr_s), // to transfer this
    .adc_rst (adc_rst),
    .adc_clk (adc_clk),
    .adc_wr (adc_dwr_s),
    .adc_wdata (adc_ddata_s), // in
    .axi_clk (axi_clk),
    .axi_resetn (axi_resetn),
    .axi_awvalid (axi_awvalid),
    .axi_awid (axi_awid),
    .axi_awburst (axi_awburst),
    .axi_awlock (axi_awlock),
    .axi_awcache (axi_awcache),
    .axi_awprot (axi_awprot),
    .axi_awqos (axi_awqos),
    .axi_awuser (axi_awuser),
    .axi_awlen (axi_awlen),
    .axi_awsize (axi_awsize),
    .axi_awaddr (axi_awaddr),
    .axi_awready (axi_awready),
    .axi_wvalid (axi_wvalid),
    .axi_wdata (axi_wdata),
    .axi_wstrb (axi_wstrb),
    .axi_wlast (axi_wlast),
    .axi_wuser (axi_wuser),
    .axi_wready (axi_wready),
    .axi_bvalid (axi_bvalid),
    .axi_bid (axi_bid),
    .axi_bresp (axi_bresp),
    .axi_buser (axi_buser),
    .axi_bready (axi_bready),
    .axi_dwovf (axi_xfer_status_s[0]),
    .axi_dwunf (axi_xfer_status_s[1]),
    .axi_werror (axi_xfer_status_s[2]));

  axi_adcfifo_rd #(
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_SIZE (AXI_SIZE),
    .AXI_LENGTH (AXI_LENGTH),
    .AXI_ADDRESS (AXI_ADDRESS),
    .AXI_ADDRESS_LIMIT (AXI_ADDRESS_LIMIT)
  ) i_rd (
    .dma_xfer_req (adc_go),
    .axi_rd_req (axi_rd_req_s),
    .axi_rd_addr (axi_rd_addr_s),
    .axi_clk (axi_clk),
    .axi_resetn (axi_resetn),
    .axi_arvalid (axi_arvalid),
    .axi_arid (axi_arid),
    .axi_arburst (axi_arburst),
    .axi_arlock (axi_arlock),
    .axi_arcache (axi_arcache),
    .axi_arprot (axi_arprot),
    .axi_arqos (axi_arqos),
    .axi_aruser (axi_aruser),
    .axi_arlen (axi_arlen),
    .axi_arsize (axi_arsize),
    .axi_araddr (axi_araddr),
    .axi_arready (axi_arready),
    .axi_rvalid (axi_rvalid),
    .axi_rid (axi_rid),
    .axi_ruser (axi_ruser),
    .axi_rresp (axi_rresp),
    .axi_rlast (axi_rlast),
    .axi_rdata (axi_rdata),
    .axi_rready (axi_rready),
    .axi_rerror (axi_xfer_status_s[3]),
    .axi_drst (axi_drst_s),
    .axi_dvalid (axi_dvalid_s),
    .axi_ddata (axi_ddata_s),
    .axi_dready (axi_dready_s));


  always @(posedge dma_clk) begin
    dma_xfer_req_d  = dma_xfer_req;
    xfer_req_event = dma_xfer_req & ~dma_xfer_req_d;
    dma_wready_d <= dma_wready;
    dma_wready_pulse <= dma_wready & ~dma_wready_d;
  end
   
  cdc_samp #(
     .W(1)
  ) cdc_samp_adc_go (
     .in_data(adc_go),
     .out_data(adc_go_dma),
     .out_clk (dma_clk));
   
  axi_adcfifo_dma #(
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .DMA_DATA_WIDTH (DMA_DATA_WIDTH),
    .DMA_READY_ENABLE (DMA_READY_ENABLE)
  ) i_dma_if (
    .axi_clk (axi_clk),
    .axi_drst (axi_drst_s),
    .axi_dvalid (axi_dvalid_s),
    .axi_ddata (axi_ddata_s),
    .axi_dready (axi_dready_s),
    .axi_xfer_status (axi_xfer_status_s),
    .dma_clk (dma_clk),
    .dma_wr (dma_wr),
    .dma_wdata (dma_wdata),
    .dma_wready (dma_wready),
    .dma_xfer_req (adc_go_dma),
    .dma_xfer_status (dma_xfer_status));

endmodule
