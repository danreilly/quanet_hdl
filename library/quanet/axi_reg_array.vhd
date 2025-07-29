--
--  AXI bus register arry

--  See //mahler/vhdl_and_c_ip/reg_iface/axi_reg_array/*.doc


--  arvalid    __-_
--  arready    ---_
--  got_ra_nxt __--_
--  got_ra     ___--_
--  rdce       ___v

--  rready     __---_
--  rvalid     ____-_

library ieee;
use ieee.std_logic_1164.all;
package axi_reg_array_pkg is

  component axi_reg_array
    generic (
      NUM_REGS: in integer;
      A_W: in integer := 32);
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

      dbg: out std_logic_vector(3 downto 0);
      
      -- connect these to your hdl code
      reg_w_vec :  out std_logic_vector(NUM_REGS*32-1 downto 0);
      reg_r_vec :  in  std_logic_vector(NUM_REGS*32-1 downto 0);
      -- use the following for register access "side effects"
      reg_w_pulse : out std_logic_vector(NUM_REGS-1 downto 0);
      reg_r_pulse : out std_logic_vector(NUM_REGS-1 downto 0));
  end component;

end axi_reg_array_pkg;



library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.axi_reg_array_pkg.all;
use work.util_pkg.all;

entity axi_reg_array is
  generic (
    NUM_REGS: in integer;
    A_W: in integer := 32);
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
    wvalid : in std_logic; -- can assert before awvalid
    wstrb  : in std_logic_vector(3 downto 0);
    wready : out std_logic;

    -- wr rsp chan
    bresp: out std_logic_vector(1 downto 0);
    bvalid: out std_logic;
    bready: in std_logic;

    -- read addr
    araddr: in std_logic_vector(A_W-1 downto 0);
    arvalid: in std_logic;
    arready: out std_logic;
    
    rdata: out std_logic_vector(31 downto 0);
    rresp: out std_logic_vector(1 downto 0);
    rvalid: out std_logic;
    rready: in std_logic;
    
    dbg: out std_logic_vector(3 downto 0);
    
    -- connect these to your hdl code
    reg_w_vec :  out std_logic_vector(NUM_REGS*32-1 downto 0);
    reg_r_vec :  in  std_logic_vector(NUM_REGS*32-1 downto 0);
    -- use the following for register access "side effects"
    reg_w_pulse : out std_logic_vector(NUM_REGS-1 downto 0);
    reg_r_pulse : out std_logic_vector(NUM_REGS-1 downto 0));
end axi_reg_array;


library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
--use ieee.std_logic_misc.all;
library work;
use work.util_pkg.all;
architecture rtl of axi_reg_array is

  type axi_reg_array_t is array (0 to NUM_REGS-1)
    of std_logic_vector(31 downto 0);

  
  constant ADR_W: integer := u_bitwid(NUM_REGS-1); -- relevant addr bits
  signal adr_sav: std_logic_vector(ADR_W-1 downto 0);
  
  constant RESP_OK:     std_logic_vector(1 downto 0) := "00";
  constant RESP_EXOK:   std_logic_vector(1 downto 0) := "01";
  constant RESP_SLVERR: std_logic_vector(1 downto 0) := "10";
  constant RESP_DECERR: std_logic_vector(1 downto 0) := "11";

  signal reg_w_pulse_i, reg_r_pulse_i:
    std_logic_vector(NUM_REGS-1 downto 0) := (others => '0');
  signal reg_w_i: axi_reg_array_t := (others => (others => '0'));
  signal axi_wrce, axi_rdce: std_logic_vector(NUM_REGS-1 downto 0) := (others=>'0');
  signal had_wa, had_wd, done_wt, had_ra, saw_rdy,
    awready_l, arready_l, wready_l, bvalid_l, rvalid_l: std_logic:='0';

  signal got_wa, got_wd, got_ra, got_ra_d, got_w_d, done_wa_wd,
         got_wa_nxt, got_wd_nxt, got_ra_nxt: std_logic:='0';

  signal wdata_l, rdata_l: std_logic_vector(31 downto 0) := (others=>'0');
  signal reg_r_i : axi_reg_array_t;
--  type ac_st_t is (IDL, WACK, RACK);
--  signal ac_st: ac_st_t := IDL;
--  signal rd_st: ac_st_t := IDL;

