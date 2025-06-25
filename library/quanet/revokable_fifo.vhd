--
--  revokable fifo
--
--  Typically used for packetized communications.
--
--  For example, a suppose a "packet reciever" writes to a "revokable fifo".
--  The "packet reciever" can start enquing a packet before it even sees the
--  end of the packet.  If the checksum at the end of the packet fails,
--  the receiever can "revoke" the packet, and it gets erased from the fifo.  Whatever
--  is reading the fifo wont be able to read the packet until the reciever
--  "commits" it.
--  Similarly, a "packet transmitter" could reading a packet from the fifo and
--  trasmit it.  Later if the "packet transmitter" learns that the packet was corrupted
--  or never receieved, it can "revoke" its reads and retransmit the packet.
--  But if it gets some kind of acknowledge of successful transmission, it can
--  "commit" its reads.
--  However, note that such a system will "block" any pending packets until the one
--  at the head succeeds or is given up on.   You would need more of a RAM if you want
--  to have multiple outstanding transmitted packets, and then you might also
--  need sequence numbers in the packets if you want to preserve order.
--
--  Fifo will not malfunction as a result of a read from mt or write to full.

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
package revokable_fifo_pkg is

  component revokable_fifo
    generic (
      A_W  : in integer; -- max occ is 2**A_W-1
      D_W  : in integer; -- width of fifo
      AFULL_OCC : in integer := 0; -- occupancy when almost full.
      HAS_FIRST_WORD_FALLTHRU : in boolean;
      HAS_RD_REVOKE : in boolean;
      HAS_WR_REVOKE : in boolean);
    port (
      wclk: in std_logic;
      rst: in std_logic; -- overrides everyting.  ANY clk domain
      din: in std_logic_vector(D_W-1 downto 0);
      wr_en: in std_logic; -- wr to full fifo has no effect
      wr_revoke: in std_logic; -- overrides commit
      wr_commit: in std_logic;
      full: out std_logic; -- 0 during rst
      afull: out std_logic; -- almost full
      
      w_mt: out std_logic; -- write-side mt flag, 1 during rst.
      -- pessimisively indicates not mt,
      -- but when indicates mt, fifo is truely mt.

      rclk: in std_logic;
      rd_en: in std_logic;
      rd_revoke: in std_logic; -- overrides commit
      rd_commit: in std_logic; -- rd from mt fifo has no effect
      rd_occ: out std_logic_vector(A_W-1 downto 0);
      dout: out std_logic_vector(D_W-1 downto 0);
      mt: out std_logic); -- 1 during rst
  end component;
  
end revokable_fifo_pkg;

library ieee;
use ieee.std_logic_1164.all;
use work.revokable_fifo_pkg.all;

entity revokable_fifo is
  generic (
    A_W  : in integer;
    D_W  : in integer;
    AFULL_OCC : in integer:= 0; -- occupancy when almost full.
    HAS_FIRST_WORD_FALLTHRU : in boolean;
    HAS_RD_REVOKE : in boolean;
    HAS_WR_REVOKE : in boolean);
  port (
    wclk: in std_logic;
    rst: in std_logic; -- overrides everyting. may be in ANY clock domain.
    din: in std_logic_vector(D_W-1 downto 0);
    wr_en: in std_logic; -- wr to full fifo has no effect
    wr_revoke: in std_logic; -- overrides commit
    wr_commit: in std_logic;
    full: out std_logic; -- 0 during rst
    afull: out std_logic; -- 0 during rst
    
    w_mt: out std_logic; -- write-side mt flag, 1 during rst.
                         -- pessimisively indicates not mt,
                         -- but when indicates mt, fifo is truely mt.

    rclk: in std_logic;
    rd_en: in std_logic;
    rd_revoke: in std_logic; -- overrides commit
    rd_commit: in std_logic; -- rd from mt fifo has no effect
    rd_occ: out std_logic_vector(A_W-1 downto 0);
    dout: out std_logic_vector(D_W-1 downto 0);
    mt: out std_logic); -- 1 during rst
end revokable_fifo;

