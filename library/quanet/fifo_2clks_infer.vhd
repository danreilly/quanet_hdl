--
--  fifo_2clks_infer
--  two independent clocks, inferred from RTL
--
--
--  Fifo will not malfunction as a result of a read from mt or write to full.
--
--  reseting
--    Optional. Use a pulse or level in any clock domain.  Auto self-resets at power up.

-- writing
--    wr_en   ___-_____
--    din        V
--    full    ____---__  (full can go high the cycle after wr_en)


-- reading
--
--   When HAS_FIRST_WORD_FALLTHRU=0, dout is valid same cycle as rd_en.
--   When HAS_FIRST_WORD_FALLTHRU=1, dout is valid the cycle after rd_en
--
--   When HAS_FIRST_WORD_FALLTHRU=1
--     rd_en    ___-___
--     r_raddr  aaaabbb
--     dout     AAAABBB     (might be valid before rd_en but not always)
--     mt       ____---     (could go high cycle after rd_en)
--   When HAS_FIRST_WORD_FALLTHRU=0
--     rd_en    ___-___
--     r_raddr  aaaabbb
--     dout         A
--     mt       ____---     (behavior of mt is same regardless of fallthru)

library ieee;
use ieee.std_logic_1164.all;
package fifo_2clks_infer_pkg is

  component fifo_2clks_infer
    generic (
      A_W  : in integer; -- max occ is 2**A_W-1
      D_W  : in integer; -- width of fifo
      AFULL_OCC : in integer := 0; -- occupancy when almost full.
      HAS_FIRST_WORD_FALLTHRU : in boolean);
    port (
      wclk: in std_logic;
      rst: in std_logic; -- overrides everyting.  ANY clk domain
      din: in std_logic_vector(D_W-1 downto 0);
      wr_en: in std_logic; -- wr to full fifo has no effect
      full: out std_logic; -- 0 during rst
      afull: out std_logic; -- almost full
      
      w_mt: out std_logic; -- write-side mt flag, 1 during rst.
      -- pessimisively indicates not mt,
      -- but when indicates mt, fifo is truely mt.

      rclk: in std_logic;
      rd_en: in std_logic;
      rd_occ: out std_logic_vector(A_W-1 downto 0);
      dout: out std_logic_vector(D_W-1 downto 0);
      mt: out std_logic); -- 1 during rst
  end component;
  
end fifo_2clks_infer_pkg;

library ieee;
use ieee.std_logic_1164.all;
use work.fifo_2clks_infer_pkg.all;
entity fifo_2clks_infer is
  generic (
    A_W  : in integer;
    D_W  : in integer;
    AFULL_OCC : in integer:= 0; -- occupancy when almost full.
    HAS_FIRST_WORD_FALLTHRU : in boolean);
  port (
    wclk: in std_logic;
    rst: in std_logic; -- overrides everyting. may be in ANY clock domain.
    din: in std_logic_vector(D_W-1 downto 0);
    wr_en: in std_logic; -- wr to full fifo has no effect
    full: out std_logic; -- 0 during rst
    afull: out std_logic; -- 0 during rst
    
    w_mt: out std_logic; -- write-side mt flag, 1 during rst.
                         -- pessimisively indicates not mt,
                         -- but when indicates mt, fifo is truely mt.

    rclk: in std_logic;
    rd_en: in std_logic;
    rd_occ: out std_logic_vector(A_W-1 downto 0);
    dout: out std_logic_vector(D_W-1 downto 0);
    mt: out std_logic); -- 1 during rst
end fifo_2clks_infer;

