
-- TODO:
-- dac_tx_out should be delayed by pm_dly cycs also!!!


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package quanet_dac_pkg is
  
  component quanet_dac is
  generic (
    AXI_A_W: integer := 8;
    DAC_D_W: integer := 16;
    MEM_A_W: integer := 8; -- set in system_bd.tcl (dac_fifo_address_width)
    MEM_D_W: integer := 16*4);
  port (
    s_axi_aclk: in std_logic;
    s_axi_aresetn: in std_logic;
    irq   : out std_logic;

    cipher_en_out        : out std_logic; -- passed to Bob's RX side
    cipher_out           : out std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
    cipher_out_vld       : out std_logic;
    alice_pm             : out std_logic;
    second_im            : out std_logic;

    -- serial link to QNA2 board
    ser0_tx: out std_logic;
    ser0_rx: in std_logic;

    -- serial link to RP
    ser1_tx: out std_logic;
    ser1_rx: in std_logic;

    -- serial link to QNA1
    ser2_tx: out std_logic;
    ser2_rx: in std_logic;
    
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

--  dac_xfer_out : out std_logic;
    hdr_vld      : out std_logic; -- used as scope trig
    
    -- A kludgy connection to quanet_sfp
    gth_status : in  std_logic_vector(3 downto 0);
    gth_rst    : out std_logic;  -- axi clk domain
    
    -- DMA interface
    dma_clk       : in std_logic;
    dma_rst       : in std_logic;
    dma_valid     : in std_logic;
    dma_data      : in std_logic_vector(MEM_D_W-1 downto 0);
    dma_ready     : out std_logic;
    dma_xfer_req  : in std_logic; -- hi till all data sent;
    dma_xfer_last : in std_logic; -- hi during last xfer

    -- DAC interface (data flows to DAC)
    dac_clk   : in std_logic;
    dac_rst   : in std_logic;
    dac_valid : in std_logic; -- means dac accepts the data
    dac_data  : out std_logic_vector(4*DAC_D_W*2-1 downto 0);
    dac_dunf  : out std_logic; -- always 0
    
    -- This is used when we want to simultanously transmit and recieve.
    -- The DMA reciever must be ready before we transmit frames.
    -- The quanet_adc raises this to let us know he's ready to rx data.
    tx_commence : in std_logic; -- in adc clk.  a level

    frame_sync_in   : in std_logic;

    -- Anyway, after quanet_adc decides its ok to start,
    -- and raises tx_commence,
    -- it may be some cycles before the first frame is emitted,
    -- and at that cycle, quanet_dac acknowledges tx_commence with dac_tx_out.
    -- This tells quanet_adc to begin saving data.
    --
    -- Alice/Bob can also use this signal for CDM (lidar),
    -- but Alice does not use it for QSDC.  She must emit (drive PM)
    -- at exactly the correct time relative to incomming headers from Bob.
    dac_tx_out: out std_logic);
  end component;
    