library ieee;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use work.util_pkg.all;
--library unisim;
--use unisim.vcomponents.all;
use work.util_pkg.all;  -- defines all things named u_*
use work.cdc_pulse_pkg.all;
architecture struct of revokable_fifo is

  signal w_full_prov, w_afull_prov, w_waddr_isnew, wr_commit_d,
         r_raddr_isnew, r_rst_d, w_rst_d: std_logic := '0';
  signal r_rst, w_rst, r_mt_prov, w_mt_prov: std_logic := '1';
  signal rd_revoke_l, rd_commit_l,
         wr_revoke_l, wr_commit_l: std_logic := '0';
  signal wr_d, w_cross, w_cross_rc, w_cross_rc_d, w_cross_ack, w_cross_pend,
         rd_d, r_cross, r_cross_rc, r_cross_rc_d, r_cross_ack, r_cross_pend: std_logic := '0';
  signal w_waddr, w_waddr_prov,              w_waddr_mb, w_raddr, 
         r_raddr, r_raddr_prov, r_raddr_nxt, r_raddr_mb, r_waddr,
         rd_occ_l
            : unsigned(A_W-1 downto 0) := (others => '0');
  type mem_t is array (0 to 2**A_W-1) of std_logic_vector(D_W-1 downto 0);
  signal mem: mem_t := (others => (others => '0'));
  signal mem_o, mem_d: std_logic_vector(D_W-1 downto 0);
  type st_t is (IDL, WACK);
  signal w_st, r_st: st_t := IDL;



  
begin


  full  <= w_full_prov;
  afull <= w_afull_prov;


  process(wclk, rst)
  begin
    if (rst='1') then
      w_rst <= '1';
    elsif (rising_edge(wclk)) then
      -- guarantee at least one cycle of w_rst
      w_rst   <= w_rst and not (not rst and w_rst_d);
      w_rst_d <= w_rst;
    end if;
  end process;
  
  process(rclk, rst)
  begin
    if (rst='1') then
      r_rst <='1';
    elsif (rising_edge(rclk)) then
      -- guarantee at least one cycle of r_rst
      r_rst   <= r_rst and not (not rst and r_rst_d);
      r_rst_d <= r_rst;
    end if;
  end process;

  gen_rd_revoke: if (HAS_RD_REVOKE) generate
  begin
    rd_revoke_l <= rd_revoke;    
    rd_commit_l <= rd_commit;
  end generate gen_rd_revoke;
  gen_no_rd_revoke: if (not HAS_RD_REVOKE) generate
  begin
    rd_revoke_l <= '0';
    rd_commit_l <= rd_d;
  end generate gen_no_rd_revoke;

  gen_wr_revoke: if (HAS_WR_REVOKE) generate
  begin
    wr_revoke_l <= wr_revoke;
    wr_commit_l <= wr_commit;
  end generate gen_wr_revoke;
  gen_no_wr_revoke: if (not HAS_WR_REVOKE) generate
  begin
    wr_revoke_l <= '0';
    wr_commit_l <= wr_d;
  end generate gen_no_wr_revoke;

  gen_fwft: if (HAS_FIRST_WORD_FALLTHRU) generate
  begin
    dout <= mem_o;
  end generate gen_fwft;
  
  gen_no_fwft: if (not HAS_FIRST_WORD_FALLTHRU) generate
  begin
    dout <= mem_d;
  end generate gen_no_fwft;
  
  w_mt <= w_mt_prov;  
  
  process(wclk)
  begin
    if (rising_edge(wclk)) then

      -- provisional full flag
      if (w_rst='1') then
        w_full_prov <= '0';
      elsif (wr_revoke_l='1') then
        w_full_prov <= u_b2b((w_waddr+1)=w_raddr);
      elsif ((wr_en and not w_full_prov)='1') then
        w_full_prov <= u_b2b((w_waddr_prov+2)=w_raddr);
      else
        w_full_prov <= u_b2b((w_waddr_prov+1)=w_raddr);
      end if;

      -- provisional almostfull flag
      if (w_rst='1') then
        w_afull_prov <= '0';
      elsif (wr_revoke_l='1') then
        w_afull_prov <= u_b2b(w_waddr-w_raddr>=AFULL_OCC);
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
        w_raddr <= (others=>'0');
      elsif (r_cross_rc='1') then
        w_raddr <= r_raddr_mb; -- safe to sample
      end if;
      r_cross_rc_d <= r_cross_rc;
       
      
      if ((wr_en and not w_full_prov)='1') then
        mem(to_integer(w_waddr_prov)) <= din;
      end if;
      wr_d <= wr_en and not w_full_prov;

      -- provisional write address
      if (w_rst='1') then
        w_waddr_prov <= (others => '0');
      elsif (wr_revoke_l='1') then
        w_waddr_prov <= w_waddr;
      elsif ((wr_en and not w_full_prov)='1') then
        w_waddr_prov <= w_waddr_prov+1;
      end if;

      -- actual write-side write address
      if (w_rst='1') then
        w_waddr <= (others => '0');
