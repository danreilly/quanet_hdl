-- uart.vhd
-- Dan Reilly 8/10/2023
--
--
-- Why not use the Xilinx UART?
--   1. You are stuck using AXI
--   2. It always prescales the reference clock by 16.  So if, for example,
--      your reference is 100MHz, you can't do 10Mbaud!
--   3. It can't do exceptional handling of specific chars exactly at
--      the moment they are recieved.  For example XON and XOFF.
--   4. The flags don't tell you when the transmit fifo is full.  Just when it's
--      empty.
--
-- Features of Dan's uart:
--   optional transmit and recieve fifos
--   true XON/XOFF flow control support
--   true RTS/CTS "hardware" flow control support
--   programmable baud rate >10Mbps and parity
--   glitch filtering using hysterisis
--
--   Transmit and Recieve Fifos
--     You can specify how deep you want your transmit and recieve fifos to be.
--     If the transmit fifo depth is zero, well, it's actually one.
--     If the recieve fifo depth is zero, it never holds onto a recieved byte,
--     but rather, indicates when it's valid, which will be for only one cycle.
--
--   Glitch Filtering:
--     Recieved data is sampled at the refclk rate.  The most recent N bits
--     receieved are kept in a shift register (rxd_filt). If they are all ones, we consider
--     that we're getting a one.  After that, they must all be zero before we
--     consider we're getting a zero.  Then after that they must all be ones before
--     we consider we're reciveing a one again.  This way, transient ones or zeros
--     are filtered out.  Note that the depth of this shift register must be considered
--     relative to the referecne clock and the baud rate.  The number of refclk
--     cycles per baud period ought to be at least 2*N.  But regardless, it's
--     expected that N is small, like 3 or maybe 4.
--  
--   XON/XOFF Support:
--     When rx fifo gets almost full, this will transmit an XOFF
--     that will skip ahead of any chars pending in the transmit fifo.
--     Then when rx fifo emties, transmits an XON.  If recieves an XOFF,
--     it halts transmission until it gets an XON or a timeout is exceeded.
--     All this is done automatically.  For debug purpose it maintains
--     counters of XON timouts etc.

-- generics:
--   REFCLK_HZ: frequency of the refclk, in Hz.  A real.
--   DFLT_BAUD_HZ: default baud rate, which must be an integer division of REFCLK_HZ.
--              Will be be overridden when set_params=1.


--   MIN_BAUD_HZ: Smallest expected operational baud frequency.  Specifying this
--              allows implementation to be efficient in the size of its counters.
--   ENABLE_EDGE_ADJ: if 1, reciever looks at transitions.  If they occur early
--     or late, it shortens or lengthens a bit period by one cycle, for just one
--     bit.  This is a quick and dirty attempt at automatic clock recovery.  It
--     may or may not work well in any given application.
--   TXFIFO_DEPTH: may be 0
--   RXFIFO_DEPTH: may be 0


-- Transmitting:
--   Serially, the least signifigant bit goes first
--
--     tx_data       V
--     tx_w       ___-______
--     tx_full    ____---___  (if it happens to be full)
--     tx_mt      ----____--  (if it happens to be mt)
--
--
-- Recieving:
--
--   If RXFIFO_DEPTH>0, wait for rx_vld, then pulse rx_r.
--
--     rx_vld   ____-----___
--     rx_data      VVVVV
--     rx_r     ________-___
--
--   If RXFIFO_DEPTH=0, external circuitry must consume the data, which is
--   valid for only one cycle IN THE REFCLK DOMAIN.  The rx_ovf signal
--   will always be zero.
--
--     rx_vld   ____-___
--     rx_data      V
--




-- least signifigant bit goes first

-- Reception:
--   A falling edge on rxd starts the rxclk running, which causes rx_cyc_ctr_athalf
-- and rx_cyc_ctr_atlim to start pulsing.  rxd_filt_d is sampled at rx_cyc_ctr_athalf,
-- (saved into rxd_samp) which is theoretically in the center of the data eye.  The
-- state rx_st transitions after rx_cyc_ctr_atlim.
--
--  rxd_filt_d       ----___________------------____________________
--  rxclk_run        _____------------------------------------------
--  rx_st            IDL  ST_E      D_E
--  rx_cyc_ctr_athalf ________-__________-__________-__________
--  rx_cyc_ctr_atlim  _____________-__________-__________-__________
--  baud_tog          _________-----______-----______-----___




