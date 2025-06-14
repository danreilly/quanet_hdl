library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package quanet_adc_pkg is

  -- Vivado mixed-language synthesis only supports generics of
  -- types: integer, real, string, boolean.
  -- not std_logic vector!
  
  component quanet_adc
    generic (
      ADC_DATA_WIDTH   : integer := 128;
      DMA_DATA_WIDTH   : integer :=  64;
      AXI_DATA_WIDTH   : integer := 512; -- the AXI to the DDR that is.
      DMA_READY_ENABLE : integer :=   1;
      AXI_SIZE         : integer :=   2;
      AXI_LENGTH       : integer :=  16;
      AXI_A_W          : integer :=   8);
--      AXI_ADDRESS       : integer; -- std_logic_vector(31 downto 0) := x"80000000";  -- start addr in DDR
--      AXI_ADDRESS_LIMIT : integer); -- std_logic_vector(31 downto 0) := x"8fffffff");
    port (
      s_axi_aclk: in std_logic;
      s_axi_aresetn: in std_logic;

      -- wr addr chan
      s_axi_awaddr : in std_logic_vector(AXI_A_W-1 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      s_axi_awprot  : in std_logic_vector( 2 downto 0 );
      
      -- wr data chan
      s_axi_wdata  : in std_logic_vector(31 downto 0);
      s_axi_wvalid : in std_logic;
      s_axi_wstrb  : in std_logic_vector(3 downto 0);
      s_axi_wready : out std_logic;
      
      -- wr rsp chan
      s_axi_bresp: out std_logic_vector(1 downto 0);
      s_axi_bvalid: out std_logic;
      s_axi_bready: in std_logic;

      s_axi_araddr: in std_logic_vector(AXI_A_W-1 downto 0);
      s_axi_arvalid: in std_logic;
      s_axi_arready: out std_logic;
      s_axi_arprot: in std_logic_vector(2 downto 0);
      
      s_axi_rdata: out std_logic_vector(31 downto 0);
      s_axi_rresp: out std_logic_vector(1 downto 0);
      s_axi_rvalid: out std_logic;
      s_axi_rready: in std_logic;

      -- Quanet additions
      rxq_sw_ctl          : out std_logic;
      dac_clk             : in  std_logic;
      dac_tx              : out std_logic;
      dac_tx_in           : in  std_logic; -- dac is ready

      -- fifo interface
      adc_rst             : in  std_logic; -- only seems to happen once
      adc_clk             : in  std_logic;
      adc_wr              : in  std_logic;
      adc_wdata           : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      adc_wovf            : out std_logic;

      -- dma interface
      dma_clk             : in  std_logic;
      dma_wr              : out std_logic;
      dma_wdata           : out std_logic_vector(DMA_DATA_WIDTH-1 downto 0);
      dma_wready          : in  std_logic;
      dma_xfer_req        : in  std_logic;
      dma_xfer_status     : out std_logic_vector(3 downto 0);

      -- axi interface to DDR
      axi_clk             : in  std_logic;
      axi_resetn          : in  std_logic;
      axi_awvalid         : out std_logic;
      axi_awid            : out std_logic_vector(3 downto 0);
      axi_awburst         : out std_logic_vector(1 downto 0);
      axi_awlock          : out std_logic;
      axi_awcache         : out std_logic_vector(3 downto 0);
      axi_awprot          : out std_logic_vector(2 downto 0);
      axi_awqos           : out std_logic_vector(3 downto 0);
      axi_awuser          : out std_logic_vector(3 downto 0);
      axi_awlen           : out std_logic_vector(7 downto 0);
      axi_awsize          : out std_logic_vector(2 downto 0);
      axi_awaddr          : out std_logic_vector(31 downto 0);
      axi_awready         : in  std_logic;
      axi_wvalid          : out std_logic;
      axi_wdata           : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
      axi_wstrb           : out std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0);
      axi_wlast           : out std_logic;
      axi_wuser           : out std_logic_vector(3 downto 0);
      axi_wready          : in  std_logic;
      axi_bvalid          : in  std_logic;
      axi_bid             : in  std_logic_vector(3 downto 0);
      axi_bresp           : in  std_logic_vector(1 downto 0);
      axi_buser           : in  std_logic_vector(3 downto 0);
      axi_bready          : out std_logic;
      axi_arvalid         : out std_logic;
      axi_arid            : out std_logic_vector(3 downto 0);
      axi_arburst         : out std_logic_vector(1 downto 0);
      axi_arlock          : out std_logic;
      axi_arcache         : out std_logic_vector(3 downto 0);
      axi_arprot          : out std_logic_vector(2 downto 0);
      axi_arqos           : out std_logic_vector(3 downto 0);
      axi_aruser          : out std_logic_vector(3 downto 0);
      axi_arlen           : out std_logic_vector(7 downto 0);
      axi_arsize          : out std_logic_vector(2 downto 0);
      axi_araddr          : out std_logic_vector(31 downto 0);
      axi_arready         : in  std_logic;
      axi_rvalid          : in  std_logic;
      axi_rid             : in  std_logic_vector(3 downto 0);
      axi_ruser           : in  std_logic_vector(3 downto 0);
      axi_rresp           : in  std_logic_vector(1 downto 0);
      axi_rlast           : in  std_logic;
      axi_rdata           : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
      axi_rready          : out std_logic);
  end component;

  
end package;


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;

