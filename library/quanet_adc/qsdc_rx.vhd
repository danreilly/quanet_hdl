
-- incomming data must already be cycle aligned

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package qsdc_rx_pkg is

  type qsdc_sum_array_t is array(0 to 3) of std_logic_vector(G_QSDC_SUM_W-1 downto 0);

  component qsdc_rx is
    generic (
      SAMP_W: integer;
      SYMLEN_W: integer;
      CODE_W: integer;
      SUM_W: integer);
    port (
      clk : in std_logic;
      code                   : in std_logic_vector(CODE_W-1 downto 0);
      use_transitions        : in std_logic;
      qsdc_pos_min1_cycs     : in std_logic_vector(G_QSDC_FRAME_CYCS_W-3 downto 0);
      qsdc_data_syms_min1    : in std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
      qsdc_symlen_min1_cycs  : in std_logic_vector(SYMLEN_W-1 downto 0); -- 3
      qsdc_bit_len_min1_syms : in std_logic_vector(SYMLEN_W-1 downto 0); -- 3

      -- The priming pulse indicates the start of the first bit.
      -- It may be simultaneous with frame_start but not after it.
      -- It does not happen before every frame.
      -- It may not happen during any preceeding data_vld
      prime_pul   : in std_logic;
      
      frame_start : in std_logic;
      ii          : in g_adc_samp_array_t;
      qq          : in g_adc_samp_array_t;

      
      sum_vld : out std_logic;
      sum     : out qsdc_sum_array_t);
  end component;

end package;



library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
use work.qsdc_rx_pkg.all;
entity qsdc_rx is
  generic (
    SAMP_W: integer;
    SYMLEN_W: integer;
    CODE_W: integer;
    SUM_W: integer);
  port (
    clk : in std_logic;
    code                   : in std_logic_vector(CODE_W-1 downto 0);
    use_transitions        : in std_logic;
    qsdc_pos_min1_cycs     : in std_logic_vector(G_QSDC_FRAME_CYCS_W-3 downto 0);
    qsdc_data_syms_min1    : in std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
    qsdc_symlen_min1_cycs  : in std_logic_vector(SYMLEN_W-1 downto 0); -- 3
    qsdc_bit_len_min1_syms : in std_logic_vector(SYMLEN_W-1 downto 0); -- 3

    -- The priming pulse indicates the start of the first bit.
    -- It may be simultaneous with frame_start but not after it.
    -- It does not happen before every frame.
    -- It may not happen during any preceeding data_vld
    prime_pul   : in std_logic;
    
    frame_start : in std_logic;
    ii          : in g_adc_samp_array_t;
    qq          : in g_adc_samp_array_t;

    
    sum_vld : out std_logic;
    sum     : out qsdc_sum_array_t);
end qsdc_rx;
    
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.global_pkg.all;
use work.duration_ctr_pkg.ALL;
architecture struct of qsdc_rx is
  signal ii_sgned, qq_sgned: g_adc_samp_array_t;
  signal data_start, data_vld, sym_start, sym_end, data_sym_last, bit_start,
    bit_sym_last, acc_en, primed: std_logic := '0';
  signal cyc_ctr: std_logic_vector(G_QSDC_FRAME_CYCS_W-1 downto 0);
  signal data_sym_ctr:  std_logic_vector(SYMLEN_W-1 downto 0);
  signal bit_sym_ctr:  std_logic_vector(SYMLEN_W-1 downto 0);
  signal code_shreg: std_logic_vector(CODE_W-1 downto 0);
  signal ii_acc, qq_acc: qsdc_sum_array_t;
begin

  frame_start_dly_ctr: duration_ctr
     generic map (
       LEN_W => G_QSDC_FRAME_CYCS_W)
     port map(
       clk      => clk,
       rst      => '0',
       go_pul   => frame_start,
       len_min1 => qsdc_pos_min1_cycs,
       sig_last => data_start);

-- symbols per frame = 10
-- symbols per bit   = 4
-- below is one frame
  
