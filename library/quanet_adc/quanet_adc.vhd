-- The way AD originally wrote their code,
-- 14-bit ADC samples were always padded out to 16 samples.
-- This makes it easy to view this in simulation, and
-- in some cases the pad drops out during optimizaion,
-- but not always.
--
-- I wrote this in the interest of efficiency, but I follow
-- this convention when multiple samples are together in one vector.
-- In my code, SAMP_W is 14.  Or smaller if we want to discard bits.
-- And the sample plus pad is a "word", where WORD_W is 16.
--
-- VHDL provides the concept of arrays of vectors,
-- which verilog lacks.  My code frequently converts between
-- the two, because I think things are more clear when
-- using vectors.


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
      DMA_DATA_WIDTH   : integer :=  64; -- or is it 128
      AXI_DATA_WIDTH   : integer := 512; -- the AXI to the DDR that is.
      DMA_READY_ENABLE : integer :=   1;
      AXI_LENGTH       : integer :=   4; -- actually the burst len
      AXI_A_W          : integer :=   8;
      AXI_ADDRESS_SIZE : integer := 536870912);
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
      tx_commence         : out std_logic; -- once hi, stays hi till tear-down
      frame_sync_o        : out std_logic;
      dac_tx_in           : in  std_logic; -- dac is ready
      sfp_rxclk_in        : in  std_logic; -- dac is ready
      sfp_rxclk_vld       : in  std_logic; -- dac is ready
      
      cipher_en_in        : in  std_logic;
      cipher_in           : in  std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
      cipher_in_vld       : in  std_logic;
      dbg_clk_sel_o       : out std_logic;
      
      -- fifo interface
      -- MAIN DATA FLOW INPUT
      adc_rst             : in  std_logic; -- only seems to happen once
      adc_clk             : in  std_logic;
      adc_wr              : in  std_logic;
      adc_wdata           : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      adc_wovf            : out std_logic;

      -- dma interface -- samples to PS
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
--     AXI_SIZE : integer :=  2;
     AXI_LENGTH : integer := 4;-- actually the burst length
     AXI_A_W: integer := 8;
     AXI_ADDRESS_SIZE : integer := 536870912);
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
    tx_commence         : out std_logic;
    frame_sync_o        : out std_logic;
    dac_tx_in           : in  std_logic; -- dac txes first frame
    sfp_rxclk_in        : in  std_logic; -- dac is ready
    sfp_rxclk_vld       : in  std_logic; -- dac is ready
    cipher_en_in        : in  std_logic;
    cipher_in           : in std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
    cipher_in_vld       : in std_logic;
    dbg_clk_sel_o       : out std_logic;
    
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
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
use work.rebalancer_quad_pkg.ALL;
use work.duration_ctr_pkg.ALL;
use work.rotate_iq_pkg.ALL;
use work.synchronizer_pkg.ALL;
use work.decipher_pkg.ALL;
use work.axi_reg_array_pkg.ALL;
use work.cdc_samp_pkg.ALL;
use work.cdc_thru_pkg.ALL;
use work.cdc_sync_cross_pkg.ALL;
use work.cdc_pulse_pkg.ALL;
use work.hdr_corr_pkg.ALL;
use work.event_ctr_pkg.ALL;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
use work.lfsr_w_pkg.all;
use work.fifo_2clks_infer_pkg.all;

architecture rtl of quanet_adc is

  -- This used to be a parameter to axi_adcfifo.
  -- But it was redundant with AXI_DATA_WIDTH.
  -- So now we calculate it here.
  -- Must be log2(axi_data_width/8).
  constant  AXI_SIZE : integer := u_bitwid(AXI_DATA_WIDTH/8-1);

  constant FWVER_CONST: std_logic_vector(3 downto 0) :=
    std_logic_vector(to_unsigned(G_FWVER, 4));
  signal fwver: std_logic_vector(3 downto 0) := FWVER_CONST;


  constant AREG_ACTL:  integer := 0;
  constant AREG_STAT:  integer := 1;
  constant AREG_CSTAT: integer := 2;
  constant AREG_FR1:   integer := 3;
  constant AREG_FR2:   integer := 4;
  constant AREG_HDR:   integer := 5;
  constant AREG_SYNC:  integer := 6;
  constant AREG_PCTL:  integer := 7;
  constant AREG_CTL2:   integer := 8;
  constant AREG_REBALM: integer := 9;
  constant AREG_CIPHER: integer := 10;
  constant AREG_REBALO: integer := 11;
  constant AREG_DBG:   integer := 12;
  constant AREG_CIPHER2: integer := 13;
  
  constant NUM_REGS: integer := 14;
  
  signal areg_r_vec, areg_w_vec: std_logic_vector(NUM_REGS*32-1 downto 0);
  type reg_array_t is array(0 to NUM_REGS-1) of std_logic_vector(31 downto 0);
  signal areg_r, areg_w, areg_w_adc: reg_array_t;
  signal areg_w_pulse, areg_r_pulse: std_logic_vector(NUM_REGS-1 downto 0);


  -- it is awkward to express x80000000 as an integer.  I'd rather use
  -- std_logic_vector.  But that doesn't pass to verilog.
  constant  AXI_ADDRESS       : integer := (-2**30)*2; -- std_logic_vector(31 downto 0) := x"80000000";  -- start addr in DDR

