--
--  axi_regs
--  This implements a fixed size set of slave registers.
--  The ports are all std_logic_vector, so it's easy to instantiate this
--  in Verilog (unlike axi_reg_array, which uses arrays of std_logic_vector).
--
--  The reg*_w ports are typically for control
--  and the reg*_r ports are typically for status.
--
--  I claim this is a better way to implement registers than how Analog
--  Devices does it. Here are two examples:
--    axi_dmac/axi_dma_regmap.v: The function of an axi slave is all mixed up
--        with the particular registers needed by this IP.  This is so ad-hoc.
--        Why didn't they use their own up_axi.v ?
--    library/common/up_axi.v: 
--        Here the function of an axi slave is abstracted.  But the IP
--        that uses it still has to wack and rack.  You've got to write code
--        (inside an always @(posedge s_axi_ack) maybe) to use up_axi.v.
--        This is insufficient abstraction.

library ieee;
use ieee.std_logic_1164.all;

entity axi_regs is
  generic (
    A_W: integer := 4);
  port (
    aclk: in std_logic;
    arstn: in std_logic;

    -- wr addr chan
    awaddr : in std_logic_vector(A_W-1 downto 0);
    awvalid : in std_logic;
    awready : out std_logic;

    -- wr data chan
    wdata  : in std_logic_vector(31 downto 0);
    wvalid : in std_logic;
    wstrb  : in std_logic_vector(3 downto 0);
    wready : out std_logic;
    
    -- wr rsp chan
    bresp: out std_logic_vector(1 downto 0);
    bvalid: out std_logic;
    bready: in std_logic;

    araddr: in std_logic_vector(A_W-1 downto 0);
    arvalid: in std_logic;
    arready: out std_logic;
    
    rdata: out std_logic_vector(31 downto 0);
    rresp: out std_logic_vector(1 downto 0);
    rvalid: out std_logic;
    rready: in std_logic;

    reg0_w: out std_logic_vector(31 downto 0);
    reg1_w: out std_logic_vector(31 downto 0);
    reg2_w: out std_logic_vector(31 downto 0);
    reg3_w: out std_logic_vector(31 downto 0);
    
    reg0_r: in std_logic_vector(31 downto 0);
    reg1_r: in std_logic_vector(31 downto 0);
    reg2_r: in std_logic_vector(31 downto 0);
    reg3_r: in std_logic_vector(31 downto 0));
end axi_regs;



library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
library work;
use work.util_pkg.all;
use work.axi_reg_array_pkg.ALL;
architecture rtl of axi_regs is
  constant NUM_REGS: integer := 4;
  signal reg_r, reg_w: std_logic_vector(NUM_REGS*32-1 downto 0);
  signal axi_rst: std_logic;
  signal reg_w_pulse, reg_r_pulse: std_logic_vector(NUM_REGS-1 downto 0);
begin

  axi_rst <= not arstn;
  ara: axi_reg_array
    generic map(
      NUM_REGS => NUM_REGS,
      A_W => A_W)
    port map(
      -- connect these to system
      axi_clk => aclk,
      axi_rst => axi_rst,
      
      -- wr addr chan
      awaddr   => awaddr,
      awvalid  => awvalid,
      awready  => awready,
      
      -- wr data chan
      wdata   => wdata,
      wvalid  => wvalid,
      wstrb   => wstrb,
      wready  => wready,
      
      -- wr rsp chan
      bresp  => bresp,
      bvalid => bvalid,
      bready => bready,

      araddr  => araddr,
      arvalid => arvalid,
      arready => arready,
      
      rdata => rdata,
      rresp => rresp,
      rvalid => rvalid,
      rready => rready,

      -- connect these to your main vhdl code
      reg_w  => reg_w,
      reg_r  => reg_r,
      -- use the following for register access "side effects"
      reg_w_pulse  => reg_w_pulse,
      reg_r_pulse  => reg_r_pulse);
  
  reg0_w <= reg_w( 31 downto  0);
  reg1_w <= reg_w( 63 downto 32);
  reg2_w <= reg_w( 95 downto 64);
  reg3_w <= reg_w(127 downto 96);
  
  reg_r( 31 downto  0) <= reg0_r;
  reg_r( 63 downto 32) <= reg1_r;
  reg_r( 95 downto 64) <= reg2_r;
  reg_r(127 downto 96) <= reg3_r;
  
end architecture rtl;
  