entity quanet_adc is
  generic (
     ADC_DATA_WIDTH : integer := 128;
     DMA_DATA_WIDTH : integer :=  64;
     AXI_DATA_WIDTH : integer :=  512; -- to ddr axi
     DMA_READY_ENABLE : integer :=  1;
     AXI_SIZE : integer :=  2;
     AXI_LENGTH : integer :=  16;
     AXI_A_W: integer := 8);
--     AXI_ADDRESS : integer;
--     AXI_ADDRESS_LIMIT : integer);
  port (
    s_axi_aclk: in std_logic;
    s_axi_aresetn: in std_logic;

    -- wr addr chan
    s_axi_awaddr : in std_logic_vector(AXI_A_W-1 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;
    s_axi_awprot  : in std_logic_vector( 2 downto 0 );
    
    -- wr data chan
    s_axi_wdata  : in std_logic_vector(31 downto 0);
    s_axi_wvalid : in std_logic;
    s_axi_wstrb  : in std_logic_vector(3 downto 0);
    s_axi_wready : out std_logic;
    
    -- wr rsp chan
    s_axi_bresp: out std_logic_vector(1 downto 0);
    s_axi_bvalid: out std_logic;
    s_axi_bready: in std_logic;

    s_axi_araddr: in std_logic_vector(AXI_A_W-1 downto 0);
    s_axi_arvalid: in std_logic;
    s_axi_arready: out std_logic;
    s_axi_arprot: in std_logic_vector(2 downto 0);
    
    s_axi_rdata: out std_logic_vector(31 downto 0);
    s_axi_rresp: out std_logic_vector(1 downto 0);
    s_axi_rvalid: out std_logic;
    s_axi_rready: in std_logic;

    -- Quanet additions
    rxq_sw_ctl          : out std_logic;
    dac_clk             : in  std_logic;
    dac_tx              : out std_logic;
    dac_tx_in           : in  std_logic; -- dac is ready

    -- fifo interface
    adc_rst             : in  std_logic;
    adc_clk             : in  std_logic;
    adc_wr              : in  std_logic;
    adc_wdata           : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
    adc_wovf            : out std_logic;

    -- dma interface
    dma_clk             : in  std_logic;
    dma_wr              : out std_logic;
    dma_wdata           : out std_logic_vector(DMA_DATA_WIDTH-1 downto 0);
    dma_wready          : in  std_logic;
    dma_xfer_req        : in  std_logic;
    dma_xfer_status     : out std_logic_vector(3 downto 0);

    -- axi interface to DDR
    axi_clk             : in  std_logic;
    axi_resetn          : in  std_logic;
    axi_awvalid         : out std_logic;
    axi_awid            : out std_logic_vector(3 downto 0);
    axi_awburst         : out std_logic_vector(1 downto 0);
    axi_awlock          : out std_logic;
    axi_awcache         : out std_logic_vector(3 downto 0);
    axi_awprot          : out std_logic_vector(2 downto 0);
    axi_awqos           : out std_logic_vector(3 downto 0);
    axi_awuser          : out std_logic_vector(3 downto 0);
    axi_awlen           : out std_logic_vector(7 downto 0);
    axi_awsize          : out std_logic_vector(2 downto 0);
    axi_awaddr          : out std_logic_vector(31 downto 0);
    axi_awready         : in  std_logic;
    axi_wvalid          : out std_logic;
    axi_wdata           : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    axi_wstrb           : out std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0);
    axi_wlast           : out std_logic;
    axi_wuser           : out std_logic_vector(3 downto 0);
    axi_wready          : in  std_logic;
    axi_bvalid          : in  std_logic;
    axi_bid             : in  std_logic_vector(3 downto 0);
    axi_bresp           : in  std_logic_vector(1 downto 0);
    axi_buser           : in  std_logic_vector(3 downto 0);
    axi_bready          : out std_logic;
    axi_arvalid         : out std_logic;
    axi_arid            : out std_logic_vector(3 downto 0);
    axi_arburst         : out std_logic_vector(1 downto 0);
    axi_arlock          : out std_logic;
    axi_arcache         : out std_logic_vector(3 downto 0);
    axi_arprot          : out std_logic_vector(2 downto 0);
    axi_arqos           : out std_logic_vector(3 downto 0);
    axi_aruser          : out std_logic_vector(3 downto 0);
    axi_arlen           : out std_logic_vector(7 downto 0);
    axi_arsize          : out std_logic_vector(2 downto 0);
    axi_araddr          : out std_logic_vector(31 downto 0);
    axi_arready         : in  std_logic;
    axi_rvalid          : in  std_logic;
    axi_rid             : in  std_logic_vector(3 downto 0);
    axi_ruser           : in  std_logic_vector(3 downto 0);
    axi_rresp           : in  std_logic_vector(1 downto 0);
    axi_rlast           : in  std_logic;
    axi_rdata           : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    axi_rready          : out std_logic);