library ieee;
use ieee.std_logic_1164.all;
package uart_pkg is

  constant UART_NUM_CTRS        : integer := 4;
  constant UART_CTR_SEL_W       : integer := 2;
  constant UART_CTR_SEL_TX      : integer := 0;
  constant UART_CTR_SEL_RX      : integer := 1; -- not including XON or XOFF
  constant UART_CTR_SEL_TX_XON  : integer := 2;
  constant UART_CTR_SEL_TX_XOFF : integer := 3;
  
  -- reminder: parameters given default values below (such as MIN_BAUD_HZ)
  --     in the component declaration need not be specified in your intantiation.
  component uart
    generic (
      REFCLK_HZ: real;
      DFLT_BAUD_HZ: real;
      DFLT_PARITY: std_logic_vector(1 downto 0):="00";
      DFLT_XON_XOFF_EN: std_logic :='0';
      DFLT_RTS_CTS_EN: std_logic :='0';
      MIN_BAUD_HZ: real := 9600.0;
      XOFF_TIMO_CTR_W: integer :=3;  -- timo is 2**CTR_W seconds
      TXFIFO_DEPTH: integer;         -- may be 0
      RXFIFO_DEPTH: integer;        -- may be 0
      CTR_W: integer := 0); -- may be 0
    port (
      refclk  : in  std_logic;
      s_pulse : in std_logic; -- once/sec in refclk domain. for xoff timo
      uart_txd: out std_logic;
      uart_rxd: in std_logic;
      uart_rts: in  std_logic;
      uart_cts: out std_logic;
      rxd_filtered: out std_logic; -- optional use
      
      ifaceclk  : in std_logic; -- clock used for the following signals
      set_params: in std_logic; -- pulse to set refclk_div, parity
      refclk_div_min1 : in std_logic_vector(15 downto 0) := (others=>'0');
      parity    : in  std_logic_vector(1 downto 0) := "00"; -- 00=none, 01=odd, 10=even
      xon_xoff_en : in std_logic;
      rts_cts_en : in std_logic;
      set_flowctl : in std_logic;
      
      tx_data   : in std_logic_vector(7 downto 0);
      tx_w      : in std_logic; -- a pulse
      tx_full   : out std_logic;
      tx_mt     : out std_logic; -- 1 means done tx (flushed out).
      tx_rst    : in  std_logic; -- clears tx state and tx fifo
      
      rx_vld    : out std_logic; -- a level or a pulse (depends on RXFIFO_DEPTH)
      rx_rst    : in  std_logic; -- clears rx state and rx fifo
      rx_data   : out std_logic_vector(7 downto 0);
      rx_r      : in std_logic; -- pulse to read fifo. set to 0 if no RXFIFO

      ctr_sel   : in std_logic_vector(UART_CTR_SEL_W-1 downto 0);
      ctr       : out std_logic_vector(CTR_W-1 downto 0);
      ctrs_clr  : in std_logic;
      
      clr_errs  : in std_logic; -- high clears frame_err and rx_ovf
      frame_err : out  std_logic;
      parity_err: out  std_logic;
      rx_ovf    : out std_logic; -- relevant only if RXFIFO present
      tx_ovf    : out std_logic; -- means you did tx_w while tx_full=1
      saw_xoff_timo : out std_logic;
      dbg_err : out std_logic;
      dbg_rx     : out std_logic_vector(7 downto 0);

      dbg_saw_d  : out std_logic;
      dbg_saw_0 : out std_logic;
      dbg_sri : out std_logic_vector(63 downto 0);
      dbg_sri_vld: out std_logic;
      dbg_rx_st : out std_logic_vector(2 downto 0));

  end component;
end uart_pkg;

library ieee;
use ieee.std_logic_1164.all;
use work.uart_pkg.all;
use work.revokable_fifo_pkg.all;
entity uart is
  generic (
    REFCLK_HZ: real;
    DFLT_BAUD_HZ: real;
    MIN_BAUD_HZ: real := 9600.0;
    DFLT_PARITY: std_logic_vector(1 downto 0):="00";
    DFLT_XON_XOFF_EN : std_logic :='0';
      DFLT_RTS_CTS_EN: std_logic :='0';
    XOFF_TIMO_CTR_W: integer :=3;  -- timo is 2**CTR_W seconds
    TXFIFO_DEPTH: integer;         -- may be 0
    RXFIFO_DEPTH: integer;
    CTR_W: integer := 0); -- may be 0
  port (
    refclk  : in  std_logic;
    s_pulse : in std_logic; -- once/sec in refclk domain. for xoff timo
    uart_txd: out std_logic;
    uart_rxd: in  std_logic;
    uart_rts: in  std_logic;
    uart_cts: out std_logic;
    rxd_filtered: out std_logic; -- optional use
    
    ifaceclk  : in std_logic; -- clock used for the following signals
    set_params: in std_logic; -- pulse to set refclk_div, parity
    refclk_div_min1 : in std_logic_vector(15 downto 0);  -- optional use
    parity    : in  std_logic_vector(1 downto 0) := "00"; -- 00=none, 01=odd, 10=even
    xon_xoff_en : in std_logic;
    rts_cts_en : in std_logic;
    set_flowctl : in std_logic;
      
    tx_data   : in std_logic_vector(7 downto 0);
    tx_w      : in std_logic; -- a pulse
    tx_full   : out std_logic;
    tx_mt     : out std_logic;
    tx_rst    : in  std_logic;
    
    rx_vld    : out std_logic; -- a level or a pulse (depends on RXFIFO_DEPTH)
    rx_rst    : in  std_logic; -- resets rxfifo, prevents reception
    rx_data   : out std_logic_vector(7 downto 0);
    rx_r      : in std_logic; -- pulse to read fifo. set to 0 if no RXFIFO

    ctr_sel   : in std_logic_vector(UART_CTR_SEL_W-1 downto 0);
    ctr       : out std_logic_vector(CTR_W-1 downto 0);    
    ctrs_clr  : in std_logic;
    
    clr_errs  : in std_logic; -- high clears errors and ovf indications
    frame_err : out  std_logic;
    parity_err: out  std_logic;
    rx_ovf    : out std_logic; -- relevant only if RXFIFO present
    tx_ovf    : out std_logic; -- can happen even when there's no TXFIFO
    saw_xoff_timo : out std_logic;
    dbg_err      : out std_logic;
    dbg_rx     : out std_logic_vector(7 downto 0);

    dbg_saw_d : out std_logic;    
    dbg_saw_0 : out std_logic;
    dbg_sri : out std_logic_vector(63 downto 0);
    dbg_sri_vld: out std_logic;
    dbg_rx_st : out std_logic_vector(2 downto 0));