--  constant  AXI_ADDRESS_SIZE : integer := 2**28;
  constant  AXI_ADDRESS_LIMIT : integer := AXI_ADDRESS + (AXI_ADDRESS_SIZE - 1); -- std_logic_vector(31 downto 0) := x"8fffffff");
--  constant  AXI_ADDRESS_LIMIT : integer := AXI_ADDRESS + (2**10 - 1); -- std_logic_vector(31 downto 0) := x"8fffffff");  

  component axi_adcfifo_adc
    generic (
      ADC_DATA_WIDTH : integer;
      AXI_DATA_WIDTH : integer);
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
      AXI_DATA_WIDTH: integer;
      DMA_DATA_WIDTH: integer;
      DMA_READY_ENABLE: integer);
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


  component phase_est is
    generic (
      MAG_W: integer;
      TRIG_W: integer);
    port(
      clk           : in std_logic;
      en            : in std_logic;
      hdr_vld       : in std_logic;
      hdr_i         : in std_logic_vector(MAG_W-1 downto 0);
      hdr_q         : in std_logic_vector(MAG_W-1 downto 0);
      hdr_mag       : in std_logic_vector(MAG_W-1 downto 0);
      ph_cos : out std_logic_vector(TRIG_W-1 downto 0);
      ph_sin : out std_logic_vector(TRIG_W-1 downto 0));
  end component;    
  
  signal meas_noise, meas_noise_adc, dma_xfer_req_rc, dma_xfer_req_inadc, dma_xfer_req_inadc_d, s_axi_rst, axi_rst,
    save_buf_avail, save_buf_avail_aclk, txrx_en: std_logic := '0';
  signal
    areg_actl_w, areg_actl_r,
    areg_pctl_w, areg_pctl_r,
    areg_stat_w, areg_stat_r,
    areg_cstat_w, areg_cstat_r,
    areg_fr1_w, areg_fr1_r,
    areg_fr2_w, areg_fr2_r,
    areg_hdr_w, areg_hdr_r,
    areg_dbg_w, areg_dbg_r,
    areg_ctl2_w, areg_ctl2_r,
    areg_rebalm_w, areg_rebalm_r,
    areg_rebalo_w, areg_rebalo_r,
    areg_cipher_w, areg_cipher_r,
    areg_cipher2_w, areg_cipher2_r,
    areg_sync_w, areg_sync_r: std_logic_vector(31 downto 0);

  signal noise_ctr_en, rxq_sw_ctl_i, dma_xfer_req_d, xfer_req_event, dma_wready_d, dma_wready_pulse: std_logic := '0';
  signal noise_ctr_go: std_logic := '0';
  signal noise_ctr_is0, noise_trig: std_logic:='0';
  signal noise_ctr: std_logic_vector(10 downto 0) := (others=>'0');
  signal dac_tx_in_adc: std_logic;

  signal adc_xfer_req_m: std_logic_vector(2 downto 0) := (others=>'0');
  signal adc_xfer_req, adc_xfer_req_d, adc_dwr: std_logic := '0';
  signal save_go, save_go_d, save_go_pulse, adc_rst_d, adc_rst_pulse, adc_rst_axi: std_logic := '0';
  signal clr_ctrs, save_go_dma: std_logic;

  -- event counters for debug
  constant CTR_W: integer := 4;
  constant EVENTS_QTY: integer := 5;
  signal event_v, evclk_v: std_logic_vector(EVENTS_QTY-1 downto 0);
  type event_cnt_a_t is array(0 to EVENTS_QTY-1) of std_logic_vector(CTR_W-1 downto 0);  
  signal event_cnt_a: event_cnt_a_t;
  signal dma_wready_cnt, save_go_cnt, xfer_req_cnt,  adc_rst_cnt: std_logic_vector(CTR_W-1 downto 0);
  

  signal osamp_min1: std_logic_vector(1 downto 0);
  signal corrstart, search, search_en, sfp_rxclk_vld_adc,
    sav_data_wr, sfp_rclk_vld,
    sfp_rxclk_vld_rc: std_logic :='0';

  signal ext_frame_pd_min1_cycs: std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
  signal ext_frame_ctr: std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0) := (others=>'0');
  
  signal frame_pd_min1, ref_frame_ctr, ref_frame_dur, ref_frame_dur_pre: std_logic_vector(G_FRAME_PD_CYCS_W-1 downto 0);
  signal num_pass_min1: std_logic_vector(G_PASS_W-1 downto 0);
  signal hdr_len_min1_cycs: std_logic_vector(G_HDR_LEN_W-1 downto 0);
  signal frame_qty_min1: std_logic_vector(G_FRAME_QTY_W-1 downto 0);
  signal hdr_pwr_thresh: std_logic_vector(14-1 downto 0);
  signal init_thresh_d16: std_logic_vector(7 downto 0);
  signal hdr_thresh: std_logic_vector(G_CORR_MAG_W-1 downto 0);

  signal sync_ref_sel: std_logic_vector(1 downto 0);
  
  signal samps_in_i, samps_in_q: g_adc_samp_array_t;
  signal samps_derot_i, samps_derot_q: g_adc_samp_array_t;
  signal samps_deciph_i, samps_deciph_q: g_adc_samp_array_t;
  signal samps_balanced_i, samps_balanced_q: g_adc_samp_array_t;
  
  signal hdr_subcyc: std_logic_vector(1 downto 0);
  signal save_after_init, save_after_pwr, save_after_hdr,
    pwr_event_iso, saw_pwr_event, deciph_vld,
    hdr_det, saw_hdr_det, rxbuf_exists,
    ext_frame_ref,
    sync_lock, saw_sync_ool, clr_saw_sync_ool,
    hdr_pwr_det, dbg_met_init, dbg_framer_going,
    hdr_sync, hdr_found, frame_sync,
    hdr_sync_dlyd, corr_vld: std_logic := '0';
  signal hdr_i, hdr_q, hdr_mag: std_logic_vector(G_CORR_MAG_W-1 downto 0);
  constant TRIG_W: integer := 9;
  signal ph_cos, ph_sin: std_logic_vector(TRIG_W-1 downto 0);
  signal ext_frame_atlim: std_logic := '1';