end quanet_adc;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
use work.axi_reg_array_pkg.ALL;
use work.cdc_samp_pkg.ALL;
use work.cdc_sync_cross_pkg.ALL;
use work.cdc_pulse_pkg.ALL;
use work.hdr_corr_pkg.ALL;
use work.event_ctr_pkg.ALL;
architecture rtl of quanet_adc is

  constant FWVER_CONST: std_logic_vector(3 downto 0) :=
    std_logic_vector(to_unsigned(G_FWVER, 4));
  signal fwver: std_logic_vector(3 downto 0) := FWVER_CONST;
  
  constant NUM_REGS: integer := 8;
  
  signal areg_r_vec, areg_w_vec: std_logic_vector(NUM_REGS*32-1 downto 0);
  type reg_array_t is array(0 to NUM_REGS-1) of std_logic_vector(31 downto 0);
  signal areg_r, areg_w: reg_array_t;
  signal areg_w_pulse, areg_r_pulse: std_logic_vector(NUM_REGS-1 downto 0);

  constant AREG_ACTL:  integer := 0;
  constant AREG_STAT:  integer := 1;
  constant AREG_CSTAT: integer := 2;
  constant AREG_FR1:   integer := 3;
  constant AREG_FR2:   integer := 4;
  constant AREG_HDR:   integer := 5;
  constant AREG_SYNC:  integer := 6;
  constant AREG_PCTL:  integer := 7;

  -- it is awkward to express x80000000 in vhdl.  I'd rather use
  -- std_logic_vector.  But that doesn't pass to verilog.
  constant  AXI_ADDRESS       : integer := (-2**30)*2; -- std_logic_vector(31 downto 0) := x"80000000";  -- start addr in DDR
  constant  AXI_ADDRESS_LIMIT : integer := AXI_ADDRESS + (2**28 - 1); -- std_logic_vector(31 downto 0) := x"8fffffff");


  component axi_adcfifo_adc
    generic (
      ADC_DATA_WIDTH : integer := 128;
      AXI_DATA_WIDTH : integer := 512);
    port (
      -- fifo interface
      adc_rst: in std_logic;
      adc_clk: in std_logic;
      adc_wr: in std_logic;
      adc_wdata: in std_logic_vector(ADC_DATA_WIDTH-1 downto 0);  
      adc_wovf: out std_logic;
      adc_dwr: out std_logic;
      adc_ddata: out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);

      -- axi interface
      axi_drst: in std_logic;
      axi_clk: in std_logic;
      axi_xfer_status:  in std_logic_vector(3 downto 0));
  end component;

  component axi_adcfifo_wr
    generic (
      AXI_DATA_WIDTH : integer;
      AXI_SIZE       : integer;
      AXI_LENGTH     : integer;
      AXI_ADDRESS    : integer;
      AXI_ADDRESS_LIMIT : integer);
    port (
      -- request and synchronization
      dma_xfer_req: in std_logic;

      -- read interface
      axi_rd_req: out std_logic;
      axi_rd_addr: out std_logic_vector( 31 downto 0);

      -- fifo interface
      adc_rst: in std_logic;
      adc_clk: in std_logic;
      adc_wr: in std_logic;
      adc_wdata: in std_logic_vector(AXI_DATA_WIDTH-1 downto 0);

      -- axi interface
      axi_clk: in std_logic;
      axi_resetn: in std_logic;
      axi_awvalid: out std_logic;
      axi_awid: out std_logic_vector( 3 downto 0);
      axi_awburst: out std_logic_vector( 1 downto 0);
      axi_awlock: out std_logic;
      axi_awcache: out std_logic_vector( 3 downto 0);
      axi_awprot: out std_logic_vector( 2 downto 0);
      axi_awqos: out std_logic_vector( 3 downto 0);
      axi_awuser: out std_logic_vector( 3 downto 0);
      axi_awlen: out std_logic_vector( 7 downto 0);
      axi_awsize: out std_logic_vector( 2 downto 0);
      axi_awaddr: out std_logic_vector( 31 downto 0);
      axi_awready: in std_logic;
      axi_wvalid: out std_logic;
      axi_wdata: out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
      axi_wstrb: out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
      axi_wlast: out std_logic;
      axi_wuser: out std_logic_vector( 3 downto 0);
      axi_wready: in std_logic;
      axi_bvalid: in std_logic;
      axi_bid: in std_logic_vector( 3 downto 0);
      axi_bresp: in std_logic_vector( 1 downto 0);
      axi_buser: in std_logic_vector( 3 downto 0);
      axi_bready: out std_logic;

      -- axi status
      axi_dwovf: out std_logic;
      axi_dwunf: out std_logic;
      axi_werror: out std_logic);
  end component;


  component axi_adcfifo_rd
    generic (
      AXI_DATA_WIDTH : integer;
      AXI_SIZE : integer;
      AXI_LENGTH : integer;
      AXI_ADDRESS : integer;
      AXI_ADDRESS_LIMIT : integer);
    port (
      -- request and synchronization
      dma_xfer_req: in std_logic;

      -- read interface
      axi_rd_req: in std_logic;
      axi_rd_addr: in std_logic_vector( 31 downto 0);

      -- axi interface
      axi_clk: in std_logic;
      axi_resetn: in std_logic;
      axi_arvalid: out std_logic;
      axi_arid: out std_logic_vector( 3 downto 0);
      axi_arburst: out std_logic_vector( 1 downto 0);
      axi_arlock: out std_logic;
      axi_arcache: out std_logic_vector( 3 downto 0);
      axi_arprot: out std_logic_vector( 2 downto 0);
      axi_arqos: out std_logic_vector( 3 downto 0);
      axi_aruser: out std_logic_vector( 3 downto 0);
      axi_arlen: out std_logic_vector( 7 downto 0);
      axi_arsize: out std_logic_vector( 2 downto 0);
      axi_araddr: out std_logic_vector( 31 downto 0);
      axi_arready: in std_logic;
      axi_rvalid: in std_logic;
      axi_rid: in std_logic_vector( 3 downto 0);
      axi_ruser: in std_logic_vector( 3 downto 0);
      axi_rresp: in std_logic_vector( 1 downto 0);
      axi_rlast: in std_logic;
      axi_rdata: in std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
      axi_rready: out std_logic;

      -- axi status
      axi_rerror: out std_logic;

      -- fifo interface
      axi_drst: out std_logic;
      axi_dvalid: out std_logic;
      axi_ddata: out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
      axi_dready: in std_logic);
  end component;

  component axi_adcfifo_dma
    generic (
      AXI_DATA_WIDTH: integer := 512;
      DMA_DATA_WIDTH: integer :=  64;
      DMA_READY_ENABLE: integer := 1);
    port (
      axi_clk   : in std_logic;
      axi_drst  : in std_logic;
      axi_dvalid: in std_logic;
      axi_ddata : in std_logic_vector(AXI_DATA_WIDTH-1 downto 0); 
      axi_dready: out std_logic;
      axi_xfer_status: in  std_logic_vector(3 downto 0); 

      dma_clk    : in std_logic;
      dma_wr     : out std_logic;
      dma_wdata  : out std_logic_vector(DMA_DATA_WIDTH-1 downto 0); 
      dma_wready : in std_logic;
      dma_xfer_req : in std_logic;
      dma_xfer_status: out std_logic_vector(3 downto 0));
  end component;
  
  signal meas_noise, meas_noise_adc, dma_xfer_req_rc, dma_xfer_req_inadc, dma_xfer_req_inadc_d, s_axi_rst, axi_rst, save_buf_avail, txrx_en: std_logic := '0';
  signal
    areg_actl_w, areg_actl_r,
    areg_pctl_w, areg_pctl_r,
    areg_stat_w, areg_stat_r,
    areg_cstat_w, areg_cstat_r,
    areg_fr1_w, areg_fr1_r,
    areg_fr2_w, areg_fr2_r,
    areg_hdr_w, areg_hdr_r,
    areg_sync_w, areg_sync_r: std_logic_vector(31 downto 0);

  signal noise_ctr_en, rxq_sw_ctl_i, dma_xfer_req_d, xfer_req_event, dma_wready_d, dma_wready_pulse: std_logic := '0';
  signal noise_ctr_go: std_logic := '0';
  signal noise_ctr_is0, noise_trig: std_logic:='0';
  signal noise_ctr: std_logic_vector(10 downto 0) := (others=>'0');
  signal dac_tx_in_adc: std_logic;

  signal adc_xfer_req_m: std_logic_vector(2 downto 0) := (others=>'0');
  signal adc_xfer_req, adc_xfer_req_d, dac_tx_pre, adc_dwr: std_logic := '0';
  signal save_go, save_go_d, save_go_pulse, adc_rst_d, adc_rst_pulse, adc_rst_axi: std_logic := '0';
  signal clr_ctrs, save_go_dma: std_logic;

  -- event counters for debug
  constant CTR_W: integer := 4;
  constant EVENTS_QTY: integer := 5;
  signal event_v, evclk_v: std_logic_vector(EVENTS_QTY-1 downto 0);
  type event_cnt_a_t is array(0 to EVENTS_QTY-1) of std_logic_vector(CTR_W-1 downto 0);  
  signal event_cnt_a: event_cnt_a_t;
  signal dma_wready_cnt, save_go_cnt, xfer_req_cnt,  adc_rst_cnt,
    dac_tx_cnt  : std_logic_vector(CTR_W-1 downto 0);
  

  signal osamp_min1: std_logic_vector(1 downto 0);
  signal corrstart, search, search_en: std_logic :='0';
  signal frame_pd_min1: std_logic_vector(G_FRAME_PD_CYCS_W-1 downto 0);
  signal num_pass_min1: std_logic_vector(G_PASS_W-1 downto 0);
  signal hdr_len_min1_cycs: std_logic_vector(G_HDR_LEN_W-1 downto 0);
  signal frame_qty_min1: std_logic_vector(G_FRAME_QTY_W-1 downto 0);
  signal hdr_pwr_thresh: std_logic_vector(14-1 downto 0);
  signal init_thresh_d16: std_logic_vector(7 downto 0);
  signal hdr_thresh: std_logic_vector(G_CORR_MAG_W-1 downto 0);
  signal samps_in: std_logic_vector(14*8-1 downto 0);
  signal hdr_subcyc: std_logic_vector(1 downto 0);
  signal save_after_pwr, hdr_pwr_det, dbg_hdr_det, dbg_framer_going,
    hdr_sync, hdr_found,
    hdr_sync_dlyd, corr_vld: std_logic;
  signal sync_dly_cycs: std_logic_vector(G_FRAME_PD_CYCS_W-1 downto 0);
  signal corr_out: std_logic_vector(G_CORR_MEM_D_W*4-1 downto 0);
  signal proc_dout: std_logic_vector(31 downto 0);
  signal proc_sel: std_logic_vector(3 downto 0);
  signal lfsr_rst_st: std_logic_vector(10 downto 0);
  signal alice_syncing, alice_txing, alice_txing_d, a_restart_search, dbg_hold,
    proc_clr_cnts: std_logic;
  signal wdata_aug: std_logic_vector(7 downto 0);
  signal adc_wdata_aug:std_logic_vector(ADC_DATA_WIDTH-1 downto 0);	

  signal axi_xfer_status_s: std_logic_vector(3 downto 0);
  signal adc_ddata_s, axi_ddata_s: std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
  signal adc_dwr_s, axi_rd_req_s, axi_drst_s, axi_dvalid_s, axi_dready_s: std_logic;
  signal axi_rd_addr_s: std_logic_vector(31 downto 0);
  
