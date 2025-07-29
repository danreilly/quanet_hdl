
-- a four-word wide M-psk symbolizer (max of 4 symbols per cycle)
-- with configurable symbol length

-- din is valid when din_r rises
--
-- din   vvvvvxxxvvv
-- din_r ____-_____
--

library ieee;
use ieee.std_logic_1164.all;
package qsdc_data_symbolizer_pkg is
  
  component qsdc_data_symbolizer is
    generic (
      M_MAX     : in integer;
      LOG2M_MAX : in integer;
      LOG2M_W   : in integer;
      SYMLEN_W  : in integer;
      CODE_W    : in integer;
      BITDUR_W  : in integer;
      MEM_W     : in integer;
      DAC_W     : in integer); -- 16
    port (
      clk   : in std_logic;
      rst   : in std_logic;
      prime : in std_logic;
      en    : in std_logic;

      mem_data  : in std_logic_vector(MEM_W-1 downto 0);
      mem_last  : in std_logic;
      mem_rd    : out std_logic;
      
      code : in std_logic_vector(CODE_W-1 downto 0);
      bitdur_min1_codes:  in std_logic_vector(BITDUR_W-1 downto 0);
      symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
      
      -- when this component generates M-PSK, M is determined by:
      log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
      dout_done: out std_logic;
      dout      : out std_logic_vector(DAC_W*4-1 downto 0);
      dout_vld  : out std_logic);
  end component;
end package qsdc_data_symbolizer_pkg;

library ieee;
use ieee.std_logic_1164.all;
entity qsdc_data_symbolizer is
  generic (
    M_MAX     : in integer; -- 8
    LOG2M_MAX : in integer; -- 3
    LOG2M_W   : in integer; -- 2
    SYMLEN_W  : in integer;
    CODE_W: in integer;
    BITDUR_W: in integer;
    MEM_W     : in integer;
    DAC_W     : in integer);    -- 16
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    prime : in std_logic;
    en    : in std_logic;

    mem_data : in std_logic_vector(MEM_W-1 downto 0);
    mem_last : in std_logic;
    mem_rd   : out std_logic;
    
    code               : in std_logic_vector(CODE_W-1 downto 0);
    bitdur_min1_codes  : in std_logic_vector(BITDUR_W-1 downto 0);
    symlen_min1_asamps : in std_logic_vector(SYMLEN_W-1 downto 0);
      
    -- when this component generates M-PSK, M is determined by:
    log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
    dout_done: out std_logic;
    dout      : out std_logic_vector(DAC_W*4-1 downto 0);
    dout_vld  : out std_logic);
end qsdc_data_symbolizer;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.symbol_reader_pkg.all;
architecture rtl of qsdc_data_symbolizer is
  constant OCC_W: integer := u_bitwid(MEM_W);
  constant NEW_OCC:std_logic_vector(OCC_W-1 downto 0):=
    std_logic_vector(to_unsigned(MEM_W, OCC_W));
  constant LOG2M_MAX_V: std_logic_vector(LOG2M_W-1 downto 0)
    := std_logic_vector(to_unsigned(LOG2M_MAX, LOG2M_W));

  constant SHIFT_W: integer := u_min(OCC_W, LOG2M_W+2);
  
  signal shreg_occ: std_logic_vector(OCC_W-1 downto 0);
  signal shreg, bits1_w, bits2_w, bits3_w: std_logic_vector(MEM_W-1 downto 0);
  signal bits0, bits1, bits2, bits3: std_logic_vector(LOG2M_MAX-1 downto 0);
  signal shreg_shift, shreg_atlim, shreg_last, prime_d, prime_dd, mem_done, mem_done_d,
    shreg_done_i, code_r, mem_rd_i, din_vld, code_rd, sym_last, all_done, code_last,
    symlen_is1, bitdur_ctr_atlim: std_logic:='0';
  signal symlen_asamps: std_logic_vector(1 downto 0);
  signal bitdur_ctr: std_logic_vector(BITDUR_W-1 downto 0);
  signal left_adj: std_logic_vector(LOG2M_W-1 downto 0);
  signal cur_code: std_logic_vector(CODE_W-1 downto 0);


  signal shift_amt_pre: std_logic_vector(LOG2M_W+1 downto 0);
  signal shift_amt: std_logic_vector(SHIFT_W-1 downto 0);

  signal sympad: std_logic_vector(DAC_W-LOG2M_MAX-2 downto 0) := (others=>'0');
  signal dout_pre: std_logic_vector(4*2-1 downto 0);
