library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package quanet_dac_pkg is
  
  component quanet_dac is
  generic (
    DMA_A_W: integer := 16;
    AXI_A_W: integer := 4;
    IMMEM_A_W: integer := G_FRAME_PD_W);
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

--  dac_xfer_out : out std_logic;
    hdr_vld      : out std_logic; -- used as scope trig
    
    -- A kludgy connection to quanet_sfp
    gth_status : in  std_logic_vector(3 downto 0); -- axi clk domain
    gth_rst    : out std_logic;  -- axi clk domain
    
    -- DMA interface
    dma_clk       : in std_logic;
    dma_rst       : in std_logic;
    dma_valid     : in std_logic;
    dma_data      : in std_logic_vector(127 downto 0);
    dma_ready     : out std_logic;
    dma_xfer_req  : in std_logic; -- hi till all data sent;
    dma_xfer_last : in std_logic; -- hi during last xfer

    -- DAC interface (data flows to DAC)
    dac_clk   : in std_logic;
    dac_rst   : in std_logic;
    dac_valid : in std_logic; -- means dac accepts the data
    dac_data  : out std_logic_vector(4*16*2-1 downto 0);
    dac_dunf  : out std_logic; -- always 0
    
    -- This is used when we want to simultanously transmit and recieve.
    -- The DMA reciever must be ready before we transmit frames.
    -- The quanet_adc raises this to let us know he's ready to rx data.
    dac_tx_in : in std_logic; -- a request from quanet_adc. in dac_clk domain.

    -- This module has a frame counter that repeats and never stops.
    -- Bob only starts frames when this counter ticks.
    -- Perhaps this constraint is not needed, but for now it results
    -- in a certain consistency.
    --
    -- Anyway, after quanet_adc does a request with dac_tx_in,
    -- it may be some cycles before the frame is emitted,
    -- and at that cycle, quanet_dac acknowledges dac_tx_in with dac_tx_out.
    -- This tells quanet_adc to begin saving data.
    --
    -- Alice can also use this constraint for CDM (lidar),
    -- but when for QSDC she does not.  She must emit (drive PM)
    -- at exactly the correct time relative to incomming headers from Bob.
    dac_tx_out: out std_logic);
  end component;
    
end package;


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity util_dacfifo is
  generic (
    DMA_A_W: integer := 16;
    AXI_A_W: integer := 4;
    IMMEM_A_W: integer := G_FRAME_PD_W);
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

--  dac_xfer_out : out std_logic;
    hdr_vld      : out std_logic; -- used as scope trig
    
    -- A kludgy connection to quanet_sfp
    gth_status : in  std_logic_vector(3 downto 0); -- axi clk domain
    gth_rst    : out std_logic;  -- axi clk domain
    
    -- DMA interface
    dma_clk       : in std_logic;
    dma_rst       : in std_logic;
    dma_valid     : in std_logic;
    dma_data      : in std_logic_vector(127 downto 0);
    dma_ready     : out std_logic;
    dma_xfer_req  : in std_logic; -- hi till all data sent;
    dma_xfer_last : in std_logic; -- hi during last xfer

    -- DAC interface (data flows to DAC)
    dac_clk   : in std_logic;
    dac_rst   : in std_logic;
    dac_valid : in std_logic; -- means dac accepts the data
    dac_data  : out std_logic_vector(4*16*2-1 downto 0);
    dac_dunf  : out std_logic; -- always 0
    
    -- This is used when we want to simultanously transmit and recieve.
    -- The DMA reciever must be ready before we transmit frames.
    -- The quanet_adc raises this to let us know he's ready to rx data.
    dac_tx_in : in std_logic; -- a request from quanet_adc. in dac_clk domain.

    -- This module has a frame counter that repeats and never stops.
    -- Bob only starts frames when this counter ticks.
    -- Perhaps this constraint is not needed, but for now it results
    -- in a certain consistency.
    --
    -- Anyway, after quanet_adc does a request with dac_tx_in,
    -- it may be some cycles before the frame is emitted,
    -- and at that cycle, quanet_dac acknowledges dac_tx_in with dac_tx_out.
    -- This tells quanet_adc to begin saving data.
    --
    -- Alice can also use this constraint for CDM (lidar),
    -- but when for QSDC she does not.  She must emit (drive PM)
    -- at exactly the correct time relative to incomming headers from Bob.
    dac_tx_out: out std_logic);