begin


  hdr_corr_inst: hdr_corr
    generic map(
      USE_CORR => 0,
      SAMP_W             => 14,
      FRAME_PD_CYCS_W    => G_FRAME_PD_CYCS_W, -- 24
      REDUCED_SAMP_W     => 8,
      HDR_LEN_CYCS_W     => G_HDR_LEN_W,
      MAX_SLICES         => G_MAX_SLICES,
      PASS_W             => G_PASS_W,
      FRAME_QTY_W        => G_FRAME_QTY_W, -- 16
      MEM_D_W            => G_CORR_MEM_D_W, -- width of corr vals in corr mem
      MAG_W              => G_CORR_MAG_W)
    port map(
      clk                => adc_clk,
      rst                => adc_rst,
      
      osamp_min1         => osamp_min1,
      corrstart_in       => corrstart,
      search             => search_en,
      search_restart     => a_restart_search,
      dbg_hold => dbg_hold,
      alice_syncing      => alice_syncing,
      alice_txing        => alice_txing,
      frame_pd_min1      => frame_pd_min1,
      num_pass_min1      => num_pass_min1,
      hdr_len_min1_cycs  => hdr_len_min1_cycs,
      frame_qty_min1     => frame_qty_min1,
      init_thresh_d16    => init_thresh_d16,
      hdr_pwr_thresh     => hdr_pwr_thresh,
      hdr_thresh         => hdr_thresh,
      lfsr_rst_st        => lfsr_rst_st,
      samps_in           => samps_in,
      hdr_pwr_det        => hdr_pwr_det,
      dbg_hdr_det        => dbg_hdr_det,
      dbg_framer_going   => dbg_framer_going,
      hdr_subcyc         => hdr_subcyc,
      hdr_sync           => hdr_sync,
      hdr_found_out      => hdr_found,
      sync_dly           => sync_dly_cycs, -- cycles it is delayed
      hdr_sync_dlyd      => hdr_sync_dlyd,
      corr_vld           => corr_vld,
      corr_out           => corr_out,

      -- below here is in proc clk domain		   
      proc_clk=> s_axi_aclk,
      proc_clr_cnts => proc_clr_cnts,
      proc_sel=> proc_sel,
      proc_dout=> proc_dout);

  
  axi_rst <= not s_axi_aresetn;

  gen_per_reg: for k in 0 to NUM_REGS-1 generate
  begin
    areg_w(k) <= areg_w_vec(31+k*32 downto k*32);
    areg_r_vec(31+k*32 downto k*32) <= areg_r(k);
  end generate gen_per_reg;

  
  ara: axi_reg_array
    generic map(
      NUM_REGS => NUM_REGS,
      A_W      => AXI_A_W)
    port map(
      axi_clk => s_axi_aclk,
      axi_rst => axi_rst,
      
      -- wr addr chan
      awaddr   => s_axi_awaddr,
      awvalid  => s_axi_awvalid,
      awready  => s_axi_awready,
      
      -- wr data chan
      wdata   => s_axi_wdata,
      wvalid  => s_axi_wvalid,
      wstrb   => s_axi_wstrb,
      wready  => s_axi_wready,
      
      -- wr rsp chan
      bresp  => s_axi_bresp,
      bvalid => s_axi_bvalid,
      bready => s_axi_bready,

      -- rd addr chan
      araddr  => s_axi_araddr,
      arvalid => s_axi_arvalid,
      arready => s_axi_arready,

      -- rd data rsp chan
      rdata => s_axi_rdata,
      rresp => s_axi_rresp,
      rvalid => s_axi_rvalid,
      rready => s_axi_rready,

      -- connect these to your main vhdl code
      reg_w_vec => areg_w_vec,
      reg_r_vec => areg_r_vec,
      -- use the following for register access "side effects"
      reg_w_pulse  => areg_w_pulse,
      reg_r_pulse  => areg_r_pulse);


