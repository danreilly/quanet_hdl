-- Typically used to count statistics for the processor, sometimes for debug.
-- counts events in one clock domain.
-- transfers them to another (typically the processor's) clock domain.
-- May be cleared. This ctl sig is in proc clock domain.

library ieee;
use ieee.std_logic_1164.all;
package event_ctr_pkg is

  component event_ctr is
  generic (
    W: integer);
  port (
    clk   : in std_logic;
    event : in std_logic; -- in clk domain
    
    rclk  : in std_logic; -- typically proc clk.
    clr   : in std_logic; -- in domain of rclk
    cnt   : out std_logic_vector(W-1 downto 0)); -- in rclk domain
  end component;

end event_ctr_pkg;

library ieee;
use ieee.std_logic_1164.all;
entity event_ctr is
  generic (
    W: integer);
  port (
    clk   : in std_logic;
    event : in std_logic;
    
    rclk  : in std_logic; -- typically proc clk.
    clr   : in std_logic;
    cnt   : out std_logic_vector(W-1 downto 0));
end event_ctr;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.cdc_pulse_pkg.all;
use work.cdc_samp_pkg.all;
use work.cdc_thru_pkg.all;
  
architecture struct of event_ctr is
  signal ctr_l, ctr_uc, ctr_still, cnt_i: std_logic_vector(W-1 downto 0) := (others=>'0');
  signal clr_pc, req_tog, req_c, req_d, ack_tog, ack_pc, ack_d, ctr_atlim: std_logic :='0';
begin
  
  clr_pb: cdc_pulse
    port map(
      in_pulse  => clr,
      in_clk    => rclk,
      out_pulse => clr_pc,
      out_clk   => clk);

  process(clk)
  begin
    if (rising_edge(clk)) then
      if (clr_pc='1') then
        ctr_l <= (others=>'0');
        ctr_atlim <= '0';
      elsif ((event and not ctr_atlim)='1') then
        ctr_l <= std_logic_vector(unsigned(ctr_l) + 1);
        if (unsigned(not ctr_l(W-1 downto 1))=0) then
          ctr_atlim <= '1';
        else
          ctr_atlim <= '0';
        end if;
      end if;
      
      if ((ack_pc xor req_tog)='0') then
        ctr_still <= ctr_l;
        req_tog   <= not req_tog;
      end if;

    end if;
  end process;

  -- 
  ctr_thru: cdc_thru
    generic map(W=>W)
    port map(
      in_data  => ctr_still,
      out_data => ctr_uc);

  req_thru: cdc_samp
    generic map(W=>1)
    port map(
      in_data(0)  => req_tog,
      out_data(0) => req_c,
      out_clk     => rclk);

  ack_thru: cdc_samp
    generic map(W=>1)
    port map(
      in_data(0)  => ack_tog,
      out_data(0) => ack_pc,
      out_clk     => clk);
  
  process(rclk)
  begin
    if (rising_edge(rclk)) then
      if ((req_c xor ack_tog)='1') then
        cnt_i   <= ctr_uc;
        ack_tog <= req_c;
      end if;
    end if;
  end process;
  
  cnt <= cnt_i;
  
end architecture struct;
    