end package;


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity quanet_dac is
  generic (
    AXI_A_W: integer := 8;
    DAC_D_W: integer := 16;
    MEM_A_W: integer := 8;
    MEM_D_W: integer := 16*4);
  port (
    s_axi_aclk: in std_logic;
    s_axi_aresetn: in std_logic;
    irq   : out std_logic;
    
    cipher_en_out        : out std_logic; -- passed to Bob's RX side
    cipher_out           : out std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
    cipher_out_vld       : out std_logic;
    alice_pm             : out std_logic;
    second_im            : out std_logic;
    
    -- serial link to QNA board
    ser0_tx: out std_logic;
    ser0_rx: in std_logic;

    -- serial link to RP
    ser1_tx: out std_logic;
    ser1_rx: in std_logic;
    
    -- serial link to QNA1
    ser2_tx: out std_logic;
    ser2_rx: in std_logic;

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

--  dac_xfer_out : out std_logic;
    hdr_vld      : out std_logic; -- used as scope trig
    
    -- A kludgy connection to quanet_sfp
    gth_status : in  std_logic_vector(3 downto 0);
    gth_rst    : out std_logic;  -- axi clk domain
    
    -- DMA interface (data from fpga's PS, maybe from host in future)
    dma_clk       : in std_logic;
    dma_rst       : in std_logic;
    dma_valid     : in std_logic;
    dma_data      : in std_logic_vector(MEM_D_W-1 downto 0);
    dma_ready     : out std_logic;
    dma_xfer_req  : in std_logic; -- hi till all data sent;
    dma_xfer_last : in std_logic; -- hi during last xfer

    -- DAC interface (data flows to DAC)
    dac_clk   : in std_logic;
    dac_rst   : in std_logic;
    dac_valid : in std_logic; -- means dac accepts the data
    dac_data  : out std_logic_vector(4*DAC_D_W*2-1 downto 0);
    dac_dunf  : out std_logic; -- always 0
    
    tx_commence : in std_logic;


    -- This is from the synchronizer in the rx side:
    frame_sync_in : in std_logic;
    -- The transmit side (this module) has its own free-running frame sync.
    
    dac_tx_out: out std_logic);
end quanet_dac;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
use work.axi_reg_array_pkg.ALL;
use work.event_ctr_pkg.ALL;
use work.cdc_samp_pkg.ALL;
use work.cdc_pulse_pkg.ALL;
use work.gen_hdr_pkg.ALL;
use work.gen_cipher_pkg.ALL;
--use work.pulse_dly_pkg.ALL;
use work.duration_ctr_pkg.all;
use work.uart_pkg.ALL;
use work.timekeeper_pkg.ALL;
--use work.symbolize_pkg.ALL;
use work.qsdc_data_symbolizer_pkg.ALL;
architecture rtl of quanet_dac is

  constant FWVER_CONST: std_logic_vector(3 downto 0) :=
    std_logic_vector(to_unsigned(G_FWVER, 4));
  signal fwver: std_logic_vector(3 downto 0) := FWVER_CONST;


  constant REG_FR1:    integer := 0;
  constant REG_FR2:    integer := 1;
  constant REG_CTL:    integer := 2;
  constant REG_STATUS : integer := 3;
  constant REG_IM     : integer := 4;
  constant REG_HDR    : integer := 5;
  constant REG_DMA    : integer := 6;
  constant REG_PCTL   : integer := 7;  
  constant REG_QSDC   : integer := 8;  
  constant REG_SER    : integer := 9;  
  constant REG_DBG    : integer := 10;  
  constant REG_CIPHER : integer := 11;  
  constant REG_ALICE  : integer := 12;  
  constant REG_HDR2   : integer := 13;  
  
  constant NUM_REGS: integer := 14;
  
  signal reg_fr1_w, reg_fr1_r,
    reg_fr2_w, reg_fr2_r,
    reg_ctl_w, reg_ctl_r,
    reg_alice_w, reg_alice_r,
    reg_pctl_w, reg_pctl_r,
    reg_status_w, reg_status_r,
    reg_im_w, reg_im_r,
    reg_dma_w, reg_dma_r,
    reg_qsdc_w, reg_qsdc_r,
    reg_dbg_w, reg_dbg_r,
    reg_ser_w, reg_ser_r,
    reg_cipher_w, reg_cipher_r,
    reg_hdr2_w, reg_hdr2_r,
    reg_hdr_w, reg_hdr_r: std_logic_vector(31 downto 0);

  signal reg_r_vec, reg_w_vec: std_logic_vector(NUM_REGS*32-1 downto 0);
  type reg_array_t is array(0 to NUM_REGS-1) of std_logic_vector(31 downto 0);
  signal reg_r, reg_w, reg_w_dac: reg_array_t;


  
  constant MEM_CHAN_W: integer := MEM_D_W/4;
   
  component ad_mem is
    generic (
      DATA_WIDTH    : integer;
      ADDRESS_WIDTH : integer);
    port (
      clka  : in std_logic;
      wea   : in std_logic;
      addra : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      dina  : in std_logic_vector(DATA_WIDTH-1 downto 0);

      clkb  : in std_logic;
      reb   : in std_logic;
      addrb : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      doutb : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;    

  component frame_ctl is
    generic (
      FRAME_PD_CYCS_W: in integer;
      FRAME_QTY_W: in integer);
    port (
      clk : in std_logic; -- at baud/4
      rst: in std_logic;

      -- The period counter is free running.
      pd_min1 : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0); -- in clk cycles
      pd_tic : out std_logic;
      
      framer_rst      : in std_logic;
      tx_always       : in std_logic;
      tx_indefinite   : in std_logic;
      tx_commence     : in std_logic;
      alice_syncing   : in std_logic;
      frame_sync_qual : in std_logic;
      frame_qty_min1  : in std_logic_vector(FRAME_QTY_W-1 downto 0);

      -- control signals indicate when to transmit
      frame_first     : out std_logic;
      frame_first_pul : out std_logic;
      frame_go        : out std_logic); -- pulse at beginning of headers
--      txing           : out std_logic); -- remains high during pauses, until after final pause
  end component;

  component preemph is
    generic (
      D_W: in integer;
      CONST_W: in integer);
    port (
      clk  : in  std_logic;
      rst  : in  std_logic;
      en   : in  std_logic;
      din  : in  std_logic_vector(D_W*4-1 downto 0);
      f    : in  std_logic_vector(CONST_W-1 downto 0);
      dout : out std_logic_vector(D_W*4-1 downto 0));
  end component;

  
  signal frame_sync_in_cnt: std_logic_vector(5 downto 0);
  
  signal axi_rst: std_logic;
  signal reg_w_pulse, reg_r_pulse: std_logic_vector(NUM_REGS-1 downto 0);

  signal lfsr_rst_st, lfsr_rst_st2, lfsr_rst_st_in: std_logic_vector(10 downto 0);
  signal frame_qty_min1, frame_ctr: std_logic_vector(G_FRAME_QTY_W-1 downto 0);
  signal frame_pd_min1: std_logic_vector(G_FRAME_PD_CYCS_W-1 downto 0);

    
  signal framer_rst, cipher_en, cipher_en_d, cipher_prime, hdr_use_lfsr, lfsr_ld,
      tx_always, tx_indefinite, pm_hdr_disable,
      pm_hdr_go, pm_hdr_go_pre, pm_preemph_en,
    lfsr_hdr_vld, im_hdr_vld, im_hdr_last, im_body_vld, im_body_last,
    tx_req_p, frame_sync_qualified, tx_req_d, clr_cnts, memtx_to_pm,
    memtx_circ, mem_ren, mem_ren_last_pulse, alice_syncing, hdr_same, cipher_same: std_logic;
  signal hdr_len_min1_cycs: std_logic_vector(7 downto 0);
  signal osamp_min1: std_logic_vector(1 downto 0);
  signal cipher_symlen_min1_asamps: std_logic_vector(G_CIPHER_SYMLEN_ASAMPS_W-1 downto 0);
  signal body_len_min1_cycs: std_logic_vector(G_BODY_LEN_W-1 downto 0);

  signal dma_rst_i, dma_xfer_req_d, dma_xfer_req_dd, dma_xfer_pul,
    dac_xfer_req, dma_ready_i, mem_we: std_logic;

  signal mem_waddr_lim_min1, waddr_lim_min1_aclk,
    dma_raddr, mem_waddr_lim_min1_rc: std_logic_vector(MEM_A_W-1 downto 0);
  signal waddr_lim_min1: std_logic_vector(15 downto 0);

  -- In Bob, the immem (IM memory) could hold preemphasis for IM during the frame.
  -- In Alice, it could hold data to be transmitted via QSDC securely.
  -- However a full-duplex design will need separate fifos.

  -- constant MEM_D_W: integer := 16*4*2;
  signal mem_dout, mem_dout_d, txdata_shreg: std_logic_vector(MEM_D_W-1 downto 0);
  signal mem_waddr, mem_raddr: std_logic_vector(MEM_A_W-1 downto 0) := (others=>'0');
  signal mem_dout_vld, mem_dout_vld_d, mem_raddr_last: std_logic := '0';

  

  -- phase modulator (PM) and intensity modulator (IM) data
  signal pm_data, pm_data_d, im_data: std_logic_vector(DAC_D_W*4-1 downto 0);
  signal dac_data_i: std_logic_vector(4*DAC_D_W*2-1 downto 0);

  signal dac_rst_axi, dac_xfer_start, pm_data_vld: std_logic := '0';
  signal frame_first, frame_first_pul, frame_go, frame_pd_tic, txing: std_logic := '0';
  
  signal hdr_end_pre, cipher_go, cipher_vld, dbody_vld, dbody_done: std_logic;

  constant CIPHER_M_MAX: integer := G_MAX_CIPHER_M*2; -- for experimentation
  constant CIPHER_LOG2M_MAX: integer := u_bitwid(CIPHER_M_MAX-1);
  constant CIPHER_LOG2M_W: integer := u_bitwid(CIPHER_LOG2M_MAX);

  signal cipher_rst_st: std_logic_vector(G_CIPHER_LFSR_W-1 downto 0)
    := G_CIPHER_RST_STATE; --21 bits
  signal im_body, im_hdr: std_logic_vector(15  downto 0);
  signal body_pad: std_logic_vector(15-G_CIPHER_W downto 0) := (others=>'0');
  signal lfsr_hdr: std_logic_vector(3 downto 0);
  signal lfsr_hdr_data, cipher_data, dbody_data: std_logic_vector(DAC_D_W*4-1 downto 0);
  signal dbg_cipher_data: std_logic_vector(DAC_D_W-1 downto 0);
  signal dbg2: std_logic_vector(1 downto 0);
      
  signal is_bob, alice_txing, qsdc_is_dpsk, qs_start0, alice_txing_d, tx_dbits, twopi_tog, lfsr_d,
    second_im_is_probe, second_im_is_pilot,
    hdr_twopi, im_preemph, simple_im_hdr_en, dbg_zero_raddr: std_logic:='0'; -- reg field
  signal qsdc_symlen_min1_cycs: std_logic_vector(3 downto 0);
  signal tx_force, qsdc_data_is_qpsk: std_logic; -- reg field. 0=BPSK, 1=QPSK

  signal qsdc_data_cycs_min1, qsdc_data_ctr: std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
  signal cipher_m_log2 : std_logic_vector(1 downto 0);
  signal qsdc_log2m: std_logic_vector(1 downto 0);
  

  signal qsdc_frame_go,
    qsdc_data_go, qsdc_data_go_pre, qsdc_data_go_pre2,
    qsdc_data_going, qsdc_prime, qsdc_mem_ren, mem_ren_pre,
    qsdc_symbolizer_rst,
    sym_last, dbits_en,
