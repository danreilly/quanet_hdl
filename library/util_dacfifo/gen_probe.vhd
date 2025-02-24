
-- Example:
-- probe_len_min1=3
-- osamp_min1=3
-- probe_qty_min1=1
--
--  probe_first     ____-________________________________
--  probe_tx        ____-__________________________-_____
--  en              --------------------
--  probe_vld         _____--------_______
--  probe_ctr              76543210
--  probe_ctr_atlim  _____________-_______

--  lfsr_rst        ____-_______________
--  lfsr_en         ____--------________
--  lfsr_data       _____ABCDEFGHHHHHHHH
--  dout                  

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity gen_probe is
  port (
    clk : in std_logic;
    rst: in std_logic;

    gen_en      : in std_logic; -- if 0, probe_first and probe_tx ignored
    tx_0        : in std_logic;
    probe_first : in std_logic;
    probe_tx    : in std_logic;

    en: in std_logic;

    osamp_min1   : in std_logic_vector(G_OSAMP_W-1 downto 0); -- currently ignored
    probe_len_min1 : in std_logic_vector(G_PROBE_LEN_W-1 downto 0); -- units of cycles at 308MHz

    probe_vld  : out std_logic; -- high only during the headers
    dout       : out std_logic_vector(63 downto 0));
end gen_probe;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of gen_probe is

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
  signal probe_ctr: std_logic_vector(G_PROBE_LEN_W-1 downto 0) := (others=>'0');

  signal tx, tx_pend, tx_pend_first, pd_ctr_atlim, lsfr_rst, lfsr_en, probe_end,
    probe_vld_i, probe_vld_o, probe_ctr_atlim, osamp_ctr_atlim, lfsr_rst
    : std_logic:='0';
  signal lfsr_data: std_logic_vector(0 downto 0);

begin

  lfsr_rst <= rst or (gen_en and probe_first);
  
  lfsr_en  <= (gen_en and probe_tx) or (probe_vld_i and en and not probe_ctr_atlim);

  lfsr0: lfsr_w
    generic map(
      W => 1,
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
  
-- dout(127 downto 112) <= (not lfsr_data(1)) & "100000000000000";
--- dout(111 downto  96) <= (not lfsr_data(1)) & "100000000000000";
-- dout( 95 downto  80) <= (not lfsr_data(1)) & "100000000000000";
-- dout( 79 downto  64) <= (not lfsr_data(1)) & "100000000000000";

  dout(63 downto 48) <= (not lfsr_data(0)) & "100000000000000";
  dout(47 downto 32) <= (not lfsr_data(0)) & "100000000000000";
  dout(31 downto 16) <= (not lfsr_data(0)) & "100000000000000";
  dout(15 downto  0) <= (not lfsr_data(0)) & "100000000000000";

--  tx <= pd_ctr_atlim and (tx_always or tx_pend);

  probe_end <= en and probe_ctr_atlim;
--  pd_tic <= pd_ctr_atlim;
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then

                  
--      if (rst='1') then
--        txing_i <= '0';
--      elsif ((gen_en and probe_tx)='1') then
--        txing_i <= '1';
--      end if;     

      probe_vld_o <= ((gen_en and probe_tx and not tx_0) or probe_vld_o) and not (rst or probe_end);
      probe_vld_i <= ((gen_en and probe_tx) or probe_vld_i) and not (rst or probe_end);

--      if (not probe_vld_i or (en and osamp_ctr_atlim))='1') then
--        osamp_ctr <= osamp_min1;
--        osamp_ctr_atlim <= u_b2b(unsigned(osamp_min1)=0));
--      elsif (en='1') then
--        osamp_ctr <= std_logic_vector(unsigned(osamp_ctr)-1);
--        osamp_ctr_atlim <= u_b2b((unsigned(osamp_ctr)=1));
--      end if;
      
      osamp_ctr_atlim <= '1';

      -- count the cycles in each probe
      if ((rst or not probe_vld_i) ='1') then
        probe_ctr       <= probe_len_min1;
        probe_ctr_atlim <= '0';
      elsif ((en and osamp_ctr_atlim)='1') then
        probe_ctr       <= std_logic_vector(unsigned(probe_ctr)-1);
        probe_ctr_atlim <= u_b2b(unsigned(probe_ctr)=1);
      end if;
      
    end if;
  end process;
  
  probe_vld <= probe_vld_o;

end rtl;
  