begin
    
  awready <= awready_l;
  arready <= arready_l;
  wready  <= wready_l;  

  bresp <= RESP_OK;
  rresp <= RESP_OK;

  rvalid <= rvalid_l;
  bvalid <= bvalid_l;

  done_wa_wd <= (got_wa and got_wd) and not bvalid_l;
                
  got_wa_nxt <= not axi_rst
                and ((not got_wa and (awvalid and awready_l))
                      or (got_wa and not done_wa_wd));
  got_wd_nxt <= not axi_rst
                and ((not got_wd and (wvalid and wready_l))
                      or (got_wd and not done_wa_wd));

  got_ra_nxt <= not axi_rst
                and ((not got_ra and (arvalid and arready_l))
                     or (got_ra and not (rvalid_l and rready)));



  
  axi_clk_proc: process (axi_clk)
  begin
    if (axi_clk'event and axi_clk='1') then

      got_w_d <= not axi_rst and (got_wa and got_wd); -- in case got wa & wd
                                                     -- held mult cycs
      
      if (bvalid_l='0') then
        bvalid_l <= (got_wa and got_wd);
      else
        bvalid_l <= not bready;
      end if;

      if (rvalid_l='0') then
        -- may not be asserted before araddr has been transferred
        rvalid_l <= got_ra; -- got_ra_nxt;
      else
        rvalid_l <= not rready;
      end if;


      -- WARN: write data may appear before write addr, or in same cycle.

      -- register write addr
      awready_l <= not axi_rst and not got_wa_nxt;
      if ((awvalid and awready_l)='1') then
        axi_wrce <= u_decode(awaddr(ADR_W+1 downto 2), NUM_REGS);
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
        axi_rdce <= u_decode(araddr(ADR_W+1 downto 2), NUM_REGS);
        adr_sav  <= araddr(ADR_W+1 downto 2);
      end if;
      got_ra   <= got_ra_nxt;
      got_ra_d <= got_ra;
      
      if (axi_rst='1') then
        for i in 0 to NUM_REGS-1 loop
          reg_w_i(i) <= (others => '0');
        end loop;
      else
        if ((got_wa and got_wd and not got_w_d)='1') then
          for i in 0 to NUM_REGS-1 loop
            if (axi_wrce(i)='1') then
              reg_w_i(i) <= wdata_l;
            end if;
          end loop;
        end if;
      end if;

      if ((got_wa and got_wd and not got_w_d)='1') then
        reg_w_pulse_i <= axi_wrce;
      else
        reg_w_pulse_i <= (others => '0');
      end if;
      
      if ((got_ra and not got_ra_d)='1') then
        reg_r_pulse_i <= axi_rdce;
      else
        reg_r_pulse_i <= (others => '0');
      end if;
--      saw_rdy <=  not axi_rst and (saw_rdy or arvalid);
      had_ra <= had_ra or got_ra;
      had_wa <= had_wa or got_wa;
      had_wd <= had_wd or got_wd;
      done_wt <= done_wt or (bvalid_l and bready);

      rdata_l <= reg_r_i(to_integer(unsigned(adr_sav)));
      
    end if;
  end process;

  gen_per_reg: for k in 0 to NUM_REGS-1 generate
  begin
    reg_w_vec(31+k*32 downto k*32) <= reg_w_i(k);
    reg_r_i(k) <= reg_r_vec(31+k*32 downto k*32);
  end generate;
  reg_w_pulse <= reg_w_pulse_i;
  reg_r_pulse <= reg_r_pulse_i;

  dbg(0) <= had_wa;
  dbg(1) <= had_wd;
  dbg(2) <= done_wt;
  dbg(3) <= had_ra;
  
  
--  rdata_proc : process(axi_rdce, reg_r_i) is
--    variable tmp : std_logic_vector(31 downto 0):= (others => '0');
--  begin
--n    -- note: it's guaranteed that only one
--    -- bit in rdce will ever be high at a time.
--    for j in 0 to NUM_REGS-1 loop
--      tmp := tmp or (u_rpt(axi_rdce(j),32) and reg_r_i(j));
--    end loop;
--    rdata_l <= tmp;
--  end process;

  
  -- rdata must remain stable when rvalid is asserted and rready low
  rdata <= rdata_l;

end architecture rtl;