--    dbits_pre_vld, dbits_pre_needs_data, dbits_pre_needs_data_d,
    dbits_pre_done, qsdc_data_done, qsdc_data_done_i, qsdc_tx_irq_en,
    qsdc_data_last: std_logic := '0';

  signal qsdc_pos_min1_cycs: std_logic_vector(G_QSDC_FRAME_CYCS_W-3 downto 0) := (others=>'0');



  signal dbit_enc_d, dbit_enc: std_logic_vector(1 downto 0);

  signal im_hdr_go_pre, im_hdr_go, im_hdr_simple_go, im_dly_en, im_dly_is0: std_logic;
  signal im_dly_cycs: std_logic_vector(3 downto 0);
  signal pm_dly_cycs: std_logic_vector(5 downto 0);


  constant uart_ctr_w: integer := 4;
  signal ser_rx_vld, ser_tx_irq_en, ser_rx_irq_en,
    ser_tx_w, ser_tx_w_d, ser_tx_w_pulse, ser_tx, ser_rx,
    ser_rx_r, ser_rx_r_d, ser_rx_r_pulse, ser_sel_0, ser_sel_1, ser_sel_2,
    ser_clr_errs, ser_rst, ser_tx_mt, ser_tx_full,
    ser_xon_xoff_en, ser_set_params, ser_set_flowctl,
    ser_frame_err,ser_parity_err, ser_saw_xoff_timo,
    ser_clr_ctrs, tx_commence_dac, tx_commence_aclk,
    ser_rx_ovf, ser_tx_ovf: std_logic := '0';
  signal ser_ctr_sel: std_logic_vector(uart_ctr_sel_w-1 downto 0);
  signal ser_ctr: std_logic_vector(uart_ctr_w-1 downto 0);
  signal ser_sel: std_logic_vector(1 downto 0);
  
  signal ser_parity : std_logic_vector(1 downto 0) := "00";
  signal ser_tx_data, ser_rx_data: std_logic_vector(7 downto 0);
  signal ser_refclk_div_min1: std_logic_vector(13 downto 0);
  signal s_pulse: std_logic;

  signal mem_addr_w: std_logic_vector(5 downto 0) :=
    std_logic_vector(to_unsigned(MEM_A_W, 6));
  signal pm_preemph_const: std_logic_vector(2 downto 0);

--  signal frame_dly_asamps_min1: std_logic_vector(1 downto 0);
--  signal frame_dly_cycs_min1: std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
  signal alice_pm_invert: std_logic; -- used by alice

  signal dma_lastvld: std_logic;
  signal dma_last_cnt, dma_lastvld_cnt: std_logic_vector(2 downto 0);
  signal mem_raddr_lim_min1: std_logic_vector(15 downto 0);
  signal frame_go_cnt, qsdc_frame_go_cnt: std_logic_vector(7 downto 0);
  signal qsdc_bitdur_min1_codes: std_logic_vector(8 downto 0);
  constant QSDC_BITCODE_W: integer := G_QSDC_BITCODE'length;


  signal dbg_sym_vld, dbg_sym_clr: std_logic;
  signal dbg_sym: std_logic_vector(11 downto 0);


  constant CTR_W: integer := 16;
  constant EVENTS_QTY: integer := 3;
  constant EVENT_A_LEN: integer := 2**u_bitwid(EVENTS_QTY-1);
  signal event_v, evclk_v: std_logic_vector(EVENTS_QTY-1 downto 0);
  type event_cnt_a_t is array(0 to EVENT_A_LEN-1) of std_logic_vector(CTR_W-1 downto 0);  
  signal event_cnt_a: event_cnt_a_t;
  signal tx_event_cnt: std_logic_vector(CTR_W-1 downto 0);
  signal tx_event_cnt_sel: std_logic_vector(1 downto 0);


  signal gth_status_rc : std_logic_vector(3 downto 0);
  
begin


--  assert (dma_a_w >= mem_a_w)
--    report "dma_a_w must be >= mem_a_w" severity failure;
  
  axi_rst <= not s_axi_aresetn;
  ara: axi_reg_array
    generic map(
      num_regs => NUM_REGS,
      a_w      => AXI_A_W)
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
      reg_w_vec => reg_w_vec,
      reg_r_vec => reg_r_vec,
      -- use the following for register access "side effects"
      reg_w_pulse  => reg_w_pulse,
      reg_r_pulse  => reg_r_pulse);

  gen_per_reg: for k in 0 to NUM_REGS-1 generate
  begin
    reg_w(k) <= reg_w_vec(31+k*32 downto k*32);
    reg_r_vec(31+k*32 downto k*32) <= reg_r(k);
    
    -- If a register drives signals in the dac_clk domain,
    -- we use the reg_w_dac array instead of reg_w:
    reg_w_samp: cdc_samp
      generic map(W =>32)
      port map(
        in_data  => reg_w(k),
        out_data => reg_w_dac(k),
        out_clk  => dac_clk);

  end generate gen_per_reg;

--  reg_fr1_w    <= reg_w(reg_fr1);
--  reg_fr2_w    <= reg_w(reg_fr2);
-- reg_ctl_w    <= reg_w(reg_ctl);
  reg_pctl_w    <= reg_w(REG_PCTL);
  reg_status_w <= reg_w(REG_STATUS);
