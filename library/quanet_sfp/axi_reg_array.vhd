--
--  AXI bus register arry
--  last modified 10/15/2014
--  See //mahler/vhdl_and_c_ip/reg_iface/axi_reg_array/*.doc

library ieee;
use ieee.std_logic_1164.all;
package axi_reg_array_pkg is
  constant AXI_REG_ARRAY_NUM_REG: integer := 4;
  subtype axi_reg_sel_t is std_logic_vector(AXI_REG_ARRAY_NUM_REG-1 downto 0);
  type axi_reg_array_t is array (0 to AXI_REG_ARRAY_NUM_REG-1)
    of std_logic_vector(31 downto 0);

  component axi_reg_array
    generic (
      A_W: integer := 32);
    port (
      -- connect these to system
      axi_clk: in std_logic;
      axi_rst: in std_logic;
      
      -- wr addr chan
      awaddr : in std_logic_vector(A_W-1 downto 0);
      awvalid : in std_logic;
      awready : out std_logic;

      dbg_w_adcctl: out std_logic;
      
      -- wr data chan
      wdata  : in std_logic_vector(31 downto 0);
      wvalid : in std_logic;
      wstrb  : in std_logic_vector(3 downto 0);  -- ignored
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

      -- connect these to your main vhdl code
      reg_w :  out axi_reg_array_t;
      reg_r :  in  axi_reg_array_t;
      -- use the following for register access "side effects"
      reg_w_pulse : out axi_reg_sel_t;
      reg_r_pulse : out axi_reg_sel_t);
  end component;

end axi_reg_array_pkg;



library ieee;
use ieee.std_logic_1164.all;
use work.axi_reg_array_pkg.all;

entity axi_reg_array is
    generic (
      A_W: integer := 32);
  port (
    -- connect these to system
    axi_clk: in std_logic;
    axi_rst: in std_logic;

    -- wr addr chan
    awaddr : in std_logic_vector(A_W-1 downto 0);
    awvalid : in std_logic;
    awready : out std_logic;

    -- wr data chan
    wdata  : in std_logic_vector(31 downto 0);
    wvalid : in std_logic;
    wstrb  : in std_logic_vector(3 downto 0);
    wready : out std_logic;

    dbg_w_adcctl: out std_logic;
    
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

    -- connect these to your main vhdl code
    reg_w :  out axi_reg_array_t;
    reg_r :  in  axi_reg_array_t;
    -- use the following for register access "side effects"
    reg_w_pulse : out axi_reg_sel_t;
    reg_r_pulse : out axi_reg_sel_t);
end axi_reg_array;


library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
library work;
use work.util_pkg.all;
architecture rtl of axi_reg_array is

  constant ADR_W: integer := u_log2(AXI_REG_ARRAY_NUM_REG-1); -- relevant addr bits
  
  constant RESP_OK:     std_logic_vector(1 downto 0) := "00";
  constant RESP_EXOK:   std_logic_vector(1 downto 0) := "01";
  constant RESP_SLVERR: std_logic_vector(1 downto 0) := "10";
  constant RESP_DECERR: std_logic_vector(1 downto 0) := "11";

  signal reg_w_pulse_i, reg_r_pulse_i:
    std_logic_vector(AXI_REG_ARRAY_NUM_REG-1 downto 0) := (others => '0');
  signal reg_w_i: axi_reg_array_t := (others => (others => '0'));
  signal axi_wrce, axi_rdce: std_logic_vector(AXI_REG_ARRAY_NUM_REG-1 downto 0);
  signal awready_l, arready_l, wready_l, bvalid_l, rvalid_l: std_logic:='0';

  signal got_wa, got_wd, got_ra, got_ra_d,
         got_wa_nxt, got_wd_nxt, got_ra_nxt: std_logic:='0';

  signal wdata_l: std_logic_vector(31 downto 0);
  
  type ac_st_t is (IDL, WACK, RACK);
  signal ac_st: ac_st_t := IDL;