--  signal sync_dly_cycs: std_logic_vector(G_FRAME_PD_CYCS_W-1 downto 0);
  signal corr_out: std_logic_vector(G_CORR_MEM_D_W*4-1 downto 0);
  signal proc_dout: std_logic_vector(31 downto 0);
  signal proc_sel: std_logic_vector(3 downto 0);
  signal lfsr_rst_st: std_logic_vector(10 downto 0);
  signal alice_syncing, alice_txing, alice_txing_d, a_restart_search, dbg_hold,
    phase_est_en, resync, resync_i,
    proc_clr_cnts, sync_ref, corr_out_tog, corr_out_w_vld: std_logic := '0';
  signal wdata_aug: std_logic_vector(7 downto 0);
  signal corr_out_w, sav_data, adc_wdata_aug: std_logic_vector(ADC_DATA_WIDTH-1 downto 0);	

  signal axi_xfer_status_s: std_logic_vector(3 downto 0);
  signal adc_ddata_s, axi_ddata_s: std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
  signal adc_dwr_s, axi_rd_req_s, axi_drst_s, axi_dvalid_s, axi_dready_s: std_logic;
  signal axi_rd_addr_s: std_logic_vector(31 downto 0);

  signal i_offset, q_offset: std_logic_vector(5 downto 0);
  signal m11, m21, m12, m22: std_logic_vector(7 downto 0);

  constant CIPHER_LOG2M_MAX: integer := 2; -- (for now).
  constant CIPHER_LOG2M_W: integer := 2; -- (for now).
  signal decipher_rst, decipher_en, cipher_en, cipher_en_d, decipher_go_pre, decipher_go, cipher_fifo_mt, cipher_fifo_full,
    decipher_pre, decipher_pre_d, decipher_prime, decipher_going, cipher_lfsr_rst,
    cipher_fifo_rd: std_logic := '0';
  signal cipher_dly_min1_cycs: std_logic_vector(G_FRAME_PD_CYCS_W-1 downto 0);
  signal cipher_dly_asamps: std_logic_vector(1 downto 0);
  signal cipher_log2m: std_logic_vector(CIPHER_LOG2M_W-1 downto 0);
  signal cipher_symlen_min1_asamps: std_logic_vector(G_CIPHER_SYMLEN_W-1 downto 0);
  signal cipher_body_len_min1_cycs: std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
  signal data_len_min1_cycs: std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
  signal cipher_rst_st: std_logic_vector(G_CIPHER_LFSR_W-1 downto 0) := G_CIPHER_RST_STATE;
  signal cipher, cipher_lfsr_data: std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
  
  signal tx_go_cond: std_logic_vector(1 downto 0);
  signal syncro_errsum: std_logic_vector(15 downto 0);
  signal syncro_errsum_ovf: std_logic;
  signal syncro_qty: std_logic_vector(4 downto 0);
  signal dbg_clk_sel: std_logic;
  

begin

  -- The way AD originally wrote their code,
  -- 14-bit ADC samples were always padded out to 16 samples.
  -- This makes it easy to view this in simulation, and
  -- in some cases the pad might drop the pad during optimizaion,
  -- but I think not always.
  --
  -- I wrote this in the interest of efficiency, but I follow
  -- this convention when multiple samples are together in one vector.
  -- In my code, SAMP_W is 14.  Or smaller if we want to discard bits.
  -- And the sample plus pad is a "word", where WORD_W is 16.


  gen_din: for k in 0 to 3 generate
  begin
    samps_in_i(k) <= adc_wdata(k*32+13 downto k*32);
    samps_in_q(k) <= adc_wdata(k*32+16+13 downto k*32+16);
  end generate gen_din;
  
  
  -- Our ADC might be able to do this,
  -- but just in case, we can do it here
  rebal_i: rebalancer_quad
    generic map(
      OFF_W    => 6,
      MULT_W   => 8)
    port map(
      clk => adc_clk,
      in_i => samps_in_i,
      in_q => samps_in_q,
      i_offset => i_offset,
      q_offset => q_offset,
      m11 => m11,
      m21 => m21,
      m12 => m12,
      m22 => m22,
      out_i => samps_balanced_i,
      out_q => samps_balanced_q);

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
      dbg_hold           => dbg_hold,