end uart;

library ieee;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_samp_pkg.all;
use work.cdc_pulse_pkg.all;
use work.event_ctr_pkg.all;
architecture struct of uart is


  constant MAX_BIT_CYCS: integer := integer(REFCLK_HZ/MIN_BAUD_HZ);
  constant BIT_CYCS_W: integer := u_bitwid(MAX_BIT_CYCS-1);

  -- conversion to int using integer() does *rounding*
  constant DFLT_BIT_CYCS : integer := integer(REFCLK_HZ/DFLT_BAUD_HZ);
  constant DFLT_BIT_CYCS_MIN1 : std_logic_vector(BIT_CYCS_W-1 downto 0) :=
    std_logic_vector(to_unsigned(DFLT_BIT_CYCS-1, BIT_CYCS_W));

  constant RXD_FILT_CYCS: integer := 3;

  constant TXMEM_A_W: integer:= u_bitwid(TXFIFO_DEPTH-1);
  constant RXMEM_A_W: integer:= u_bitwid(RXFIFO_DEPTH-1);

  

  signal txmem_waddr, txmem_raddr: unsigned(TXMEM_A_W-1 downto 0);
  signal rxmem_waddr, rxmem_raddr: unsigned(RXMEM_A_W-1 downto 0);

  signal event: std_logic_vector(UART_NUM_CTRS-1 downto 0);
  
  type ctr_array_t is array(0 to UART_NUM_CTRS-1) of std_logic_vector(CTR_W-1 downto 0);
  signal ctr_a: ctr_array_t := (others=>(others=>'0'));


       
  signal refclk_div_min1_refclk, refclk_div_min1_i: std_logic_vector(15 downto 0) :=
            std_logic_vector(to_unsigned(DFLT_BIT_CYCS-1, 16));
  signal parity_refclk, parity_i: std_logic_vector(1 downto 0) := DFLT_PARITY;
  signal bit_cycs_min1, bit_cycs_div2: std_logic_vector(BIT_CYCS_W-1 downto 0);
  signal tx_cyc_ctr: std_logic_vector(BIT_CYCS_W-1 downto 0)
    := DFLT_BIT_CYCS_MIN1;
  signal tx_cyc_ctr_atlim, tx_cyc_ctr_atlim_d: std_logic:='0';

  signal txfifo_r, txfifo_r_vld, txfifo_r_ic, txfifo_w_mt,
         tx_w_vld, tx_w_rc: std_logic :='0';
  signal txbuf, txfifo_dout, tx_sro: std_logic_vector(7 downto 0) := (others=>'0');
  signal tx_bit_ctr, rx_bit_ctr: std_logic_vector(2 downto 0) :=  (others=>'0');
  signal tx_bit_ctr_atlim, rx_bit_ctr_atlim, tx_parity, tx_pend: std_logic:='0';
  signal rts_i, txd_i, txfifo_mt: std_logic := '1';

  signal tx_full_i, tx_afull_i, tx_full_out, rxd_samp, sro_ld: std_logic := '0';

  type tx_st_t is (IDL_E, ST_E, D_E, P_E, SP_E, W_E);
  signal rx_st, tx_st: tx_st_t := IDL_E;
  signal tx_st_idl, tx_st_idl_rc: std_logic;

  signal rxd_filt: std_logic_vector(RXD_FILT_CYCS-1 downto 0) := (others=>'1');
  signal rxd_filt_d, rxd_filt_dd, rxd_change: std_logic := '1';
  signal rx_sri, rx_sri_d: std_logic_vector(7 downto 0) := (others=>'0');

  signal rxclk_run, rx_cyc_ctr_atlim, rx_cyc_ctr_athalf, rx_cyc_ctr_athalf_d, baud_tog,
    rx_edge_early, rx_edge_late, rx_edge_adj: std_logic :='0';
  signal rx_bit_cycs, rx_cyc_ctr: std_logic_vector(BIT_CYCS_W-1 downto 0) := (others=>'0');

  signal rx_parity, parity_err_r, parity_err_i, parity_err_p,
    frame_err_r, frame_err_i, frame_err_p, rx_ovf_r, rx_ovf_i,
    tx_ovf_i, rx_ovf_p: std_logic :='0';

  signal dbg_saw_d_i, dbg_saw_0_i: std_logic := '0';
  signal rx_sri_vld, rxfifo_w, rxfifo_full, rxfifo_afull, rxfifo_afull_d,
    rxfifo_w_mt, rxfifo_mt: std_logic := '0';
  signal adj_ctr: signed(3 downto 0) := (others=>'0');