begin

  mem_rd <= mem_rd_i;
  mem_rd_i <= (prime or (shreg_shift and shreg_atlim)) and not mem_done;

  



--  shift_amt_pre <= u_if(symlen_asamps(0)='1', log2m&"00",
--                   u_if(symlen_asamps(1)='1', '0'&log2m&'0',
--                        "00"&log2m));

  cur_code <= code when (shreg(0)='1')
              else not code;
  
  process(clk)
  begin
    if (rising_edge(clk)) then

      
      mem_done     <= not (prime or rst) and ((mem_rd_i and mem_last) or mem_done);
      mem_done_d   <= mem_done;
      shreg_done_i <= not (prime or rst) and ((mem_done and shreg_shift and shreg_atlim) or shreg_done_i);
        
      prime_d <= prime;
      prime_dd <= prime_d;
      
      symlen_asamps <= u_inc(symlen_min1_asamps(1 downto 0));
--      shift_amt     <= u_trunc(shift_amt_pre, SHIFT_W);

      -- data from memory is stored in this shift register
      din_vld      <= mem_rd_i;
      if (din_vld='1') then
        shreg       <= u_if(mem_done_d='0', mem_data, u_rpt('0',MEM_W));
        shreg_occ   <= NEW_OCC;
        shreg_atlim <= u_b2b(unsigned(NEW_OCC)=1);
        shreg_last  <= mem_done;
      elsif (shreg_shift='1') then
        shreg       <= u_shift_right_u(shreg, "1");
        shreg_occ   <= u_dec(shreg_occ);
        shreg_atlim <= u_b2b(unsigned(shreg_occ)=2);
      end if;
      shreg_shift <= code_rd and bitdur_ctr_atlim;
      -- The lsb of the shreg expands into cur_code

      -- each code_rd counts towards the bit duration.
      if ((prime or (code_rd and bitdur_ctr_atlim))='1') then
        bitdur_ctr       <= bitdur_min1_codes;
        bitdur_ctr_atlim <= u_b2b(unsigned(bitdur_min1_codes)=0);
      elsif (code_rd='1') then
        bitdur_ctr       <= u_dec(bitdur_ctr);
        bitdur_ctr_atlim <= u_b2b(unsigned(bitdur_ctr)=1);
      end if;  



      sym_last <= not (prime or rst) and (sym_last or (code_rd and code_last));
      dout_done <= not (prime or rst) and (all_done or (code_rd and sym_last));
      
    end if;
  end process;


  code_last <= bitdur_ctr_atlim and shreg_atlim and mem_done;
  sym_rdr: symbol_reader
    generic map(
      M_MAX     => M_MAX,
      LOG2M_MAX => LOG2M_MAX,
      LOG2M_W   => 2,
      SYMLEN_W  => SYMLEN_W,
      DIN_W     => CODE_W)
    port map(
      clk     => clk,
      rst     => rst,
      prime   => prime_dd,
      en      => en,

      din      => cur_code,
      din_r    => code_rd,
      
      symlen_min1_asamps => symlen_min1_asamps,
      -- when this component generates M-PSK, M is determined by:
      log2m  => log2m,
      -- TODO: why doesnt log2m come from symlen asamps???!!1
      
      dout     => dout_pre,
      dout_vld => dout_vld);

  gen_out: for k in 0 to 3 generate
  begin
    dout((k+1)*DAC_W-1 downto k*DAC_W) <= dout_pre(k*2+1 downto k*2) & u_rpt('0', DAC_W-2);
  end generate gen_out;
  
end architecture rtl;