--      alice_syncing      => alice_syncing,
      alice_txing        => alice_txing,
      frame_pd_min1      => frame_pd_min1,
      num_pass_min1      => num_pass_min1,
      hdr_len_min1_cycs  => hdr_len_min1_cycs,
      frame_qty_min1     => frame_qty_min1,
      init_thresh_d16    => init_thresh_d16,
      hdr_pwr_thresh     => hdr_pwr_thresh,
      hdr_thresh         => hdr_thresh,
      lfsr_rst_st        => lfsr_rst_st,
      samps_in_i         => samps_balanced_i,
      samps_in_q         => samps_balanced_q,
      dbg_pwr_event_iso  => pwr_event_iso,
      hdr_pwr_det        => hdr_pwr_det,
      met_init_o         => dbg_met_init,
      
      hdr_det_o          => hdr_det,
      hdr_i_o            => hdr_i, -- goes to phase est
      hdr_q_o            => hdr_q, -- goes to phase est
      hdr_mag_o          => hdr_mag,
      
      dbg_framer_going   => dbg_framer_going,
      hdr_subcyc         => hdr_subcyc,
      hdr_sync           => hdr_sync,
      hdr_found_out      => hdr_found,
--      sync_dly           => sync_dly_cycs, -- cycles it is delayed
--      hdr_sync_dlyd      => hdr_sync_dlyd,

      
      corr_vld           => corr_vld,
      corr_out           => corr_out,

      -- below here is in proc clk domain		   
      proc_clk=> s_axi_aclk,
      proc_clr_cnts => proc_clr_cnts,
      proc_sel=> proc_sel,
      proc_dout=> proc_dout);

  gen_ph_est: if (G_OPT_GEN_PH_EST>0) generate
  begin
    
    phase_est_i: phase_est
      generic map (
        MAG_W  => G_CORR_MAG_W,
        TRIG_W => TRIG_W)
      port map(
        clk     => adc_clk,
        en      => phase_est_en,
        hdr_vld => hdr_det,
        hdr_i   => hdr_i,
        hdr_q   => hdr_q,
        hdr_mag => hdr_mag,
        ph_cos  => ph_cos,
        ph_sin  => ph_sin);

    rotate_i1_i: rotate_iq
      generic map(
        WORD_W => 14,
        TRIG_W => TRIG_W)
      port map(
        clk    => adc_clk,
        din_i  => samps_balanced_i,
        din_q  => samps_balanced_q,
        ph_cos => ph_cos,
        ph_sin => ph_sin,
        dout_i => samps_derot_i,
        dout_q => samps_derot_q);
    
  end generate gen_ph_est;
  gen_no_ph_est: if (G_OPT_GEN_PH_EST<=0) generate
    samps_derot_i <= samps_balanced_i;
    samps_derot_q <= samps_balanced_q;
  end generate gen_no_ph_est;

  gen_any_decipher: if ((G_OPT_GEN_DECIPHER_LFSR>0) or (G_OPT_GEN_CIPHER_FIFO>0)) generate

   decipher_go_pre <= decipher_en and dac_tx_in_adc;
   decipher_dly_ctr: duration_ctr
     generic map(
       LEN_W => G_FRAME_PD_CYCS_W)
     port map(
       clk      => adc_clk,
       rst      => decipher_rst,
       go_pul   => decipher_go_pre,
       len_min1 => cipher_dly_min1_cycs,
       sig_last => decipher_go);

    decipher_i: decipher
      generic map(
        M_MAX     => 4,
        LOG2M_MAX => 2,
        LOG2M_W   => CIPHER_LOG2M_W,
        SYMLEN_W  => G_CIPHER_SYMLEN_W,
        FRAME_PD_W => G_QSDC_FRAME_CYCS_W,
        CIPHER_W   => G_CIPHER_FIFO_D_W)
      port map(
        clk    => adc_clk,
        prime  => decipher_prime,
        go     => decipher_go,
        en     => decipher_going,
        frame_pd_cycs_min1 => frame_pd_min1(G_QSDC_FRAME_CYCS_W-1 downto 0),
        ii     => samps_derot_i,
        iq     => samps_derot_q,
        dly_asamps => cipher_dly_asamps,
        symlen_min1_asamps => cipher_symlen_min1_asamps,
        body_len_min1_cycs => cipher_body_len_min1_cycs,
        log2m  => cipher_log2m, -- the modulation used
        cipher_rd => cipher_fifo_rd,
        cipher => cipher,
        o_vld  => deciph_vld,
        oi     => samps_deciph_i,
        oq     => samps_deciph_q);
   
    process(adc_clk)
    begin
      if (rising_edge(adc_clk)) then
        -- goes high the first time cipher fifo has something in it
        cipher_en_d <= cipher_en;
