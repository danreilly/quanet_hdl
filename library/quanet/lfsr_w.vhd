--  lfsr_w
--
--  Produces the next W bits of any LFSR sequence every cycle.
--
--  The characteristic polynomial CP corresponds to page 283 in
--  "Wireless Digital Communications:Design and Theory" (McDermott)
--  The CP is what we normally consider to be the polynomial,
--  except we omit the msb which is always 1.
--  CP(0) must be 1.
--  We shift the state to the right, and put the xors in on the left
--  (because that seems to be the conventional way to do it.)
--  We obtain the output from the rightmost bits of the state.
--  We flip the output, so reading left to right within the output word
--  is the temporal order of the LFSR.
--
-- How to reset the LFSR:
-- Pulse for one cycle, during which rst_st must be valid.
-- The next cycle, that becomes the state.
-- Note that the bitflip of the reset state is the first CP_W bits of the sequence.
--
--  rst     ___-_________
--  rst_st     A
--  en      ___x---__-___
--  state       ABCDDDEEE
--  d_o         vvvv  v
--
-- Example sequences:
-- CP="01000000001", rst_st="10100001111"
-- It's easy to see these are the same sequence, regardless of word width:
-- W=4:
--    f 0 b 2 b 8 4 6 a 0 e f
-- W=2:
--    3 3 0 0 2 3 0 2 2
-- W=1:
--    1 1 1 1 0 0 0 0 1 0 1 1 0 0 1 0 1 0 1 1
library ieee;
use ieee.std_logic_1164.all;
-- vhdl 2008

library ieee;
use ieee.std_logic_1164.all;
package lfsr_w_pkg is
  
  component lfsr_w is
  generic(
    W: in integer;     -- number of bits to produce per cycle
    CP: in std_logic_vector);
  port (
    d_o: out std_logic_vector(W-1 downto 0);
    en : in std_logic;
    
    d_i: in std_logic_vector(W-1 downto 0);
    ld : in std_logic; -- loads d_i.  If 0 BER, this syncs lfsr

    rst_st: in std_logic_vector(CP'LENGTH-1 downto 0);
    rst: in std_logic;                  -- a syncronous reset
    err: out std_logic;
    state_nxt: out std_logic_vector(CP'LENGTH-1 downto 0);
    clk: in std_logic);
  end component;
  
end package;  

library ieee;
use ieee.std_logic_1164.all;
entity lfsr_w is
  generic(
    W: in integer;     -- number of bits to produce per cycle
    CP: in std_logic_vector);
  port (
    d_o: out std_logic_vector(W-1 downto 0); -- valid the cycle after rst or en
    en : in std_logic;
    
    d_i: in std_logic_vector(W-1 downto 0);
    ld : in std_logic; -- loads d_i.  If 0 BER, this syncs lfsr

    rst_st: in std_logic_vector(CP'LENGTH-1 downto 0);
    rst: in std_logic;                  -- a syncronous reset
    err: out std_logic;
    state_nxt: out std_logic_vector(CP'LENGTH-1 downto 0);
    clk: in std_logic);
end lfsr_w;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of lfsr_w is
  
--  function u_or(v: std_logic_vector)
--    return std_logic is
--  begin
--    return u_b2b(unsigned(v)/=0);
--  end function u_or;

  constant CP_W: integer := CP'length; -- width of characteristic polynomian (minus one)
  constant SW: integer := u_max(W, CP_W);
  constant WPCP: integer := (CP_W+W-1)/W;
  constant WPCP_W: integer := u_max(1,u_bitwid(WPCP-1));

--  signal st_new, st, st_post: std_logic_vector(SW-1 downto 0) := CP(CP_W-1 downto 0);
  signal st_new, st, st_post: std_logic_vector(SW-1 downto 0) := u_extr(CP, SW);
  signal rst_int: std_logic := '0';
  signal state_out_i: std_logic_vector(CP_W-1 downto 0) := (others => '0');
  
  constant CHUNK_W: integer := 16;
  constant NON0_W: integer := (CP_W+CHUNK_W-1)/CHUNK_W;
  signal st_non0_v: std_logic_vector(NON0_W-1 downto 0) := (others => '1');
  signal st_is0: std_logic := '0';


  signal wpcp_ctr: std_logic_vector(WPCP_W-1 downto 0) := (others=>'0');
  signal wpcp_en: std_logic:='0';

  type dbg_array_t is array (0 to SW-1) of std_logic_vector(SW-1 downto 0);
  signal dbg_msk: dbg_array_t;
  
  -- returns the bits of state that contribute to bit i in st_new.
  -- If W>CP_W, only the upper bits of state contribute.
  function mask(i: integer) return std_logic_vector is
    variable poly, v: std_logic_vector(SW-1 downto 0);
    variable m: std_logic;
  begin
    poly := u_extr(CP, SW); -- left justify CP
    v := (others => '0');
    v(i) := '1';
    for j in 1 to W loop
      m := v(SW-1);
      v := v(SW-2 downto 0)&'0'; -- shift v left one bit
      if (m = '1') then -- if there was a carry
        v := v xor poly; --    xor v with poly
      end if;
    end loop;
    return v;
  end mask;
  
  

begin
  assert (CP(CP'right(1))='1')
    report "CP must end in 1" severity failure;

  rst_int <= rst or st_is0;


  
  clk_proc: process(clk)
    variable f, b: integer;
  begin
    if (clk'event and clk='1') then

      if (rst_int='1') then
        st <= u_extr(rst_st, SW);
      elsif (en='1') then
        st <= st_new;
      end if;

      
      if (wpcp_en='0') then
        wpcp_ctr <= std_logic_vector(to_unsigned(WPCP-1, WPCP_W));
      else
        wpcp_ctr <= std_logic_vector(unsigned(wpcp_ctr)-1);
      end if;
      if (ld='1') then
        wpcp_en<='1';
      elsif (unsigned(wpcp_ctr)=0) then
        wpcp_en<='0';
      end if;
      
      -- In our devices, sometimes our clock is temporarily screwed up.
      -- This can cause the state to be set to zero, from which it can not
      -- normally recover.  So here we detect that and auto reset it.
      -- Note that only part of the state contributes to the next state.
      --
      -- Also, PAR optimizes u_or to use the fast carry logic resources.
      -- Here we break things into chunks to help with speed.
      -- However, I since found that it's not necessary.
      -- a reductive or for a 31-bit vector only takes 3.1 ns!
--      for i in 0 to NON0_W-1 loop
--        b := i*CHUNK_W;
--        st_non0_v(i) <= u_or(st(u_min(CHUNK_W-1+b, CP_W-1) downto b));
--      end loop;  -- i
      -- only upper CP_W bits of state matter.
      st_is0 <= not u_or(st(SW-1 downto SW-CP_W));
      
    end if;
  end process;

  err <= st_is0;

  st_post <= st when (wpcp_en='0') else (d_i & st(SW-W-1 downto 0));
  lfsr_gen: for i in 0 to SW-1 generate
  begin
    st_new(i) <= u_xor(st_post and mask(i));
    dbg_msk(i) <= mask(i);
  end generate;
  state_nxt <= st_new;

  d_o <= u_flip(st(W-1 downto 0));
  
end rtl;