--  reg_hdr_w    <= reg_w(reg_hdr);
  reg_ser_w    <= reg_w(REG_SER);
  reg_dbg_w    <= reg_w(REG_DBG);


  reg_r(REG_FR1)    <= reg_fr1_r;
  reg_r(REG_FR2)    <= reg_fr2_r;
  reg_r(REG_CTL)    <= reg_ctl_r;
  reg_r(REG_STATUS) <= reg_status_r;
  reg_r(REG_IM)     <= reg_im_r;
  reg_r(REG_HDR)    <= reg_hdr_r;
  reg_r(REG_HDR2)   <= reg_hdr2_r;
  reg_r(REG_DMA)    <= reg_dma_r;
  reg_r(REG_PCTL)   <= reg_pctl_r;
  reg_r(REG_QSDC)   <= reg_qsdc_r;
  reg_r(REG_SER)    <= reg_ser_r;
  reg_r(REG_DBG)    <= reg_dbg_r;
  reg_r(REG_CIPHER) <= reg_cipher_r;
  reg_r(REG_ALICE)  <= reg_alice_r;
  
  -- reg fr1 = 0
  reg_fr1_w <= reg_w_dac(REG_FR1);      
  reg_fr1_r <= reg_w(REG_FR1);
  frame_pd_min1  <= reg_fr1_w(G_FRAME_PD_CYCS_W-1 downto 0);

  -- reg 1 = fr2
  reg_fr2_w <= reg_w_dac(REG_FR2);
  reg_fr2_r <= reg_w(REG_FR2);
  pm_dly_cycs    <= reg_fr2_w(21 downto 16);
  frame_qty_min1 <= reg_fr2_w(G_FRAME_QTY_W-1 downto 0);

  -- reg 2 = ctl
  reg_ctl_w <= reg_w_dac(REG_CTL);
  reg_ctl_r <= reg_w(REG_CTL);
  -- default is to tx syncronously with adc dma.  old AD way was for dma req to start it.
  framer_rst     <= reg_ctl_w(31); -- for dbg. probably dont need.
  cipher_en      <= reg_ctl_w(30); -- bob sets to scramble frame bodies
  memtx_to_pm    <= reg_ctl_w(29); -- 
  tx_always      <= reg_ctl_w(28); -- used for dbg to view on scope
  pm_hdr_disable <= reg_ctl_w(27); -- header has no PM modulation
  memtx_circ     <= reg_ctl_w(26); -- circular xmit from mem
  alice_syncing  <= reg_ctl_w(25);
  tx_indefinite  <= reg_ctl_w(24); -- runs until stopped
  tx_dbits       <= reg_ctl_w(23); -- alice transmits data
  simple_im_hdr_en <= reg_ctl_w(22); -- use vals from IM register
  alice_txing    <= reg_ctl_w(21); -- set for qsdc
  dbg_zero_raddr <= reg_ctl_w(20);
--  qsdc_data_is_qpsk <= reg_ctl_w(20);
  is_bob             <= reg_ctl_w(19);
  qsdc_tx_irq_en     <= reg_ctl_w(18);
  pm_preemph_en      <= reg_ctl_w(17);
  pm_preemph_const   <= reg_ctl_w(16 downto 14);
  ser_rx_irq_en      <= reg_ctl_w(13);
  ser_tx_irq_en      <= reg_ctl_w(12);
  osamp_min1         <= reg_ctl_w(11 downto 10); -- oversampling: 0=1,1=2,3=4
  body_len_min1_cycs <= reg_ctl_w( 9 downto  0); -- set with hdr_len

  irq <=    (ser_tx_irq_en and ser_tx_mt)
         or (ser_rx_irq_en and ser_rx_vld)
         or (qsdc_tx_irq_en and qsdc_data_done_i);
  
  -- reg pctl
  gth_rst     <= reg_pctl_w(31);
  clr_cnts    <= reg_pctl_w(30);
  ser_sel     <= reg_pctl_w(29 downto 28);
  dbg_sym_clr <= reg_pctl_w(27);
  reg_pctl_r(31 downto 16) <= reg_pctl_w(31 downto 16);
  reg_pctl_r(12 downto 1)  <= dbg_sym;
  reg_pctl_r(0)            <= dbg_sym_vld;
  
  -- reg status
  reg_status_r(31 downto 24) <= (others=>'0');
  reg_status_r(22)           <= ser_tx_mt;
  reg_status_r(21)           <= qsdc_data_done;
  reg_status_r(20 downto 15) <= mem_addr_w;
  reg_status_r(14)           <= dac_rst_axi;
  reg_status_r(13 downto 8)  <= frame_sync_in_cnt;
  reg_status_r( 7 downto 4)  <= fwver;
  reg_status_r( 3 downto 0)  <= gth_status_rc;
  
  -- reg IM
  reg_im_w <= reg_w_dac(REG_IM);
  im_hdr  <= reg_im_w(31 downto 16);
  im_body <= reg_im_w(15 downto  0);
  reg_im_r <= reg_w(REG_IM);
  
  -- reg HDR
  reg_hdr_w <= reg_w_dac(REG_HDR);
  second_im_is_probe   <= reg_hdr_w(29);
  second_im_is_pilot   <= reg_hdr_w(28);
  hdr_use_lfsr         <= reg_hdr_w(27); -- header contains lfsr
  hdr_same             <= reg_hdr_w(26); -- tx all the same hdr
  im_preemph           <= reg_hdr_w(25); -- use im preemphasis
  hdr_twopi            <= reg_hdr_w(24);
  im_dly_cycs          <= reg_hdr_w(23 downto 20);
  hdr_len_min1_cycs    <= reg_hdr_w(19 downto 12); -- in cycles, minus 1  
  lfsr_rst_st          <= reg_hdr_w(10 downto 0); -- often x50f
  reg_hdr_r <= reg_w(REG_HDR);

  -- reg HDR2
  reg_hdr2_w <= reg_w_dac(REG_HDR2);
  lfsr_rst_st2   <= reg_hdr2_w(10 downto 0); -- often x0a5  
  reg_hdr2_r <= reg_w(REG_HDR2);

  
  -- reg dma
