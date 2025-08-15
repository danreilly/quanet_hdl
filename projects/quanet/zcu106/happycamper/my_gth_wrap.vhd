library ieee;
use ieee.std_logic_1164.all;

entity my_gth_wrap is
  generic (
    DRPCLK_PD_NS: integer);
  port (
    freerun_clk : in std_logic;
    
    drp_sel_pll : in std_logic;
    drp_sel_gt  : in std_logic;
    drp_addr   : in std_logic_vector(9 downto 0);
    drp_clk    : in std_logic;
    drp_din    : in std_logic_vector(15 downto 0);
    drp_dout   : out std_logic_vector(15 downto 0); 
    drp_en     : in std_logic; 
    drp_rdy    : out std_logic; 
    drp_we     : in std_logic;

    txdata    : in std_logic_vector(31 downto 0);
    txusrclk_out : out std_logic;
    rxdata      : out std_logic_vector(31 downto 0);

    rxusrclk_out: out std_logic;
    rxusrclk_vld: out std_logic;
    
    tx_p : out std_logic;
    tx_n : out std_logic;
    rx_p : in std_logic;
    rx_n : in std_logic;

    soft_reset_tx: in std_logic;
    soft_reset_rx: in std_logic;
    tx_fsm_reset_done : out std_logic;
    rx_fsm_reset_done : out std_logic;
    
    gtrefclk : in std_logic;

    eyescanreset_in : in std_logic;
    rxrate_in: in std_logic_vector ( 2 downto 0 );
    txdiffctrl_in : in std_logic_vector ( 4 downto 0 );    
    txpostcursor_in : in std_logic_vector ( 4 downto 0 );
    txprecursor_in : in std_logic_vector ( 4 downto 0 );
    rxlpmen_in : in std_logic;

--    extref : in std_logic;
--    sel_extref: in std_logic;

    qpllrefclklost: out std_logic; -- not connected!!!
    qplllock: out std_logic);   -- for dbg
end my_gth_wrap;


library work;
use work.util_pkg.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

architecture rtl of my_gth_wrap is
  --  attribute DowngradeIPIdentifiedWarnings: string;
  --  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";

  component my_gth is
  port ( 
    gtwiz_userclk_tx_active_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_active_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_clk_freerun_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_all_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_pll_and_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_pll_and_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_cdr_stable_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 31 downto 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 31 downto 0 );
    gtrefclk00_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    drpaddr_in : in STD_LOGIC_VECTOR ( 9 downto 0 );
    drpclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drpen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpwe_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    eyescanreset_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxn_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gthrxp_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rx8b10ben_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxlpmen_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxrate_in : in STD_LOGIC_VECTOR ( 2 downto 0 );
    rxusrclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    rxusrclk2_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    tx8b10ben_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txctrl0_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    txctrl1_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    txctrl2_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    txdiffctrl_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txpostcursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txprecursor_in : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txusrclk_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    txusrclk2_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drprdy_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxn_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gthtxp_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtpowergood_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxctrl0_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rxctrl1_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rxctrl2_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxctrl3_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxoutclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txoutclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 ));
  end component;

  signal txoutclk, rxoutclk, rx_fsm_reset_done_i,
    txoutclk_rst, rxoutclk_rst,
    txusrclk, rxusrclk, tx_rst_done, rx_rst_done: std_logic;
  signal rxpmaresetdone, txpmaresetdone: std_logic;
  
begin

  -- According to the Xilinx example design,
  -- "The TX user clocking helper block should be held in reset until
  -- the clock source of that block is known to be stable."
  rxoutclk_rst <= not rxpmaresetdone;
  rxoutclk_bufg: BUFG_GT
    port map(
      CE => '1',
      CEMASK => '0',
      CLR => rxoutclk_rst,
      CLRMASK => '0',
      DIV => "000",
      I => rxoutclk,
      O => rxusrclk);
  rxusrclk_out <= rxusrclk;
  
  txoutclk_rst <= not txpmaresetdone;
  txoutclk_bufg: BUFG_GT
    port map (
      CE => '1',
      CEMASK => '0',
      CLR => txoutclk_rst,
      CLRMASK => '0',
      DIV => "000",
      I=>txoutclk,
      O=>txusrclk);
  txusrclk_out <= txusrclk;

  qpllrefclklost <= '0';
  qplllock <= '0';


  rxusrclk_vld <= rx_fsm_reset_done_i;
  rx_fsm_reset_done <= rx_fsm_reset_done_i;
  gthi: my_gth
    port map( 
    gtwiz_userclk_tx_active_in => "1",
    gtwiz_userclk_rx_active_in => "1",
    gtwiz_reset_clk_freerun_in(0) => freerun_clk,
    gtwiz_reset_all_in(0) => '0',
    gtwiz_reset_tx_pll_and_datapath_in(0) => soft_reset_tx,
    gtwiz_reset_tx_datapath_in(0)         => '0',
    gtwiz_reset_rx_pll_and_datapath_in(0) => soft_reset_rx,
    gtwiz_reset_rx_datapath_in(0)         => '0',
--    gtwiz_reset_rx_cdr_stable_out       => '0',
    gtwiz_reset_tx_done_out(0) => tx_fsm_reset_done,
    gtwiz_reset_rx_done_out(0) => rx_fsm_reset_done_i,

    gtwiz_userdata_tx_in  => txdata,
    gtwiz_userdata_rx_out => rxdata,
    
    gtrefclk00_in(0) => gtrefclk,
    
--    qpll0outclk_out(0) => qplllock, -- for dbg
--    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );

    gthrxp_in(0)  => rx_p,
    gthrxn_in(0)  => rx_n,
    gthtxp_out(0) => tx_p,
    gthtxn_out(0) => tx_n,
    
    drpaddr_in    => drp_addr,
    drpclk_in(0)  => drp_clk,
    drpdi_in      => drp_din,
    drpen_in(0)   => drp_en,
    drpwe_in(0)   => drp_we,
    drpdo_out     => drp_dout,
    drprdy_out(0) => drp_rdy,
    
    eyescanreset_in(0) => eyescanreset_in,
    rx8b10ben_in    => "1",
    rxlpmen_in(0)   => rxlpmen_in,
    rxrate_in => rxrate_in,
    rxusrclk_in(0)  => rxusrclk,
    rxusrclk2_in(0) => rxusrclk,
    tx8b10ben_in    => "1",
    
    txctrl0_in  => (others=>'0'),
    txctrl1_in  => (others=>'0'),
    txctrl2_in  => (others=>'0'),
    txdiffctrl_in => txdiffctrl_in,
    
    txpostcursor_in => txpostcursor_in,
    txprecursor_in  => txprecursor_in,
    txusrclk_in(0)  => txusrclk,
    txusrclk2_in(0) => txusrclk,
    
--    gtpowergood_out : out STD_LOGIC_VECTOR ( 0 to 0 );
--    rxctrl0_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
--    rxctrl1_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
--    rxctrl2_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
--    rxctrl3_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxoutclk_out(0)       => rxoutclk,
    rxpmaresetdone_out(0) => rxpmaresetdone,
    txoutclk_out(0)       => txoutclk,
    txpmaresetdone_out(0) => txpmaresetdone);

end rtl;
