library ieee;
use ieee.std_logic_1164.all;

entity adcfifo_regs is
  generic (
    A_W: integer := 11);
  port (
    -- connect these to system
    axi_clk: in std_logic;
    axi_rst: in std_logic;

    -- wr addr chan
    awaddr  : in std_logic_vector(A_W-1 downto 0);
    awvalid : in std_logic;
    awready : out std_logic;

    -- wr data chan
    wdata  : in std_logic_vector(31 downto 0);
    wvalid : in std_logic;
    wready : out std_logic;
    wstrb  : in std_logic_vector(3 downto 0);

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

    arprot: in std_logic;
    awprot: in std_logic;
    
    reg_ctl_w : out std_logic_vector(31 downto 0);
    reg_stat_r : in std_logic_vector(31 downto 0);
    reg_samp_r : in std_logic_vector(31 downto 0));
end adcfifo_regs;


library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
library work;
use work.util_pkg.all;
use work.axi_reg_array_pkg.all;
architecture rtl of adcfifo_regs is

  constant ADR_W: integer := u_log2(AXI_REG_ARRAY_NUM_REG-1); -- relevant addr bits
  
  constant REG_CTL: integer := 0;
  constant REG_STAT: integer := 1;
  constant REG_SAMP: integer := 2;

  signal reg_w_pulse_i, reg_r_pulse_i:
    std_logic_vector(AXI_REG_ARRAY_NUM_REG-1 downto 0) := (others => '0');

  signal reg_r, reg_w :  axi_reg_array_t;
  signal reg_r_pulse, reg_w_pulse : axi_reg_sel_t;
  
begin
  
  --  axi_rst <= not     s_axi_aresetn;
  ara: axi_reg_array
    generic map(
      A_W => A_W)
    port map(
      -- connect these to system
      axi_clk => axi_clk,
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
  
  -- This gives meaningful names to registers
  -- so that we don't need to refer to them by numbers
  reg_ctl_w <= reg_w(REG_CTL);
  reg_r(REG_CTL)  <= reg_w(REG_CTL);
  reg_r(REG_STAT) <= reg_stat_r;
  reg_r(REG_SAMP) <= reg_samp_r;

end architecture rtl;
