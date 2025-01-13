
`timescale 1ns/100ps


// overall, the data flows in in the adc_clk domain,
// goes to the axi_clk domain,
// and then out on the dma_clk domain.

module axi_adcfifo #(

  parameter   ADC_DATA_WIDTH = 128,
  parameter   DMA_DATA_WIDTH = 64,
  parameter   AXI_DATA_WIDTH = 512,
  parameter   DMA_READY_ENABLE = 1,
  parameter   AXI_SIZE = 2,
  parameter   AXI_LENGTH = 16,
  parameter   AXI_ADDRESS = 32'h00000000, // an address in DDR maybe
  parameter   AXI_ADDRESS_LIMIT = 32'hffffffff
) (

  // NuCrypt additions
  input [511:0] 		  regs_w,
  input 			  dac_txed, // high while DAC txes
  input 			  dac_clk,
  output 			  dbg_adc_en,
  output reg 			  rxq_sw_ctl,
  input 			  reg_clk,
  output reg [63:0] 		  reg_samp,
  output reg [31:0] 		  reg_adc_stat,
  input              link_valid, // from axi_ad9680_jesd
  input              core_valid, // from axi_ad9680_tpl_core
  input              dbg_core_rst,
  input              dbg_dev_rst,
  input              dbg_charisk,
   
  // a writable fifo-like interface
  input 			  adc_rst, // Seems to happen at powerup, one time only.
  input 			  adc_clk,
  input 			  adc_wr, // seems to rise to 1 and stay hi forever
  input [ADC_DATA_WIDTH-1:0] 	  adc_wdata,
  output 			  adc_wovf,

  // dma interface
  // I guess this is a axi master iface that drives a main slave port on PS
  input 			  dma_clk,
  output 			  dma_wr,
  output [DMA_DATA_WIDTH-1:0] 	  dma_wdata,
  input 			  dma_wready,
  input 			  dma_xfer_req, // from axi_ad9680_dma.  seems to go hi once.
  output [ 3:0] 		  dma_xfer_status,
  // I tried doing N iio_buffer refils, and for N>1, saw N-1 reqs????

  // axi interface
  // I guess it intrfaces to a ddr ctlr.
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

  wire                            adc_dwr_s, adc_fifo_wr;
  wire    [AXI_DATA_WIDTH-1:0]    adc_ddata_s;
  wire                            axi_rd_req_s;
  wire    [ 31:0]                 axi_rd_addr_s;
  wire    [  3:0]                 axi_xfer_status_s;
  wire                            axi_drst_s;
  wire                            axi_dvalid_s;
  wire    [AXI_DATA_WIDTH-1:0]    axi_ddata_s;
  wire                            axi_dready_s;

   wire  dac_txed_adcclk, dma_xfer_req_uc, dma_xfer_req_rc, adc_trig, link_valid_rc, core_valid_rc,
         dbg_charisk_rc, dbg_dev_rst_rc, dbg_core_rst_rc, charisk_event;

   reg 	  adc_xfer_pend=1'b0, adc_en=0, adc_trig_d=0, dac_txed_d=0, init=0, dac_trig;
   reg 	  adc_xfer_req=1'b0, adc_xfer_req_d=1'b0, dbg_charisk_d;


   wire   samp_req_rc, samp_ack_ac;
   reg 	  samp_req=0, samp_req_rc_d=0, samp_ack=0, adc_wr_d, samp_timo = 0;
   reg [5:0] samp_timo_ctr=0;


   reg  [4*16-1 : 0] adc_abs=0, adc_data_sav=0, adc_max=0;
   wire [4*16-1 : 0] adc_data_sav_uc;

  genvar	     i;
   
   wire   reg_done, reg_clr_ctrs, reg_clr_samp_max, reg_meas_noise, reg_wovf_ignore, wovf_ignore, adc_wovf_pre;
   reg 		done=0,clr_ctrs=0;
   
   reg adc_rst_d=0, clr_samp_max=0, clr_samp_max_d, adc_ctr_is0=0, meas_noise=0, noise_trig=0;
   reg [10:0] 				adc_ctr=0;

   wire adc_en_dma, adc_en_axi, adc_wr_event, adc_rst_event, xfer_req_event;

   wire [3:0] core_vld_cnt, xfer_req_cnt, charisk_cnt, adc_wr_cnt;

   
  // This widens the data from "adc" to "axi" width
  assign adc_wovf = adc_wovf_pre & ~wovf_ignore; // a debug test
  axi_adcfifo_adc #(
    .ADC_DATA_WIDTH (ADC_DATA_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH)
  ) i_adc_if (
    .adc_rst (adc_rst),
    .adc_clk (adc_clk),
    .adc_wr (adc_wr),
    .adc_wdata (adc_wdata), // in
    .adc_wovf (adc_wovf_pre),   // out
	      
    .adc_dwr (adc_dwr_s),     // pulses one out of out four cycs
    .adc_ddata (adc_ddata_s), // output
    .axi_drst (axi_drst_s),   // in from axi_adcfifo_rd
    .axi_clk (axi_clk),
    .axi_xfer_status (axi_xfer_status_s)); // in from axi_adcfifo_wr. error flags.  only ovf used.


  cdc_thru #(
    .W (1)
  ) dac_lastaddr_thru (
    .in_data  (dma_xfer_req),
    .out_data (dma_xfer_req_uc));

  // for dbg
  cdc_samp #(
     .W(1)
  ) cdc_samp_req (
     .in_data(dma_xfer_req),
     .out_data(dma_xfer_req_rc),
     .out_clk (reg_clk));
  // for dbg
  cdc_samp #(
     .W(1)
  ) link_valid_samp (
     .in_data(link_valid),
     .out_data(link_valid_rc),
     .out_clk (reg_clk));
  // for dbg
  cdc_samp #(
     .W(1)
  ) core_valid_samp (
     .in_data(core_valid),
     .out_data(core_valid_rc),
     .out_clk (reg_clk));


  // for dbg
  cdc_samp #(
     .W(1)
  ) dbg_dev_rst_samp (
     .in_data(dbg_dev_rst),
     .out_data(dbg_dev_rst_rc),
     .out_clk (reg_clk));
  cdc_samp #(
     .W(1)
  ) dbg_core_rst_samp (
     .in_data(dbg_core_rst),
     .out_data(dbg_core_rst_rc),
     .out_clk (reg_clk));

  cdc_samp #(
     .W(1)
  ) dbg_charisk (
     .in_data(dbg_charisk),
     .out_data(dbg_charisk_rc),
     .out_clk (reg_clk));
   
   
  cdc_samp #(
     .W(1)
  ) cdc_wovf_ignore (
     .in_data(reg_wovf_ignore),
     .out_data(wovf_ignore),
     .out_clk (adc_clk));

   
  cdc_thru #(
    .W (4*16)
  ) adc_data_thru (
    .in_data  (adc_data_sav),
    .out_data (adc_data_sav_uc));

   
  cdc_sync_cross #(
     .W(1)
  ) xfer_req_cross (
    .clk_in_bad (1'b0),
    .clk_in (dac_clk),
    .d_in (dac_txed),
    .clk_out_bad (adc_rst),
    .clk_out (adc_clk),
    .d_out ( dac_txed_adcclk));
   

  pulse_bridge #() req_pb (
    .in_pulse (samp_req),
    .in_clk   (adc_clk),
    .out_pulse (samp_req_rc),
    .out_clk   (reg_clk));
   
  pulse_bridge #() ack_pb (
    .in_pulse (samp_ack),
    .in_clk   (reg_clk),
    .out_pulse (samp_ack_ac),
    .out_clk   (adc_clk));
   
  always @(posedge reg_clk) begin
    samp_req_rc_d <= samp_req_rc;
    if (samp_req_rc & ~samp_req_rc_d)
      reg_samp <= adc_data_sav_uc;
    samp_ack <= samp_req_rc & ~samp_req_rc_d;

    reg_adc_stat[31:20]=core_vld_cnt;
    reg_adc_stat[19:16]=adc_wr_cnt;
    reg_adc_stat[15:12]=xfer_req_cnt;
    reg_adc_stat[11: 8]=charisk_cnt;
    reg_adc_stat[7:6] =0;
    reg_adc_stat[5]  = dbg_charisk;
    reg_adc_stat[4]  = dbg_dev_rst_rc;
    reg_adc_stat[3]  = dbg_core_rst_rc;

    reg_adc_stat[2]  = core_valid_rc;
    reg_adc_stat[1]  = link_valid_rc;
     
    reg_adc_stat[0]    =dma_xfer_req_rc;
     
  end

   
  generate
    for (i =0; i<4; i=i+1) begin
      always @(posedge adc_clk) begin
	  if (adc_wr) begin
	     if (adc_wdata[16*i+13]) // adc data is 14 bits, signed
	       adc_abs[16*i+13:16*i] <= - adc_wdata[16*i+13:16*i];
             else
	       adc_abs[16*i+13:16*i] <=   adc_wdata[16*i+13:16*i];
	  end
	  if (clr_samp_max & ~clr_samp_max_d)
	    adc_max[16*i+13:16*i] <= 0;
	  else if (adc_wr_d && (adc_max[16*i+14:16*i] <  adc_abs[16*i+14:16*i]))
  	    adc_max[16*i+13:16*i] <= adc_abs[16*i+13:16*i];
      end
    end
  endgenerate
    
  // reg 3
  assign reg_meas_noise   = regs_w[0 + 96];
  assign reg_clr_samp_max = regs_w[1 + 96];
  assign reg_clr_ctrs     = regs_w[2 + 96];
  assign reg_wovf_ignore  = regs_w[3 + 96];
  assign reg_done         = regs_w[4 + 96];

  assign adc_wr_event   = adc_wr & ~adc_wr_d;
  assign adc_rst_event  = adc_rst & ~adc_rst_d;
  assign xfer_req_event = adc_xfer_req & ~ adc_xfer_req_d;
			  
  pulse_ctr #(
    .W(4)
  ) i_charisk_ctr (
    .pulse_clk (adc_clk),
    .pulse     (charisk_event),
    .clk   (reg_clk),
    .clr   (reg_clr_ctrs),
    .ctr   (charisk_cnt));
  pulse_ctr #(
    .W(4)
  ) i_xfer_req_ctr (
    .pulse (xfer_req_event),
    .pulse_clk   (adc_clk),
    .clk   (reg_clk),
    .clr   (reg_clr_ctrs),
    .ctr   (xfer_req_cnt));
  pulse_ctr #(
    .W(4)
  ) i_xfer_wr_ctr (
    .pulse (adc_wr_event),
    .pulse_clk   (adc_clk),
    .clk   (reg_clk),
    .clr   (reg_clr_ctrs),
    .ctr   (adc_wr_cnt));

  pulse_ctr #(
    .W(4)
  ) core_vld_event_ctr (
    .pulse (core_valid),
    .pulse_clk   (adc_clk),
    .clk   (reg_clk),
    .clr   (reg_clr_ctrs),
    .ctr   (core_vld_cnt));

  assign charisk_event = dbg_charisk & !dbg_charisk_d;
  always @(posedge adc_clk) begin
     adc_rst_d <= adc_rst;
     dbg_charisk_d <= dbg_charisk;
     
     meas_noise     <= reg_meas_noise;

     done           <= reg_done;
     
     clr_samp_max   <= reg_clr_samp_max;
     clr_samp_max_d <= clr_samp_max;
     
     if (!meas_noise || adc_ctr_is0) 
       adc_ctr <= (6100/4-1);
     else
       adc_ctr <= adc_ctr-1;
     adc_ctr_is0 <= (adc_ctr==1);
     if (!meas_noise)
       rxq_sw_ctl <= 0;
     else if (adc_ctr_is0)
       rxq_sw_ctl <= ~rxq_sw_ctl;
     
    adc_wr_d <= adc_wr;
     
    if (!samp_req) begin
      samp_req      <= 1;
      adc_data_sav  <= adc_max;
      samp_timo_ctr <= ~0;
      samp_timo     <= 0;
    end else begin
      if (samp_ack_ac || samp_timo) begin
        samp_req     <= 0;
      end
      samp_timo_ctr <= samp_timo_ctr-1;
      samp_timo     <= (samp_timo_ctr==0);
    end
    


     adc_xfer_req   <= dma_xfer_req_uc;
     adc_xfer_req_d <= adc_xfer_req;

     // adc_pend is set when an dma ctlr requests a transfer
     // and cleared after it actually starts.
     adc_xfer_pend  <=    ((adc_xfer_req & !adc_xfer_req_d) | adc_xfer_pend)
                        & !adc_en;

     // adc_en is high while ADC stream is stored.
     // It's cleared when the adc transfer no longer requested,
     // so we might store more samples than we need.
     // That's why I reset the fifo while there's no xfer requested.

     dac_txed_d <= dac_txed_adcclk;
     init       <= dac_txed_adcclk & !dac_txed_d;     

     dac_trig  <= init;
     
     adc_trig_d <= adc_trig;
     adc_en <= ( adc_en
		 | (adc_xfer_pend & adc_trig & !adc_trig_d))
               & ~done;

  end // always @ (posedge adc_clk)
   
  assign adc_trig = dac_trig | meas_noise;
  

  cdc_samp #(
     .W(1)
  ) cdc_adc_en_axi (
     .in_data(adc_en),
     .out_data(adc_en_axi),
     .out_clk (axi_clk));

  assign adc_fifo_wr = adc_dwr_s & adc_en;
  // This contains a shallow buffer for bursting into ddr
  // 
  // adc_wr is a second enable.
  // 
  axi_adcfifo_wr #(
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_SIZE (AXI_SIZE),
    .AXI_LENGTH (AXI_LENGTH),
    .AXI_ADDRESS (AXI_ADDRESS), // 0
    .AXI_ADDRESS_LIMIT (AXI_ADDRESS_LIMIT) // not used!
  ) i_wr (
    .en_adc (adc_en),
    .en_axi (adc_en_axi),
    .axi_rd_req (axi_rd_req_s),   // pulses at end of each burst to ddr3
    .axi_rd_addr (axi_rd_addr_s), // to transfer this
    .adc_rst (init), // WAS    .adc_rst (adc_rst),
    .adc_clk (adc_clk),
    .adc_wr (adc_fifo_wr),
    .adc_wdata (adc_ddata_s), // in

    // AXI interface to PL DDR	  
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

   
  // reads from DDR.
  // however it will not read past what was not yet written
  // using the rd_req_s and rd_addr_s mechnism.
  axi_adcfifo_rd #(
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_SIZE (AXI_SIZE),
    .AXI_LENGTH (AXI_LENGTH),
    .AXI_ADDRESS (AXI_ADDRESS),
    .AXI_ADDRESS_LIMIT (AXI_ADDRESS_LIMIT)
  ) i_rd (
    .en (adc_en_axi),
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
    .axi_rlast (axi_rlast), // in from port
    .axi_rdata (axi_rdata), // in from port (from ddr ???)
    .axi_rready (axi_rready), // out to port
    .axi_rerror (axi_xfer_status_s[3]),
    .axi_drst (axi_drst_s), // back out to axi_adcfifo_wr... to clear adc_xfer_status?
    .axi_dvalid (axi_dvalid_s),
    .axi_ddata (axi_ddata_s),  // out to axi_adcfifo_dma (just a dlyd copy of axi_rdata)
    .axi_dready (axi_dready_s));


  cdc_samp #(
     .W(1)
  ) cdc_adc_en_dma (
     .in_data(adc_en),
     .out_data(adc_en_dma),
     .out_clk (dma_clk));
   
  // This might be more of a fifo than it is a "dma ctlr"
  axi_adcfifo_dma #(
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .DMA_DATA_WIDTH (DMA_DATA_WIDTH),
    .DMA_READY_ENABLE (DMA_READY_ENABLE)
  ) i_dma_if (
    .dma_xfer_req (adc_en_dma),
    .axi_clk (axi_clk),
    .axi_drst (axi_drst_s), // in 
    .axi_dvalid (axi_dvalid_s), // in
    .axi_dready (axi_dready_s), // out
    .axi_ddata (axi_ddata_s),   // in
	      
    .axi_xfer_status (axi_xfer_status_s),
    .dma_clk (dma_clk),      
    .dma_wr (dma_wr),         // out
    .dma_wdata (dma_wdata),   // out
    .dma_wready (dma_wready), // in
    .dma_xfer_status (dma_xfer_status));

endmodule