--  signal edge_adj_ctr: unsigned(2 downto 0) := (others=>'0');
  signal edge_adj_ctr_atlim, adj_ctr_athi, adj_ctr_atlo, rx_rst_rc: std_logic:='0';
  signal tx_xon, tx_xon_pend, tx_xoff, tx_xoff_pend, rx_xon, rx_xoff,
    cts_blocked,
    rx_blocked, tx_blocked: std_logic := '0';
  signal xon_xoff_en_refclk, xon_xoff_en_i: std_logic := DFLT_XON_XOFF_EN;
  signal rts_cts_en_refclk, rts_cts_en_i: std_logic := DFLT_RTS_CTS_EN;
  
  signal xoff_timo_ctr: std_logic_vector(XOFF_TIMO_CTR_W-1 downto 0) :=(others=>'0');
  signal xoff_timo, xoff_timo_p, saw_xoff_timo_i: std_logic :='0';
  signal dbg_sav, dbg_ctr_atlim, dbg_sav_full: std_logic:='0';
  signal dbg_sav_sri: std_logic_vector(63 downto 0) := (others=>'1');
  signal dbg_ctr: std_logic_vector(6 downto 0);

  signal set_params_rc: std_logic;

begin

  assert (abs(REFCLK_HZ/DFLT_BAUD_HZ - real(DFLT_BIT_CYCS))<0.1)
    report "DFLT_BAUD_HZ must be integer division of REFCLK_HZ."
