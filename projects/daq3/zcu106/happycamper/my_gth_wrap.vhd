library ieee;
use ieee.std_logic_1164.all;

entity my_gth_wrap is
  generic (
    DRPCLK_PD_NS: integer);
  port (
    drp_sel_pll : in std_logic;
    drp_sel_gt  : in std_logic;
    drp_addr   : in std_logic_vector(9 downto 0);
    drp_clk    : in std_logic; -- goes to wiz freerun clk too
    drp_din    : in std_logic_vector(15 downto 0);
    drp_dout   : out std_logic_vector(15 downto 0); 
    drp_en     : in std_logic; 
    drp_rdy    : out std_logic; 
    drp_we     : in std_logic;

    txdata    : in std_logic_vector(31 downto 0);
    txusrclk_out : out std_logic;
    rxdata      : out std_logic_vector(31 downto 0);
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
end my_gth_wrap;


library work;
use work.util_pkg.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

architecture RTL of my_gth_wrap is
  --  attribute DowngradeIPIdentifiedWarnings: string;
  --  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";

  component my_gth is
  Port ( 
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
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 )  );
  end component;

  signal txoutclk, rxoutclk, txusrclk, rxusrclk: std_logic;
  
begin

  
  rxoutclk_bufg: BUFG
    port map(
      I => rxoutclk,
      O => rxusrclk);
  rxusrclk_out <= rxusrclk;
  
  txoutclk_bufg: BUFG
    port map (
      I=>txoutclk,
      O=>txusrclk);
  txusrclk_out <= txusrclk;


  
  gthi: my_gth
    port map( 
    gtwiz_userclk_tx_active_in(0) =>
    gtwiz_userclk_rx_active_in(0) : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_clk_freerun_in(0) => drp_clk,
    gtwiz_reset_all_in => "0",
    gtwiz_reset_tx_pll_and_datapath_in => "0",
    gtwiz_reset_tx_datapath_in         => "0",
    gtwiz_reset_rx_pll_and_datapath_in => "0",
    gtwiz_reset_rx_datapath_in         => "0",
    gtwiz_reset_rx_cdr_stable_out      => "0",
    gtwiz_reset_tx_done_out(0) => tx_rst_done,
    gtwiz_reset_rx_done_out(0) => rx_rst_done,

    gtwiz_userdata_tx_in  => txdata,
    gtwiz_userdata_rx_out => rxdata,
    
    gtrefclk00_in => gtrefclk,
    
--    qpll0outclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );
--    qpll0outrefclk_out : out STD_LOGIC_VECTOR ( 0 to 0 );

    gthrxp_in => rx_p,
    gthrxn_in => rx_n,
    gthtxp_out => tx_p,
    gthtxn_out => tx_n,
    
    drpaddr_in => drp_addr,
    drpclk_in  => drp_clk,
    drpdi_in   => drp_din,
    drpen_in   => drp_en,
    drpwe_in   => drp_we,
    drpdo_out  => drp_dout,
    drprdy_out => drp_rdy,
    
    eyescanreset_in => '0',
    rx8b10ben_in(0) => '1',
    rxlpmen_in => "0',
    rxrate_in => (others=>'0'),
    rxusrclk_in  => rxusrclk,
    rxusrclk2_in => rxusrclk,
    tx8b10ben_in(0) => '1',
    
    txctrl0_in  => (others=>'0'),
    txctrl1_in  => (others=>'0'),
    txctrl2_in  => (others=>'0'),
    txdiffctrl_in => (others=>'0'),
    
    txpostcursor_in => (others =>'0'),
    txprecursor_in  => (others =>'0'),
    txusrclk_in(0) => txusrclk,
    txusrclk2_in(0) => txusrclk,
    
--    gtpowergood_out : out STD_LOGIC_VECTOR ( 0 to 0 );
--    rxctrl0_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
--    rxctrl1_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
--    rxctrl2_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
--    rxctrl3_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rxoutclk_out  => rxoutclk,
--    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    txoutclk_out => txoutclk,
--    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end    