begin
    
  awready <= awready_l;
  arready <= arready_l;
  wready  <= wready_l;  

  bresp <= RESP_OK;
  rresp <= RESP_OK;

  rvalid <= rvalid_l;
  bvalid <= bvalid_l;

  dbg_w_adcctl <= axi_wrce(8) and got_wa and got_wd;

  got_wa_nxt <= not axi_rst
                and ((not got_wa and (awvalid and awready_l))
                      or (got_wa and not got_wd));
  got_wd_nxt <= not axi_rst
                and ((not got_wd and (wvalid and wready_l))
                      or (got_wd and not got_wa));

  got_ra_nxt <= not axi_rst
                and ((not got_ra and (arvalid and arready_l))
                     or (got_ra and not rready));
  
  axi_clk_proc: process (axi_clk)
  begin
    if (axi_clk'event and axi_clk='1') then

      case (ac_st) is
        when IDL =>
          rvalid_l <= '0';
          bvalid_l <= '0';
          if ((got_wa and got_wd)='1') then
            bvalid_l <= '1';
            ac_st    <= WACK;
          elsif (got_ra_nxt='1') then
            rvalid_l <= '1';
            ac_st    <= RACK;
          end if;
        when WACK =>
          rvalid_l <= '0';
          bvalid_l <= not bready;
          if (bready='1') then
            ac_st<=IDL;
          end if;
        when RACK =>
          bvalid_l <= '0';
          rvalid_l <= not rready;
          if (rready='1') then
            ac_st<=IDL;
          end if;
      end case;

      -- WARN: write data may appear before write addr, or in same cycle.

      -- register write addr
      awready_l <= not axi_rst and not got_wa_nxt;
      if ((awvalid and awready_l)='1') then
        axi_wrce <= u_decode(awaddr(ADR_W+1 downto 2), AXI_REG_ARRAY_NUM_REG);
      end if;
      got_wa <= got_wa_nxt;

      -- register write data
      wready_l <= not axi_rst and not got_wd_nxt;
      if ((wvalid and wready_l)='1') then
        wdata_l <= wdata;
      end if;
      got_wd <= got_wd_nxt;
      
      -- capture read address
      arready_l <= not axi_rst and not got_ra_nxt;
      if ((arvalid and arready_l)='1') then
        axi_rdce <= u_decode(araddr(ADR_W+1 downto 2), AXI_REG_ARRAY_NUM_REG);
      end if;
      got_ra   <= got_ra_nxt;
      got_ra_d <= got_ra;
      
      if (axi_rst='1') then
        for i in 0 to AXI_REG_ARRAY_NUM_REG-1 loop
          reg_w_i(i) <= (others => '0');
        end loop;
      else
        if ((got_wa and got_wd)='1') then
          for i in 0 to AXI_REG_ARRAY_NUM_REG-1 loop
            if (axi_wrce(i)='1') then
              reg_w_i(i) <= wdata_l;
            end if;
          end loop;
        end if;
      end if;

      if ((got_wa and got_wd)='1') then
        reg_w_pulse_i <= axi_wrce;
      else
        reg_w_pulse_i <= (others => '0');
      end if;
      
      if ((got_ra and not got_ra_d)='1') then
        reg_r_pulse_i <= axi_rdce;
      else
        reg_r_pulse_i <= (others => '0');
      end if;
   
        
    end if;
  end process;
  reg_w <= reg_w_i;
  reg_w_pulse <= reg_w_pulse_i;
  reg_r_pulse <= reg_r_pulse_i;
  
  rdata_proc : process(axi_rdce, reg_r) is
    variable tmp : std_logic_vector(31 downto 0);
    variable tmpb : std_logic_vector(0 downto 0);
  begin
    tmp := (others => '0');
    -- note: it's guaranteed that only one
    -- bit in rdce will ever be high at a time.
    for j in 0 to AXI_REG_ARRAY_NUM_REG-1 loop
      tmpb(0) := axi_rdce(j);
      tmp := tmp or (SXT(tmpb, 32) and reg_r(j));
    end loop;
    rdata <= tmp;
  end process;

end architecture rtl;