library ieee;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use work.util_pkg.all;
--library unisim;
--use unisim.vcomponents.all;
use work.util_pkg.all;  -- defines all things named u_*
use work.cdc_pulse_pkg.all;
use work.cdc_thru_pkg.all;
--use work.cdc_samp_pkg.all;
architecture struct of fifo_2clks_infer is

  signal w_full_prov, w_afull_prov, w_waddr_isnew, wr_commit_d,
         r_raddr_isnew, rst_uc, r_rst_d, w_rst_d: std_logic := '0';
  signal r_rst, w_rst, r_mt_prov, w_mt_prov: std_logic := '1';
  signal rd_commit_l,
         wr_commit_l: std_logic := '0';
  signal wr_d, w_cross, w_cross_rc, w_cross_rc_d, w_cross_ack, w_cross_pend,
         rd_d, r_cross, r_cross_rc, r_cross_rc_d, r_cross_ack, r_cross_pend: std_logic := '0';
  signal w_waddr, w_waddr_prov,              w_raddr,
         r_raddr, r_raddr_prov, r_raddr_nxt,  r_waddr,
         rd_occ_l
    : unsigned(A_W-1 downto 0) := (others => '0');
   
  signal w_waddr_gray, w_waddr_gray_uc, w_raddr_gray, w_occ,
         r_raddr_mb, r_raddr_gray, r_raddr_gray_uc, r_waddr_gray, r_occ
     : std_logic_vector(A_W-1 downto 0) := (others => '0');
  type mem_t is array (0 to 2**A_W-1) of std_logic_vector(D_W-1 downto 0);
  signal mem: mem_t := (others => (others => '0'));
  signal mem_o, mem_d: std_logic_vector(D_W-1 downto 0);
  type st_t is (IDL, WACK);
  signal w_st, r_st: st_t := IDL;

  attribute DONT_TOUCH: string;
  attribute DONT_TOUCH of mem_o: signal is "TRUE";
  
