library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;

entity util_dacfifo_regs is
  generic (
    A_W: integer := 32);
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
end util_dacfifo_regs;



library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
library work;
use work.util_pkg.all;
use work.axi_reg_array_pkg.ALL;
architecture rtl of util_dacfifo_regs is
  constant NUM_REGS: integer := 4;
  signal reg_r, reg_w: std_logic_vector(NUM_REGS*32-1 downto 0);
  signal axi_rst: std_logic;
  signal reg_w_pulse, reg_r_pulse : std_logic_vector(NUM_REGS-1 downto 0) := (others=>'0');  
begin

  axi_rst <= not arstn;
  ara: axi_reg_array
    generic map(
      NUM_REGS => 4,
      A_W => 16)
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
  
  reg0_w <= reg_w(0*32+31 downto 0*32);
  reg1_w <= reg_w(1*32+31 downto 1*32);
  reg2_w <= reg_w(2*32+31 downto 2*32);
  reg3_w <= reg_w(3*32+31 downto 3*32);
  
  reg_r(0*32+31 downto 0*32) <= reg0_r;
  reg_r(1*32+31 downto 1*32) <= reg1_r;
  reg_r(2*32+31 downto 2*32) <= reg2_r;
  reg_r(3*32+31 downto 3*32) <= reg3_r;
  
end architecture rtl;
  