--  areg_actl_w   <= areg_w(AREG_ACTL);
  areg_pctl_w   <= areg_w(AREG_PCTL);
  areg_stat_w   <= areg_w(AREG_STAT);
  areg_cstat_w  <= areg_w(AREG_CSTAT);
--  areg_fr1_w  <= areg_w(AREG_FR1);  
--  areg_fr2_w  <= areg_w(AREG_FR2);
--  areg_hdr2_w <= areg_w(AREG_HDR);
  
  areg_r(AREG_ACTL)   <= areg_actl_r;
  areg_r(AREG_PCTL)   <= areg_pctl_r;
  areg_r(AREG_STAT)   <= areg_stat_r;
  areg_r(AREG_CSTAT)  <= areg_cstat_r;
  areg_r(AREG_FR1)    <= areg_fr1_r;
  areg_r(AREG_FR2)    <= areg_fr2_r;
  areg_r(AREG_HDR)    <= areg_hdr_r;
  areg_r(AREG_SYNC)   <= areg_sync_r;

  -- pctl
  -- fields are kept in processor clock domain
  clr_ctrs      <= areg_pctl_w(0);
  proc_clr_cnts <= areg_pctl_w(8);
  areg_pctl_r <= areg_pctl_w;
  
  -- reg0 = actl
  -- entire reg transferred to adc_clk domain  
  areg_actl_samp: cdc_samp
    generic map(W =>32)
    port map(
      in_data  => areg_w(AREG_ACTL),
      out_data => areg_actl_w,
      out_clk  => adc_clk);
  areg_actl_r    <= areg_w(AREG_ACTL);
  meas_noise     <= areg_actl_w(1);
  txrx_en        <= areg_actl_w(2);
