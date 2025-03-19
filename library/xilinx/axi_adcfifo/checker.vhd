library ieee;
use ieee.std_logic_1164.all;
entity checker is
  port (
    ctl_clk   : in std_logic;
    rd        : in std_logic;
    rd_ack    : out std_logic;
    sel       : in std_logic_vector(1 downto 0);
    maxd      : out std_logic_vector(11 downto 0);

    clk    : in std_logic;  -- typically 250MHz
    din    : in std_logic_vector(127 downto 0));  -- asserted by dmac
end checker;

-- library unisim;
-- use unisim.vcomponents.all;
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_samp_pkg.all;
--use work.cdc_pulse_pkg.all;

architecture struct of checker is
  signal x: std_logic;
  type chan_a_t is array (3 downto 0) of std_logic_vector(11 downto 0);

  signal rd_rc, rd_rc_d: std_logic:='0';
  signal t1, t2: std_logic_vector(11 downto 0);
  signal din_i_a, din_q_a, din_d_a, diff_a, max_a,
     max_reg_a: chan_a_t := (others => (others => '0')); --  std_logic_vector(15 downto 0);
begin
  gen_ch: for ch in 0 to 3 generate
    din_i_a(ch) <= din(ch*32+11    downto ch*32);
    din_q_a(ch) <= din(ch*32+11+16 downto ch*32+16);

    samp_max: cdc_samp
      generic map( W => 12)
      port map(
        in_data  => max_a(ch),
        out_data => max_reg_a(ch),
        out_clk  => ctl_clk);
    
  end generate gen_ch;

  cdc_rd: cdc_samp
    generic map( W => 1)
    port map(
      in_data(0)  => rd,
      out_data(0) => rd_rc,
      out_clk  => clk);
  
  cdc_rd_ack: cdc_samp
    generic map( W => 1)
    port map(
      in_data(0)  => rd_rc,
      out_data(0) => rd_ack,
      out_clk  => ctl_clk);

  
  din_d_a(3 downto 1) <= din_i_a(2 downto 0);
  process(clk)
  begin
    if (rising_edge(clk)) then
      din_d_a(0) <= din_i_a(3);
      for ch in 0 to 3 loop
--        t1 <= std_logic_vector(signed(din_i_a(ch))-signed(din_d_a(ch)));
        diff_a(ch) <= u_abs(std_logic_vector(signed(din_i_a(ch))-signed(din_d_a(ch))));
        if (rd_rc='0') then
          if (rd_rc_d='1') then
            max_a(ch) <= (others=>'0');
          elsif (unsigned(diff_a(ch))>unsigned(max_a(ch))) then
            max_a(ch) <= diff_a(ch);
          end if;
        end if;
        rd_rc_d <= rd_rc;
      end loop;
        
    end if;
  end process;

  process(ctl_clk)
  begin
    if (rising_edge(ctl_clk)) then
      maxd <= max_reg_a(to_integer(unsigned(sel)));
    end if;
  end process;
  
end architecture struct;
