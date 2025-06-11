library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package quanet_adc_pkg is
  
end package;


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity quanet_adc is
--  generic (
--    DMA_A_W: integer := 16;
--    AXI_A_W: integer := 4;
--    IMMEM_A_W: integer := G_FRAME_PD_W);
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
    s_axi_rready: in std_logic);

end quanet_adc;

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
architecture rtl of quanet_adc is
begin
  constant AREG_FOFO:    integer := 0;
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

  areg_fofo_w       <= reg_w(AREG_FOFO);
  areg_r(AREG_FOFO) <= areg_fofo_r;
  
  -- reg 0 = fr1 
  skinny <= areg_fofo_w(3 downto 0);
  
end architecture rtl;

