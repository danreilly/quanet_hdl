
`timescale 1ns/100ps

module util_dacfifo #(
  parameter       ADDRESS_WIDTH = 6,
  parameter       DATA_WIDTH = 128
) (

  // NuCrypt additions
  input  [511:0] regs_w,
  output [511:0] regs_r,
   
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
  output reg [(DATA_WIDTH-1):0] dac_data,
  output 			dac_dunf, // always 0
  output reg 			dac_xfer_out=0, // Dan added. Goes to ADC fifo to tell it to start

  input 			bypass // always 0
);

//  reg 				dac_xfer_out = 0;
   
   
//   wire 			dac_dunf;
   
  // How could I include global_pkg.vhd?
  parameter G_HDR_PD_W  = 24;
  parameter G_HDR_LEN_W = 6;
  parameter G_OSAMP_W   = 12;
  parameter G_HDR_QTY_W = 16;
   
  localparam  FIFO_THRESHOLD_HI = {(ADDRESS_WIDTH){1'b1}} - 4;

  // internal registers

  reg                                 dma_init = 1'b0;
  reg     [(ADDRESS_WIDTH-1):0]       dma_waddr = 'b0;
//  reg     [(ADDRESS_WIDTH-1):0]       dma_waddr_g = 'b0;
  reg [(ADDRESS_WIDTH-1):0] 	      dma_lastaddr = 'h0f;

   reg 				      dax_xfer_out = 0;
   

  reg                                 dma_xfer_req_d1 = 1'b0;
  reg                                 dma_xfer_req_d2 = 1'b0;
  reg                                 dma_xfer_out_fifo = 1'b0;

  wire 			      dma_rd_done;

  wire 		      dac_xfer_last;

   
  wire    	      dac_xfer_req;
  wire 		      mem_ren_last_pulse;


  wire hdr_pd_tic;
   
  reg     [(ADDRESS_WIDTH-1):0]       mem_raddr = 'b0;
  reg     [(ADDRESS_WIDTH-1):0]       dac_waddr = 'b0;



   
  wire  [(ADDRESS_WIDTH-1):0] 	      dac_lastaddr_m0;
  reg     [(ADDRESS_WIDTH-1):0]       dac_lastaddr_m1 = 'b0;

  reg     [(ADDRESS_WIDTH-1):0]       dac_lastaddr = 'b0;



  reg  mem_raddr_last=1'b0;
  reg  mem_ren=1'b0;
  reg  mem_ren_pend = 1'b0;
  reg  mem_dout_vld=0, mem_dout_vld_d=0;



  wire regw_tx_req, regw_use_lfsr, regw_tx_always, dma_rst_int_s;
  wire [G_HDR_LEN_W-1:0] regw_hdr_len_min1;
  wire [G_HDR_QTY_W-1:0] regw_hdr_qty_min1;
  wire [G_HDR_PD_W-1:0]  regw_hdr_pd_min1;
   
  reg [G_HDR_QTY_W-1:0] hdr_qty_min1 = 0;
  reg [G_HDR_LEN_W-1:0] hdr_len_min1 = 0;
  reg [G_HDR_PD_W-1:0]  hdr_pd_min1 = 0;
  reg tx_req, use_lfsr, tx_always, tx_0,
      tx_req_p, tx_req_d, tx_req_pulse = 0;
   
  wire gen_tx_req, gen_tx_always, dma_wren;
  wire dma_xfer_posedge_s;
  reg  dac_data_vld_p=0;


  wire [(DATA_WIDTH-1):0] gen_dout, mem_dout;
  reg  [(DATA_WIDTH-1):0]          dac_data_p, mem_dout_d;


//  wire    [(ADDRESS_WIDTH-1):0]       dma_waddr_b2g_s;
  wire    [(ADDRESS_WIDTH-1):0]       dac_waddr_g2b_s;


  wire                                dac_xfer_posedge_s;
  wire                                dac_rst_int_s;

  wire pd_tic, lfsr_hdr_vld, txing, hdr_first;

   
//  wire [(DATA_WIDTH-1):0] lfsr_hdr_dout;
   
  wire [(DATA_WIDTH/2-1):0] hdr_dout;

  // internal reset generation

  always @(posedge dma_clk) begin
    dma_xfer_req_d1 <= dma_xfer_req;
    dma_xfer_req_d2 <= dma_xfer_req_d1;
  end
  assign dma_xfer_posedge_s = ~dma_xfer_req_d2 & dma_xfer_req_d1;

  // a readback test
  assign regs_r[31:24]  = 0;
  assign regs_r[23:0]                = regw_hdr_pd_min1;
  assign regs_r[G_HDR_QTY_W-1+32:32] = regw_hdr_qty_min1;
  assign regs_r[511:63] = 0;

  // reg 0
  assign regw_hdr_pd_min1  = regs_w[G_HDR_PD_W-1:0];

  // reg 1   
  assign regw_hdr_qty_min1 = regs_w[G_HDR_QTY_W-1+32:32];

  // reg 2
  assign regw_tx_req       = regs_w[30 + 64];
  assign regw_use_lfsr     = regs_w[29 + 64]; // header contains lfsr
  assign regw_tx_always    = regs_w[28 + 64];
  assign regw_tx_0         = regs_w[27 + 64]; // header contains zeros
  assign regw_hdr_len_min1 = regs_w[17+64:12+64];

   

   
  // status register indicating that the module is in initialization phase


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
      dma_xfer_out_fifo <= 1'b0;
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
	
      dma_xfer_out_fifo <= dma_wren & dma_xfer_last;

//      dma_waddr_g <= dma_waddr_b2g_s;
    end // else: !if(dma_rst_int_s == 1'b1)

     
  end

//  cdc_thru #(
//   .W ( 1 )
//  ) i_cdc_thru (
//   .in_data (mem_ren_last_pulse),
//   .out_data (dma_rd_done));


  hdr_ctl hdr_ctl_i (
    .clk(dac_clk),
    .rst(dac_rst_int_s),

    //-- The period counter is free running.
    .pd_min1(hdr_pd_min1),
    .pd_tic(hdr_pd_tic),
    
    .tx_always(tx_always),
    .tx_req(tx_req_pulse),
    .hdr_qty_min1(hdr_qty_min1),

    //-- control signals indicate when to transmit
    .hdr_first(hdr_first),
    .hdr_tx(hdr_tx), // pulse at beginning of headers
    .txing(txing)); // remains high during pauses, until after final pause

  gen_hdr gen_hdr_i (
    .clk(dac_clk),
    .rst(dac_rst_int_s),

    .en(dac_valid), // flow ctl from DAC
		     
    .gen_en(use_lfsr),
    .tx_0(tx_0),		     
    .hdr_first(hdr_first),		     
    .hdr_tx(hdr_tx), // request transission by pulsing high for one cycle

    .osamp_min1(2'd3), // not used yet
    .hdr_len_min1(hdr_len_min1),

    .hdr_vld(lfsr_hdr_vld), // high only during the headers
    .dout(gen_dout));
   
//   assign gen_dout[127:112] = 0;
//   assign gen_dout[111: 96] = 0;
//   assign gen_dout[ 95: 80] = 0;
//   assign gen_dout[ 79: 64] = 0;
//   assign gen_dout[ 63: 48] = lfsr_hdr_dout[63:48];
//   assign gen_dout[ 47: 32] = lfsr_hdr_dout[47:32];
//   assign gen_dout[ 31: 16] = lfsr_hdr_dout[31:16];
//   assign gen_dout[ 15:  0] = lfsr_hdr_dout[15: 0];

  pulse_bridge #() xfer_req_pb (
    .in_pulse (dma_xfer_req),
    .in_clk   (dma_clk),
    .out_pulse (dac_xfer_req),
    .out_clk   (dac_clk));




  cdc_thru #(
    .W (ADDRESS_WIDTH)
  ) dac_lastaddr_thru (
    .in_data  (dma_lastaddr),
    .out_data (dac_lastaddr_m0));

  pulse_bridge #() rd_pulse_bridge (
    .in_pulse (dma_xfer_out_fifo),
    .in_clk (dma_clk),
    .out_pulse (dac_xfer_last),
    .out_clk (dac_clk));



  // we can reset the DAC side at each positive edge of dma_xfer_req, even if
  // sometimes the reset is redundant
  assign dac_rst_int_s = dac_xfer_req | dac_rst;

   
  always @(posedge dac_clk) begin

    // resample reg fields into this clock domain
    use_lfsr     <= regw_use_lfsr;
    tx_always    <= regw_tx_always;
    tx_0         <= regw_tx_0;
    hdr_pd_min1  <= regw_hdr_pd_min1;     
    hdr_qty_min1 <= regw_hdr_qty_min1;
    hdr_len_min1 <= regw_hdr_len_min1;
    tx_req       <= regw_tx_req;
     
    dac_lastaddr    <= dac_lastaddr_m0;
     
    tx_req_p <= tx_req   & !dac_rst_int_s;
    tx_req_d <= tx_req_p & !dac_rst_int_s;
    tx_req_pulse <= (tx_req_d & !tx_req_p) & !dac_rst_int_s;


     

// dac_valid    --------_-_-_----
// mem_ren      ___-----------__
// mem_raddr       01234556677
// mem_raddr_last __________--__
// mem_dout      ___abcdeffgghh
// mem_dout_vld  ___-----------__
     
    // This wont be set if using lfsr.
    mem_ren <= (hdr_tx | mem_ren)
               & !((mem_ren_last_pulse | use_lfsr) | dac_rst_int_s);

    if (mem_ren & dac_valid)
      mem_raddr <= mem_raddr+1;
    else
      mem_raddr <= 0;
     
    if (dac_rst_int_s | !mem_ren)
      mem_raddr_last <= 0;
    else if (dac_valid)
      mem_raddr_last <= (mem_raddr == dac_lastaddr);
     
    mem_dout_vld <= !dac_rst_int_s & mem_ren;

    dac_xfer_out <= hdr_first | (dax_xfer_out & !hdr_tx);
        
  end

  assign mem_ren_last_pulse = (dac_valid & mem_ren) & mem_raddr_last;


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
    mem_dout_d <= mem_dout; // kludge for timing
    mem_dout_vld_d <= mem_dout_vld;
    if (mem_dout_vld_d)
      dac_data <= mem_dout_d;
    else begin
      if (lfsr_hdr_vld)
        dac_data <= gen_dout;
      else
        dac_data <= 0;
    end
  end

endmodule