--        w_full  <= '0';
      elsif ((wr_commit_l and not wr_revoke_l)='1') then
        w_waddr <= w_waddr_prov;
--        w_full  <= w_full_prov;
      end if;
      w_waddr_isnew <= not w_rst and (wr_commit_l and not wr_revoke_l);

      if (w_rst='1') then
        w_st <= IDL;
        w_cross <= '0';
        w_cross_pend <= '0';
      else
        case (w_st) is
          when IDL =>
            w_cross <= '0';
            w_cross_pend <= '0';
            if (w_waddr_isnew='1') then
              w_waddr_mb <= w_waddr;
              w_cross <= '1';
              w_st <= WACK;
            end if;
          when WACK =>
            w_cross <= '0';
            if (w_cross_ack='1') then
              if (w_waddr_isnew='1') then
                w_waddr_mb <= w_waddr;
                w_cross <= '1';
                w_cross_pend <= '0';
              elsif (w_cross_pend='1') then
                w_waddr_mb    <= w_waddr;
                w_cross <= '1';
                w_cross_pend<='0';
              else
                w_cross <= '0';
                w_cross_pend<='0';
                w_st <= IDL;
              end if;
            elsif (w_waddr_isnew='1') then
              w_cross_pend <= '1';
            end if;
         end case;
       end if;
      
    end if;
  end process;


  
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
    
  process(rclk)
  begin
    if (rising_edge(rclk)) then
      if (r_rst='1') then
        r_waddr <= (others=>'0');
      elsif (w_cross_rc='1') then
        r_waddr <= w_waddr_mb; -- safe to sample
      end if;
      w_cross_rc_d <= w_cross_rc;
      
      -- provisional empty flag
      if (r_rst='1') then
        r_mt_prov <= '1';
      elsif (rd_revoke_l='1') then
        r_mt_prov <= u_b2b(r_waddr=w_raddr);
      else -- if ((rd_en and not r_mt_prov)='1') then
        r_mt_prov <= u_b2b(r_raddr_nxt=r_waddr);
      end if;
      rd_occ_l <= r_waddr - r_raddr_nxt;
      
      if (r_rst='1') then
        r_raddr_prov <= (others => '0');
      elsif (rd_revoke_l='1') then
        r_raddr_prov <= r_raddr;
      elsif ((rd_en and not r_mt_prov)='1') then
        r_raddr_prov <= r_raddr_prov+1;
      end if;
      r_raddr_isnew <= not r_rst and (rd_commit_l and not rd_revoke_l);
      rd_d <= rd_en and not r_mt_prov;
      
      -- actual read-side read address
      if (r_rst='1') then
        r_raddr <= (others => '0');
      elsif ((rd_commit_l and not rd_revoke_l)='1') then
        r_raddr <= r_raddr_prov;
      end if;
      
      if (r_rst='1') then
        r_st <= IDL;
        r_cross <= '0';
        r_cross_pend <= '0';
      else
        case (r_st) is
          when IDL =>
            r_cross <= '0';
            r_cross_pend <= '0';
            if (r_raddr_isnew='1') then
              r_raddr_mb <= r_raddr;
              r_cross <= '1';
              r_st <= WACK;
            end if;
          when WACK =>
            r_cross <= '0';
            if (r_cross_ack='1') then
              if (r_raddr_isnew='1') then
                r_raddr_mb <= r_raddr;
                r_cross <= '1';
                r_cross_pend <= '0';
              elsif (r_cross_pend='1') then
                r_raddr_mb    <= r_raddr;
                r_cross <= '1';
                r_cross_pend<='0';
              else
                r_cross <= '0';
                r_cross_pend<='0';
                r_st <= IDL;
              end if;
            elsif (r_raddr_isnew='1') then
              r_cross_pend <= '1';
            end if;
         end case;
      end if;
      mem_d <= mem_o;
    end if;
  end process;
  rd_occ <= std_logic_vector(rd_occ_l);
  mem_o <= mem(to_integer(r_raddr_prov));

end architecture struct;
