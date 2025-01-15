-- GTX "common" or "quad" PLL (QPLL)
--
-- use the QPLL when the baud rate is above the CPLL range.

-- All this is similar to V7 GTP transcievers.

-- These are the main equations (see ug476 p55 eqn 2-3 and 2-4)
-- baud = pll * 2 / outdiv
-- pll = refin * fbdiv / (refdiv *2 )

-- fbdiv = 16,20,32,40,64,66,80,100   -- below called QPLL_FBDIV_TOP
-- refdiv = 1,2,3,4                   -- below called QPLL_REFCLK_DIV
-- outdiv = 1,2,4,8,16 (THE TXOUT_DIV OR RXOUT_DIV attributes of GTXE2_CHANNEL)
-- The wizard puts this into <name>_gt.vhd 

-- currently:   pll = 200M * 100 / (2 * 2) = 5G    and TXOUT_DIV=1
-- pll operates in two bands:
--  lower 5.93 -8.0,   upper 9.8-12.5

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity my_gtx_common is
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

    -- 1=gtrefclk0, 2=gtrefclk1, 7=gtgrefclk
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
end my_gtx_common;



architecture RTL of my_gtx_common is

  -- This is table 2-16 p59
    impure function conv_qpll_fbdiv_top (qpllfbdiv_top : in integer) return bit_vector is
    begin
       if (qpllfbdiv_top = 16) then
         return "0000100000";
       elsif (qpllfbdiv_top = 20) then
         return "0000110000" ;
       elsif (qpllfbdiv_top = 32) then
         return "0001100000" ;
       elsif (qpllfbdiv_top = 40) then
         return "0010000000" ;
       elsif (qpllfbdiv_top = 64) then
         return "0011100000" ;
       elsif (qpllfbdiv_top = 66) then
         return "0101000000" ;
       elsif (qpllfbdiv_top = 80) then
         return "0100100000" ;
       elsif (qpllfbdiv_top = 100) then
         return "0101110000" ;
       else 
         return "0000000000" ;
       end if;
    end function;

    impure function conv_qpll_fbdiv_ratio (qpllfbdiv_top : in integer) return bit is
    begin
       if (qpllfbdiv_top = 16) then
         return '1';
       elsif (qpllfbdiv_top = 20) then
         return '1' ;
       elsif (qpllfbdiv_top = 32) then
         return '1' ;
       elsif (qpllfbdiv_top = 40) then
         return '1' ;
       elsif (qpllfbdiv_top = 64) then
         return '1' ;
       elsif (qpllfbdiv_top = 66) then
         return '0' ;
       elsif (qpllfbdiv_top = 80) then
         return '1' ;
       elsif (qpllfbdiv_top = 100) then
         return '1' ;
       else 
         return '1' ;
       end if;
    end function;
  
    constant   QPLL_FBDIV_TOP   : integer  := 100;
    constant   QPLL_FBDIV_IN    :   bit_vector(9 downto 0) := conv_qpll_fbdiv_top(QPLL_FBDIV_TOP);
    constant   QPLL_FBDIV_RATIO :   bit := conv_qpll_fbdiv_ratio(QPLL_FBDIV_TOP);

    -- ground and tied_to_vcc_i signals
    signal  tied_to_ground_i                :   std_logic;
    signal  tied_to_ground_vec_i            :   std_logic_vector(63 downto 0);
    signal  tied_to_vcc_i                   :   std_logic;
    signal  tied_to_vcc_vec_i               :   std_logic_vector(63 downto 0);
  
begin

  tied_to_ground_i                    <= '0';
  tied_to_ground_vec_i(63 downto 0)   <= (others => '0');
  tied_to_vcc_i                       <= '1';
  tied_to_vcc_vec_i(63 downto 0)      <= (others => '1');
  
  gtxe2_common_i : GTXE2_COMMON
    generic map (
      -- Simulation attributes
      SIM_RESET_SPEEDUP    => WRAPPER_SIM_GTRESET_SPEEDUP,
      SIM_QPLLREFCLK_SEL   => (SIM_QPLLREFCLK_SEL),
      SIM_VERSION          => "4.0",


       ------------------COMMON BLOCK Attributes---------------
        BIAS_CFG                                =>     (x"0000040000001000"),
        COMMON_CFG                              =>     (x"00000000"),
        QPLL_CFG                                =>     (x"0680181"),
        QPLL_CLKOUT_CFG                         =>     ("0000"),
        QPLL_COARSE_FREQ_OVRD                   =>     ("010000"),
        QPLL_COARSE_FREQ_OVRD_EN                =>     ('0'),
        QPLL_CP                                 =>     ("0000011111"),
        QPLL_CP_MONITOR_EN                      =>     ('0'),
        QPLL_DMONITOR_SEL                       =>     ('0'),
        QPLL_FBDIV                              =>     (QPLL_FBDIV_IN),
        QPLL_FBDIV_MONITOR_EN                   =>     ('0'),
        QPLL_FBDIV_RATIO                        =>     (QPLL_FBDIV_RATIO),
        QPLL_INIT_CFG                           =>     (x"000006"),
        QPLL_LOCK_CFG                           =>     (x"21E8"),
        QPLL_LPF                                =>     ("1111"),
        QPLL_REFCLK_DIV                         =>     (2))
    port map (
        ------------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
        DRPADDR                         =>      drpaddr,
        DRPCLK                          =>      drpclk,
        DRPDI                           =>      drpdi,
        DRPDO                           =>      drpdo,
        DRPEN                           =>      drpen,
        DRPRDY                          =>      drprdy,
        DRPWE                           =>      drpwe,
        ---------------------- Common Block  - Ref Clock Ports ---------------------
        GTGREFCLK                       =>      tied_to_ground_i,
        GTREFCLK0                       =>      gtrefclk(0),
        GTREFCLK1                       =>      gtrefclk(1),
        GTSOUTHREFCLK0                  =>      southrefclk(0),
        GTSOUTHREFCLK1                  =>      southrefclk(1),
        GTNORTHREFCLK0                  =>      northrefclk(0),
        GTNORTHREFCLK1                  =>      northrefclk(1),
        ------------------------- Common Block -  QPLL Ports -----------------------
        QPLLDMONITOR                    =>      open,
        ----------------------- Common Block - Clocking Ports ----------------------
        QPLLOUTCLK                      =>      qplloutclk_out,
        QPLLOUTREFCLK                   =>      qplloutrefclk_out,
        REFCLKOUTMONITOR                =>      open,
        ------------------------- Common Block - QPLL Ports ------------------------
        QPLLFBCLKLOST                   =>      open,
        QPLLLOCK                        =>      qplllock_out,
        QPLLLOCKDETCLK                  =>      qplllockdetclk_in,
        QPLLLOCKEN                      =>      tied_to_vcc_i,
        QPLLOUTRESET                    =>      tied_to_ground_i,
        QPLLPD                          =>      tied_to_ground_i,
        QPLLREFCLKLOST                  =>      qpllrefclklost_out,
        QPLLREFCLKSEL                   =>      qpllrefclksel,
        QPLLRESET                       =>      qpllreset_in,
        QPLLRSVD1                       =>      "0000000000000000",
        QPLLRSVD2                       =>      "11111",
        --------------------------------- QPLL Ports -------------------------------
        BGBYPASSB                       =>      tied_to_vcc_i,
        BGMONITORENB                    =>      tied_to_vcc_i,
        BGPDB                           =>      tied_to_vcc_i,
        BGRCALOVRD                      =>      "11111",
        PMARSVD                         =>      "00000000",
        RCALENB                         =>      tied_to_vcc_i);

end RTL;