--  new_go_en     <= '1'; --'
  save_after_pwr <= areg_actl_w(3);
  osamp_min1     <= areg_actl_w(5 downto 4);
  search         <= areg_actl_w(6);
  corrstart      <= areg_actl_w(7);
  alice_txing    <= areg_actl_w(8);
  alice_syncing  <= areg_actl_w(9);
  dbg_hold       <= areg_actl_w(10);
  lfsr_rst_st    <= areg_actl_w(26 downto 16);

  -- reg1 <= stat   
  areg_stat_r(31 downto 28) <= (others=>'0');
  areg_stat_r(27 downto 24) <= fwver;
  areg_stat_r(23 downto 20) <= dac_tx_cnt;
  areg_stat_r(19 downto 16) <= adc_rst_cnt;
  areg_stat_r(15 downto 12) <= xfer_req_cnt;
  areg_stat_r(11 downto 8)  <= save_go_cnt;
  areg_stat_r(7 downto 4)   <= dma_wready_cnt;
  areg_stat_r(3 downto 2)   <= (others=>'0'); 
  areg_stat_r(1)            <= adc_rst_axi;
  areg_stat_r(0)            <= dma_xfer_req_rc; -- for dbg

  -- reg2 = hdr_corr stats
  proc_sel <= areg_cstat_w(3 downto 0);
  areg_cstat_r <= proc_dout;
   

  reg_fr1_samp: cdc_samp
    generic map(W =>32)
    port map(
      in_data  => areg_w(AREG_FR1),
      out_data => areg_fr1_w,
      out_clk  => adc_clk);
  areg_fr1_r <= areg_w(AREG_FR1);
  num_pass_min1 <= areg_fr1_w(29 downto 24);
  frame_pd_min1 <= areg_fr1_w(23 downto 0); -- in cycles

  reg_fr2_samp: cdc_samp
    generic map(W =>32)
    port map(
      in_data  => areg_w(AREG_FR2),
      out_data => areg_fr2_w,
      out_clk  => adc_clk);
  areg_fr2_r <= areg_w(AREG_FR2);
  frame_qty_min1    <= areg_fr2_w(31 downto 16);
  hdr_len_min1_cycs <= areg_fr2_w(7 downto 0);
 
  reg_hdr_samp: cdc_samp
    generic map(W =>32)
    port map(
      in_data  => areg_w(AREG_HDR),
      out_data => areg_hdr_w,
      out_clk  => adc_clk);
  areg_hdr_r <= areg_w(AREG_HDR);
  hdr_pwr_thresh <= areg_hdr_w(13 downto 0);
  hdr_thresh     <= areg_hdr_w(23 downto 14);

  -- sync = 6
  reg_sync_samp: cdc_samp
    generic map(W =>32)
    port map(
      in_data  => areg_w(AREG_SYNC),
      out_data => areg_sync_w,
      out_clk  => adc_clk);
  areg_sync_r <= areg_w(AREG_SYNC);
  sync_dly_cycs   <= areg_sync_w(23 downto 0);
  init_thresh_d16 <= areg_sync_w(31 downto 24);


   
      
      
 
    
  -- This sends a signal to DAC fifo every time ADC xfer starts ( or restarts)

  xfer_req_cross: cdc_sync_cross
    generic map (W=>1)
    port map(
      clk_in_bad  => adc_rst,
      clk_in      => adc_clk,
      d_in(0)     => dac_tx_pre,
      clk_out_bad => '0',
      clk_out     => dac_clk,
      d_out(0)    => dac_tx);
   
  dac_tx_in_cross: cdc_sync_cross
    generic map(W =>1)
    port map(
      clk_in_bad  => '0',
      clk_in      => dac_clk,
      d_in(0)     => dac_tx_in,
      clk_out_bad => adc_rst,
      clk_out     => adc_clk,
      d_out(0)    => dac_tx_in_adc);


  -- EVENT CTRS FOR DEBUG
  event_v(0) <= dma_wready_pulse;
  evclk_v(0) <= dma_clk;
  event_v(1) <= save_go_pulse;
  evclk_v(1) <= adc_clk;
  event_v(2) <= xfer_req_event;
  evclk_v(2) <= dma_clk;
  adc_rst_pulse <= adc_rst and not adc_rst_d;
  event_v(3) <= adc_rst_pulse;
  evclk_v(3) <= adc_clk;
  event_v(4) <= dac_tx_pre;
  evclk_v(4) <= adc_clk;
  gen_event_ctrs: for k in 0 to EVENTS_QTY-1 generate
  begin
    event_ctr_i: event_ctr
      generic map (W => 4)
      port map(
        clk   => evclk_v(k),
        event => event_v(k),
        rclk  => s_axi_aclk,
        clr   => clr_ctrs,
        cnt   => event_cnt_a(k));
  end generate gen_event_ctrs;
  dma_wready_cnt <= event_cnt_a(0);
  save_go_cnt    <= event_cnt_a(1);
  xfer_req_cnt   <= event_cnt_a(2);
  adc_rst_cnt    <= event_cnt_a(3);
  dac_tx_cnt     <= event_cnt_a(4);

  
  -- for dbg
  req_samp_aclk: cdc_samp
    generic map(W => 2)
    port map(
     in_data(0)  => dma_xfer_req_d,
     in_data(1)  => adc_rst,
     out_data(0) => dma_xfer_req_rc,
     out_data(1) => adc_rst_axi,
     out_clk     => s_axi_aclk);
   
