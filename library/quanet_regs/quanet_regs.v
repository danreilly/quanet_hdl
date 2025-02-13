`timescale 1ns / 1ps

module quanet_regs #(
  parameter REG_ADDR_W = 4
) (
   //axi interface

  input 				  s_axi_aclk,
  input 				  s_axi_aresetn,
  input 				  s_axi_awvalid,
  input [15:0] 				  s_axi_awaddr,
  input [2:0] 				  s_axi_awprot,
  output 				  s_axi_awready,
  input 				  s_axi_wvalid,
  input [31:0] 				  s_axi_wdata,
  input [3:0] 				  s_axi_wstrb,
  output 				  s_axi_wready,
  output 				  s_axi_bvalid,
  output [1:0] 				  s_axi_bresp,
  input 				  s_axi_bready,
  input 				  s_axi_arvalid,
  input [15:0] 				  s_axi_araddr,
  input [2:0] 				  s_axi_arprot,
  output 				  s_axi_arready,
  output 				  s_axi_rvalid,
  output [1:0] 				  s_axi_rresp,
  output [31:0] 			  s_axi_rdata,
  input 				  s_axi_rready,

//  input [63:0] 				  reg_samp,
  input [3:0] 				  gth_status,
  output 				  gth_rst,
  // input [31:0] 				  reg_adc_stat,
  output reg [(32*(2**REG_ADDR_W) - 1):0] regs_w,
  input [(32*(2**REG_ADDR_W) - 1):0] 	  regs_r
);

  localparam  AXI_ADDR_W = REG_ADDR_W+2;
   

  reg                             up_wack = 'd0;
  reg   [31:0]                    up_rdata_s = 'd0;
  reg                             up_rack_s = 'd0;
  reg                             up_rreq_s_d = 'd0;
  reg   [31:0]               reg4='d0,     up_scratch = 'd0;

  wire                            up_clk;
  wire                            up_rstn;
  wire                            up_rreq_s;
  wire  [(REG_ADDR_W-1):0]     up_raddr_s;
  wire                            up_wreq_s;
  wire  [(REG_ADDR_W-1):0]     up_waddr_s;
  wire  [31:0]                    up_wdata_s;

  wire [(32*(2**REG_ADDR_W) - 1):0] regs_r_int;
   

  assign regs_r_int[191:0] = regs_r[191:0];
  assign regs_r_int[255:192]=0; //reg_samp;
  assign regs_r_int[287:256]=0; // reg_adc_stat;
  assign regs_r_int[291:288]=gth_status;
  assign regs_r_int[(32*(2**REG_ADDR_W) - 1):292]=0;

  assign gth_rst = regs_w[64];
					  
  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;



   
  // axi_sysid used addr w + 4 but I dont know why.   
  up_axi #(
    .AXI_ADDRESS_WIDTH(AXI_ADDR_W)
  ) i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr[AXI_ADDR_W-1:0]),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr[AXI_ADDR_W-1:0]),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

  //axi registers read
  always @(posedge up_clk) begin
    if (up_rstn == 1'b0) begin
      up_rack_s <= 'd0;
      up_rdata_s <= 'd0;
    end else begin
      up_rack_s <= up_rreq_s;
      if (up_rreq_s == 1'b1) begin
        up_rdata_s <= regs_r_int[32*up_raddr_s +: 32];
//      end else begin
//        up_rdata_s <= 32'd0;
      end
    end

    if (up_rstn == 1'b0) begin
      up_wack <= 'd0;
      up_scratch <= 'd0;
    end else begin
      up_wack <= up_wreq_s;
      if (up_wreq_s == 1) begin
        regs_w[32*up_waddr_s +: 32] <= up_wdata_s;
      end
    end
  end

endmodule
