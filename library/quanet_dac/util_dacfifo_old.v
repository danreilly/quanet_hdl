
`timescale 1ns/100ps

module util_dacfifo #(



  parameter       ADDRESS_WIDTH = 6,
  parameter       DATA_WIDTH = 128
		      
) (
   
  // NuCrypt additions
  output reg 			dac_xfer_out=0,
  input 			dac_tx_in,
  output 			dac_tx_out,
  output 			hdr_vld,
   
  // A kludgy connection to quanet_sfp
  input [3:0] 			gth_status, // axi clk domain
  output 			gth_rst, // axi clk domain
   
  input 			s_axi_aclk,
  input 			s_axi_aresetn,
  input 			s_axi_awvalid,
  input [15:0] 			s_axi_awaddr,
  output 			s_axi_awready,
  input [2:0] 			s_axi_awprot,
  input 			s_axi_wvalid,
  input [31:0] 			s_axi_wdata,
  input [ 3:0] 			s_axi_wstrb,
  output 			s_axi_wready,
  output 			s_axi_bvalid,
  output [ 1:0] 		s_axi_bresp,
  input 			s_axi_bready,
  input 			s_axi_arvalid,
  input [15:0] 			s_axi_araddr,
  output 			s_axi_arready,
  input [2:0] 			s_axi_arprot,
  output 			s_axi_rvalid,
  input 			s_axi_rready,
  output [ 1:0] 		s_axi_rresp,
  output [31:0] 		s_axi_rdata,

   
  // DMA interface
  input 			dma_clk,
  input 			dma_rst,
  input 			dma_valid,
  input [(DATA_WIDTH-1):0] 	dma_data,
  output 			dma_ready,
  input 			dma_xfer_req, // hi till all data sent
  input 			dma_xfer_last,

  // DAC interface (data flows to DAC)
  input 			dac_clk,
  input 			dac_rst,
  input 			dac_valid, // flow ctl from dac
  output [(DATA_WIDTH-1):0]     dac_data,
  output 			dac_dunf, // always 0

  input 			bypass // always 0
);

   
    
//  parameter G_FRAME_PD_W  = 24;
//  parameter G_HDR_LEN_W = 8;
//  parameter G_OSAMP_W   = 12;
//  parameter G_FRAME_QTY_W = 16;
   
  `include "global_pkg.v"


   
  localparam  FIFO_THRESHOLD_HI = {(ADDRESS_WIDTH){1'b1}} - 4;

  // internal registers

  reg                                 dma_init = 1'b0;
  reg     [(ADDRESS_WIDTH-1):0]       dma_waddr = 'b0;
//  reg     [(ADDRESS_WIDTH-1):0]       dma_waddr_g = 'b0;
  reg [(ADDRESS_WIDTH-1):0] 	      dma_lastaddr = 'h0f;

//   reg 				      dax_xfer_out = 0;
   

  reg                                 dma_xfer_req_d1 = 1'b0;
  reg                                 dma_xfer_req_d2 = 1'b0;
  reg                                 dma_xfer_last_pulse = 1'b0;



  wire 		      dac_xfer_last;

   
  wire    	      dac_xfer_req;
  wire 		      mem_ren_last_pulse;


  wire frame_pd_tic, hdr_end_pre, hdr_go, lfsr_state_nxt_vld;
  wire [G_HDR_LEN_W-1:0] hdr_cyc_cnt_down;
  wire [10:0] 		lfsr_state_nxt;
  wire [15:0] 		im_hdr, im_body;
   
   
   
  reg     [(ADDRESS_WIDTH-1):0]       mem_raddr = 'b0;
  reg     [(ADDRESS_WIDTH-1):0]       dac_waddr = 'b0;
  wire [(ADDRESS_WIDTH-1):0] 	      dac_lastaddr;

  reg  mem_raddr_last=1'b0;
  reg  mem_ren=1'b0;
  reg  mem_ren_pend = 1'b0;
  reg  mem_dout_vld=0, mem_dout_vld_d=0;



  wire dma_rst_int_s;


  wire [G_HDR_LEN_W-1:0] hdr_len_min1;
  wire [G_FRAME_QTY_W-1:0] frame_qty_min1, frame_qty_min1_dac;
  wire [G_FRAME_PD_W-1:0]  frame_pd_min1,  frame_pd_min1_dac;

  wire use_lfsr, tx_always, tx_0, tx_unsync, memtx_circ, framer_go,
       alice_syncing, frame_tx, rand_body, same_hdrs;
  reg tx_req_p=0, tx_req_d=0, tx_req_pulse=0;
  wire [1:0] osamp_min1;
   
   
   
  wire gen_tx_req, dma_wren, body_lfsr_nxt_vld, body_vld, body_go, body_end_pre;
  wire dma_xfer_posedge_s;
  reg  dac_data_vld_p=0;


  wire [3:0] gen_dout;

  wire [15-G_BODY_RAND_BITS:0] body_pad = 0;
  function [G_BODY_RAND_BITS:0] bf;
    input [G_BODY_RAND_BITS-1:0] vin;
    begin
      bf = vin - 2**(G_BODY_RAND_BITS-1) + vin[G_BODY_RAND_BITS-1];
    end
  endfunction // bf


   
  wire [G_BODY_RAND_BITS*4-1:0] body_out;
  wire [G_BODY_LEN_W-1:0] 	body_len_min1, body_cyc_ctr;
  wire [20:0] 			body_lfsr_nxt;
   
  wire [63:0] 			hdr_data, body_data;
  wire [15:0] 			dbg_pm, dbg_im;

  reg [63:0] pm_data, im_data;   
   
   
  wire [(DATA_WIDTH-1):0] mem_dout;
  reg  [(DATA_WIDTH-1):0] mem_dout_d;
  reg [31:0] 			   reg0;
   
  wire    [(ADDRESS_WIDTH-1):0]       dac_waddr_g2b_s;

  wire                                dac_xfer_posedge_s;
  wire                                dac_rst_int_s;

  wire pd_tic, txing, frame_first, lfsr_ld;

  wire [31:0] reg0_w, reg1_w, reg2_w, reg3_w, reg4_w, reg5_w, reg6_w,
	      reg0_r, reg1_r, reg2_r, reg3_r, reg4_r, reg5_r, reg6_r,
              reg2_w_dac, reg4_w_dac;
  wire [10:0] lfsr_rst_st, lfsr_rst_st_dac;


   

   


  // internal reset generation

  always @(posedge dma_clk) begin
    dma_xfer_req_d1 <= dma_xfer_req;
    dma_xfer_req_d2 <= dma_xfer_req_d1;
  end
  assign dma_xfer_posedge_s = ~dma_xfer_req_d2 & dma_xfer_req_d1;


  // At first I had a separate IP called quanet_regs that fanned in and out
  // to other IPs.  But this requires lots of individually-named interconnections
  // between IPs, and this complicates the daq_bd.tcl script that builds the design.
  // So now I think it's better for each IP to have its own small reg set,
  // even though I think that might be less efficient in FPGA resources.
  // 
  // Perhaps the following can be generalized, to be used in more than just util_dacfifo.v
  axi_regs #(
    .A_W(16)
  ) axi_regs_i (
    .aclk( s_axi_aclk),
    .arstn( s_axi_aresetn),

    // wr addr chan
    .awaddr ( s_axi_awaddr ),
    .awvalid ( s_axi_awvalid ),
    .awready ( s_axi_awready ),

    // wr data chan
    .wdata  ( s_axi_wdata  ),
    .wvalid ( s_axi_wvalid ),
    .wstrb  ( s_axi_wstrb  ),
    .wready ( s_axi_wready ),
    
    // wr rsp chan
    .bresp( s_axi_bresp),
    .bvalid( s_axi_bvalid),
    .bready( s_axi_bready),

    .araddr( s_axi_araddr),
    .arvalid( s_axi_arvalid),
    .arready( s_axi_arready),
    
    .rdata( s_axi_rdata),
    .rresp( s_axi_rresp),
    .rvalid( s_axi_rvalid),
    .rready( s_axi_rready),

    .reg0_w(reg0_w),
    .reg1_w(reg1_w),
    .reg2_w(reg2_w),
    .reg3_w(reg3_w),
    .reg4_w(reg4_w),
    .reg5_w(reg5_w),
    .reg6_w(reg6_w),
			
    .reg0_r(reg0_r),
    .reg1_r(reg1_r),
    .reg2_r(reg2_r),
    .reg3_r(reg3_r),
    .reg4_r(reg4_r),
    .reg5_r(reg5_r),
    .reg6_r(reg6_r));

  // reg 0 - probepd
  assign frame_pd_min1  = reg0_w[G_FRAME_PD_W-1:0];
  assign reg0_r = reg0_w;

  // reg 1 - frameqty
  assign frame_qty_min1 = reg1_w[G_FRAME_QTY_W-1:0];
  assign reg1_r = reg1_w;
   
  // reg 2 - ctl
  assign gth_rst    = reg2_w[20];
  assign reg2_r = 32'h2;
   
  // reg 3 - status
  assign reg3_r[31:8] = 24'h0;
  assign reg3_r[7:4]  = 2; // version
  assign reg3_r[3:0]  = gth_status;

  assign reg4_r = reg4_w;

  // reg 5
  assign lfsr_rst_st = reg5_w[10:0]; // was 11'b10100001111
  assign reg5_r = reg5_w;

  assign reg6_r = reg6_w;

   cdc_samp #(
     .W(11)
   ) samp_lfsr_rst_st ( 
     .in_data   ( lfsr_rst_st),
     .out_data  ( lfsr_rst_st_dac),
     .out_clk   ( dac_clk));



  // if the module is not in initialization phase, it should go
  // into reset at a positive edge of dma_xfer_req

 assign dma_rst_int_s = dma_rst | dma_xfer_posedge_s;

  // DMA / Write interface

  // write address generation

  assign dma_wren = dma_valid & dma_ready;

  always @(posedge dma_clk) begin
    if(dma_rst_int_s == 1'b1) begin
      dma_waddr <= 'b0;
//      dma_waddr_g <= 'b0;
      dma_xfer_last_pulse <= 1'b0;
    end else begin
      if (dma_wren == 1'b1) begin
	if (dma_xfer_last == 1'b1)
          dma_waddr    <= 'b0;
        else
          dma_waddr <= dma_waddr + 1'b1;
      end

      // dma_lastaddr held constant until end of the next dma xfer
      if (dma_xfer_last == 1'b1)
	  dma_lastaddr <= dma_waddr-1;
	
      dma_xfer_last_pulse <= dma_wren & dma_xfer_last;


    end // else: !if(dma_rst_int_s == 1'b1)

  end

   
  cdc_samp #(
   .W (G_FRAME_PD_W)
  ) frame_pd_cdc_samp (
   .in_data  (frame_pd_min1),
   .out_clk  (dac_clk),		       
   .out_data (frame_pd_min1_dac));
   
  cdc_samp #(
   .W (G_FRAME_QTY_W)
  ) frame_qty_cdc_samp (
   .in_data  (frame_qty_min1),
   .out_clk  (dac_clk),		       
   .out_data (frame_qty_min1_dac));

   
  cdc_samp #(
   .W (32*2)
  ) reg2_cdc_samp (
   .in_data  ({reg2_w, reg4_w}),
   .out_clk  (dac_clk),		       
   .out_data ({reg2_w_dac, reg4_w_dac}));
  assign tx_unsync      = reg2_w_dac[31]; // default is to tx syncronously with adc dma.  old ADI way was for dma req to start it.
  // assign tx_req         = reg2_w_dac[30]; // no longer used
  assign rand_body      = reg2_w_dac[30];   //
  assign use_lfsr       = reg2_w_dac[29]; // header contains lfsr
  assign tx_always      = reg2_w_dac[28];
  assign tx_0           = reg2_w_dac[27]; // header contains zeros
  assign memtx_circ     = reg2_w_dac[26]; // circular xmit from mem
  assign alice_syncing  = reg2_w_dac[25]; // means I am alice, doing sync
  assign same_hdrs      = reg2_w_dac[24]; // tx all the same hdr

 // gth_rst = reg2_w_dac[20]; // REALLY!   
  assign hdr_len_min1 = reg2_w_dac[19:12];
  assign osamp_min1     = reg2_w_dac[11:10]; // oversampling: 0=1,1=2,3=4
  assign body_len_min1  = reg2_w_dac[9:0];

  assign im_hdr  = reg4_w_dac[31:16];
  assign im_body = reg4_w_dac[15: 0];

  assign framer_go = tx_req_pulse & !alice_syncing;
  frame_ctl frame_ctl_i (
    .clk(dac_clk),
    .rst(dac_rst_int_s),

    // The period counter is free running.
    .pd_min1(frame_pd_min1_dac),
    .pd_tic(frame_pd_tic),
    
    .tx_always(tx_always),
    .tx_req(framer_go),
    .frame_qty_min1(frame_qty_min1_dac),

    // control signals indicate when to transmit
    .frame_first(frame_first),
    .frame_tx(frame_tx), // pulse at beginning of frames
    .txing(txing)); // remains high during pauses, until after final pause

  assign hdr_go = alice_syncing ? tx_req_pulse : (frame_tx && use_lfsr);
  assign lfsr_ld = frame_first | (same_hdrs & frame_tx);
  gen_hdr #(
    .HDR_LEN_W(G_HDR_LEN_W)
  )gen_hdr_i (
    .clk(dac_clk),
    .rst(dac_rst_int_s),
    .osamp_min1(osamp_min1),
    .hdr_len_min1(hdr_len_min1),

    .gen_en(1'b0), // MEANINGLESS		     

    .lfsr_state_ld(lfsr_ld),
    .lfsr_state_in(lfsr_rst_st_dac),
    .lfsr_state_nxt(lfsr_state_nxt),
    .lfsr_state_nxt_vld(lfsr_state_nxt_vld),
		     
    .go_pulse(hdr_go),
    .en(1'b1),

    .hdr_vld(hdr_vld), // high only during the headers
    .hdr_end_pre(hdr_end_pre),
    .cyc_cnt_down(hdr_cyc_cnt_down),		     
    .dout(gen_dout));
  assign  hdr_data = {~gen_dout[3],1'b1,14'd0,
			  ~gen_dout[2],1'b1,14'd0,
			  ~gen_dout[1],1'b1,14'd0,
			  ~gen_dout[0],1'b1,14'd0};

  assign body_go = hdr_end_pre && rand_body;
  gen_body #(
    .LEN_W(G_BODY_LEN_W),
    .CP(G_BODY_CHAR_POLY),
    .D_W(G_BODY_RAND_BITS)
  ) gen_body_i (
    .clk(dac_clk),
    .rst(dac_rst_int_s),
    .osamp_min1(osamp_min1),
    .len_min1(body_len_min1),

    .lfsr_state_ld(frame_first),
    .lfsr_state_in(21'habcde),
    .lfsr_state_nxt(body_lfsr_nxt),
    .lfsr_state_nxt_vld(body_lfsr_nxt_vld),
		     
    .go_pulse(body_go),
    .en(1'b1),

    .end_pre(body_end_pre),
    .cyc_cnt_down(body_cyc_ctr),
    .dout_vld(body_vld), // high only during the headers
    .dout(body_out));
	
//
//body_out[3*G_BODY_LEN_W-1 downto 2*G_BODY_LEN_W]
//body_out[2*G_BODY_LEN_W-1 downto 1*G_BODY_LEN_W]

  assign body_data = {bf(body_out[4*G_BODY_RAND_BITS-1:3*G_BODY_RAND_BITS]),body_pad,
 		      bf(body_out[3*G_BODY_RAND_BITS-1:2*G_BODY_RAND_BITS]),body_pad,
		      bf(body_out[2*G_BODY_RAND_BITS-1:1*G_BODY_RAND_BITS]),body_pad,
		      bf(body_out[1*G_BODY_RAND_BITS-1:0*G_BODY_RAND_BITS]),body_pad};
   
  cdc_pulse #() xfer_req_pb (
    .in_pulse (dma_xfer_req),
    .in_clk   (dma_clk),
    .out_pulse (dac_xfer_req),
    .out_clk   (dac_clk));




  cdc_samp #(
    .W (ADDRESS_WIDTH)
  ) dac_lastaddr_samp (
    .in_data  (dma_lastaddr),
    .out_clk  (dac_clk),		       
    .out_data (dac_lastaddr));


  // we can reset the DAC side at each positive edge of dma_xfer_req, even if
  // sometimes the reset is redundant
  assign dac_rst_int_s = dac_xfer_req | dac_rst;

   
  always @(posedge dac_clk) begin

     
     
   // dac_tx is a dac_clk domain signal from adc fifo that tells dac when to tx.     
    tx_req_p <= (tx_unsync ? dac_xfer_req : dac_tx_in) & !dac_rst_int_s;
    tx_req_d <= tx_req_p & !dac_rst_int_s;
    // This pulse starts transmision:
    tx_req_pulse <= (tx_req_p & !tx_req_d) & !dac_rst_int_s;


     

// dac_valid    --------_-_-_----
// mem_ren      ___-----------__
// mem_raddr       01234556677
// mem_raddr_last __________--__
// mem_dout      ___abcdeffgghh
// mem_dout_vld  ___-----------__
     
    // This wont be set if using lfsr.
    mem_ren <= (frame_tx | mem_ren)
               & !((mem_ren_last_pulse | use_lfsr) | dac_rst_int_s);

    if (dac_valid) begin
      if (!mem_ren | mem_raddr_last)
        mem_raddr <= 0;
      else
        mem_raddr <= mem_raddr+1;
    end
     
    if (dac_rst_int_s | !mem_ren)
      mem_raddr_last <= 0;
    else if (dac_valid)
      mem_raddr_last <= (mem_raddr == dac_lastaddr);
     
    mem_dout_vld <= !dac_rst_int_s & mem_ren;

    dac_xfer_out <= frame_first | (dac_xfer_out & !frame_tx);
        
  end

  assign dac_tx_out = dac_xfer_out;
   
  assign mem_ren_last_pulse = !memtx_circ & (dac_valid & mem_ren) & mem_raddr_last;


  // memory instantiation
  // output is registered, so its like
  //   raddr  0000112333
  //   dout   aaaaabbcdd
  ad_mem #(
    .ADDRESS_WIDTH (ADDRESS_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
  ) i_mem_fifo (
    .clka (dma_clk),
    .wea (dma_wren),
    .addra (dma_waddr),
    .dina (dma_data),
		
    .clkb (dac_clk),
    .reb (1'b1),
    .addrb (mem_raddr),
    .doutb (mem_dout));


  // underflow make sense only if bypass is enabled
  assign dac_dunf = 0;




  // the util_dacfifo is always ready for the DMA
  assign dma_ready = 1'b1;


  always @(posedge dac_clk) begin
     
    mem_dout_vld_d <= mem_dout_vld;
     
    if (mem_dout_vld)
      mem_dout_d <= mem_dout;
    else
      mem_dout_d <= 0;
       
//    dac_data[127:64] <= mem_dout_d[127:64];

    if (hdr_vld)
      im_data <= {im_hdr,im_hdr,im_hdr,im_hdr};
    else if (body_vld)
      im_data <= {im_body,im_body,im_body,im_body};
    else
      im_data <= 0;
     
    if (hdr_vld)
      pm_data <= hdr_data;
    else if (body_vld)
      pm_data <= body_data;
    else if (mem_dout_vld_d)
      pm_data <= mem_dout_d[63:0];
    else
      pm_data <= 0;

     
  end // always @ (posedge dac_clk)
  assign dac_data = {im_data[63:48], pm_data[63:48], im_data[47:32], pm_data[47:32],
		     im_data[31:16], pm_data[31:16], im_data[15:0], pm_data[15:0]};

  assign dbg_pm = dac_data[15:0];
  assign dbg_im = dac_data[15+64:64];

endmodule
