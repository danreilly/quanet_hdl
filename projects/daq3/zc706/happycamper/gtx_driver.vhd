library ieee;
use ieee.std_logic_1164.all;

entity gtx_driver is
  port (
    tx_p : out std_logic;
    tx_n : out std_logic;
    rx_p : in std_logic;
    rx_n : in std_logic;
    
    gtrefclk : in std_logic);
end gtx_driver;


library work;
use work.util_pkg.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

architecture RTL of gtx_driver is

  component my_gtx_wrap is
  generic (
    DRPCLK_PD_NS: integer);
  port (
    drp_sel_pll : in std_logic;
    drp_sel_gt  : in std_logic;
    drp_addr   : in std_logic_vector(8 downto 0);
    drp_clk    : in std_logic;
    drp_din    : in std_logic_vector(15 downto 0);
    drp_dout   : out std_logic_vector(15 downto 0); 
    drp_en     : in std_logic; 
    drp_rdy    : out std_logic; 
    drp_we     : in std_logic;

    txdata: in std_logic_vector(31 downto 0);
    txusrclk_out: out std_logic;
    rxslide : in std_logic;
    rxdata: out std_logic_vector(31 downto 0);
    rxusrclk_out: out std_logic;
    
    tx_p : out std_logic;
    tx_n : out std_logic;
    rx_p : in std_logic;
    rx_n : in std_logic;

    soft_reset_tx: in std_logic;
    soft_reset_rx: in std_logic;
    tx_fsm_reset_done : out std_logic;
    rx_fsm_reset_done : out std_logic;
    
    gtrefclk : in std_logic;
--    extref : in std_logic;
--    sel_extref: in std_logic;

    qpllrefclklost: out std_logic;
    qplllock: out std_logic);   
  end component;

  component lfsr_w 
  generic(
    W: in integer;     -- number of bits to produce per cycle
    CP: in std_logic_vector);
  port (
    d_o: out std_logic_vector(W-1 downto 0); -- valid the cycle after rst or en
    en : in std_logic;
    
    d_i: in std_logic_vector(W-1 downto 0);
    ld : in std_logic; -- loads d_i.  If 0 BER, this syncs lfsr

    rst_st: in std_logic_vector(CP'LENGTH-1 downto 0);
    rst: in std_logic;                  -- a syncronous reset
    err: out std_logic;
    clk: in std_logic);
  end component;

  signal txclk, tx_rst_done, lfsr_rst: std_logic;
  signal txdata: std_logic_vector(31 downto 0);

begin

  lfsr_rst <= not tx_rst_done;  
  lfi: lfsr_w
    generic map(
      W => 32,
      CP => x"100400003")
    port map (
      d_o => txdata, -- valid the cycle after rst or en
      en => '1',
    
      d_i => (others=>'0'),
      ld => '0',

      rst_st => (others => '1'),
      rst  => lfsr_rst,       -- a syncronous reset
--      err  => : out std_logic;
      clk  => txclk);

  gtx_i: my_gtx_wrap
    generic map(
      DRPCLK_PD_NS => 10)
    port map(
      drp_sel_pll => '0',
      drp_sel_gt  => '0',
      drp_addr    => (others => '0'),
      drp_clk     => '0',
      drp_din     => (others => '0'),
--    drp_dout   : out std_logic_vector(15 downto 0); 
      drp_en      => '0',
--    drp_rdy    : out std_logic; 
      drp_we      =>'0',

      txdata      => txdata,
      txusrclk_out => txclk,
      rxslide      => '0',
--    rxdata : out std_logic_vector(31 downto 0);
--    rxusrclk_out: out std_logic;
      
      tx_p => tx_p,
      tx_n => tx_n,
      rx_p => rx_p,
      rx_n => rx_n,

      soft_reset_tx => '0',
      soft_reset_rx => '0',
      tx_fsm_reset_done => tx_rst_done,
      
--    rx_fsm_reset_done : out std_logic;
      
--    extref : in std_logic;
--    sel_extref: in std_logic;

--    qpllrefclklost: out std_logic;
--    qplllock: out std_logic
      
      gtrefclk => gtrefclk);   

  
end RTL;