--        decipher_pre <= not cipher_rst and (not cipher_fifo_mt or decipher_pre);
--        decipher_pre_d <= decipher_pre;
        
        decipher_going <= (decipher_go or decipher_going)
                            and not decipher_rst;
      end if;
    end process;
   
    decipher_rst   <= not cipher_en;
    decipher_prime <= cipher_en and not cipher_en_d;

  end generate gen_any_decipher;
  
  gen_cipher_lfsr: if (G_OPT_GEN_DECIPHER_LFSR>0) generate
    -- we use a pure LFSR, so we re-create the pseudo-random sequence
    -- instead of queuing random values from Bob's TX side to his RX side.
    -- So we don't have to use any BRAMs.
    cipher_lfsr_rst <= decipher_prime;
    cipher_lfsr: lfsr_w
      generic map(
--      W  => 4*CIPHER_LOG2M_MAX,  -- or LCM of all possible log2m's.  Or add bitshift after
        W  => G_CIPHER_FIFO_D_W,
        CP => G_CIPHER_CHAR_POLY)
      port map(
        en  => cipher_fifo_rd,
      
        d_i => (others=>'0'),
        ld  => '0',

        rst_st    => cipher_rst_st,
        rst       => cipher_lfsr_rst,
--        state_nxt => cipher_lfsr_state_nxt,

        d_o       => cipher_lfsr_data,
      
        clk       => adc_clk);
    -- we want "first" bit to be lsb.
    cipher <= u_flip(cipher_lfsr_data);
    
  end generate gen_cipher_lfsr;
  
  gen_cipher_fifo: if (G_OPT_GEN_CIPHER_FIFO>0) generate
    -- Bob's using a "true" random number generator (TRNG), or perhaps seeding an LFSR
    -- or counting-mode cipher such as AES from a TRNG or /dev/random.  As his
    -- transmit side generates this, it enques these values in this "cipher fifo".
    -- After a fixed delay, Bob's recieve side starts to dequeue these values.
    cipher_fifo: fifo_2clks_infer
      generic map(
        A_W  => G_CIPHER_FIFO_A_W,
        D_W  => G_CIPHER_FIFO_D_W,
        HAS_FIRST_WORD_FALLTHRU => true)
      port map(
        rst   => decipher_rst, -- overrides everyting.  ANY clk domain
        
        wclk  => dac_clk,
        din   => cipher_in,
        wr_en => cipher_in_vld,
        full  => cipher_fifo_full,

        rclk   => adc_clk,
        rd_en  => cipher_fifo_rd,
        dout   => cipher,
        mt     => cipher_fifo_mt); -- 1 during rst
  end generate gen_cipher_fifo;
  
  gen_no_decipher: if ((G_OPT_GEN_DECIPHER_LFSR<=0) and (G_OPT_GEN_CIPHER_FIFO<=0)) generate
    samps_deciph_i <= samps_derot_i;
    samps_deciph_q <= samps_derot_q;
  end generate gen_no_decipher;


  
  axi_rst <= not s_axi_aresetn;

  gen_per_reg: for k in 0 to NUM_REGS-1 generate
  begin
    areg_w(k) <= areg_w_vec(31+k*32 downto k*32);
    areg_r_vec(31+k*32 downto k*32) <= areg_r(k);

    -- If a register drives signals in the adc_clk domain,
    -- we use the areg_w_adc array instead of areg_w:
    areg_w_samp: cdc_samp
      generic map(W =>32)
      port map(
        in_data  => areg_w(k),
        out_data => areg_w_adc(k),
        out_clk  => adc_clk);
    
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
--  areg_stat_w   <= areg_w(AREG_STAT);
--  areg_fr1_w  <= areg_w(AREG_FR1);  
--  areg_fr2_w  <= areg_w(AREG_FR2);
--  areg_hdr2_w <= areg_w(AREG_HDR);
  
  
  areg_r(AREG_ACTL)   <= areg_actl_r;
  areg_r(AREG_PCTL)   <= areg_pctl_r;
  areg_r(AREG_CTL2)   <= areg_ctl2_r;
  areg_r(AREG_STAT)   <= areg_stat_r;
  areg_r(AREG_CSTAT)  <= areg_cstat_r;
  areg_r(AREG_FR1)    <= areg_fr1_r;
  areg_r(AREG_FR2)    <= areg_fr2_r;
  areg_r(AREG_HDR)    <= areg_hdr_r;
  areg_r(AREG_SYNC)   <= areg_sync_r;
  areg_r(AREG_REBALM) <= areg_rebalm_r;
  areg_r(AREG_REBALO) <= areg_rebalo_r;
  areg_r(AREG_CIPHER) <= areg_cipher_r;
  areg_r(AREG_CIPHER2) <= areg_cipher_r;
  areg_r(AREG_DBG)    <= areg_dbg_r;

  -- pctl
  -- fields are kept in processor clock domain
  clr_ctrs         <= areg_pctl_w(0);
  clr_saw_sync_ool <= areg_pctl_w(1);
  proc_clr_cnts    <= areg_pctl_w(8);
  areg_pctl_r <= areg_pctl_w;
  
  -- reg actl
  areg_actl_w <= areg_w_adc(AREG_ACTL);
  areg_actl_r    <= areg_w(AREG_ACTL);
  meas_noise     <= areg_actl_w(1);
  txrx_en        <= areg_actl_w(2);
  save_after_pwr <= areg_actl_w(3);
  osamp_min1     <= areg_actl_w(5 downto 4);
  search         <= areg_actl_w(6);
  corrstart      <= areg_actl_w(7); -- starts full CDC correlation
  alice_txing    <= areg_actl_w(8);
--  alice_syncing  <= areg_actl_w(9);
  save_after_init <= areg_actl_w(11);
  lfsr_rst_st     <= areg_actl_w(22 downto 12);
  phase_est_en    <= areg_actl_w(23);
  resync          <= areg_actl_w(24);
  decipher_en     <= areg_actl_w(25);

  -- reg stat
  areg_stat_r(31 downto 30) <= (others=>'0');
  areg_stat_r(29) <= saw_sync_ool;
  areg_stat_r(28) <= sync_lock;
  areg_stat_r(27 downto 24) <= fwver;