end util_dacfifo;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
use work.axi_reg_array_pkg.ALL;
use work.cdc_samp_pkg.ALL;
use work.cdc_pulse_pkg.ALL;
use work.gen_hdr_pkg.ALL;
use work.gen_body_pkg.ALL;
architecture rtl of util_dacfifo is

  constant VERSION: std_logic_vector(3 downto 0) :=
    std_logic_vector(to_unsigned(2, 4));
  
  constant NUM_REGS: integer := 7;
  
  signal reg_r_vec, reg_w_vec: std_logic_vector(NUM_REGS*32-1 downto 0);
  type reg_array_t is array(0 to NUM_REGS-1) of std_logic_vector(31 downto 0);
  signal reg_r, reg_w: reg_array_t;

  constant REG_FR1:    integer := 0;
  constant REG_FR2:    integer := 1;
  constant REG_CTL:    integer := 2;
  constant REG_STATUS : integer := 3;
  constant REG_IM     : integer := 4;
  constant REG_HDR    : integer := 5;
  
  signal reg_fr1_w, reg_fr1_r,
         reg_fr2_w, reg_fr2_r,
         reg_ctl_w, reg_ctl_r,
         reg_status_w, reg_status_r,
         reg_im_w, reg_im_r,
         reg_hdr_w, reg_hdr_r: std_logic_vector(31 downto 0);

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
    port (
      clk : in std_logic; -- at baud/4
      rst: in std_logic;

      -- The period counter is free running.
      pd_min1 : in std_logic_vector(G_FRAME_PD_W-1 downto 0); -- in clk cycles
      pd_tic : out std_logic;
      
      tx_always: in std_logic;
      tx_req: in std_logic; -- request transission by pulsing high for one cycle

      frame_qty_min1 : in std_logic_vector(G_FRAME_QTY_W-1 downto 0);

      -- control signals indicate when to transmit
      frame_first : out std_logic;
      frame_tx    : out std_logic; -- pulse at beginning of headers
      txing     : out std_logic); -- remains high during pauses, until after final pause
  end component;



  
--function bf(vin: std_logic_vector)
--  return std_logic_vector is;
-- begin
--   return u_ext
--     return = vin - 2**(G_BODY_RAND_BITS-1) + vin[G_BODY_RAND_BITS-1];
--  end
--endfunction // bf

  
  signal axi_rst: std_logic;
  signal reg_w_pulse, reg_r_pulse: std_logic_vector(NUM_REGS-1 downto 0);

  signal lfsr_rst_st: std_logic_vector(10 downto 0);
  signal frame_qty_min1, frame_qty_min1_dac: std_logic_vector(G_FRAME_QTY_W-1 downto 0);
  signal frame_pd_min1, frame_pd_min1_dac: std_logic_vector(G_FRAME_PD_W-1 downto 0);

    
  signal tx_unsync, rand_body, use_lfsr, lfsr_ld, tx_always, tx_0, hdr_go, hdr_vld_i,
    tx_req_p, tx_req_pulse, tx_req_d,
    memtx_circ, mem_ren, mem_ren_last_pulse, alice_syncing, same_hdrs: std_logic;
  signal hdr_len_min1: std_logic_vector(7 downto 0);
  signal osamp_min1: std_logic_vector(1 downto 0);
  signal body_len_min1: std_logic_vector(9 downto 0);

  signal dma_rst_i, dma_xfer_req_d, dma_xfer_req_dd, dma_xfer_pul,
    dac_xfer_req, dma_ready_i, dma_wren: std_logic;

  signal mem_waddr_last, dma_waddr, dma_raddr, dma_lastaddr, dac_lastaddr: std_logic_vector(DMA_A_W-1 downto 0);

  -- The immem (IM memory) could hold preemphasis for IM during the frame.