begin

  full  <= w_full_prov;
  afull <= w_afull_prov;

  rst_thru: cdc_thru
    generic map( W => 1)
    port map(
      in_data(0)  => rst,
      out_data(0) => rst_uc);
  
  process(wclk, rst_uc)
  begin
    if (rst_uc='1') then
      w_rst <= '1';
    elsif (rising_edge(wclk)) then
      -- guarantee at least one cycle of w_rst
      w_rst   <= w_rst and not (not rst_uc and w_rst_d);
      w_rst_d <= w_rst;
    end if;
  end process;
  
  process(rclk, rst_uc)
  begin
    if (rst_uc='1') then
      r_rst <='1';
    elsif (rising_edge(rclk)) then
      -- guarantee at least one cycle of r_rst
      r_rst   <= r_rst and not (not rst_uc and r_rst_d);
      r_rst_d <= r_rst;
    end if;
  end process;

  rd_commit_l <= rd_d;


  wr_commit_l <= wr_d;


  gen_fwft: if (HAS_FIRST_WORD_FALLTHRU) generate
  begin
    dout <= mem_o;
  end generate gen_fwft;
  
  gen_no_fwft: if (not HAS_FIRST_WORD_FALLTHRU) generate
  begin
    dout <= mem_d;
  end generate gen_no_fwft;
  
  w_mt <= w_mt_prov;  


  w_waddr <= w_waddr_prov;
  


  w_occ <= std_logic_vector(w_waddr - w_raddr);
  process(wclk)
  begin
    if (rising_edge(wclk)) then
      
      -- provisional full flag
      if (w_rst='1') then
        w_full_prov <= '0';
      elsif ((wr_en and not w_full_prov)='1') then
        w_full_prov <= u_b2b((w_waddr_prov+2)=w_raddr);
      else
        w_full_prov <= u_b2b((w_waddr_prov+1)=w_raddr);
      end if;

      -- provisional almostfull flag
      if (w_rst='1') then
        w_afull_prov <= '0';
      elsif ((wr_en and not w_afull_prov)='1') then
        w_afull_prov <= u_b2b(w_waddr_prov-w_raddr>=(AFULL_OCC-1));
      else
        w_afull_prov <= u_b2b(w_waddr_prov-w_raddr>=AFULL_OCC);
      end if;
      
      if (w_rst='1') then
        w_mt_prov <='1';
      elsif (wr_en='1') then
        w_mt_prov <= '0';
      else
        w_mt_prov <= u_b2b(w_waddr_prov=w_raddr);
      end if;

      if (w_rst='1') then
        w_raddr_gray <= (others=>'0');
        w_raddr <= (others=>'0');
      else
        w_raddr_gray <= r_raddr_gray_uc; -- safe to sample
        w_raddr <= unsigned(u_g2b(w_raddr_gray));
      end if;
      r_cross_rc_d <= r_cross_rc;
       
      
      if ((wr_en and not w_full_prov)='1') then
        mem(to_integer(w_waddr_prov)) <= din;
      end if;
      wr_d <= wr_en and not w_full_prov;

      -- provisional write address
      if (w_rst='1') then
        w_waddr_prov <= (others => '0');
        w_waddr_gray <= (others => '0');
      elsif ((wr_en and not w_full_prov)='1') then
        w_waddr_prov <= w_waddr_prov+1;
        w_waddr_gray <= u_b2g(std_logic_vector(w_waddr_prov+1));
      end if;

    end if;
  end process;

  raddr_thru: cdc_thru
    generic map(W => A_W)
    port map(
      in_data  => r_raddr_gray,
      out_data => r_raddr_gray_uc);
  
  waddr_thru: cdc_thru
    generic map(W => A_W)
    port map(
      in_data  => w_waddr_gray,
      out_data => w_waddr_gray_uc);

  w_cross_pb: cdc_pulse
    port map(
      in_pulse  => w_cross,
      in_clk    => wclk,
      out_pulse => w_cross_rc,
      out_clk   => rclk);
  w_cross_ack_pb: cdc_pulse
    port map(
      in_pulse  => w_cross_rc_d,
      in_clk    => rclk,
      out_pulse => w_cross_ack,
      out_clk   => wclk);


  r_cross_pb: cdc_pulse
    port map(
      in_pulse  => r_cross,
      in_clk    => rclk,
      out_pulse => r_cross_rc,
      out_clk   => wclk);
  r_cross_ack_pb: cdc_pulse
    port map(
      in_pulse  => r_cross_rc_d,
      in_clk    => wclk,
      out_pulse => r_cross_ack,
      out_clk   => rclk);

  mt <= r_mt_prov;

  r_raddr_nxt <= r_raddr_prov + u_if((rd_en and not r_mt_prov)='1',1,0);


  r_raddr <= r_raddr_prov;
  process(rclk)
  begin
    if (rising_edge(rclk)) then


      if (r_rst='1') then
        r_waddr_gray <= (others=>'0');
--      elsif (w_cross_rc='1') then
        r_waddr <= (others=>'0');
      else
        r_waddr_gray <= w_waddr_gray_uc; -- safe to sample
        r_waddr <= unsigned(u_g2b(r_waddr_gray));
      end if;

      w_cross_rc_d <= w_cross_rc;
      
      -- provisional empty flag
      if (r_rst='1') then
        r_mt_prov <= '1';
      else -- if ((rd_en and not r_mt_prov)='1') then
        r_mt_prov <= u_b2b(r_raddr_nxt=r_waddr);
      end if;
      rd_occ_l <= r_waddr - r_raddr_nxt;
      
      if (r_rst='1') then
        r_raddr_prov <= (others => '0');
        r_raddr_gray <= (others => '0');
      elsif ((rd_en and not r_mt_prov)='1') then
        r_raddr_prov <= r_raddr_prov+1;
        r_raddr_gray <= u_b2g(std_logic_vector(r_raddr));
      end if;
      
      r_raddr_isnew <= not r_rst and rd_commit_l;
      rd_d <= rd_en and not r_mt_prov;

      mem_d <= mem_o;
    end if;
  end process;
  rd_occ <= std_logic_vector(rd_occ_l);
  mem_o <= mem(to_integer(r_raddr_prov));

end architecture struct;