-- prime        _-_______________________________________________
-- data_start   ____-____________________________________________
-- data_vld     _____----------------------------------------____
-- bit_start    __----
-- cyc_ctr           32103210321032103210321032103210321032103333
-- sym_start    _____-___-___-___-___-___-___-___-___-___-___----
-- sym_end      ________-___-___-___-___-___-___-___-___-___-____
-- acc_en       ______--__--__--__--__--__--__--__--__--__--_____
-- data_sym_ctr xxxxx99998888777766665555444433332222111100000000
-- data_sym_last xxxxx____________________________________-------
-- code_sgn     xxpppppppmmmmppppmmmmppppmmmmppppmmmmppppmmmmpppp
-- bit_start    xx-----______________--______________--__________
-- bit_sym_ctr  xx33333332222111100003333222211110000333322221111
-- bit_sym_last xx_______________----____________----____________
-- sumvld       _____________________-_______________-___________
-- sum          xxxxxxxabbbcdddefffghh abbbcdddefffghh abbbcddddd

  gen_per_ss: for ss in 0 to 3 generate -- per sub-cycle
  begin
    ii_sgned(ss) <= ii(ss) when (code_shreg(0)='0') else u_neg(ii(ss));
    qq_sgned(ss) <= qq(ss) when (code_shreg(0)='0') else u_neg(qq(ss));
    sum(ss)      <= ii_acc(ss);
  end generate gen_per_ss;

  -- This signal is hi when we should accumulate ii_sgned.
  acc_en <= data_vld and (use_transitions or (not sym_start or not sym_end));
  
  process(clk)
  begin
    if (rising_edge(clk)) then

      -- This is high while ii_sgned and qq_sgned carry the data body
      data_vld <= (data_start or data_vld) and not (data_sym_last and sym_end);

      -- This counts cycles to mark symbols.
      if ((data_start or (data_vld and sym_end))='1') then
        cyc_ctr   <= qsdc_symlen_min1_cycs;
        sym_end  <= u_b2b(unsigned(qsdc_symlen_min1_cycs)=0);
        sym_start <= '1';
      else
        cyc_ctr   <= u_dec(cyc_ctr);
        sym_end   <= u_b2b(unsigned(cyc_ctr)=1);
        sym_start <= '0';
      end if;

      -- This counts symbols to deliniate the data body
      if (data_start='1') then
        data_sym_ctr  <= qsdc_data_syms_min1;
        data_sym_last <= '0';
      elsif ((data_vld and sym_end and not data_sym_last)='1') then
        data_sym_ctr  <= u_dec(data_sym_ctr); -- symbols in the bit
        data_sym_last <= u_b2b(unsigned(data_sym_ctr)=1);
      end if;

      -- This circularly cycles the code so we know what sign to use when accumulating
      if ((prime_pul or (data_vld and bit_sym_last and sym_end))='1') then
        code_shreg <= code;
      elsif (sym_end='1') then
        code_shreg <= code_shreg(0)&code_shreg(CODE_W-1 downto 1);
      end if;

      -- this is high to make start of bit
      if ((prime_pul or (bit_sym_last and sym_end))='1') then
        bit_start <='1';
      elsif (acc_en='1') then
        bit_start <='0';
      end if;

      -- this counts symbols to delinate bits
      if (prime_pul='1') then
        bit_sym_ctr  <= qsdc_bit_len_min1_syms;
        bit_sym_last <= '0';
      elsif ((data_vld and not bit_sym_last and sym_end)='1') then
        bit_sym_ctr  <= u_dec(bit_sym_ctr); -- symbols in the bit
        bit_sym_last <= u_b2b(unsigned(bit_sym_ctr)=1);
      end if;
      
      -- this does the accumulation
      if (acc_en='1') then
        for ss in 0 to 3 loop
          if (bit_start='1') then
            ii_acc(ss) <= u_extl_s(ii_sgned(ss), SUM_W);
--          qq_acc <= u_extl_s(qq_sgned, SUM_W);
          else
            ii_acc(ss) <= u_add_s_clamp(u_extl_s(ii_sgned(ss), SUM_W), ii_acc(ss));
--          qq_acc <= u_add_s_clamp(u_extl_s(qq_sgned, SUM_W), qq_acc);
          end if;
        end loop;
      end if;
      sum_vld <= data_vld and bit_sym_last and sym_end;
      
    end if;
  end process;
end  architecture struct;  
