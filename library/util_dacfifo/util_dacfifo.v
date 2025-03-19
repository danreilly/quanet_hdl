
`timescale 1ns/100ps

module util_dacfifo #(
  parameter       ADDRESS_WIDTH = 6,
  parameter       DATA_WIDTH = 128
) (

  // NuCrypt additions
  output reg 			dac_xfer_out=0,
  input 			dac_tx_in,
  output 			dac_tx_out,
  // A kludgy connection to quanet_sfp
  input [3:0] 			gth_status, // axi clk domain
  output 			gth_rst, // axi clk domain
   
  input 			s_axi_aclk,
  input 			s_axi_aresetn,
  input 			s_axi_awvalid,
  input [5:0] 			s_axi_awaddr,
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
  input [5:0] 			s_axi_araddr,
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
  output reg [(DATA_WIDTH-1):0] dac_data,
  output 			dac_dunf, // always 0

  input 			bypass // always 0
);

   
  // How could I include global_pkg.vhd?
  `include "global_pkg.v"
    
//  parameter G_PROBE_PD_W  = 24;
//  parameter G_PROBE_LEN_W = 8;
//  parameter G_OSAMP_W   = 12;
//  parameter G_PROBE_QTY_W = 16;
   
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


  wire probe_pd_tic; // pulses hi every probe pd\
   
  reg     [(ADDRESS_WIDTH-1):0]       mem_raddr = 'b0;
  reg     [(ADDRESS_WIDTH-1):0]       dac_waddr = 'b0;
  wire [(ADDRESS_WIDTH-1):0] 	      dac_lastaddr;

  reg  mem_raddr_last=1'b0;
  reg  mem_ren=1'b0;
  reg  mem_ren_pend = 1'b0;
  reg  mem_dout_vld=0, mem_dout_vld_d=0;



  wire dma_rst_int_s;


  wire [G_PROBE_LEN_W-1:0] probe_len_min1;
  wire [G_PROBE_QTY_W-1:0] probe_qty_min1, probe_qty_min1_dac;
  wire [G_PROBE_PD_W-1:0]  probe_pd_min1,  probe_pd_min1_dac;

  wire use_lfsr, tx_always, tx_0, tx_unsync, memtx_circ;
  reg tx_req_p=0, tx_req_d=0, tx_req_pulse=0;
   
   
  wire gen_tx_req, dma_wren;
  wire dma_xfer_posedge_s;
  reg  dac_data_vld_p=0;


  wire [63:0] gen_dout;

  wire [(DATA_WIDTH-1):0] mem_dout;
  reg  [(DATA_WIDTH-1):0] mem_dout_d;
  reg [31:0] 			   reg0;
   
  wire    [(ADDRESS_WIDTH-1):0]       dac_waddr_g2b_s;

  wire                                dac_xfer_posedge_s;
  wire                                dac_rst_int_s;

  wire pd_tic, lfsr_probe_vld, txing, probe_first;

  wire [31:0] reg0_w, reg1_w, reg2_w, reg2_w_dac, reg3_r;
   

   


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
    .A_W(6)
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
			
    .reg0_r(reg0_w),
    .reg1_r(reg1_w),
    .reg2_r(reg2_w),
    .reg3_r(reg3_r));

  // reg 0 - probepd
  assign probe_pd_min1  = reg0_w[G_PROBE_PD_W-1:0];

  // reg 1 - probeqty
  assign probe_qty_min1 = reg1_w[G_PROBE_QTY_W-1:0];

  // reg 3 - status
  assign reg3_r[3:0]  = gth_status;
  assign reg3_r[7:4]  = 1; // version



   



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
   .W (G_PROBE_PD_W)
  ) probe_pd_cdc_samp (
   .in_data  (probe_pd_min1),
   .out_clk  (dac_clk),		       
   .out_data (probe_pd_min1_dac));
   
  cdc_samp #(
   .W (G_PROBE_QTY_W)
  ) probe_qty_cdc_samp (
   .in_data  (probe_qty_min1),
   .out_clk  (dac_clk),		       
   .out_data (probe_qty_min1_dac));

  assign gth_rst  =    reg2_w[10];
   
  cdc_samp #(
   .W (32)
  ) reg2_cdc_samp (
   .in_data  (reg2_w),
   .out_clk  (dac_clk),		       
   .out_data (reg2_w_dac));
  assign tx_unsync      = reg2_w_dac[31]; // default is to tx syncronously with adc dma
  // assign tx_req         = reg2_w_dac[30]; // no longer used
  assign use_lfsr       = reg2_w_dac[29]; // header contains lfsr
  assign tx_always      = reg2_w_dac[28];
  assign tx_0           = reg2_w_dac[27]; // header contains zeros
  assign memtx_circ     = reg2_w_dac[26]; // circular xmit from mem
  assign probe_len_min1 = reg2_w_dac[19:12];


  probe_ctl probe_ctl_i (
    .clk(dac_clk),
    .rst(dac_rst_int_s),

    // The period counter is free running.
    .pd_min1(probe_pd_min1_dac),
    .pd_tic(probe_pd_tic),
    
    .tx_always(tx_always),
    .tx_req(tx_req_pulse),
    .probe_qty_min1(probe_qty_min1_dac),

    // control signals indicate when to transmit
    .probe_first(probe_first),
    .probe_tx(probe_tx), // pulse at beginning of probes
    .txing(txing)); // remains high during pauses, until after final pause

  gen_probe gen_probe_i (
    .clk(dac_clk),
    .rst(dac_rst_int_s),

    .en(dac_valid), // flow ctl from DAC
		     
    .gen_en(use_lfsr),
    .tx_0(tx_0),		     
    .probe_first(probe_first),		     
    .probe_tx(probe_tx), // request transission by pulsing high for one cycle

    .osamp_min1(2'd3), // not used yet
    .probe_len_min1(probe_len_min1),

    .probe_vld(lfsr_probe_vld), // high only during the headers
    .dout(gen_dout));
   

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
    mem_ren <= (probe_tx | mem_ren)
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

    dac_xfer_out <= probe_first | (dac_xfer_out & !probe_tx);
        
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
       
    dac_data[127:64] <= mem_dout_d[127:64];
    if (lfsr_probe_vld)
      dac_data[63:0] <= gen_dout;
    else if (mem_dout_vld_d)
      dac_data[63:0] <= mem_dout_d[63:0];
    else
      dac_data[63:0] <= 0;

     
  end

endmodule