--  constant IMMEM_A_W: integer := G_FRAME_PD_W;
  signal immem_din, immem_dout, immem_dout_d: std_logic_vector(16*4-1 downto 0);
  signal mem_waddr, mem_raddr: std_logic_vector(DMA_A_W-1 downto 0);
  signal mem_dout_vld, mem_dout_vld_d, mem_raddr_last: std_logic := '0';

  -- phase modulator (PM) and intensity modulator (IM) data
  signal pm_data, im_data: std_logic_vector(63 downto 0);

  signal dac_data_i: std_logic_vector(4*16*2-1 downto 0);

  signal dac_rst_int_s: std_logic;
  signal frame_first, frame_tx, framer_go, frame_pd_tic, txing: std_logic;
  
  signal hdr_end_pre, body_go, body_end_pre, body_vld: std_logic;
  signal body_out: std_logic_vector(G_BODY_RAND_BITS*4-1 downto 0);
  constant BODY_LFSR_W: integer := 21; -- std_logic_vector(G_BODY_CHAR_POLY)'length;
  signal body_rst_st: std_logic_vector(BODY_LFSR_W-1 downto 0) := '0'&X"abcde"; --
--21 bits
  signal im_body, im_hdr: std_logic_vector(15  downto 0);
  signal body_pad: std_logic_vector(15-G_BODY_RAND_BITS downto 0) := (others=>'0');
  signal gen_dout: std_logic_vector(3 downto 0);
  signal hdr_data, body_data: std_logic_vector(16*4-1 downto 0);
    
begin

  assert (DMA_A_W >= IMMEM_A_W)
    report "DMA_A_W must be >= IMMEM_A_W" severity failure;
  
  axi_rst <= not s_axi_aresetn;
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
      reg_w_vec => reg_w_vec,
      reg_r_vec => reg_r_vec,
      -- use the following for register access "side effects"
      reg_w_pulse  => reg_w_pulse,
      reg_r_pulse  => reg_r_pulse);

  gen_per_reg: for k in 0 to NUM_REGS-1 generate
  begin
    reg_w(k) <= reg_w_vec(31+k*32 downto k*32);
    reg_r_vec(31+k*32 downto k*32) <= reg_r(k);
  end generate gen_per_reg;

  reg_fr1_w    <= reg_w(REG_FR1);
  reg_fr2_w    <= reg_w(REG_FR2);
-- reg_ctl_w    <= reg_w(REG_CTL);
  reg_status_w <= reg_w(REG_STATUS);
