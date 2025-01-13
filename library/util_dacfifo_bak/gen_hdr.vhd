library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;

-- Example:
-- hdr_len_min1=3
-- osamp_min1=3
-- hdr_qty_min1=1
--
--  hdr_first       ____-________________________________
--  hdr_tx          ____-__________________________-_____
--  en              --------------------
--  hdr_vld         _____--------_______
--  word_ctr             76543210
--  word_ctr_atlim  ____________-_______

--  lfsr_rst        ____-_______________
--  lfsr_en         ____--------________
--  lfsr_data       _____ABCDEFGHHHHHHHH
--  dout                  


entity gen_hdr is
  port (
    clk : in std_logic;
    rst: in std_logic;

    gen_en    : in std_logic; -- if 0, hdr_first and hdr_tx ignored
    tx_0      : in std_logic;
    hdr_first : in std_logic;
    hdr_tx    : in std_logic;

    en: in std_logic;

    osamp_min1   : in std_logic_vector(G_OSAMP_W-1 downto 0);
    hdr_len_min1 : in std_logic_vector(G_HDR_LEN_W-1 downto 0); -- units of 4-symbols

    hdr_vld  : out std_logic; -- high only during the headers
    dout     : out std_logic_vector(127 downto 0));
end gen_hdr;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of gen_hdr is

  -- b2b stands for "Boolean to Bit".  It's a very useful conversion.
  function u_b2b(b: boolean)
    return std_logic is
  begin
    if (b) then return '1';
    else return '0';
    end if;
  end function u_b2b;

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
    clk: in std_logic);
  end component;
  
  signal osamp_ctr: std_logic_vector(G_OSAMP_W-1 downto 0) := (others=>'0');
  signal word_ctr: std_logic_vector(G_HDR_LEN_W-1 downto 0) := (others=>'0');

  signal tx, tx_pend, tx_pend_first, pd_ctr_atlim, lsfr_rst, lfsr_en, hdr_end,
    hdr_vld_i, hdr_vld_o, word_ctr_atlim, osamp_ctr_atlim, hdr_ctr_atlim, lfsr_rst
    : std_logic:='0';
  signal lfsr_data: std_logic_vector(1 downto 0);

begin

  lfsr_rst <= rst or (gen_en and hdr_first);
  
  lfsr_en  <= (gen_en and hdr_tx) or (hdr_vld_i and en and not word_ctr_atlim);

  lfsr0: lfsr_w
    generic map(
      W => 2,
      CP => "01000000001") -- x^11 + x^9 + 1
    port map(
      d_o => lfsr_data,
      en  => lfsr_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st => "10100001111",
      rst    => lfsr_rst,
--    err    => 
      clk    => clk);
  
 dout(127 downto 112) <= (not lfsr_data(1)) & "100000000000000";
 dout(111 downto  96) <= (not lfsr_data(1)) & "100000000000000";
 dout( 95 downto  80) <= (not lfsr_data(1)) & "100000000000000";
 dout( 79 downto  64) <= (not lfsr_data(1)) & "100000000000000";

  dout(63 downto 48) <= (not lfsr_data(0)) & "100000000000000";
  dout(47 downto 32) <= (not lfsr_data(0)) & "100000000000000";
  dout(31 downto 16) <= (not lfsr_data(0)) & "100000000000000";
  dout(15 downto  0) <= (not lfsr_data(0)) & "100000000000000";

--  tx <= pd_ctr_atlim and (tx_always or tx_pend);

  hdr_end <= en and word_ctr_atlim;
--  pd_tic <= pd_ctr_atlim;
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then

                  
--      if (rst='1') then
--        txing_i <= '0';
--      elsif ((gen_en and hdr_tx)='1') then
--        txing_i <= '1';
--      end if;     

      hdr_vld_o <= ((gen_en and hdr_tx and not tx_0) or hdr_vld_o) and not (rst or hdr_end);
      hdr_vld_i <= ((gen_en and hdr_tx) or hdr_vld_i) and not (rst or hdr_end);

--      if (not hdr_vld_i or (en and osamp_ctr_atlim))='1') then
--        osamp_ctr <= osamp_min1;
--        osamp_ctr_atlim <= u_b2b(unsigned(osamp_min1)=0));
--      elsif (en='1') then
--        osamp_ctr <= std_logic_vector(unsigned(osamp_ctr)-1);
--        osamp_ctr_atlim <= u_b2b((unsigned(osamp_ctr)=1));
--      end if;
      osamp_ctr_atlim <= '1';

      -- count the words in each header
      if ((rst or not hdr_vld_i) ='1') then
        word_ctr       <= hdr_len_min1;
        word_ctr_atlim <= '0';
      elsif ((en and osamp_ctr_atlim)='1') then
        word_ctr       <= std_logic_vector(unsigned(word_ctr)-1);
        word_ctr_atlim <= u_b2b(unsigned(word_ctr)=1);
      end if;
      
    end if;
  end process;
  
  hdr_vld <= hdr_vld_o;
--  txing <= txing_i;  
end rtl;
  
