library ieee;
use ieee.std_logic_1164.all;

entity my_gtx_wrap is
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
end my_gtx_wrap;


library work;
use work.util_pkg.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

architecture RTL of my_gtx_wrap is
  --  attribute DowngradeIPIdentifiedWarnings: string;
  --  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";

  component my_gtx_common is
  generic (
    -- Simulation attributes
    WRAPPER_SIM_GTRESET_SPEEDUP     : string     :=  "TRUE";        -- Set to "true" to speed up sim reset 
    SIM_QPLLREFCLK_SEL              : bit_vector :=  "001");
  port (
    drpaddr   : in std_logic_vector(7 downto 0);
    drpclk    : in std_logic;
    drpdi     : in std_logic_vector(15 downto 0);
    drpdo     : out std_logic_vector(15 downto 0); 
    drpen     : in std_logic; 
    drprdy    : out std_logic; 
    drpwe     : in std_logic;
    
    qpllrefclksel  : in std_logic_vector(2 downto 0);
    
    qplloutclk_out : out std_logic;
    gtrefclk       : in std_logic_vector(1 downto 0);
    southrefclk    : in std_logic_vector(1 downto 0);
    northrefclk    : in std_logic_vector(1 downto 0);

    qplloutrefclk_out : out std_logic;

    qpllrefclklost_out : out std_logic;    
    qplllock_out       : out std_logic;
    qplllockdetclk_in  : in std_logic;
    
    qpllreset_in : in std_logic);
  end component;


  component my_gtx
    port (
      sysclk_in                               : in   std_logic;
      soft_reset_tx_in                        : in   std_logic;
      soft_reset_rx_in                        : in   std_logic;
      dont_reset_on_data_error_in             : in   std_logic;
      gt0_tx_fsm_reset_done_out               : out  std_logic;
      gt0_rx_fsm_reset_done_out               : out  std_logic;
      gt0_data_valid_in                       : in   std_logic;

      --_________________________________________________________________________
      --gt0  (x0y0)
      --____________________________channel ports________________________________
      ---------------------------- channel - drp ports  --------------------------
      gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
      gt0_drpclk_in                           : in   std_logic;
      gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
      gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
      gt0_drpen_in                            : in   std_logic;
      gt0_drprdy_out                          : out  std_logic;
      gt0_drpwe_in                            : in   std_logic;
      --------------------------- digital monitor ports --------------------------
      gt0_dmonitorout_out                     : out  std_logic_vector(7 downto 0);
      --------------------- rx initialization and reset ports --------------------
      gt0_eyescanreset_in                     : in   std_logic;
      gt0_rxuserrdy_in                        : in   std_logic;
      -------------------------- rx margin analysis ports ------------------------
      gt0_eyescandataerror_out                : out  std_logic;
      gt0_eyescantrigger_in                   : in   std_logic;
      ------------------ receive ports - fpga rx interface ports -----------------
      gt0_rxusrclk_in                         : in   std_logic;
      gt0_rxusrclk2_in                        : in   std_logic;
      ------------------ receive ports - fpga rx interface ports -----------------
      gt0_rxdata_out                          : out  std_logic_vector(31 downto 0);
      --------------------------- receive ports - rx afe -------------------------
      gt0_gtxrxp_in                           : in   std_logic;
      ------------------------ receive ports - rx afe ports ----------------------
      gt0_gtxrxn_in                           : in   std_logic;
      --------------------- receive ports - rx equalizer ports -------------------
      gt0_rxdfelpmreset_in                    : in   std_logic;
      gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
      gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
      --------------- receive ports - rx fabric output control ports -------------
      gt0_rxoutclk_out                        : out  std_logic;
      gt0_rxoutclkfabric_out                  : out  std_logic;
      ------------- receive ports - rx initialization and reset ports ------------
      gt0_gtrxreset_in                        : in   std_logic;
      gt0_rxpmareset_in                       : in   std_logic;
      ---------------------- receive ports - rx gearbox ports --------------------
      gt0_rxslide_in                          : in   std_logic;
      -------------- receive ports -rx initialization and reset ports ------------
      gt0_rxresetdone_out                     : out  std_logic;
      --------------------- tx initialization and reset ports --------------------
      gt0_gttxreset_in                        : in   std_logic;
      gt0_txuserrdy_in                        : in   std_logic;
      ------------------ transmit ports - fpga tx interface ports ----------------
      gt0_txusrclk_in                         : in   std_logic;
      gt0_txusrclk2_in                        : in   std_logic;
      ------------------ transmit ports - tx data path interface -----------------
      gt0_txdata_in                           : in   std_logic_vector(31 downto 0);
      ---------------- transmit ports - tx driver and oob signaling --------------
      gt0_gtxtxn_out                          : out  std_logic;
      gt0_gtxtxp_out                          : out  std_logic;
      ----------- transmit ports - tx fabric clock output control ports ----------
      gt0_txoutclk_out                        : out  std_logic;
      gt0_txoutclkfabric_out                  : out  std_logic;
      gt0_txoutclkpcs_out                     : out  std_logic;
      ------------- transmit ports - tx initialization and reset ports -----------
      gt0_txresetdone_out                     : out  std_logic;

      --____________________________common ports________________________________
      gt0_qplllock_in : in std_logic;
      gt0_qpllrefclklost_in  : in std_logic;
      gt0_qpllreset_out  : out std_logic;
      gt0_qplloutclk_in  : in std_logic;
      gt0_qplloutrefclk_in : in std_logic);
  end component;

  component my_gtx_common_reset
    generic (
      STABLE_CLOCK_PERIOD      : integer := 8        -- Period of the stable clock driving this state-machine, unit is [ns]
      );
    port (    
      STABLE_CLOCK             : in std_logic;             --Stable Clock, either a stable clock from the PCB
      SOFT_RESET               : in std_logic;               --User Reset, can be pulled any time
      COMMON_RESET             : out std_logic:= '0'  --Reset QPLL
      );
  end component;

  signal qplloutclk, qpllrefclklost_i, qplllock_i, qplllockdetclk,
    qplloutrefclk, qpllreset, qpllreset_i, commonreset,
    rxoutclk, txoutclk, rxusrclk, txusrclk 
    : std_logic;

  signal pll_drpdo, gt_drpdo: std_logic_vector(15 downto 0); 
  signal pll_drprdy, gt_drprdy, pll_drpen, gt_drpen, pll_drpwe, gt_drpwe: std_logic;
  signal qpllrefclksel: std_logic_vector(2 downto 0); 
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




  
  common_reset_i: my_gtx_common_reset 
    generic map(
      STABLE_CLOCK_PERIOD => DRPCLK_PD_NS)  -- Period of the stable clockne, unit is [ns]
    port map(    
      STABLE_CLOCK => drp_clk,          --Stable Clock, either a stable clock from the PCB
      SOFT_RESET   => soft_reset_tx,   --User Reset, can be pulled any time
      COMMON_RESET => commonreset);    --Reset QPLL

  gt_drpwe <= drp_we and drp_sel_gt;  
  gt_drpen <= drp_en and drp_sel_gt;  
  my_gtx_i : my_gtx
    port map(
      sysclk_in                       =>      drp_clk,
      soft_reset_tx_in                =>      soft_reset_tx,
      soft_reset_rx_in                =>      soft_reset_rx,
      dont_reset_on_data_error_in     =>      '1',
      gt0_tx_fsm_reset_done_out       =>      tx_fsm_reset_done,
      gt0_rx_fsm_reset_done_out       =>      rx_fsm_reset_done,
      gt0_data_valid_in               =>      '1',

      ---------------------------- Channel - DRP Ports  --------------------------
      gt0_drpaddr_in                  =>      drp_addr,
      gt0_drpclk_in                   =>      drp_clk,
      gt0_drpdi_in                    =>      drp_din,
      gt0_drpdo_out                   =>      gt_drpdo,
      gt0_drpen_in                    =>      gt_drpen,
      gt0_drprdy_out                  =>      gt_drprdy,
      gt0_drpwe_in                    =>      gt_drpwe,
      --------------------------- Digital Monitor Ports --------------------------
--        gt0_dmonitorout_out             =>      gt0_dmonitorout_out,
      --------------------- RX Initialization and Reset Ports --------------------
      gt0_eyescanreset_in             => '0',
      gt0_rxuserrdy_in                => '1',
      -------------------------- RX Margin Analysis Ports ------------------------
--        gt0_eyescandataerror_out        =>      gt0_eyescandataerror_out,
      gt0_eyescantrigger_in           =>  '0', --    gt0_eyescantrigger_in,
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      gt0_rxusrclk_in                 =>   rxusrclk,
      gt0_rxusrclk2_in                =>   rxusrclk,
      ------------------ Receive Ports - FPGA RX interface Ports -----------------
      gt0_rxdata_out                  =>   rxdata,
      --------------------------- Receive Ports - RX AFE -------------------------
      gt0_gtxrxp_in                   =>   rx_p,
      ------------------------ Receive Ports - RX AFE Ports ----------------------
      gt0_gtxrxn_in                   =>   rx_n,
      --------------------- Receive Ports - RX Equalizer Ports -------------------
      gt0_rxdfelpmreset_in            =>  '0',
--        gt0_rxmonitorout_out        =>      gt0_rxmonitorout_out,
      gt0_rxmonitorsel_in             =>  "00",
      --------------- Receive Ports - RX Fabric Output Control Ports -------------
      gt0_rxoutclk_out                =>  rxoutclk,
--        gt0_rxoutclkfabric_out      =>      gt0_rxoutclkfabric_out,
      ------------- Receive Ports - RX Initialization and Reset Ports ------------
      gt0_gtrxreset_in                => '0', -- think has no effect
      gt0_rxpmareset_in               => '0', -- NOT SURE
      ---------------------- Receive Ports - RX gearbox ports --------------------
      gt0_rxslide_in                  => rxslide,
      ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
--      gt0_rxcharisk_out             =>      gt0_rxcharisk_out,
      -------------- Receive Ports -RX Initialization and Reset Ports ------------
--      gt0_rxresetdone_out             =>      gt0_rxresetdone_out,
      --------------------- TX Initialization and Reset Ports --------------------

      
      gt0_gttxreset_in                => '0',  -- think has no effect
      gt0_txuserrdy_in                => '1',
      ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
      gt0_txusrclk_in                 => txusrclk,
      gt0_txusrclk2_in                =>      txusrclk,
      ------------------ Transmit Ports - TX Data Path interface -----------------
      gt0_txdata_in                   =>      txdata,
      ---------------- Transmit Ports - TX Driver and OOB signaling --------------
      gt0_gtxtxn_out                  =>      tx_n,
      gt0_gtxtxp_out                  =>      tx_p,
      ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
      gt0_txoutclk_out                =>      txoutclk,
--        gt0_txoutclkfabric_out          =>      gt0_txoutclkfabric_out,
--        gt0_txoutclkpcs_out             =>      gt0_txoutclkpcs_out,
      ------------- Transmit Ports - TX Initialization and Reset Ports -----------
--        gt0_txresetdone_out             =>      gt0_txresetdone_out

      gt0_qplllock_in => qplllock_i,
      gt0_qpllrefclklost_in => qpllrefclklost_i,
      gt0_qpllreset_out => qpllreset_i,
      gt0_qplloutclk_in => qplloutclk,
      gt0_qplloutrefclk_in => qplloutrefclk);
  
  pll_drpwe <= drp_we and drp_sel_pll;
  pll_drpen <= drp_en and drp_sel_pll;

  -- 011=northref0, 100=northref1, 001=gtref0, 010=gtref1