--    REF/BAUD = "
--      & real'image(REFCLK_HZ/DFLT_BAUD_HZ) & " is not close enough to "
--      & integer'image(DFLT_BIT_CYCS) & " because "
--      & real'image(abs(REFCLK_HZ/DFLT_BAUD_HZ - real(DFLT_BIT_CYCS)))
    severity error;
  assert (DFLT_BIT_CYCS>1)
    report "DFLT_BAUD_HZ must be half of REFCLK_HZ or less"
    severity error;  
  
  bit_cycs_min1 <= refclk_div_min1_i(BIT_CYCS_W-1 downto 0);

  bit_cycs_div2 <= std_logic_vector(shift_right(unsigned(bit_cycs_min1)+3,1));
    
  uart_txd <= txd_i;


  -- TODO: what if XOFF got lost?  rx_blocked=1 but remote guy will still send.
  -- maybe we should use rxfifo_afull and not rxfifo_afull_d
  tx_xoff <= xon_xoff_en_i and not rx_blocked and rxfifo_afull;
  tx_xon  <= xon_xoff_en_i and     rx_blocked and rxfifo_w_mt;
  uart_cts <= not rts_cts_en_i or not cts_blocked;

  tx_st_idl_samp: cdc_samp
    generic map(W=>1)
    port map (
      in_data(0)  => tx_st_idl,
      out_data(0) => tx_st_idl_rc,
      out_clk     => ifaceclk);


  
  gen_txfifo: if (TXFIFO_DEPTH>0) generate  

    txfifo: revokable_fifo
    generic map(
      A_W=>TXMEM_A_W,
      D_W=>8,
      AFULL_OCC => 2**TXMEM_A_W-1,
      HAS_FIRST_WORD_FALLTHRU => false,
      HAS_RD_REVOKE => false,
      HAS_WR_REVOKE =>false)
    port map(
      wclk => ifaceclk,
      rst  => tx_rst,
      din => tx_data,
      wr_en => tx_w,
      wr_revoke => '0',
      wr_commit => '1',
      full => tx_full_i,
      w_mt => txfifo_w_mt,

      rclk => refclk,
      rd_en => txfifo_r,
      rd_revoke => '0',
      rd_commit => '1',
      dout => txfifo_dout, -- valid cycle after rd_en
      mt   => txfifo_mt);
  end generate gen_txfifo;
  
  gen_ntxfifo: if (TXFIFO_DEPTH<=0) generate  
    tx_w_vld <= tx_w and not tx_full_i; -- bug fix 4/1/2020
    process (ifaceclk)
    begin
      if (rising_edge(ifaceclk)) then
        
        -- for simultaneous tx_w and txfifo_r_ic, it stays "full".
        -- TODO: should I keep that?
        if (tx_w='1') then
          tx_full_i <= '1';
        elsif (txfifo_r_ic='1') then
          tx_full_i <= '0';
        end if;
        if ((tx_w and not tx_full_i)='1') then
          txfifo_dout <= tx_data;
        end if;
      end if;
    end process;

    txfifo_w_mt   <= not tx_full_i;

    txfifo_r_vld <= txfifo_r and not txfifo_mt;
    process (refclk) -- gen if no txfifo
    begin
      if (rising_edge(refclk)) then
        if (tx_w_rc='1') then
          txfifo_mt <= '0';
        elsif (txfifo_r_vld='1') then
          txfifo_mt <= '1';
        end if;
      end if;
    end process;
    tx_w_pb: cdc_pulse
      port map(
        in_pulse  => tx_w_vld,
        in_clk    => ifaceclk,
        out_pulse => tx_w_rc,
        out_clk   => refclk);
    tx_r_pb: cdc_pulse
      port map(
        in_pulse  => txfifo_r_vld,
        in_clk    => refclk,
        out_pulse => txfifo_r_ic,
        out_clk   => ifaceclk);

  end generate gen_ntxfifo;

  tx_mt <= txfifo_w_mt and tx_st_idl_rc;
  
  tx_full <=     tx_full_i;


  
  -- TODO: can tx_blocked block a transmission tx_xoff or tx_on?  should it?
  sro_ld <= tx_cyc_ctr_atlim_d and u_b2b(tx_st=ST_E) and not tx_blocked;
  txfifo_r <= sro_ld and not tx_xoff_pend and not tx_xon_pend;

  frame_err_pb: cdc_pulse
    port map(
      in_pulse  => frame_err_r,
      in_clk    => refclk,
      out_pulse => frame_err_p,
      out_clk   => ifaceclk);
  
  parity_err_pb: cdc_pulse
    port map(
      in_pulse  => parity_err_r,
      in_clk    => refclk,
      out_pulse => parity_err_p,
      out_clk   => ifaceclk);

  rx_ovf_pb: cdc_pulse
    port map(
      in_pulse  => rx_ovf_r,
      in_clk    => refclk,
      out_pulse => rx_ovf_p,
      out_clk   => ifaceclk);

  xoff_timo_pb: cdc_pulse
    port map(
      in_pulse  => xoff_timo,
      in_clk    => refclk,
      out_pulse => xoff_timo_p,
      out_clk   => ifaceclk);

  set_params_pb: cdc_pulse
    port map(
      in_pulse  => set_params,
      in_clk    => ifaceclk,
      out_pulse => set_params_rc,
      out_clk   => refclk);
  
  process (ifaceclk)
  begin
    if (rising_edge(ifaceclk)) then 

      frame_err_i  <= frame_err_p  or (not clr_errs and frame_err_i);
      parity_err_i <= parity_err_p or (not clr_errs and parity_err_i);
      rx_ovf_i     <= rx_ovf_p     or (not clr_errs and rx_ovf_i);
      tx_ovf_i     <= (tx_w and tx_full_i) or (not clr_errs and tx_ovf_i);
      saw_xoff_timo_i <= xoff_timo_p or (not clr_errs and saw_xoff_timo_i);
    end if;
  end process;
  rx_ovf     <= rx_ovf_i and u_b2b(RXFIFO_DEPTH>0);
  tx_ovf     <= tx_ovf_i;
  frame_err  <= frame_err_i;
  parity_err <= parity_err_i;
  saw_xoff_timo <= saw_xoff_timo_i;


  tx_pend <= (not txfifo_mt and not tx_blocked
              and (not rts_cts_en_i or rts_i))
             or tx_xon_pend or tx_xoff_pend;

    
  dbg_saw_d <= dbg_saw_d_i;
  dbg_saw_0  <= dbg_saw_0_i;

  rxclk_run <= u_b2b((rx_st /= IDL_E) and (rx_st /= W_E));
  dbg_sri <= dbg_sav_sri;
  dbg_sri_vld <= dbg_sav_full;


  dbg_err <= parity_err_r or frame_err_r;


  refclk_div_samp: cdc_samp
    generic map( W => 16)
    port map (
      in_data   => refclk_div_min1,
      out_data  => refclk_div_min1_refclk,
      out_clk   => refclk);
  parity_samp: cdc_samp
    generic map( W => 4)
    port map (
      in_data(1 downto 0)   => parity,
      in_data(2)            => xon_xoff_en,
      in_data(3)            => rts_cts_en,
      out_data(1 downto 0)  => parity_refclk,
      out_data(2)           => xon_xoff_en_refclk,
      out_data(3)           => rts_cts_en_refclk,
      out_clk   => refclk);


  
  process (refclk)
  begin
    if (rising_edge(refclk)) then
      if (set_params_rc='1') then
        refclk_div_min1_i <= refclk_div_min1_refclk;
        parity_i          <= parity_refclk;
      end if;
      if (set_flowctl='1') then
        xon_xoff_en_i     <= xon_xoff_en_refclk;
        rts_cts_en_i      <= rts_cts_en_refclk;
      end if;        
      -- If tx xoff or xon is pending, sro_ld will load it.
      if (tx_xoff='1') then
        tx_xoff_pend <= '1';
      elsif ((tx_xon or sro_ld)='1') then
        -- a tx_xon can cancel a pending xoff
        tx_xoff_pend <= '0';
      end if;
      if (tx_xon='1') then
        tx_xon_pend <= not (tx_xoff_pend and sro_ld);
      elsif (sro_ld='1') then
        tx_xon_pend <= '0';
      end if;

      rts_i <= uart_rts;

      if ((tx_cyc_ctr_atlim or tx_rst)='1') then
        tx_cyc_ctr <= bit_cycs_min1;
        tx_cyc_ctr_atlim <= '0';
      else
        tx_cyc_ctr <= std_logic_vector(unsigned(tx_cyc_ctr)-1);
        tx_cyc_ctr_atlim <= u_b2b(unsigned(tx_cyc_ctr)=1);
      end if;

      tx_cyc_ctr_atlim_d <= tx_cyc_ctr_atlim;