--  tx_dbits <= reg_dma_w(0); -- sets dest mem for dma. 0=IMMEM, 1=DMEM
  reg_dma_r <= reg_w(REG_DMA);
  reg_dma_w <= reg_w_dac(REG_DMA);
  mem_raddr_lim_min1 <= reg_dma_w(15 downto 0);

  -- reg CIPHER
  reg_cipher_r <= reg_w(REG_CIPHER);
  reg_cipher_w <= reg_w_dac(REG_CIPHER);
  cipher_m_log2             <= reg_cipher_w(10 downto 9); -- modulation
  cipher_same               <= reg_cipher_w(8); -- same every frame 
  cipher_symlen_min1_asamps <= reg_cipher_w(7 downto 0);
  
  -- reg QSDC
  reg_qsdc_r <= reg_w(REG_QSDC);
  reg_qsdc_w <= reg_w_dac(REG_QSDC);
  qsdc_data_cycs_min1    <= reg_qsdc_w(9 downto 0);   -- dur of body in frame.
                                                      -- (change to data_len_min1_syms)
  qsdc_symlen_min1_cycs  <= reg_qsdc_w(13 downto 10); -- dur of one QSDC symbol aka chip. 1..8
  qsdc_pos_min1_cycs     <= reg_qsdc_w(21 downto 14); -- offset of data from start of frame
  qsdc_data_is_qpsk      <= reg_qsdc_w(22);  -- 0=bpsk, 1=qpsk
  
  qsdc_bitdur_min1_codes <= reg_qsdc_w(31 downto 23); -- num code reps per bit, min 1
  -- (TOOD: change to bitdur_min1_syms)
  
  -- reg ALICE
  waddr_lim_min1 <= u_extl(waddr_lim_min1_aclk, 16); -- for debug
  reg_alice_r(31 downto 16) <= waddr_lim_min1; -- for debug
  reg_alice_r(15 downto  0) <= reg_w(REG_ALICE)(15 downto 0);
  reg_alice_w <= reg_w_dac(REG_ALICE);
--  frame_dly_asamps_min1 <= reg_alice_w(1 downto 0); -- TODO: implement
--  frame_dly_cycs_min1   <= reg_alice_w(11 downto 2); -- from synchronizer to start of frame
  alice_pm_invert       <= reg_alice_w(12);

  -- reg SER
  reg_ser_r(31)           <= ser_rx_vld;
  reg_ser_r(30)           <= ser_tx_full;
  reg_ser_r(29 downto 8)  <= reg_ser_w(29 downto 8);
  reg_ser_r(7 downto  0)  <= ser_rx_data;

  ser_refclk_div_min1 <= reg_ser_w(29 downto 16);
  ser_set_flowctl <= reg_ser_w(15);
  ser_parity      <= reg_ser_w(14 downto 13);
  ser_xon_xoff_en <= reg_ser_w(12);
  ser_set_params  <= reg_ser_w(11);
  ser_tx_w        <= reg_ser_w(10);
  ser_rx_r        <= reg_ser_w(9);
  ser_rst         <= reg_ser_w(8);
  ser_tx_data     <= reg_ser_w(7 downto 0);


  -- reg DBG
  ser_clr_errs     <= reg_dbg_w(30);
  ser_ctr_sel      <= reg_dbg_w(29 downto 28);
  ser_clr_ctrs     <= reg_dbg_w(27);
  tx_force         <= reg_dbg_w(26);
  tx_event_cnt_sel <= reg_dbg_w(25 downto 24);
  
--  reg_dbg_r(6)          <= dbg_drp_proc_won;
--  reg_dbg_r(5)          <= dbg_drp_busy;
--  reg_dbg_r(4)          <= dbg_proc_req;
  reg_dbg_r(31 downto 24) <= reg_dbg_w(31 downto 24);
--  reg_dbg_r(17  downto 15) <= dma_lastvld_cnt;
--  reg_dbg_r(14  downto 12) <= dma_last_cnt;
  reg_dbg_r(23)           <= tx_commence_aclk;
--  reg_dbg_r(22 downto 16) <= foo_cnt;
  reg_dbg_r(21 downto  6) <= tx_event_cnt;
  reg_dbg_r(4) <= ser_rx_ovf;
  reg_dbg_r(3) <= ser_tx_ovf;
  reg_dbg_r(2) <= ser_saw_xoff_timo;
  reg_dbg_r(1) <= ser_parity_err;
  reg_dbg_r(0) <= ser_frame_err;

  frame_ctl_i: frame_ctl
    generic map(
      FRAME_PD_CYCS_W => G_FRAME_PD_CYCS_W,
      FRAME_QTY_W     => G_FRAME_QTY_W)
    port map(
      clk => dac_clk,
      rst => dac_rst, -- will reset internal cyc ctr

      -- The period counter is free running
      pd_min1   => frame_pd_min1,
      pd_tic    => frame_pd_tic,

      framer_rst      => framer_rst,
      tx_always       => tx_always,
      tx_indefinite   => tx_indefinite,
      tx_commence     => tx_commence_dac,
      alice_syncing   => alice_syncing,
      frame_qty_min1  => frame_qty_min1,
      frame_sync_qual => frame_sync_qualified, -- an input. 

      -- control signals indicate when to transmit
      frame_first     => frame_first,  -- determines when lfsr is rst
      frame_first_pul => frame_first_pul,
      frame_go        => frame_go);   -- pulse at beginning of frames
--      txing       => txing);   -- remains high during pauses, until after final pause

  
  -- if the module is not in initialization phase, it should go
  -- into reset at a positive edge of dma_xfer_req
  dma_xfer_pul <= dma_xfer_req_d and not dma_xfer_req_dd;
  dma_rst_i    <= dma_rst or dma_xfer_pul;
  mem_we       <= dma_valid and dma_ready_i;
  dma_ready_i  <= '1'; -- always ready
  dma_ready    <= dma_ready_i;
  process(dma_clk)
  begin
    if (rising_edge(dma_clk)) then

      dma_xfer_req_d  <= dma_xfer_req;
      dma_xfer_req_dd <= dma_xfer_req_d;

      -- we could dma into the IM mem, or the qsdc tx data mem
      if (dma_rst_i = '1') then
        mem_waddr   <= (others=>'0');
      elsif (mem_we = '1') then
        if (dma_xfer_last = '1') then
          mem_waddr <= (others=>'0');
        else
          mem_waddr <= u_inc(mem_waddr);
        end if;
      end if;

      -- mem_waddr_lim_min1 held constant until end of the next dma xfer
      -- I thought the proper condition was:(mem_we and dma_xfer_last)
      -- but its not what AD used, and I think it didn't work.
      if (dma_xfer_last = '1') then
        mem_waddr_lim_min1 <= u_dec(mem_waddr);
      end if;
      
    end if;
  end process;

  dac_tx_out <= frame_first_pul; -- dac_xfer_out;
   
