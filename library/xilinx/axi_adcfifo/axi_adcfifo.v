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
  output [ 3:0] 		  dma_xfer_status

/*   
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
 */
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
  wire  dac_tx_in_adc;

  reg  [2:0]adc_xfer_req_m = 'd0;
  reg 	    adc_xfer_req;

  reg adc_go, adc_go_d, adc_go_pulse;

  wire  new_go_en, new_go_en_adc, clr_ctrs, adc_go_dma, uram_rst;
  wire [3:0] core_vld_cnt, xfer_req_cnt, charisk_cnt, adc_wr_cnt, adc_go_cnt,
   txrx_cnt,  dma_wready_cnt;

  wire [7:0] adcfifo_ver = 'h01;

  wire clr_ovf;





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
     .W(2)
  ) cdc_meas_noise (
     .in_data(reg_meas_noise),
     .out_data(meas_noise_adc),
     .out_clk (adc_clk));

  pulse_ctr #(
    .W(4)
  ) dma_wready_ctr (
    .pulse (dma_wready_pulse),
    .pulse_clk   (dma_clk),
    .clk   (s_axi_aclk),
    .clr   (clr_ctrs),
    .ctr   (dma_wready_cnt));

   
  pulse_ctr #(
    .W(4)
  ) adc_go_ctr (
    .pulse (adc_go_pulse),
    .pulse_clk   (adc_clk),
    .clk   (s_axi_aclk),
    .clr   (clr_ctrs),
    .ctr   (adc_go_cnt));
   
  pulse_ctr #(
    .W(4)
  ) i_xfer_req_ctr (
    .pulse (xfer_req_event),
    .pulse_clk   (dma_clk),
    .clk   (s_axi_aclk),
    .clr   (clr_ctrs),
    .ctr   (xfer_req_cnt));

  pulse_ctr #(
    .W(4)
  ) txrx_ctr (
    .pulse (tx_rx_en),
    .pulse_clk   (s_axi_aclk),
    .clk   (s_axi_aclk),
    .clr   (clr_ctrs),
    .ctr   (txrx_cnt));
   

  always @(posedge dma_clk) begin
    dma_wready_d     <= dma_wready;
    dma_wready_pulse <= dma_wready & ~dma_wready_d;
  end
   
  always @(posedge s_axi_aclk) begin
    reg_stat_r[31:24] <= adcfifo_ver;
    reg_stat_r[23:20] <= 0; // reserved
    reg_stat_r[19:16] <= txrx_cnt;
    reg_stat_r[15:12] <= xfer_req_cnt;
    reg_stat_r[11:8]  <= adc_go_cnt;
    reg_stat_r[7:4]   <= dma_wready_cnt;
    reg_stat_r[3]     <= uram_ovf; // OK if happens often
    reg_stat_r[2]     <= uram_bug; // indicates bug in HDL
    reg_stat_r[1]     <= 0;
    reg_stat_r[0]     <= dma_xfer_req_rc;
     
    reg_samp_r <= 'h5a5a5a5a; // placeholder     
  end // always @(posedge s_axi_aclk)

  assign clr_ctrs   = reg_ctl_w[0];
  assign meas_noise = reg_ctl_w[1];
  assign txrx_en    = reg_ctl_w[2];
  assign new_go_en  = reg_ctl_w[3];
  assign clr_ovf    = reg_ctl_w[4];

  cdc_samp #(
     .W(2)
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
     
  end // always @ (posedge adc_clk)


  // adc clk is 312.5MHz
  // dma clk is 250MHz
  assign uram_rst = ~adc_go;
  adc_uram_fifo #(
    .D_W(ADC_DATA_WIDTH),
    .URAM_A_W(12)  // must be >= 12
  ) ufifo (
    .ctl_clk(axi_clk),
    .rst(uram_rst),
    .fifo_ovf(uram_ovf),
    .fifo_bug(uram_bug), // should never be hi
    .clr_flags(clr_ovf),
    
    .adc_clk(adc_clk),
    .adc_wr(adc_wr),
    .adc_data(adc_wdata),

    .dma_clk(dma_clk),
    .dma_wready(dma_wready),
    .dma_wr(dma_wr),
    .dma_data(dma_wdata));

  assign dma_xfer_status = 0;
   
endmodule