--      txfifo_r is usually same as sro_ld
      if (sro_ld='1') then
        if (tx_xoff_pend='1') then
          tx_sro <= "00010011";
        elsif (tx_xon_pend='1') then
          tx_sro <= "00010001";
        else
          tx_sro <=txfifo_dout;
        end if;
        tx_parity <= u_if(parity_i="01",'1','0');
      elsif ((tx_st=D_E) and (tx_cyc_ctr_atlim='1')) then
        tx_sro <= '0'&tx_sro(7 downto 1);
        tx_parity <= tx_parity xor tx_sro(0);
      end if;

    
      if (tx_cyc_ctr_atlim='1') then

        -- tx_st          DDDDDDD     DDDPP
        -- bit_ctr       00011223 ... 677000
        -- bit_ctr_atlim ________     _--___
        if ((tx_st/=D_E) or (tx_bit_ctr_atlim='1')) then
          tx_bit_ctr <= (others=>'0');
          tx_bit_ctr_atlim <= '0';
        else
          tx_bit_ctr <= std_logic_vector(unsigned(tx_bit_ctr)+1);
          tx_bit_ctr_atlim <= u_b2b(tx_bit_ctr="110");
        end if;

        case tx_st is
          when IDL_E =>
            if (tx_pend='1') then
              tx_st <= ST_E;
            end if;
          when ST_E =>
            txd_i <= '0';
            tx_st <= D_E;
          when D_E =>
            txd_i <= tx_sro(0);
            if (tx_bit_ctr_atlim='1') then
              if (parity_i="00") then
                tx_st <= SP_E;
              else
                tx_st <= P_E;
              end if;
            end if;
          when P_E => -- parity
            txd_i <= tx_parity;
            tx_st <= SP_E;
          when SP_E =>
            txd_i <= '1';
            if (tx_pend='1') then
              tx_st <= ST_E;
            else
              tx_st <= IDL_E;
            end if;
          when W_E => -- unused
            tx_st <= IDL_E;
        end case;
      end if;

      tx_st_idl <= u_b2b(tx_st = IDL_E);

      
      -- simple hysteresis filtering
      rxd_filt   <= TO_X01(uart_rxd) & rxd_filt(RXD_FILT_CYCS-1 downto 1);
      rxd_filt_d <= u_if(rxd_filt_d='1', u_or(rxd_filt), u_and(rxd_filt));
      rxd_filt_dd <= rxd_filt_d;

      rx_rst_rc <= rx_rst;

      if ((not dbg_sav_full)='1') then
        dbg_sav_sri <= dbg_sav_sri(62 downto 0) & rxd_filt_d; -- (RXD_FILT_CYCS-1);
      end if;
      if (dbg_sav='1') then
        dbg_ctr <= std_logic_vector(unsigned(dbg_ctr)+1);
      else
        dbg_ctr <= (others=>'0');
      end if;
      dbg_ctr_atlim <= u_b2b(unsigned(dbg_ctr)=57);
      
      if ((rx_st=IDL_E) and ((not rxd_filt_d and not dbg_sav_full)='1')) then
        dbg_sav<='1';
      elsif (dbg_ctr_atlim='1') then
        dbg_sav<='0';
      end if;
      if (clr_errs='1') then
        dbg_sav_full<='0';
      elsif (dbg_ctr_atlim='1') then
        dbg_sav_full<='1';
      end if;
      