--  mem_ren_last_pulse <= not memtx_circ and dac_valid and mem_ren and mem_raddr_last;
  
  -- As Bob, this mem could store pre-emphasis data for IM of header.
  -- As alice it would contain data to xmit securely over QSDC.
  -- In this design, it's never both Alice and Bob at the same time.
  -- works like:
  --   raddr  0000112333
  --   mem_r  ___-_--___
  --   dout       a bc   <- think of it like:
  --   dout   aaaaabbcdd <- actually
  mem_ren <= mem_ren_pre when (alice_txing='0')
             else qsdc_mem_ren;
  mem: ad_mem
    generic map(
      ADDRESS_WIDTH => MEM_A_W,
      DATA_WIDTH    => MEM_D_W)
    port map(
      clka  => dma_clk,
      wea   => mem_we,
      addra => mem_waddr,
      dina  => dma_data,
      
      clkb  => dac_clk,
      reb   => '1',
      addrb => mem_raddr,
      doutb => mem_dout);

  

  xfer_req_pb: cdc_pulse
    port map(
      in_pulse  => dma_xfer_req, -- host wants to write data
      in_clk    => dma_clk,
      out_pulse => dac_xfer_req,
      out_clk   => dac_clk);




  
  -- Possibly delay IM signal a few cycles
  -- so Bob's IM and PM are synchronized optically
  im_hdr_go_pre <= is_bob and frame_go;
  im_dly: duration_ctr
     generic map (
       LEN_W => 4)
     port map(
       clk      => dac_clk,
       rst      => '0',
       go_pul   => im_hdr_go_pre,
       len_min1 => im_dly_cycs,
       sig_last => im_hdr_go);

  -- for simple IM hdr and body:
  im_hdr_simple_go <= im_hdr_go and simple_im_hdr_en;
  im_hdr_delimiter: duration_ctr
     generic map (
       LEN_W => 8)
     port map(
       clk      => dac_clk,
       rst      => dac_rst,
       go_pul   => im_hdr_simple_go,
       len_min1 => hdr_len_min1_cycs,
       sig_o    => im_hdr_vld,
       sig_last => im_hdr_last);
  im_body_delimiter: duration_ctr
     generic map (
       LEN_W => 10)
     port map(
       clk      => dac_clk,
       rst      => dac_rst,
       go_pul   => im_hdr_last,
       len_min1 => body_len_min1_cycs,
       sig_o    => im_body_vld);


-- todo: delete alice_syncing.  Use pm_hdr_disable instead.
-- dont require isbob for pm_hdr either.  
  
  -- Phase Modulation for header
  pm_hdr_go_pre <= (is_bob or alice_syncing)
                   and frame_go and hdr_use_lfsr and not pm_hdr_disable;
  pm_dly: duration_ctr
     generic map (
       LEN_W => 6)
     port map(
       clk      => dac_clk,
       rst      => '0',
       go_pul   => pm_hdr_go_pre,
       len_min1 => pm_dly_cycs,
       sig_last => pm_hdr_go);
    
  lfsr_ld <= (frame_first or hdr_same or tx_indefinite) and pm_hdr_go;
  lfsr_rst_st_in <= lfsr_rst_st2 when ((tx_indefinite and not frame_first)='1')
                    else lfsr_rst_st;
  gen_hdr_i: gen_hdr
    generic map(
      HDR_LEN_W => G_HDR_LEN_W)
    port map(
      clk          => dac_clk,
      rst          => dac_rst,
      osamp_min1   => osamp_min1,
      hdr_len_min1_cycs => hdr_len_min1_cycs,

      gen_diff => '0',

      lfsr_state_ld      => lfsr_ld,
      lfsr_state_in      => lfsr_rst_st_in,
--      lfsr_state_nxt     => lfsr_state_nxt,
--      lfsr_state_nxt_vld => lfsr_state_nxt_vld,
      
      go_pulse => pm_hdr_go,
      en => '1',

      hdr_end_pre => hdr_end_pre,
--      cyc_cnt_down => hdr_cyc_cnt_down,		     
      dout_vld => lfsr_hdr_vld, -- high only during the headers
      dout     => lfsr_hdr);
  hdr_vld <= lfsr_hdr_vld; -- used as a scope trigger
  lfsr_hdr_data <=   lfsr_hdr(3) & "100000000000000"
                   & lfsr_hdr(2) & "100000000000000"
                   & lfsr_hdr(1) & "100000000000000"
                   & lfsr_hdr(0) & "100000000000000" when (hdr_twopi='0')
          else (others=>'0') when (lfsr_hdr(0)='0')
          else u_rpt((not twopi_tog)&u_rpt(twopi_tog, DAC_D_W-1), 4);

  cipher_en_out <= cipher_en;
  cipher_prime <=    (cipher_en and not cipher_en_d)
                     or (cipher_en and frame_go and cipher_same);
  -- cipher_same is a debug thing.  Makes the cipher the same for every frame.
  
  cipher_go <= hdr_end_pre and cipher_en;
  -- for Bob's RANDOM PM body which is M-psk.
  cipher_i : gen_cipher
    generic map(
      LEN_W     => G_BODY_LEN_W,
      CP        => G_CIPHER_CHAR_POLY,
      M_MAX     => CIPHER_M_MAX,
      LOG2M_MAX => CIPHER_LOG2M_MAX+1,
      LOG2M_W   => CIPHER_LOG2M_W,
      SYMLEN_ASAMPS_W => G_CIPHER_SYMLEN_ASAMPS_W,
      DAC_W     => DAC_D_W)
    port map(
      clk        => dac_clk,
      rst        => dac_rst,
      symlen_min1_asamps => cipher_symlen_min1_asamps,

      -- when this component generates M-PSK, M is determined by:
      log2m      => cipher_m_log2, -- log2 of M. 1...LOG2M_MAX

      len_min1   => body_len_min1_cycs,

      prime         => cipher_prime,
      lfsr_state_in => cipher_rst_st,
      go_pulse      => cipher_go,
      en            => cipher_en,

      -- to the cipher fifo
      cipher_out     => cipher_out,
      cipher_out_vld => cipher_out_vld,
      
      -- to the datapath
      dout_vld      => cipher_vld,
      dout          => cipher_data);
  dbg_cipher_data <= cipher_data(15 downto 0);
                   

  gth_status_samp:  cdc_samp
    generic map(
      W => 4)
    port map(
      in_data  => gth_status,
      out_data => gth_status_rc,
      out_clk  => s_axi_aclk);

  
  mem_waddr_lim_min1_samp:  cdc_samp
    generic map(
      W => MEM_A_W)
    port map(
      in_data  => mem_waddr_lim_min1,
      out_clk  => dac_clk,		       
      out_data => mem_waddr_lim_min1_rc);
  waddr_lim_min1_samp:  cdc_samp
    generic map(
      W => MEM_A_W)
    port map(
      in_data  => mem_waddr_lim_min1,
      out_clk  => s_axi_aclk,
      out_data => waddr_lim_min1_aclk);
  
  dac_rst_samp:  cdc_samp
    generic map(
      W => 2)
    port map(
      in_data(0)  => dac_rst,
      in_data(1)  => qsdc_data_done_i,
      out_clk     => s_axi_aclk,
      out_data(0) => dac_rst_axi, -- for dbg
      out_data(1) => qsdc_data_done); -- for dbg

  frame_sync_in_ctr: event_ctr
    generic map(W => 6)
    port map(
      clk   => dac_clk,
      event => frame_sync_in,
      
      rclk  => s_axi_aclk,
      clr   => clr_cnts,
      cnt   => frame_sync_in_cnt);



  event_v(0) <= frame_go;
  evclk_v(0) <= dac_clk;
  event_v(1) <= frame_first_pul;
  evclk_v(1) <= dac_clk;
  event_v(2) <= qsdc_frame_go;
  evclk_v(2) <= dac_clk;
  gen_event_ctrs: for k in 0 to EVENTS_QTY-1 generate
  begin
    event_ctr_i: event_ctr
      generic map (W => CTR_W)
      port map(
        clk   => evclk_v(k),
        event => event_v(k),
        rclk  => s_axi_aclk,
        clr   => clr_cnts,
        cnt   => event_cnt_a(k));
  end generate gen_event_ctrs;
  tx_event_cnt <= event_cnt_a(to_integer(unsigned(tx_event_cnt_sel)));
  

  