--  reg_hdr_w    <= reg_w(REG_HDR);

  reg_r(REG_FR1)    <= reg_fr1_r;
  reg_r(REG_FR2)    <= reg_fr2_r;
  reg_r(REG_CTL)    <= reg_ctl_r;
  reg_r(REG_STATUS) <= reg_status_r;
  reg_r(REG_HDR)    <= reg_hdr_r;
  
  -- reg 0 = fr1 
  frame_pd_min1  <= reg_fr1_w(G_FRAME_PD_W-1 downto 0);
  reg_fr1_r <= reg_fr1_w;

  -- reg 1 = fr2
  frame_qty_min1 <= reg_fr2_w(G_FRAME_QTY_W-1 downto 0);
  reg_fr2_r <= reg_fr2_w;
   
  -- reg ctl
  reg_ctl_samp: cdc_samp
    generic map(W => 32)
    port map(
      in_data  => reg_w(REG_CTL),
      out_clk  => dac_clk,
      out_data => reg_ctl_w);
  gth_rst   <= reg_w(REG_CTL)(20);
   -- default is to tx syncronously with adc dma.  old ADI way was for dma req to start it.
  tx_unsync      <= reg_ctl_w(31); -- PROBALY WILL GO AWAY
  --  tx_req         = reg_ctl_w(30); -- no longer used
  rand_body      <= reg_ctl_w(30); -- bob sets to scramble frame bodies
  use_lfsr       <= reg_ctl_w(29); -- header contains lfsr
  tx_always      <= reg_ctl_w(28); -- used for dbg to view on scope
  tx_0           <= reg_ctl_w(27); -- header contains zeros
  memtx_circ     <= reg_ctl_w(26); -- circular xmit from mem
  alice_syncing  <= reg_ctl_w(25); -- means I am alice, doing sync
  same_hdrs      <= reg_ctl_w(24); -- tx all the same hdr
  hdr_len_min1   <= reg_ctl_w(19 downto 12); -- in cycles, minus 1
  osamp_min1     <= reg_ctl_w(11 downto 10); -- oversampling: 0=1,1=2,3=4
  body_len_min1  <= reg_ctl_w( 9 downto  0);
  reg_ctl_r <= reg_ctl_w;
  
  -- reg status
  reg_status_r(31 downto 8) <= (others=>'0');
  reg_status_r( 7 downto 4) <= VERSION; -- assign reg3_r[31:8] = 24'h0;
  reg_status_r( 3 downto 0) <= gth_status;
  
  -- reg im
  reg_im_samp: cdc_samp
    generic map(W => 32)
    port map(
      in_data  => reg_w(REG_IM),
      out_clk  => dac_clk,
      out_data => reg_im_w);
  im_hdr  <= reg_im_w(31 downto 16);
  im_body <= reg_im_w(15 downto  0);
  reg_im_r <= reg_w(REG_IM);
  
  -- hdr
  reg_hdr_samp: cdc_samp
    generic map(W=>32)
    port map(
      in_data  => reg_w(REG_HDR),
      out_data => reg_hdr_w,
      out_clk  => dac_clk);
  lfsr_rst_st <= reg_hdr_w(10 downto 0); -- often 11'b10100001111
  reg_hdr_r <= reg_w(REG_HDR);

  frame_pd_samp: cdc_samp
    generic map(W => G_FRAME_PD_W)
    port map(
      in_data  => frame_pd_min1,
      out_clk  => dac_clk,
      out_data => frame_pd_min1_dac);
  
  frame_qty_samp: cdc_samp
    generic map(W => G_FRAME_QTY_W)
    port map(
      in_data  => frame_qty_min1,
      out_clk  => dac_clk,		       
      out_data => frame_qty_min1_dac);



  -- if the module is not in initialization phase, it should go
  -- into reset at a positive edge of dma_xfer_req
  dma_xfer_pul <= dma_xfer_req_d and not dma_xfer_req_dd;
  dma_rst_i    <= dma_rst or dma_xfer_pul;
  dma_wren     <= dma_valid and dma_ready_i;
  dma_ready_i  <= '1'; -- always ready
  dma_ready    <= dma_ready_i;
  process(dma_clk)
  begin
    if (rising_edge(dma_clk)) then

      dma_xfer_req_d  <= dma_xfer_req;
      dma_xfer_req_dd <= dma_xfer_req_d;

      -- we could dma into the IM mem, or the qsdc tx data mem
      if (dma_rst_i = '1') then
        dma_waddr   <= (others=>'0');
      elsif (dma_wren = '1') then
        if (dma_xfer_last = '1') then
          dma_waddr <= (others=>'0');
        else
          dma_waddr <= u_inc(dma_waddr);
        end if;
      end if;

      -- dma_lastaddr held constant until end of the next dma xfer
      if (dma_xfer_last = '1') then
        dma_lastaddr <= u_dec(dma_waddr);
      end if;
      
    end if;
  end process;

  dac_tx_out <= frame_first; -- dac_xfer_out;
   
  mem_ren_last_pulse <= not memtx_circ and dac_valid and mem_ren and mem_raddr_last;
  
  -- The header mem could store pre-emphasis data for IM of header
  -- ad_mem output is registered, so its like
  --   raddr  0000112333
  --   dout   aaaaabbcdd
  -- A legacy of LIBIIO is that the DMA width is 128 bits = 16*2*4
  -- But we store only one "channel"
  immem_din <=   dma_data(15+96 downto 96) & dma_data(15+64 downto 64)
               & dma_data(15+32 downto 32) & dma_data(15    downto  0);
  immem: ad_mem
    generic map(
      ADDRESS_WIDTH => IMMEM_A_W,
      DATA_WIDTH    => 16*4)
    port map(
      clka  => dma_clk,
      wea   => dma_wren,
      addra => dma_waddr(IMMEM_A_W-1 downto 0),
      dina  => immem_din,
      
      clkb  => dac_clk,
      reb   => '1',
      addrb => mem_raddr(IMMEM_A_W-1 downto 0),
      doutb => immem_dout);


  xfer_req_pb: cdc_pulse
    port map(
      in_pulse  => dma_xfer_req, -- host wants to write data
      in_clk    => dma_clk,
      out_pulse => dac_xfer_req,
      out_clk   => dac_clk);


  -- we can reset the DAC side at each positive edge of dma_xfer_req, even if
  -- sometimes the reset is redundant
  dac_rst_int_s <= dac_xfer_req or dac_rst;
  -- TODO: revisit this concept
  
  framer_go <= tx_req_pulse and not alice_syncing;
  frame_ctl_i: frame_ctl
    port map(
      clk => dac_clk,
      rst => dac_rst, -- will reset internal cyc ctr

      -- The period counter is free running
      pd_min1   => frame_pd_min1_dac,
      pd_tic    => frame_pd_tic,
      
      tx_always => tx_always,
      tx_req    => framer_go,
      frame_qty_min1 => frame_qty_min1_dac,

      -- control signals indicate when to transmit
      frame_first => frame_first,
      frame_tx    => frame_tx, -- pulse at beginning of frames
      txing       => txing);   -- remains high during pauses, until after final pause



  hdr_go <= u_if(alice_syncing='1', tx_req_pulse, frame_tx and use_lfsr);
  lfsr_ld <= frame_first or (same_hdrs and frame_tx);
  gen_hdr_i: gen_hdr
    generic map(
      HDR_LEN_W => G_HDR_LEN_W)
    port map(
      clk          => dac_clk,
      rst          => dac_rst, -- was dac_rst_int_s but did not need to be.
      osamp_min1   => osamp_min1,
      hdr_len_min1 => hdr_len_min1,

      gen_en => '0', -- MEANINGLESS		     

      lfsr_state_ld      => lfsr_ld,
      lfsr_state_in      => lfsr_rst_st,
--      lfsr_state_nxt     => lfsr_state_nxt,
--      lfsr_state_nxt_vld => lfsr_state_nxt_vld,
      
      go_pulse => hdr_go,
      en => '1',

      hdr_vld => hdr_vld_i, -- high only during the headers
      hdr_end_pre => hdr_end_pre,
--      cyc_cnt_down => hdr_cyc_cnt_down,		     
      dout => gen_dout);
  hdr_vld <= hdr_vld_i; -- used as a scope trigger
  hdr_data <=   not gen_dout(3) & "100000000000000"
              & not gen_dout(2) & "100000000000000"
              & not gen_dout(1) & "100000000000000"
              & not gen_dout(0) & "100000000000000";
  

  body_go <= hdr_end_pre and rand_body;
  -- for Bob's RANDOM PM body
  gen_body_i : gen_body
    generic map(
      LEN_W => G_BODY_LEN_W,
      CP    => G_BODY_CHAR_POLY,
      D_W   => G_BODY_RAND_BITS)
    port map(
      clk        => dac_clk,
      rst        => dac_rst, -- was dac_rst_int_s, but did not need to be
      osamp_min1 => osamp_min1,
      len_min1   => body_len_min1,

      lfsr_state_ld      => frame_first,
      lfsr_state_in      => body_rst_st,
--    lfsr_state_nxt    => body_lfsr_nxt,
--    lfsr_state_nxt_vld => body_lfsr_nxt_vld,
      
      go_pulse     => body_go,
      en           => '1',
      end_pre      => body_end_pre,
--      cyc_cnt_down => body_cyc_ctr,
      dout_vld => body_vld,
      dout     => body_out);
  -- random data for PM body
  body_data <=   body_out(4*G_BODY_RAND_BITS-1 downto 3*G_BODY_RAND_BITS) & body_pad
	       & body_out(3*G_BODY_RAND_BITS-1 downto 2*G_BODY_RAND_BITS) & body_pad
	       & body_out(2*G_BODY_RAND_BITS-1 downto 1*G_BODY_RAND_BITS) & body_pad
	       & body_out(1*G_BODY_RAND_BITS-1 downto 0*G_BODY_RAND_BITS) & body_pad;


  dac_lastaddr_samp:  cdc_samp
    generic map(
      W => DMA_A_W)
    port map(
      in_data  => dma_lastaddr,
      out_clk  => dac_clk,		       
      out_data => dac_lastaddr);
  

  process(dac_clk)
  begin
    if (rising_edge(dac_clk)) then
      -- dac_tx is a dac_clk domain signal from adc fifo that tells dac when to tx.     
      tx_req_p <= u_if(tx_unsync='1', dac_xfer_req, dac_tx_in)
                  and not dac_rst; -- was dac_rst_int_s;
      tx_req_d <= tx_req_p and not dac_rst; -- was dac_rst_int_s;
      -- This pulse starts transmision:
      tx_req_pulse <= (tx_req_p and not tx_req_d) and not dac_rst; -- was dac_rst_int_s;