--      if (   rx_rst_rc
--          or (rx_cyc_ctr_athalf_d and rxd_samp and u_b2b(rx_st=ST_E))) then
--             -- corrupt or no start bit
--        rxclk_run <= '0';
--      elsif (rxclk_run='0') then
--        rxclk_run <= not rxd_filt_d and u_b2b(rx_st=IDL_E);
--      end if;

      if (rxclk_run='0') then
        rx_bit_cycs <= bit_cycs_min1;
        rx_cyc_ctr <= rx_bit_cycs;
        rx_cyc_ctr_atlim <= '0';
        rx_cyc_ctr_athalf <= '0';
        baud_tog <= '0';
      else
        if (rx_cyc_ctr_atlim='1') then
          baud_tog <= '0';
          rx_cyc_ctr_atlim  <= '0';
          rx_cyc_ctr_athalf <= '0';
          rx_cyc_ctr <= rx_bit_cycs;          
          -- rx_edge_adj <= adj_ctr_athi or adj_ctr_atlo;
--          if (edge_adj_en='1') then
--            if (adj_ctr_athi='1') then -- simple clock recovery
--              rx_cyc_ctr <= std_logic_vector(unsigned(rx_bit_cycs) + 1);
--            elsif (adj_ctr_atlo='1') then
--              rx_cyc_ctr <= std_logic_vector(unsigned(rx_bit_cycs) - 1);
--            end if;
--          else
--            rx_cyc_ctr <= rx_bit_cycs;
--          end if;
--          if ((adj_ctr_athi or adj_ctr_atlo)='1') then
--            adj_ctr <= (others=>'0');
--          elsif (rx_st=SP_E) then
--            if (adj_ctr>0) then
--              adj_ctr <= adj_ctr-1;
--            elsif (adj_ctr<0) then
--              adj_ctr <= adj_ctr+1;
--            end if;
--          end if;
        else
--          if ((rx_edge_early='1') and (adj_ctr>-6)) then
--            adj_ctr <= adj_ctr-1;
--          elsif ((rx_edge_late='1') and (adj_ctr<7)) then
--            adj_ctr <= adj_ctr+1;
--          end if;
          rx_cyc_ctr        <= std_logic_vector(unsigned(rx_cyc_ctr)-1);
          rx_cyc_ctr_atlim  <= u_b2b(unsigned(rx_cyc_ctr)=1);
          rx_cyc_ctr_athalf <= u_b2b(rx_cyc_ctr=bit_cycs_div2);
          baud_tog <= baud_tog or rx_cyc_ctr_athalf;
        end if;
      end if;
      rx_cyc_ctr_athalf_d <= rx_cyc_ctr_athalf;
      rx_edge_early <=     baud_tog and (rxd_filt_d xor rxd_filt_dd)
                       and rxclk_run and not rx_cyc_ctr_atlim;
      rx_edge_late  <= not baud_tog and (rxd_filt_d xor rxd_filt_dd)
                       and rxclk_run and not rx_cyc_ctr_atlim;
      adj_ctr_athi <= u_b2b(adj_ctr=7);
      adj_ctr_atlo <= u_b2b(adj_ctr=-6);