--  dma_last_ctr: event_ctr
--    generic map(W => 3)
--    port map(
--      clk   => dma_clk,
--      event => dma_xfer_last,
--      
--      rclk  => s_axi_aclk,
--      clr   => clr_cnts,
--      cnt   => dma_last_cnt);
--
--  dma_lastvld <= dma_xfer_last and dma_valid;
--  dma_lastvld_ctr: event_ctr
--    generic map(W => 3)
--    port map(
--      clk   => dma_clk,
--      event => dma_lastvld,
--      
--      rclk  => s_axi_aclk,
--      clr   => clr_cnts,
--      cnt   => dma_lastvld_cnt);
  
  

  
  commence_samp: cdc_samp
    generic map(W=>1)
    port map (
      in_data(0)  => tx_commence,
      out_data(0) => tx_commence_dac,
      out_clk     => dac_clk);

  commence_aclk_samp: cdc_samp
    generic map(W=>1)
    port map (
      in_data(0)  => tx_commence_dac,
      out_data(0) => tx_commence_aclk,
      out_clk     => s_axi_aclk);

  

  qsd_pos_ctr_i: duration_ctr -- delay from frame_go to qsdc_go
    generic map(
      LEN_W => 8)
    port map(
      clk      => dac_clk,
      rst      => dac_rst,
      go_pul   => qsdc_frame_go,
      len_min1 => qsdc_pos_min1_cycs,
      sig_last => qsdc_data_go_pre2); -- starts QSD data insertion


  
  process(dac_clk)
  begin
    if (rising_edge(dac_clk)) then

      if (lfsr_hdr_vld='1') then
        lfsr_d <= lfsr_hdr(0);
        if ((not lfsr_hdr(0) and lfsr_d)='1') then
          twopi_tog <= not twopi_tog;
        end if;
      end if;
      
      cipher_en_d <= cipher_en;
      
      -- frame_sync_in is a dac_clk domain signal from adc fifo. pulses once per frame.
      frame_sync_qualified <=     (tx_commence_dac or tx_always)
                              and u_if(is_bob='1', frame_pd_tic, frame_sync_in);


      qsdc_frame_go <= alice_txing and frame_sync_qualified and not dbody_done;
      qsdc_data_go_pre <= qsdc_data_go_pre2;
      qsdc_data_go     <= qsdc_data_go_pre;
      
-- mem_ren      ___--------___
-- mem_raddr       01234567
-- mem_raddr_last ________-__
-- mem_dout      ___abcdefgh
-- mem_dout_vld  ___-----------__
     

      if (alice_txing='0') then
        -- use mem for IM preemphasis data or repeating pattern generation
        mem_ren_pre  <= memtx_circ or
                        ((im_hdr_go and im_preemph) or
                         (mem_ren_pre and not mem_raddr_last));
      else
        mem_ren_pre <= '0';
      end if;


      -- NOTE: might want to read from mem as part of a priming operation
      -- prior to tx_commence_dac.
      if ((dbg_zero_raddr or dac_rst or (mem_ren and mem_raddr_last))='1') then
        mem_raddr_last <= '0';
        mem_raddr <= (others=>'0');
      elsif (mem_ren='1') then
        mem_raddr <= u_inc(mem_raddr);
        mem_raddr_last <= u_b2b(mem_raddr = mem_raddr_lim_min1(MEM_A_W-1 downto 0));
      end if;

--      if ((not alice_txing and not memtx_circ and not tx_always)='1') then
--      elsif (mem_ren='1') then
--      end if;
      
      mem_dout_vld   <= mem_ren;
      mem_dout_vld_d <= mem_dout_vld;
      
      if ((not alice_txing and mem_dout_vld)='1') then
        mem_dout_d <= mem_dout;
      else
        mem_dout_d <= (others=>'0');
      end if;

      -- This goes high just within a frame
      qsdc_data_going <= (qsdc_data_go and not qsdc_data_done_i) or (qsdc_data_going and not qsdc_data_last); 
      if (qsdc_data_go='1') then
        qsdc_data_ctr <= qsdc_data_cycs_min1;
      elsif (qsdc_data_going='1') then
        qsdc_data_ctr <= u_dec(qsdc_data_ctr);
      end if;
      qsdc_data_done_i <= tx_commence and ((not qsdc_data_going and dbody_done) or qsdc_data_done_i);
      qsdc_data_last <= u_b2b(unsigned(qsdc_data_ctr)=1);

      alice_txing_d <= alice_txing;

      

      -- GENERATE SIGNAl TO BOB's IM DAC
      if (im_preemph='1') then
        if (mem_dout_vld_d='1') then
          im_data <=   mem_dout_d(3*MEM_CHAN_W+15 downto 3*MEM_CHAN_W)
                     & mem_dout_d(2*MEM_CHAN_W+15 downto 2*MEM_CHAN_W)
                       & mem_dout_d(1*MEM_CHAN_W+15 downto 1*MEM_CHAN_W)
                       & mem_dout_d(0*MEM_CHAN_W+15 downto 0*MEM_CHAN_W);
        else
          im_data <= (others=>'0');
        end if;
      elsif (im_hdr_vld='1') then
        im_data <= im_hdr & im_hdr & im_hdr & im_hdr;
      elsif (im_body_vld='1') then
        im_data <= im_body & im_body & im_body &im_body;
      else 
        im_data <= (others=>'0');
      end if;

      pm_data_vld <= (not alice_txing and lfsr_hdr_vld) or cipher_vld or dbody_vld
                     or (memtx_to_pm and mem_dout_vld_d);
      if ((memtx_to_pm and mem_dout_vld_d)='1') then
        pm_data <=  mem_dout_d(3*MEM_CHAN_W+15 downto 3*MEM_CHAN_W)
                  & mem_dout_d(2*MEM_CHAN_W+15 downto 2*MEM_CHAN_W)
                  & mem_dout_d(1*MEM_CHAN_W+15 downto 1*MEM_CHAN_W)
                  & mem_dout_d(0*MEM_CHAN_W+15 downto 0*MEM_CHAN_W);
      elsif ((not alice_txing and lfsr_hdr_vld)='1') then
        pm_data <= lfsr_hdr_data;
      elsif (cipher_vld='1') then
        pm_data <= cipher_data;
      elsif (dbody_vld='1') then
        pm_data <= dbody_data;
      else
        pm_data <= (others=>'0');
      end if;

      -- Greg said we should drive Alice's modulator from a cmos output instead
      -- of from a DAC.
      alice_pm <= pm_data_vld and (alice_pm_invert xor pm_data(DAC_D_W-1));

      -- More DC-coupled.  On/Off.  For CDM probes or ext ratio enhancement
      second_im <=    (lfsr_hdr_vld and second_im_is_probe and lfsr_hdr(0))
                   or (lfsr_hdr_vld and second_im_is_pilot);
    end if;
  end process;
