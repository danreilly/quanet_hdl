// when syncing, alice sets alice_syncing but bob does not.
// Bob txes hdr_len frames.  But bob should rx hdr_len*2 frames. search=0.
// Alice does search.  alice would only save IQ samps for dbg.
//
  
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
   
  input [15:0] 			  s_axi_awaddr,
  input 			  s_axi_awvalid,
  output 			  s_axi_awready,
   
  input [2:0] 			  s_axi_awprot,
   
  input [31:0] 			  s_axi_wdata,
  input 			  s_axi_wvalid,
  output 			  s_axi_wready,
  input [ 3:0] 			  s_axi_wstrb, // per byte 1=enable
   
  output [ 1:0] 		  s_axi_bresp,
  output 			  s_axi_bvalid,
  input 			  s_axi_bready,
   
  input [15:0] 			  s_axi_araddr,
  input 			  s_axi_arvalid,
  output 			  s_axi_arready,
  input [2:0] 			  s_axi_arprot,
   
  output [31:0] 		  s_axi_rdata,
  output [ 1:0] 		  s_axi_rresp,
  output 			  s_axi_rvalid,
  input 			  s_axi_rready,
   
   
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

  `include "global_pkg.v"
   
  // internal signals

   wire [ADC_DATA_WIDTH-1:0] 	  adc_wdata_aug;
   
   
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
  wire [31:0] reg_ctl_w, reg1_w, reg2_w, reg3_w, reg3_w_adc,
    reg4_w,  reg4_w_adc, reg5_w, reg5_w_adc, reg6_w,
    reg2_r, reg3_r, reg4_r, reg5_r, reg6_r;

  wire [31:0] reg_samp_r, reg_stat_r;
  reg noise_ctr_en=0, dma_xfer_req_d, xfer_req_event, dma_wready_d, dma_wready_pulse;
  reg noise_ctr_go=0;
  reg noise_ctr_is0=0, noise_trig=0;
  reg [10:0] noise_ctr=0;
  wire  dac_tx_in_adc;
  wire      dma_xfer_req_adc;
  reg  [  2:0]           adc_xfer_req_m = 'd0;
  reg adc_xfer_req, adc_xfer_req_d, dac_tx_pre=0;
  reg 	adc_go=0, adc_go_d=0, adc_go_pulse=0;
  wire  new_go_en, new_go_en_adc, clr_ctrs, adc_go_dma;
  wire [3:0] core_vld_cnt, xfer_req_cnt, charisk_cnt, adc_wr_cnt, adc_go_cnt,
   txrx_cnt,  dma_wready_cnt;

  wire [7:0] adcfifo_ver = 'h02;
  wire [1:0] osamp_min1, osamp_min1_adc;
   wire      corrstart, corrstart_adc, search, search_adc;
   reg search_en=0;
  wire [G_FRAME_PD_W-1:0] frame_pd_min1;
  wire [G_PASS_W-1:0]  num_pass_min1;
  wire [G_HDR_LEN_W-1:0] hdr_len_min1;
  wire [G_FRAME_QTY_W-1:0] frame_qty_min1;
  wire [14-1:0] 	  hdr_pwr_thresh;
  wire [G_CORR_MAG_W-1:0] hdr_thresh;
//  wire [G_CTR_W-1:0] hdr_oop_ctr, hdr_oop_ctr_adc;
  wire [14*8-1:0] samps_in;
  wire [1:0] hdr_subcyc;
  wire dbg_hdr_pwr_flag, dbg_hdr_det, hdr_sync, hdr_sync_dlyd, corr_vld;
  wire [G_FRAME_PD_W-1:0] sync_dly;
  wire [(G_CORR_MAG_W+8)*4-1:0] corr_out;
  wire [31:0] 			proc_dout;
  wire [2:0] 			proc_sel;
  wire [10:0] 			lfsr_rst_st;
  wire 	alice_syncing, alice_syncing_adc, proc_clr_cnts;
  wire [7:0] wdata_aug;




       


   
  // NuCrypt stuff
  // reg 3


  assign s_axi_rst = ~s_axi_aresetn;
  axi_regs #(
    .A_W(16)
  ) regs (
    .aclk(s_axi_aclk),
    .arstn(s_axi_aresetn),
	  
    // wr addr chan
    .awaddr(s_axi_awaddr),
    .awvalid(s_axi_awvalid),
    .awready(s_axi_awready),
//   .awprot(s_axi_awprot),

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
//  .arprot(s_axi_arprot),

    .rdata(s_axi_rdata),
    .rresp(s_axi_rresp),
    .rvalid(s_axi_rvalid),
    .rready(s_axi_rready),

    .reg0_w(reg_ctl_w),
    .reg1_w(reg1_w),
    .reg2_w(reg2_w),
    .reg3_w(reg3_w),
    .reg4_w(reg4_w),
    .reg5_w(reg5_w),
    .reg6_w(reg6_w),

    .reg0_r(reg_ctl_w),	  
    .reg1_r(reg_stat_r),
    .reg2_r(reg2_r),
    .reg3_r(reg3_r),
    .reg4_r(reg4_r),
    .reg5_r(reg5_r),
    .reg6_r(reg6_r));

  // reg0 = ctl
  assign clr_ctrs   = reg_ctl_w[0];
  assign meas_noise = reg_ctl_w[1];
  assign txrx_en    = reg_ctl_w[2];
  assign new_go_en  = 1'b1; //'reg_ctl_w[3];
  assign osamp_min1 = reg_ctl_w[5:4]; // neu
  assign search     = reg_ctl_w[6]; // neu
  assign corrstart  = reg_ctl_w[7]; // neu
  assign proc_clr_cnts = reg_ctl_w[8]; // neu
  assign alice_syncing = reg_ctl_w[9]; // neu
  assign lfsr_rst_st = reg_ctl_w[26:16]; // neu

  // reg1 = stat   
  assign reg_stat_r[31:24] = adcfifo_ver;
  assign reg_stat_r[23:20] = 0; // reserved
  assign reg_stat_r[19:16] = txrx_cnt;
  assign reg_stat_r[15:12] = xfer_req_cnt;
  assign reg_stat_r[11:8]  = adc_go_cnt;
  assign reg_stat_r[7:4]   = dma_wready_cnt;
  assign reg_stat_r[3:1]   = 0;
  assign reg_stat_r[0]     = dma_xfer_req_rc;

  // reg2 = hdr_corr stats
  // assign reg3_r[3:0]= hdr_oop_ctr;
  assign proc_sel = reg2_w[2:0];
  assign reg2_r = proc_dout;
   

  assign reg4_r = 32'h00000004;
  assign reg5_r = 32'h00000005;



     

  cdc_samp #(.W(32))
    cdc_samp_reg3 (   
      .in_data(reg3_w),
      .out_data(reg3_w_adc),
      .out_clk(adc_clk));
  assign num_pass_min1 = reg3_w_adc[28:24]; // neu
  assign frame_pd_min1 = reg3_w_adc[23:0]; // neu

  cdc_samp #(.W(32))
    cdc_samp_reg4 (   
      .in_data(reg4_w),
      .out_data(reg4_w_adc),
      .out_clk(adc_clk));
  assign frame_qty_min1 = reg4_w_adc[31:16]; // neu
  assign hdr_len_min1   = reg4_w_adc[7:0]; // neu
 
  cdc_samp #(.W(32))
    cdc_samp_reg5 (   
      .in_data(reg5_w),
      .out_data(reg5_w_adc),
      .out_clk(adc_clk));
  assign hdr_pwr_thresh = reg5_w_adc[13:0]; // neu
  assign hdr_thresh     = reg5_w_adc[23:14]; // neu


  assign sync_dly = reg6_w[23:0];
  assign reg6_r = reg6_w;
   
//  assign reg_samp_r[11:0] = 0;
   
      
      
 
    
  // This sends a signal to DAC fifo every time ADC xfer starts ( or restarts)

  cdc_sync_cross #(
     .W(1)
  ) xfer_req_cross (
    .clk_in_bad (adc_rst),
    .clk_in (adc_clk),
    .d_in (dac_tx_pre),
    .clk_out_bad (1'b0),
    .clk_out (dac_clk),
    .d_out ( dac_tx ));
   
  cdc_sync_cross #(
     .W(1)
  ) dac_tx_in_cross (
    .clk_in_bad (1'b0),
    .clk_in (dac_clk),
    .d_in (dac_tx_in),
    .clk_out_bad (adc_rst),
    .clk_out (adc_clk),
    .d_out ( dac_tx_in_adc ));
   
  cdc_samp #(
     .W(1)
  ) cdc_meas_noise (
     .in_data(meas_noise),
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
    .pulse (txrx_en),
    .pulse_clk   (s_axi_aclk),
    .clk   (s_axi_aclk),
    .clr   (clr_ctrs),
    .ctr   (txrx_cnt));
   
  // for dbg
  cdc_samp #(
     .W(1)
  ) cdc_samp_req (
     .in_data(dma_xfer_req_d),
     .out_data(dma_xfer_req_rc),
     .out_clk (s_axi_aclk));
   
  always @(posedge s_axi_aclk) begin
   
  end // always @(posedge s_axi_aclk)


  cdc_samp #(
     .W(2)
  ) cdc_samp_to_adcclk (
     .in_data( {txrx_en     , new_go_en    }),
     .out_data({txrx_en_adc , new_go_en_adc}),
     .out_clk (adc_clk));

   
  always @(posedge adc_clk) begin
     // mimicing ADC's cdc methodology
     adc_xfer_req_m <= {adc_xfer_req_m[1:0], dma_xfer_req};
     if (alice_syncing_adc)
       // This FPGA is Alice.
       // alice has synced to Bob's headers and is now
       // inserting her own header into the frame somewhere.
       // Bob analyzes this to learn Alice's insertion latency
       // so that sync_dly can be set properly.
       dac_tx_pre <= hdr_sync_dlyd;
     else // "normal"
       // alice wants to save iq samples.  DMA is ready to store them.
       // Now request DAC to generate headers
       dac_tx_pre <= adc_xfer_req_m[2];

       // For now I want to save IQ samples while searching,
       // so I can debug it.
       // But maybe in future we will not always want to.
       search_en <= search_adc & adc_go;
     
     
     // We only save samples while txrx_en_adc is high.
     // When dma req goes high, we signal the dac, and when it acks that,
     // that is when we start taking samples.
     // After that, dma request can go up and down, but we ignore it,
     // and keep taking samples.  This is in case software can't keep up,
     // in which case we keep cramming data into the DDR so we don't
     // loose any consecutive data.
     //
     // really ought to be called "save_go"
     adc_go <= txrx_en_adc &
	       (  
		(adc_xfer_req_m[2] &
		 (search_adc | dac_tx_in_adc))
		| adc_go );
///     else // older method
//       adc_go <= adc_xfer_req_m[2] & (dac_tx_in_adc | adc_go);
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
    .adc_wdata (adc_wdata_aug), // adc data in
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

  assign wdata_aug[0] = dbg_hdr_pwr_flag;
  assign wdata_aug[1] = dbg_hdr_det;
  assign wdata_aug[2] = hdr_sync;
  assign wdata_aug[3] = hdr_sync_dlyd;
  assign wdata_aug[5:4] = hdr_subcyc;
  assign wdata_aug[7:6] = 0;
   
   genvar i;
   generate
    for(i=0; i<8; i=i+1)
      begin
        assign samps_in[i*14+13:i*14]=adc_wdata[i*16+13:i*16];
        //augment adc_wdata with signals for dbg
        assign adc_wdata_aug[i*16+14:i*16] = adc_wdata[i*16+14:i*16];
        assign adc_wdata_aug[i*16+15]      = wdata_aug[i];
      end
   endgenerate
   
  cdc_samp #( .W(5) )
    cdc_samp_i (   
      .in_data({corrstart, search,          osamp_min1,     alice_syncing}),
      .out_data({corrstart_adc, search_adc, osamp_min1_adc, alice_syncing_adc}),
      .out_clk(adc_clk));
   
  hdr_corr #(
    .USE_CORR (0),
    .SAMP_W             (14),
    .FRAME_PD_CYCS_W    (G_FRAME_PD_W), // 24
    .REDUCED_SAMP_W     (8),
    .HDR_LEN_CYCS_W     (G_HDR_LEN_W),
    .MAX_SLICES         (4),
    .FRAME_QTY_W        (G_FRAME_QTY_W),
    .MEM_D_W            (G_CORR_MEM_D_W), // width of corr vals in corr mem
    .MAG_W              (G_CORR_MAG_W)
  ) hdr_corr_inst (
    .clk                (adc_clk),
    .rst                (adc_rst),
		   
    .osamp_min1         (osamp_min1_adc),
    .corrstart_in       (corrstart_adc),
    .search             (search_en),
    .alice_syncing      (alice_syncing_adc),
    .frame_pd_min1      (frame_pd_min1),
    .num_pass_min1      (num_pass_min1),
    .hdr_len_min1       (hdr_len_min1),
    .frame_qty_min1     (frame_qty_min1),
    .hdr_pwr_thresh     (hdr_pwr_thresh),
    .hdr_thresh         (hdr_thresh),
//    .hdr_oop_ctr        (hdr_oop_ctr_adc),
    .samps_in           (samps_in),
    .dbg_hdr_pwr_flag   (dbg_hdr_pwr_flag),
    .dbg_hdr_det        (dbg_hdr_det),
    .hdr_subcyc         (hdr_subcyc),
    .hdr_sync           (hdr_sync),
    .hdr_sync_dlyd      (hdr_sync_dlyd),
    .corr_vld           (corr_vld),
    .corr_out           (corr_out),

     // below here is in proc clk domain		   
    .proc_clk(s_axi_aclk),
    .proc_clr_cnts(proc_clr_cnts),
    .sync_dly(sync_dly), // cycles it is delayed
    .proc_sel(proc_sel),
    .proc_dout(proc_dout),
    .lfsr_rst_st(lfsr_rst_st));
   
endmodule