--  always @(posedge s_axi_aclk) begin
--  end -- always @(posedge s_axi_aclk)


  req_samp_in_adc: cdc_samp
    generic map(W => 1)
    port map(
     in_data(0)  => dma_xfer_req,
     out_data(0) => dma_xfer_req_inadc,
     out_clk     => adc_clk);

  process(adc_clk)
  begin
    if (rising_edge(adc_clk)) then
      adc_rst_d <= adc_rst;
      dma_xfer_req_inadc_d <= dma_xfer_req_inadc; 
      adc_xfer_req_m(2)    <= dma_xfer_req_inadc;
      save_buf_avail <= txrx_en and (save_buf_avail or dma_xfer_req_inadc);
      if (alice_syncing='1') then
        -- This FPGA is Alice.
        -- alice has synced to Bob's headers and is now
        -- inserting her own header into the frame somewhere.
        -- Bob analyzes this to learn Alice's insertion latency
        -- so that sync_dly can be set properly.
        dac_tx_pre <= hdr_sync_dlyd;
      else -- "normal"
        -- alice wants to save iq samples.  DMA is ready to store them.
        -- Now request DAC to generate headers
        dac_tx_pre <= dma_xfer_req_inadc_d;
      end if;
      alice_txing_d <= alice_txing;
      a_restart_search <= alice_txing and not alice_txing_d;

      -- For now we begin hdr_corr search when software says.
      -- If saving to the host (txrx_en) we wait for the buffer to be avail.
      search_en <= search and (not txrx_en or save_buf_avail);
      
      -- We only save samples if txrx_en_adc is high.
      -- When dma req goes high, we signal the dac, and when it acks that,
      -- that is when we start taking samples.
      -- After that, dma request can go up and down, but we ignore it,
      -- and keep taking samples.  This is in case software can't keep up,
      -- in which case we keep cramming data into the DDR so we don't
      -- loose any consecutive data.
      --