--  qpllrefclksel <= u_if(sel_extref='1',"001","100");
  qpllrefclksel <= "001";
  
  gtx_pll: my_gtx_common
    port map(
      drpaddr => drp_addr(7 downto 0),
      drpclk  => drp_clk,
      drpdi   => drp_din,
      drpdo   => pll_drpdo,
      drpen   => pll_drpen,
      drprdy  => pll_drprdy,
      drpwe   => pll_drpwe,
      
      qpllrefclksel  => qpllrefclksel,

      qplloutclk_out => qplloutclk,
      
      gtrefclk(0)    => gtrefclk,
      gtrefclk(1)    => '0',
      southrefclk(0) => '0', 
      southrefclk(1) => '0',
      northrefclk(0) => '0',
      northrefclk(1) => '0',

      qplloutrefclk_out  => qplloutrefclk,
      qpllrefclklost_out => qpllrefclklost_i,
      qplllock_out       => qplllock_i,
      qplllockdetclk_in  => drp_clk,
      qpllreset_in => qpllreset);

  qpllreset <= commonreset or qpllreset_i;
  qplllock <= qplllock_i;
  qpllrefclklost <=  qpllrefclklost_i;

  drp_dout <= pll_drpdo  when (drp_sel_pll='1') else gt_drpdo;
  drp_rdy <= pll_drprdy when (drp_sel_pll='1') else gt_drprdy;
  
end RTL;