--      if (clr_errs='1') then
--        edge_adj_ctr <= to_unsigned(0,3);
--      elsif (((adj_ctr_athi or adj_ctr_atlo) and edge_adj_ctr_atlim
--              and not edge_adj_ctr_atlim)='1') then
--        edge_adj_ctr <= edge_adj_ctr +1;
--      end if;
--      edge_adj_ctr_atlim <= u_and(std_logic_vector(edge_adj_ctr));


      dbg_saw_d_i  <= (u_b2b(rx_st=D_E) or dbg_saw_d_i) and not clr_errs;
      dbg_saw_0_i  <= (not rxd_filt_d or dbg_saw_0_i) and not clr_errs;
      dbg_rx_st    <= std_logic_vector(to_unsigned(tx_st_t'pos(rx_st),3));
      
      if (rx_rst_rc='1') then
        rx_st <= IDL_E;
      else
        case rx_st is
          when IDL_E => -- rxclk is not running
            if (rxd_filt_d='0') then
              rx_st <= ST_E;
            end if;
          when ST_E => -- rxclk is running
            if ((rx_cyc_ctr_athalf_d and rxd_samp)='1') then
              rx_st <= IDL_E;
            elsif (rx_cyc_ctr_atlim='1') then
              rx_st <= D_E;
            end if;
          when D_E =>
            if ((rx_cyc_ctr_atlim and rx_bit_ctr_atlim)='1') then
              if (parity_i="00") then
                rx_st <= SP_E;
              else
                rx_st <= P_E;
              end if;
            end if;
          when P_E => -- parity
            if (rx_cyc_ctr_atlim='1') then
              rx_st <= SP_E;
            end if;
          when SP_E =>
            if (rx_cyc_ctr_athalf='1') then
              if (rxd_filt_d='1') then
                rx_st <= IDL_E;
              else
                rx_st <= W_E;
              end if;
            end if;
          when W_E => -- wait for stop bit high
            if (rxd_filt_d='1') then
               rx_st <= IDL_E;
            end if;
        end case;
      end if;
        
      if (rx_cyc_ctr_athalf='1') then
        rxd_samp <= rxd_filt_d; -- sample in middle of eye
        if (rx_st=ST_E) then
          rx_parity <= u_b2b(parity_i="01");
        elsif (rx_st=D_E) then
          rx_sri <= rxd_filt_d & rx_sri(7 downto 1);
          rx_parity <= rx_parity xor rxd_filt_d;
        elsif (rx_st=P_E) then
          rx_parity <= rx_parity xor rxd_filt_d;
        end if;
      end if;
      
      if (rx_st/=D_E) then
        rx_bit_ctr <= (others=>'0');
        rx_bit_ctr_atlim <= '0';
      elsif (rx_cyc_ctr_atlim='1') then
        rx_bit_ctr <= std_logic_vector(unsigned(rx_bit_ctr)+1);
        rx_bit_ctr_atlim <= u_b2b(unsigned(rx_bit_ctr)=6);
      end if;
      if ((rx_st=SP_E) and (rx_cyc_ctr_athalf='1')) then
        dbg_rx <= rx_sri;
      end if;
      rx_sri_vld <= u_b2b(rx_st=SP_E) and rx_cyc_ctr_athalf and rxd_filt_d
                    and (u_b2b(parity_i="00") or not rx_parity);
      parity_err_r <= u_b2b(rx_st=SP_E) and rx_cyc_ctr_athalf and rxd_filt_d
                      and not u_b2b(parity_i="00") and rx_parity;
      frame_err_r  <= u_b2b(rx_st=SP_E) and rx_cyc_ctr_athalf and not rxd_filt_d;
      rx_ovf_r <= rxfifo_full and rxfifo_w;

      cts_blocked <= rxfifo_afull or (cts_blocked and not rxfifo_w_mt);
      rx_blocked <= tx_xoff or (rx_blocked and not tx_xon);
      tx_blocked <= rx_xoff or (tx_blocked and not (rx_xon or xoff_timo));
      rxfifo_afull_d <= rxfifo_afull;
      
      rxfifo_w <= rx_sri_vld and not (rx_xoff or rx_xon);

      if ((not tx_blocked or not xon_xoff_en_i)='1') then
        xoff_timo_ctr <= (others=>'0');
      elsif (s_pulse='1') then
        xoff_timo_ctr <= std_logic_vector(unsigned(xoff_timo_ctr)+1);
      end if;
      xoff_timo <= u_and(std_logic_vector(xoff_timo_ctr));
      
    end if;
  end process;

  rxd_filtered <= rxd_filt_d;

  rx_xoff <= u_b2b(rx_sri="00010011") and rx_sri_vld and xon_xoff_en_i;
  rx_xon  <= u_b2b(rx_sri="00010001") and rx_sri_vld and xon_xoff_en_i;

  gen_rxfifo: if (RXFIFO_DEPTH>0) generate
    rxfifo: revokable_fifo
      generic map(
        A_W=>RXMEM_A_W,
        D_W=>8,
        AFULL_OCC => 2**RXMEM_A_W-4,
        HAS_FIRST_WORD_FALLTHRU => true,
        HAS_RD_REVOKE => false,
        HAS_WR_REVOKE =>false)
      port map(
        wclk => refclk,
        rst  => rx_rst,
        din => rx_sri,
        wr_en => rxfifo_w,
        wr_revoke => '0',
        wr_commit => '1',
        full  => rxfifo_full,
        afull => rxfifo_afull,
        w_mt  => rxfifo_w_mt,

        rclk => ifaceclk,
        rd_en => rx_r,
        rd_revoke => '0',
        rd_commit => '1',
        dout => rx_data,
        mt   => rxfifo_mt);
    rx_vld <= not rxfifo_mt;
  end generate gen_rxfifo;    
  gen_nrxfifo: if (RXFIFO_DEPTH<=0) generate
    rx_data <= rx_sri;
    rx_vld  <= rxfifo_w;
    rxfifo_full <= '0';
  end generate gen_nrxfifo;


  event(UART_CTR_SEL_TX)      <= txfifo_r;
  event(UART_CTR_SEL_RX)      <= rxfifo_w; -- not including XON or XOFF
  event(UART_CTR_SEL_TX_XOFF) <= tx_xoff;
  event(UART_CTR_SEL_TX_XON)  <= tx_xon;
  gen_ctrs: for i in 0 to UART_NUM_CTRS-1 generate
  begin
    event_ctr0: event_ctr
      generic map(
        W => CTR_W)
      port map (
        clk    => refclk,
        event  => event(i),

        rclk   => ifaceclk,
        cnt    => ctr_a(i),
        clr    => ctrs_clr);
  end generate gen_ctrs;
  ctr <= ctr_a(to_integer(unsigned(ctr_sel)));
  
end architecture struct;