--      save_go <= txrx_en and
--                 ( (dma_xfer_req_inadc_d and
--                    (search or dac_tx_in_adc))
--                  or save_go );
      
      save_go <= txrx_en and
                 (   (    dma_xfer_req_inadc_d
                      and u_if(save_after_pwr='1', hdr_pwr_det, dac_tx_in_adc))
                  or save_go );


      save_go_d <= save_go;
      save_go_pulse <= save_go and not save_go_d;
      
      noise_ctr_go <= meas_noise and save_go;
      if ((not noise_ctr_go or noise_ctr_is0)='1') then
        noise_ctr <= std_logic_vector(to_unsigned(6100/4-1, 11));
      else
        noise_ctr <= u_dec(noise_ctr);
      end if;
      noise_ctr_is0 <= u_b2b(unsigned(noise_ctr)=1);
      if (noise_ctr_go='0') then
        rxq_sw_ctl_i <= '0';
      elsif (noise_ctr_is0='1') then
        rxq_sw_ctl_i <= not rxq_sw_ctl_i;
      end if;
      adc_xfer_req   <= adc_xfer_req_m(2);
      adc_xfer_req_d <= adc_xfer_req;
    end if;     
  end process;

  rxq_sw_ctl <= rxq_sw_ctl_i;


   
   
  -- instantiations
  -- This widens the data from "adc" to "axi" width.
  -- operates continuously but maybe it should not.
  i_adc_if : axi_adcfifo_adc
    generic map(
      AXI_DATA_WIDTH => AXI_DATA_WIDTH,
      ADC_DATA_WIDTH => ADC_DATA_WIDTH)
    port map(
      adc_rst   => adc_rst,
      adc_clk   => adc_clk,
      adc_wr    => adc_wr,
      adc_wdata => adc_wdata_aug, -- adc data in
      adc_wovf  => adc_wovf,

      adc_dwr => adc_dwr, -- out
      adc_ddata => adc_ddata_s, -- axi data out
      axi_drst => axi_drst_s,
      axi_clk => axi_clk,
      axi_xfer_status => axi_xfer_status_s);

  -- This writes to DDR
  --   (contains a shallow buffer for efficient bursting)
  -- this does not change the data width
  -- 
  i_wr: axi_adcfifo_wr
    generic map(
      AXI_DATA_WIDTH => AXI_DATA_WIDTH,
      AXI_SIZE       => AXI_SIZE, -- should be called AWSIZE. value to drive on awsize
      AXI_LENGTH     => AXI_LENGTH, -- .. AWLEN. val to drive on axi_awlen.
      AXI_ADDRESS    => AXI_ADDRESS, -- starting addr in DDR.
      AXI_ADDRESS_LIMIT => AXI_ADDRESS_LIMIT)
    port map(
      dma_xfer_req => save_go, -- 0->1 resets the fifos
      
      axi_rd_req   => axi_rd_req_s,   -- pulses at end of each burst to ddr3
      axi_rd_addr  => axi_rd_addr_s, -- to transfer this
      adc_rst      => adc_rst,
      adc_clk      => adc_clk,
      adc_wr       => adc_dwr, -- in
      adc_wdata => adc_ddata_s, -- in
      axi_clk => axi_clk,
      axi_resetn => axi_resetn,
      axi_awvalid => axi_awvalid,
      axi_awid => axi_awid,
      axi_awburst => axi_awburst,
      axi_awlock => axi_awlock,
      axi_awcache => axi_awcache,
      axi_awprot => axi_awprot,
      axi_awqos => axi_awqos,
      axi_awuser => axi_awuser,
      axi_awlen => axi_awlen,
      axi_awsize => axi_awsize,
      axi_awaddr => axi_awaddr, -- out
      axi_awready => axi_awready,
      axi_wvalid => axi_wvalid,
      axi_wdata => axi_wdata,
      axi_wstrb => axi_wstrb,
      axi_wlast => axi_wlast,
      axi_wuser => axi_wuser,
      axi_wready => axi_wready,
      axi_bvalid => axi_bvalid,
      axi_bid => axi_bid,
      axi_bresp => axi_bresp,
      axi_buser => axi_buser,
      axi_bready => axi_bready,
      axi_dwovf => axi_xfer_status_s(0),
      axi_dwunf => axi_xfer_status_s(1),
      axi_werror => axi_xfer_status_s(2));

  -- this does not change the data width
  i_rd: axi_adcfifo_rd
    generic map(
      AXI_DATA_WIDTH => AXI_DATA_WIDTH,
      AXI_SIZE       => AXI_SIZE,
      AXI_LENGTH     => AXI_LENGTH,
      AXI_ADDRESS    => AXI_ADDRESS,
      AXI_ADDRESS_LIMIT => AXI_ADDRESS_LIMIT)
    port map(
      dma_xfer_req => save_go, -- must be held hi for read from ddr to continue
      axi_rd_req   => axi_rd_req_s,
      axi_rd_addr  => axi_rd_addr_s,
      axi_clk      => axi_clk,
      axi_resetn   => axi_resetn,
      axi_arvalid  => axi_arvalid,
      axi_arid => axi_arid,
      axi_arburst => axi_arburst,
      axi_arlock => axi_arlock,
      axi_arcache => axi_arcache,
      axi_arprot => axi_arprot,
      axi_arqos => axi_arqos,
      axi_aruser => axi_aruser,
      axi_arlen => axi_arlen,
      axi_arsize => axi_arsize,
      axi_araddr => axi_araddr,
      axi_arready => axi_arready,
      axi_rvalid => axi_rvalid,
      axi_rid => axi_rid,
      axi_ruser => axi_ruser,
      axi_rresp => axi_rresp,
      axi_rlast => axi_rlast,
      axi_rdata => axi_rdata,
      axi_rready => axi_rready,
      axi_rerror => axi_xfer_status_s(3),
      axi_drst => axi_drst_s,
      axi_dvalid => axi_dvalid_s,
      axi_ddata => axi_ddata_s,
      axi_dready => axi_dready_s);

  process(dma_clk)
  begin
    if (rising_edge(dma_clk)) then
      dma_xfer_req_d  <= dma_xfer_req;
      xfer_req_event <= dma_xfer_req and not dma_xfer_req_d;
      dma_wready_d <= dma_wready;
      dma_wready_pulse <= dma_wready and not dma_wready_d;
    end if;
  end process;
   
  cdc_samp_save_go: cdc_samp
    generic map(W=>1)
    port map(
      in_data(0)  => save_go,
      out_data(0) => save_go_dma,
      out_clk     => dma_clk);
  
  i_dma_if: axi_adcfifo_dma
    generic map (
      AXI_DATA_WIDTH => AXI_DATA_WIDTH,
      DMA_DATA_WIDTH => DMA_DATA_WIDTH,
      DMA_READY_ENABLE => DMA_READY_ENABLE)
    port map(
      axi_clk => axi_clk,
      axi_drst => axi_drst_s,
      axi_dvalid => axi_dvalid_s,
      axi_ddata => axi_ddata_s,
      axi_dready => axi_dready_s,
      axi_xfer_status => axi_xfer_status_s,
      dma_clk => dma_clk,
      dma_wr => dma_wr,
      dma_wdata => dma_wdata,
      dma_wready => dma_wready,
      dma_xfer_req => save_go_dma,
      dma_xfer_status => dma_xfer_status);

  wdata_aug(0) <= hdr_pwr_det;
  wdata_aug(1) <= dbg_hdr_det;
  wdata_aug(2) <= hdr_sync;
  wdata_aug(3) <= hdr_found;
  wdata_aug(4) <= hdr_sync_dlyd;
  wdata_aug(5) <= dbg_framer_going;
  wdata_aug(7 downto 5) <= (others=>'0');
  
  gen_arr: for i in 0 to 7 generate
  begin
    samps_in(i*14+13 downto i*14)<=adc_wdata(i*16+13 downto i*16);
    --augment adc_wdata with signals for dbg
    adc_wdata_aug(i*16+14 downto i*16) <= adc_wdata(i*16+14 downto i*16);
    adc_wdata_aug(i*16+15)      <= wdata_aug(i);
  end generate gen_arr;
   
   

  
end architecture rtl;

