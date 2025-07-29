-- gen_cipher
--
-- This generates a stream of M-psk symbols
-- based on an LFSR.  The security can eventually
-- be augmented with a TRNG and other means.

-- Example:
-- len_min1=3
-- osamp_min1=3
-- hdr_qty_min1=1
--
--  go_pulse        ____-______________-______-__
--  lfsr_state_ld   xxxx-xxxxxxxxxxxxxx-xxxxxx-xx
--  en              -----------------------------
--  ctr                  76543210       765432176543210
--  ctr_en          _____--------_______---------------___
--  ctr_atlim       ____________-_____________________-___

--  lfsr_state_in       a
--  lfsr_state           abcdefgh
--  lfsr_state_nxt_vld _________-____

--  lfsr_rst        ____-______________-______-__
--  lfsr_en         ____--------________
--  lfsr_data       _____ABCDEFGHHHHHHHH

--  dout_vld        ______--------_____
--  dout            ______ABCDEFGH_____
--

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package gen_cipher_pkg is
  
  component gen_cipher
    generic (
      LEN_W: in integer;
      CP: in std_logic_vector;
      M_MAX: in integer;
      LOG2M_MAX: in integer; -- 4
      LOG2M_W: in integer;   -- 3
      SYMLEN_ASAMPS_W: in integer;
      DAC_W: in integer); -- 16
    port (
      clk : in std_logic;
      rst : in std_logic;
      symlen_min1_asamps: in std_logic_vector(SYMLEN_ASAMPS_W-1 downto 0);

      -- when this component generates M-PSK, M is determined by:
      log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
      
      -- units of cycles (typ at 308MHz).  Except zero means lots of cycles, not 1.
      len_min1 : in std_logic_vector(LEN_W-1 downto 0);

      prime  : in  std_logic;

      lfsr_state_in  : in  std_logic_vector(CP'length-1 downto 0);
      lfsr_state_nxt : out std_logic_vector(CP'length-1 downto 0);
      
      go_pulse    : in std_logic;

      en: in std_logic;

      -- to the cipher fifo
      cipher_out     : out std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
      cipher_out_vld : out std_logic;
      
      -- to the datapath
      dout_vld     : out std_logic; -- high only during the headers
      dout         : out std_logic_vector(4*DAC_W-1 downto 0));
  end component;
  
end package;

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity gen_cipher is
  generic (
    LEN_W: in integer;
    CP: in std_logic_vector;
    M_MAX: in integer;     -- 8
    LOG2M_MAX: in integer; -- 3
    LOG2M_W: in integer;   -- 2
    SYMLEN_ASAMPS_W: in integer;
    DAC_W: in integer);    -- 16
  port (
    clk : in std_logic;
    rst : in std_logic;
    symlen_min1_asamps: in std_logic_vector(SYMLEN_ASAMPS_W-1 downto 0);

    -- when this generates "random" M-PSK symbols, M is determined by
    log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
    
    -- units of cycles (typ at 308MHz).  Except zero means lots of cycles, not 1.
    len_min1 : in std_logic_vector(LEN_W-1 downto 0);

    prime  : in  std_logic;

    lfsr_state_in  : in  std_logic_vector(CP'length-1 downto 0);
    lfsr_state_nxt : out std_logic_vector(CP'length-1 downto 0);

    
    go_pulse    : in std_logic;

    en: in std_logic;
    
    -- to the cipher fifo
    cipher_out     : out std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
    cipher_out_vld : out std_logic;
    
    -- to the datapath
    dout_vld     : out std_logic; -- high only during the headers
    dout         : out std_logic_vector(4*DAC_W-1 downto 0));
end gen_cipher;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.lfsr_w_pkg.all;
use work.symbolize_pkg.all;
architecture rtl of gen_cipher is

  signal ctr: std_logic_vector(LEN_W-1 downto 0) := (others=>'0');

  signal ctr_atlim, lsfr_rst, lfsr_en,
    lfsr_rst, ctr_en, ctr_en_d
    : std_logic:='0';

  signal lfsr_data, lfsr_data_flip: std_logic_vector(4*LOG2M_MAX-1 downto 0);

  signal lfsr4_state_nxt, lfsr2_state_nxt, lfsr1_state_nxt:
    std_logic_vector(CP'length-1 downto 0);

begin

  lfsr_rst <= rst or prime;

  lfsr: lfsr_w
    generic map(
      W  => 4*LOG2M_MAX,  -- or LCM of all possible log2m's.  Or add bitshift after
      CP => CP)
    port map(
      en  => lfsr_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st    => lfsr_state_in, 
      rst       => lfsr_rst,
      state_nxt => lfsr_state_nxt,

      d_o       => lfsr_data,
      
      clk       => clk);
  -- we want "first" bit to be lsb.
  lfsr_data_flip <= u_flip(lfsr_data);
  
  sym_i: symbolize
    generic map(
      M_MAX     => M_MAX,
      LOG2M_MAX => LOG2M_MAX,
      LOG2M_W   => LOG2M_W,
      SYMLEN_W  => SYMLEN_ASAMPS_W,
      DIN_W     => 4*LOG2M_MAX,
      DAC_W     => 16)
    port map (
      clk   => clk,
      rst   => '0',
      prime => prime,
      en    => ctr_en,

      din   => lfsr_data_flip,
      din_last => '0',
      din_r => lfsr_en,
      
      symlen_min1_asamps => symlen_min1_asamps,
      
      -- when this component generates M-PSK, M is determined by:
      log2m => log2m,
      dout  => dout);

  cipher_out     <= lfsr_data_flip;
  cipher_out_vld <= lfsr_en;
  
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      if ((go_pulse or (ctr_en and ctr_atlim))='1') then
        ctr       <= len_min1;
        ctr_atlim <= '0'; -- len_min1 may never be zero.
      elsif (ctr_en='1') then
        ctr       <= u_dec(ctr);
        ctr_atlim <= u_b2b(unsigned(ctr)=1);
      end if;
      ctr_en   <= en and (go_pulse or (ctr_en and not ctr_atlim));
      ctr_en_d <= ctr_en;
    end if;
  end process;
  dout_vld <= ctr_en_d;
  
end rtl;
  