--  areg_stat_r(23 downto 20) <= dac_tx_cnt;
  areg_stat_r(20)           <= sfp_rclk_vld;
  areg_stat_r(19 downto 16) <= adc_rst_cnt;
  areg_stat_r(15 downto 12) <= xfer_req_cnt;
  areg_stat_r(11 downto 8)  <= save_go_cnt;
  areg_stat_r(7 downto 4)   <= dma_wready_cnt;
  areg_stat_r(3 downto 2)   <= (others=>'0'); 
  areg_stat_r(1)            <= adc_rst_axi;
  areg_stat_r(0)            <= dma_xfer_req_rc; -- for dbg

  -- reg2 = hdr_corr stats
  areg_cstat_w  <= areg_w(AREG_CSTAT);
  proc_sel     <= areg_cstat_w(3 downto 0);
  areg_cstat_r <= proc_dout;
   
  -- reg fr1
  areg_fr1_w <= areg_w_adc(AREG_FR1);
  areg_fr1_r <= areg_w(AREG_FR1);
  num_pass_min1 <= areg_fr1_w(29 downto 24);
  frame_pd_min1 <= areg_fr1_w(23 downto 0); -- in cycles

  -- reg fr2
  areg_fr2_w <= areg_w_adc(AREG_FR2);
  areg_fr2_r <= areg_w(AREG_FR2);
  frame_qty_min1    <= areg_fr2_w(31 downto 16);
  hdr_len_min1_cycs <= areg_fr2_w(7 downto 0);

  -- reg hdr
  areg_hdr_w <= areg_w_adc(AREG_HDR);
  areg_hdr_r <= areg_w(AREG_HDR);
  sync_ref_sel   <= areg_hdr_w(25 downto 24); -- one of G_SYNC_REF_*
  hdr_thresh     <= areg_hdr_w(23 downto 14);
  hdr_pwr_thresh <= areg_hdr_w(13 downto 0);

  -- reg sync
  areg_sync_w <= areg_w_adc(AREG_SYNC);
  areg_sync_r(31 downto 22) <= areg_w(AREG_SYNC)(31 downto 22);
  init_thresh_d16 <= areg_sync_w(31 downto 24);
  areg_sync_r(21 downto 17) <= syncro_qty;
  areg_sync_r(16)          <= syncro_errsum_ovf;
  areg_sync_r(15 downto 0) <= syncro_errsum;
    
  -- reg rebalm (rebalance matrix)
  areg_rebalm_r <= areg_w(AREG_REBALM);
  areg_rebalm_w <= areg_w_adc(AREG_REBALM);
  m11 <= areg_rebalm_w(31 downto 24); -- fixed precision
  m21 <= areg_rebalm_w(23 downto 16); -- dec point after 2nd bit
  m12 <= areg_rebalm_w(15 downto  8);
  m22 <= areg_rebalm_w( 7 downto  0);

  -- reg rebalo (rebalance offsets)
  areg_rebalo_r <= areg_w(AREG_REBALO);
  areg_rebalo_w <= areg_w_adc(AREG_REBALO);
  i_offset      <= areg_rebalo_w( 5 downto 0);
  q_offset      <= areg_rebalo_w(11 downto 6);

  -- reg cipher
  areg_cipher_r <= areg_w(AREG_CIPHER);
  areg_cipher_w <= areg_w_adc(AREG_CIPHER);
