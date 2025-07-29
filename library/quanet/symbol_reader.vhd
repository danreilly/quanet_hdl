
-- Reads from a fifo like interface to get a word DIN_W of data in a
-- shift register.  While enabled counts out number of cycles per
-- symbol.  When a new symbol is needed, shifts the right number of
-- bits out of shift reg.  Keeps shift reg full by reading from the
-- fifo-like interface.


library ieee;
use ieee.std_logic_1164.all;
package symbol_reader_pkg is
  
  component symbol_reader is
    generic (
      M_MAX: in integer;     -- 8
      LOG2M_MAX: in integer; -- 3
      LOG2M_W: in integer;   -- 2
      SYMLEN_W: in integer;  -- 10
      DIN_W: in integer);
    port (
      clk   : in std_logic;
      rst   : in std_logic;
      prime : in std_logic;
      en    : in std_logic;

      din     : in std_logic_vector(DIN_W-1 downto 0);
      din_r   : out std_logic;
      
      symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
      -- when this component generates M-PSK, M is determined by:
      log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
      
      dout: out std_logic_vector(LOG2M_W*4-1 downto 0); -- left aligned
      dout_vld: out std_logic);
  end component;
  
end package symbol_reader_pkg;

library ieee;
use ieee.std_logic_1164.all;
entity symbol_reader is
  generic (
    M_MAX     : in integer; -- 8
    LOG2M_MAX : in integer; -- 3
    LOG2M_W   : in integer; -- 2
    SYMLEN_W  : in integer; -- 10
    DIN_W     : in integer);
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    prime : in std_logic;
    en    : in std_logic;

    din     : in std_logic_vector(DIN_W-1 downto 0);
    din_r   : out std_logic;
    
    symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
      
    -- when this component generates M-PSK, M is determined by:
    log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
    dout: out std_logic_vector(LOG2M_W*4-1 downto 0); -- left aligned
    dout_vld: out std_logic);
end symbol_reader;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.lfsr_w_pkg.all;
architecture rtl of symbol_reader is
  constant OCC_W: integer := u_bitwid(DIN_W);
  constant NEW_OCC:std_logic_vector(OCC_W-1 downto 0):=
    std_logic_vector(to_unsigned(DIN_W, OCC_W));
  constant LOG2M_MAX_V: std_logic_vector(LOG2M_W-1 downto 0)
    := std_logic_vector(to_unsigned(LOG2M_MAX, LOG2M_W));

  constant SHIFT_W: integer := u_min(OCC_W, LOG2M_W+2);
  
  signal shreg_occ: std_logic_vector(OCC_W-1 downto 0);
  signal shreg, bits1_w, bits2_w, bits3_w: std_logic_vector(DIN_W-1 downto 0);
  signal bits0, bits1, bits2, bits3: std_logic_vector(LOG2M_MAX-1 downto 0);
  signal shreg_ld, shreg_shift, shreg_last, prime_d,
    symlen_is1, cyc_ctr_atlim: std_logic:='0';
  signal symlen_asamps: std_logic_vector(1 downto 0);
  signal cyc_ctr: std_logic_vector(SYMLEN_W-3 downto 0);
  signal left_adj: std_logic_vector(LOG2M_W-1 downto 0);


  signal shift_amt_pre: std_logic_vector(LOG2M_W+1 downto 0);
  signal shift_amt: std_logic_vector(SHIFT_W-1 downto 0);


  signal sym0,sym1,sym2,sym3: std_logic_vector(LOG2M_W-1 downto 0);

  
begin

  din_r       <= shreg_ld;
  shreg_ld    <= prime_d or (shreg_shift and shreg_last);
  shreg_shift <= en and cyc_ctr_atlim;

  shift_amt_pre <= u_if(symlen_asamps(0)='1', log2m&"00",
                   u_if(symlen_asamps(1)='1', '0'&log2m&'0',
                        "00"&log2m));

  process(clk)
  begin
    if (rising_edge(clk)) then
      prime_d <= prime;
      symlen_asamps <= u_inc(symlen_min1_asamps(1 downto 0));
      shift_amt     <= u_trunc(shift_amt_pre, SHIFT_W);

      if (shreg_ld='1') then
        shreg      <= din;
        shreg_occ  <= NEW_OCC;
        shreg_last <= u_b2b(NEW_OCC=u_extl(shift_amt, OCC_W));
      elsif (shreg_shift='1') then
        shreg      <= u_shift_right_u(shreg, shift_amt);
        shreg_occ  <= u_sub_u(shreg_occ, shift_amt);
        shreg_last <= u_b2b(shreg_occ = u_extl(shift_amt(SHIFT_W-2 downto 0)&'0', OCC_W));
      end if;

      if ((prime or (en and cyc_ctr_atlim))='1') then
        cyc_ctr       <= symlen_min1_asamps(SYMLEN_W-1 downto 2);
        cyc_ctr_atlim <= u_b2b(unsigned(symlen_min1_asamps(SYMLEN_W-1 downto 2))=0);
      elsif (en='1') then
        cyc_ctr       <= u_dec(cyc_ctr);
        cyc_ctr_atlim <= u_b2b(unsigned(cyc_ctr)=1);
      end if;  

      --
      -- shreg_shift ____-___
      -- shreg       aaaaabbb
      -- dout           aaabbb      
      left_adj <= u_sub_u(LOG2M_MAX_V, log2m); -- to left aligns bits
      
      if (symlen_asamps(0)='1') then -- four syms per cycle
        dout <= sym3 & sym2 & sym1 & sym0;
      elsif (symlen_asamps(1)='1') then -- two syms per cycle
        dout <= sym1 & sym1 & sym0 & sym0;
      else
        dout <= sym0 & sym0 & sym0 & sym0;
      end if;
      dout_vld <= en;
    end if;

    
  end process;
  
  bits0 <= shreg(LOG2M_MAX-1 downto 0);
  bits1_w <= u_shift_right_u(shreg, log2m);
  bits2_w <= u_shift_right_u(shreg, log2m&'0');
  bits3_w <= u_shift_right_u(shreg, u_add_u(log2m&'0',log2m));
  bits1 <= bits1_w(LOG2M_MAX-1 downto 0);
  bits2 <= bits2_w(LOG2M_MAX-1 downto 0);
  bits3 <= bits3_w(LOG2M_MAX-1 downto 0);
  sym0 <= u_trunc(u_shift_left(bits0&'1', left_adj),LOG2M_W);
  sym1 <= u_trunc(u_shift_left(bits1&'1', left_adj),LOG2M_W);
  sym2 <= u_trunc(u_shift_left(bits2&'1', left_adj),LOG2M_W);
  sym3 <= u_trunc(u_shift_left(bits3&'1', left_adj),LOG2M_W);
  
end architecture rtl;