-- dac_valid    --------_-_-_----
-- mem_ren      ___-----------__
-- mem_raddr       01234556677
-- mem_raddr_last __________--__
-- mem_dout      ___abcdeffgghh
-- mem_dout_vld  ___-----------__
     
      -- This wont be set if using lfsr.
      mem_ren <= (frame_tx or mem_ren)
                 and not (mem_ren_last_pulse or use_lfsr or dac_rst); -- was dac_rst_int_s);

      if (dac_valid='1') then
        if ((not mem_ren or mem_raddr_last)='1') then
          mem_raddr <= (others=>'0');
        else
          mem_raddr <= u_inc(mem_raddr);
        end if;
      end if;
      
      if ((dac_rst_int_s or not mem_ren)='1') then
        mem_raddr_last <= '0';
      elsif (dac_valid='1') then
        mem_raddr_last <= u_b2b(mem_raddr = dac_lastaddr);
      end if;
      
      mem_dout_vld   <=  not dac_rst_int_s and mem_ren;
      mem_dout_vld_d <= mem_dout_vld;
      
      if (mem_dout_vld='1') then
        immem_dout_d <= immem_dout;
      else
        immem_dout_d <= (others=>'0');
      end if;


      
      if (hdr_vld_i='1') then
        im_data <= im_hdr & im_hdr & im_hdr & im_hdr;
      elsif (body_vld='1') then
        im_data <= im_body & im_body & im_body &im_body;
      else 
        im_data <= (others=>'0');
      end if;

      if (hdr_vld_i='1') then
        pm_data <= hdr_data;
      elsif (body_vld='1') then
        pm_data <= body_data;
      elsif (mem_dout_vld_d='1') then
        pm_data <= immem_dout_d;
      else
        pm_data <= (others=>'0');
      end if;
      
--      dac_xfer_out <= frame_first or (dac_xfer_out and not frame_tx);

    end if;
  end process;

  
  -- The final product of this module.. data for the dac
  dac_data <=   im_data(63 downto 48) & pm_data(63 downto 48)
              & im_data(47 downto 32) & pm_data(47 downto 32)
              & im_data(31 downto 16) & pm_data(31 downto 16)
              & im_data(15 downto 0)  & pm_data(15 downto  0);

end architecture rtl;