--  cipher_en                 <= areg_cipher_w(0);
  cipher_log2m              <= areg_cipher_w(2 downto 1);
  cipher_symlen_min1_asamps <= areg_cipher_w(8 downto 3);
  cipher_body_len_min1_cycs <= areg_cipher_w(G_QSDC_FRAME_CYCS_W+12 downto 13); -- 22:13
                            

  areg_cipher2_r <= areg_w(AREG_CIPHER2);
  areg_cipher2_w <= areg_w_adc(AREG_CIPHER2);
  cipher_dly_min1_cycs <= areg_cipher2_w(G_FRAME_PD_CYCS_W-1 downto 0); -- 23:0
  cipher_dly_asamps    <= areg_cipher2_w(31 downto 30);
  

  -- reg ctl2
  areg_ctl2_r <= areg_w(AREG_CTL2);
  areg_ctl2_w <= areg_w_adc(AREG_CTL2);
  data_len_min1_cycs       <= areg_ctl2_w(9 downto 0);
  tx_go_cond               <= areg_ctl2_w(11 downto 10);
  ext_frame_pd_min1_cycs   <= areg_ctl2_w(21 downto 12);
  
  -- reg dbg
  areg_dbg_w <= areg_w_adc(AREG_DBG);
  areg_dbg_r(31 downto 25) <= areg_w(AREG_DBG)(31 downto 25);
  areg_dbg_r(24)           <= save_buf_avail_aclk;
  areg_dbg_r(23 downto 0)  <= ref_frame_dur;
  save_after_hdr <= areg_dbg_w(31);
  dbg_hold       <= areg_dbg_w(30);
  dbg_clk_sel    <= areg_dbg_w(29);


  dbg_clk_sel_thru: cdc_thru
    generic map( W=>1)
    port map(
      in_data(0)  => dbg_clk_sel,
      out_data(0) => dbg_clk_sel_o);
  
    
  -- This sends a signal to DAC fifo every time ADC xfer starts ( or restarts)

  frame_sync_o_cross: cdc_sync_cross
    generic map (W=>1)
    port map(
      clk_in_bad  => adc_rst,
      clk_in      => adc_clk,
      d_in(0)     => frame_sync,
      clk_out_bad => '0',
      clk_out     => dac_clk,
      d_out(0)    => frame_sync_o);
   
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
--  event_v(4) <= dac_tx_pre;
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
--  dac_tx_cnt     <= event_cnt_a(4);

  
  -- for dbg
  req_samp_aclk: cdc_samp
    generic map(W => 3)
    port map(
     in_data(0)  => dma_xfer_req_d,
     in_data(1)  => adc_rst,
     in_data(2)  => save_buf_avail,
     out_data(0) => dma_xfer_req_rc,
     out_data(1) => adc_rst_axi,
     out_data(2) => save_buf_avail_aclk,
     out_clk     => s_axi_aclk);

  ref_frame_dur_samp: cdc_samp
    generic map(W => G_FRAME_PD_CYCS_W)
    port map(
     in_data  => ref_frame_dur_pre,
     out_data => ref_frame_dur,
     out_clk  => s_axi_aclk);

  req_samp_in_adc: cdc_samp
    generic map(W => 2)
    port map(
     in_data(0)  => dma_xfer_req,
     in_data(1)  => cipher_en_in, -- adc clk domain
     out_data(0) => dma_xfer_req_inadc,
     out_data(1) => cipher_en,
     out_clk     => adc_clk);


  process(sfp_rxclk_vld, sfp_rxclk_in)
  begin
    if (sfp_rxclk_vld='0') then
      sfp_rxclk_vld_rc <= '0';
    elsif (rising_edge(sfp_rxclk_in)) then
      sfp_rxclk_vld_rc <= sfp_rxclk_vld;
    end if;
  end process;

  rxclk_vld_samp: cdc_samp
      generic map(W =>1)
      port map(
        in_data(0)  => sfp_rxclk_vld_rc,
        out_data(0) => sfp_rxclk_vld_adc,
        out_clk  => adc_clk);
  rclk_vld_samp: cdc_samp
      generic map(W =>1)
      port map(
        in_data(0)  => sfp_rxclk_vld_adc,
        out_data(0) => sfp_rclk_vld,
        out_clk     => s_axi_aclk);
  
  -- receive clock from GTH (ultimately from Corundum)
  -- rxclk is 30.833MHz.
  process(sfp_rxclk_in)
  begin
    if (rising_edge(sfp_rxclk_in)) then
      if ((ext_frame_atlim or not sfp_rxclk_vld_rc)='1') then
        ext_frame_ctr   <= ext_frame_pd_min1_cycs;
        ext_frame_atlim <= u_b2b(unsigned(ext_frame_pd_min1_cycs)=0);
      else
        ext_frame_ctr   <= u_dec(ext_frame_ctr);
        ext_frame_atlim <= u_b2b(unsigned(ext_frame_ctr)=1);
      end if;
    end if;
  end process;

  ext_frame_pulser: cdc_pulse
    port map(
      in_pulse  => ext_frame_atlim,
      in_clk    => sfp_rxclk_in,
      out_pulse => ext_frame_ref,
      out_clk   => adc_clk);
  

  
  sync_ref <= ext_frame_ref and sfp_rxclk_vld_adc when (sync_ref_sel=G_SYNC_REF_RXCLK)
         else pwr_event_iso when (sync_ref_sel=G_SYNC_REF_PWR)
              else hdr_det;
  resync_i <= resync or (u_b2b(sync_ref_sel=G_SYNC_REF_RXCLK) and not sfp_rxclk_vld_adc);
  synchronizer_i: synchronizer
    generic map(
      CYCS_W    => G_QSDC_FRAME_CYCS_W,
      VOTES_W   => 4,
      ERRSUM_W  => 16,
      SYNCQTY_W => 5)
    port map(
      clk          => adc_clk,
      rst          => adc_rst,
      resync       => resync_i, -- next ref forces sync to align exactly.
      pd_cycs_min1 => frame_pd_min1(G_QSDC_FRAME_CYCS_W-1 downto 0),
      ref          => sync_ref,
      sync         => frame_sync,

      procclk     => s_axi_aclk,
      errsum_o     => syncro_errsum,
      errsum_ovf_o => syncro_errsum_ovf,
      errsum_q_o   => syncro_qty,
      
      saw_ool     => saw_sync_ool,
      clr_saw_ool => clr_saw_sync_ool,
      lock        => sync_lock);

  
  process(adc_clk)
  begin
    if (rising_edge(adc_clk)) then

      if (ext_frame_ref='1') then
        ref_frame_ctr <= (others=>'0');
        ref_frame_dur_pre <= ref_frame_ctr;
      else
        ref_frame_ctr <= u_inc(ref_frame_ctr);
      end if;
      
      adc_rst_d <= adc_rst;
      dma_xfer_req_inadc_d <= dma_xfer_req_inadc; 
      adc_xfer_req_m(2)    <= dma_xfer_req_inadc;
      save_buf_avail <= txrx_en and (save_buf_avail or dma_xfer_req_inadc);

      if (tx_go_cond=G_TXGOREASON_RXRDY) then
        -- In a CDR or CDMA when determining latency, we want the DAC to start
        -- transmiting while the ADC simultaneously captures data.  Usually
        -- the last this the C code will do is start up the libiio adc buffer,
        -- and after that memory is allocated, dma_xfer_req is asserted.
        -- So we use that.  We don't want to start before the DMA rx buffer
        -- exists.
        tx_commence <= rxbuf_exists;
      elsif (tx_go_cond=G_TXGOREASON_RXPWR) then
        -- When alice commences, she should do it soon after Bob's first header.
        -- We can use a simple power event for this.
        tx_commence <= saw_pwr_event;
      elsif (tx_go_cond=G_TXGOREASON_RXHDR) then
        -- or a header detection event.
        tx_commence <= saw_hdr_det;
      elsif (tx_go_cond=G_TXGOREASON_ALWAYS) then
        -- This is just forces it.  For debug I think.
        tx_commence <= txrx_en;
      end if;
      rxbuf_exists  <= txrx_en and (dma_xfer_req_inadc_d or rxbuf_exists);
      saw_pwr_event <= txrx_en and ((pwr_event_iso and dma_xfer_req_inadc_d) or saw_pwr_event);
      saw_hdr_det   <= txrx_en and ((hdr_det       and dma_xfer_req_inadc_d) or saw_hdr_det);
      
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
      
      save_go <= txrx_en and
                 (   (    dma_xfer_req_inadc_d
                          and u_if(save_after_hdr='1', hdr_det,
                                   u_if(save_after_pwr='1', hdr_pwr_det,
                                        u_if(save_after_init='1', dbg_met_init,
                                              dac_tx_in_adc))))
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

      if (corr_vld='1') then
        corr_out_w <= corr_out & corr_out_w(127 downto 64);
      end if;
      if (corrstart='0') then
        corr_out_tog <= '0';
      else
        corr_out_tog <= corr_out_tog xor corr_vld;
      end if;
      corr_out_w_vld <= corr_vld and corr_out_tog;
      
    end if;     
  end process;

  rxq_sw_ctl <= rxq_sw_ctl_i;


  -- Augmented with debug signals
  wdata_aug(0) <= hdr_pwr_det;
  wdata_aug(1) <= hdr_det;
  wdata_aug(2) <= hdr_sync;
  wdata_aug(3) <= hdr_found;
  wdata_aug(4) <= '0'; -- hdr_sync_dlyd;
  wdata_aug(5) <= pwr_event_iso;
  wdata_aug(7 downto 6) <= (others=>'0');
  
  gen_out: for k in 0 to 3 generate
  begin
    adc_wdata_aug(k*32+14 downto k*32)       <= '0'&samps_deciph_i(k);
    adc_wdata_aug(k*32+15)                   <= wdata_aug(k*2);
    adc_wdata_aug(k*32+16+14 downto k*32+16) <= '0'&samps_deciph_q(k);
    adc_wdata_aug(k*32+16+15)                <= wdata_aug(k*2+1);
  end generate gen_out;
  
  sav_data <= adc_wdata_aug when (corrstart='0')
              else corr_out_w;
  sav_data_wr <= adc_wr when (corrstart='0')
              else corr_out_w_vld;

  -- This widens the data from "adc" width (  ) to "axi" width ( ).
  i_adc_if : axi_adcfifo_adc
    generic map(
      ADC_DATA_WIDTH => ADC_DATA_WIDTH,
      AXI_DATA_WIDTH => AXI_DATA_WIDTH)
    port map(
      adc_rst   => adc_rst,
      adc_clk   => adc_clk,
      adc_wr    => sav_data_wr,
      adc_wdata => sav_data,
      adc_wovf  => adc_wovf,

      adc_dwr   => adc_dwr, -- out
      adc_ddata => adc_ddata_s, -- axi data out
      axi_drst  => axi_drst_s,
      axi_clk   => axi_clk,
      axi_xfer_status => axi_xfer_status_s);

  -- This writes to DDR
  --   (contains a shallow buffer for efficient bursting)
  -- this does not change the data width
  -- 
  i_wr: axi_adcfifo_wr
    generic map(
      AXI_DATA_WIDTH => AXI_DATA_WIDTH, -- typ 512
      AXI_SIZE       => AXI_SIZE, --value to drive on awsize
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
      adc_wdata    => adc_ddata_s, -- in
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

  -- Maybe the smallest chunk of data all this can process
  -- is 4*512 = 256bytes.
  i_dma_if: axi_adcfifo_dma
    generic map (
      AXI_DATA_WIDTH => AXI_DATA_WIDTH,
      DMA_DATA_WIDTH => DMA_DATA_WIDTH,
      DMA_READY_ENABLE => DMA_READY_ENABLE)
    port map(
      axi_clk    => axi_clk,
      axi_drst   => axi_drst_s,
      axi_dvalid => axi_dvalid_s, -- typically bursts of 4.
      axi_ddata  => axi_ddata_s, -- 512 bits data in
      axi_dready => axi_dready_s,
      axi_xfer_status => axi_xfer_status_s,
      dma_clk => dma_clk,
      dma_wr => dma_wr,
      dma_wdata => dma_wdata,
      dma_wready => dma_wready,
      dma_xfer_req => save_go_dma,
      dma_xfer_status => dma_xfer_status);

  
  
end architecture rtl;