--  dbits_pre_needs_data <= alice_txing and not dbits_pre_vld;
  qsdc_prime <= alice_txing and not alice_txing_d;




  qsdc_log2m <= u_if(qsdc_data_is_qpsk='0',"01","10");
  qsdc_symbolizer_rst <= not alice_txing;
  symbolizer: qsdc_data_symbolizer
    generic map(
      M_MAX     => 2,
      LOG2M_MAX => 2,
      LOG2M_W   => 2,
      SYMLEN_W  => G_QSDC_ALICE_SYMLEN_W,
      CODE_W    => G_QSDC_BITCODE'length,
      BITDUR_W  => G_QSDC_BITDUR_W-2,
      MEM_W     => MEM_D_W,
      DAC_W     => DAC_D_W)
    port map(
      clk   => dac_clk,
      rst   => qsdc_symbolizer_rst,
      prime => qsdc_prime,
      en    => qsdc_data_going,

      mem_data  => mem_dout,
      mem_last  => mem_raddr_last,
      mem_rd    => qsdc_mem_ren,

      code => G_QSDC_BITCODE,
      bitdur_min1_codes => qsdc_bitdur_min1_codes, -- TODO: replace w qsdc_bit_len_min1_syms
      symlen_min1_cycs  => qsdc_symlen_min1_cycs, 
      
      -- when this component generates M-PSK, M is determined by:
      log2m  => qsdc_log2m,

      dout_done  => dbody_done,
      dout       => dbody_data,
      dout_vld   => dbody_vld,

      s_axi_aclk   => s_axi_aclk,
      dbg_dout     => dbg_sym,
      dbg_dout_vld => dbg_sym_vld,
      dbg_dout_clr => dbg_sym_clr);


  pm_preemph: preemph
    generic map(
      D_W     => DAC_D_W,
      CONST_W => 3)
    port map(
      clk  => dac_clk,
      rst  => dac_rst,
      en   => pm_preemph_en,
      din  => pm_data,
      f    => pm_preemph_const,
      dout => pm_data_d);


  

  
  -- The final product of this module.. data for the dac
  dac_data <=   im_data(63 downto 48) & pm_data_d(63 downto 48)
              & im_data(47 downto 32) & pm_data_d(47 downto 32)
              & im_data(31 downto 16) & pm_data_d(31 downto 16)
              & im_data(15 downto 0)  & pm_data_d(15 downto  0);


  tk: timekeeper
    generic map (
      REF_HZ => G_S_AXI_CLK_FREQ_HZ)
    port map(
      refclk  => s_axi_aclk,
      s_pulse => s_pulse);



  ser_sel_0 <= u_b2b(unsigned(ser_sel)=0);
  ser_sel_1 <= u_b2b(unsigned(ser_sel)=1);
  ser_sel_2 <= u_b2b(unsigned(ser_sel)=2);
  
  ser_rx_r_pulse <= ser_rx_r and not ser_rx_r_d;
  ser_tx_w_pulse <= ser_tx_w and not ser_tx_w_d;
  
  ser0_tx <= ser_tx or not ser_sel_0;
  ser1_tx <= ser_tx or not ser_sel_1;
  ser2_tx <= ser_tx or not ser_sel_2;

  ser_rx <=      ser0_rx when (ser_sel_0='1')
            else ser1_rx when (ser_sel_1='1')
            else ser2_rx;

  
  comuart: uart
    generic map(
      REFCLK_HZ => G_S_AXI_CLK_FREQ_HZ,
      DFLT_BAUD_HZ  => 115200.0,
      TXFIFO_DEPTH => 16,
      RXFIFO_DEPTH => 32,
      CTR_W => UART_CTR_W)
    port map (
      refclk  => s_axi_aclk,
      s_pulse => s_pulse,
      uart_txd => ser_tx,
      uart_rxd => ser_rx,
      uart_rts => '1',
      
      ifaceclk        => s_axi_aclk,
      set_params      => ser_set_params,
      refclk_div_min1(15 downto 14) => "00",
      refclk_div_min1(13 downto 0)  => ser_refclk_div_min1,

      parity          => ser_parity,
      xon_xoff_en     => ser_xon_xoff_en,
      rts_cts_en      => '0',
      set_flowctl     => ser_set_flowctl,
      
      tx_data   => ser_tx_data,
      tx_w      => ser_tx_w_pulse,
      tx_full   => ser_tx_full,
      tx_mt     => ser_tx_mt,
      tx_rst    => ser_rst,
      
      rx_vld    => ser_rx_vld,   -- a level
      rx_rst    => ser_rst,
      rx_data   => ser_rx_data,
      rx_r      => ser_rx_r_pulse, -- pulse to read fifo.

      ctr_sel   => ser_ctr_sel,
      ctr       => ser_ctr,
      ctrs_clr  => ser_clr_ctrs,
      
      clr_errs      => ser_clr_errs, -- high clears frame_err and rx_ovf
      frame_err     => ser_frame_err,  -- stays hi till clr_errs=1
      parity_err    => ser_parity_err, -- stays hi till clr_errs=1
      saw_xoff_timo => ser_saw_xoff_timo,
      rx_ovf     => ser_rx_ovf,
      tx_ovf     => ser_tx_ovf);

  process(s_axi_aclk)
  begin
    if (rising_edge(s_axi_aclk)) then
      ser_tx_w_d <= ser_tx_w;
      ser_rx_r_d <= ser_rx_r;
    end if;
  end process;
      
end architecture rtl;
