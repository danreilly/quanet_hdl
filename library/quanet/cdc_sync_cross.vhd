

-- for passing data between syncgronous clocks that mmay have arbitratry fixed phase diff
-- with lowest possible latency.



library ieee;
use ieee.std_logic_1164.all;
package cdc_sync_cross_pkg is

  component cdc_sync_cross is
    generic (
      W: in integer);
    port (
      clk_in_bad : in std_logic;    
      clk_in : in std_logic;
      d_in   : in std_logic_vector(W-1 downto 0);
      clk_out_bad : in std_logic;    
      clk_out : in std_logic;
      changed : out std_logic; -- could be counted to monitor this CDC
      d_out  : out std_logic_vector(W-1 downto 0));
  end component;

end cdc_sync_cross_pkg;


library ieee;
use ieee.std_logic_1164.all;
entity cdc_sync_cross is
  generic (
    W: in integer);
  port (
    clk_in_bad : in std_logic;    
    clk_in : in std_logic;
    d_in   : in std_logic_vector(W-1 downto 0);
    clk_out_bad : in std_logic;    
    clk_out : in std_logic;
    changed : out std_logic; -- could be counted to monitor this CDC
    d_out  : out std_logic_vector(W-1 downto 0));
end cdc_sync_cross;


library ieee;
use ieee.numeric_std.all;
use work.cdc_thru_pkg.all;
architecture RTL of cdc_sync_cross is
  signal tog_r_i, tog_r, tog_r_u, tog_r_p, tog_r_exp,
    tog_f_i, tog_f, tog_f_u, tog_f_p, tog_f_exp,
    clk_in_bad_u, rst, rst2, rst2_u,
    ctr_at0, ctr_atlim, changed_i,
    err_r, err_f, outsel: std_logic :='0';
  signal d_in_0, d_in_1, d_in_0_u, d_in_1_u, d_out_i: std_logic_vector(W-1 downto 0) := (others=>'0');
  signal ctr: std_logic_vector(2 downto 0) := "100";

  attribute ASYNC_REG: string;
  -- place tog_r close to tog_r_p.  And tog_f close to tog_f_p.
  attribute ASYNC_REG of tog_r_p, tog_r, tog_f_p, tog_f: signal is "TRUE";
  -- place d_in_0 and d_in1 close to d_out.
  attribute ASYNC_REG of d_in_0, d_in_1, d_out: signal is "TRUE";

  -- put dont touch on these so we can set constraints
  attribute DONT_TOUCH: string;
  attribute DONT_TOUCH of
    tog_r_i, tog_f_i, clk_in_bad, rst2,
    tog_r_u, tog_f_u, clk_in_bad_u, rst2_u,
    d_in_0, d_in_1 : signal is "TRUE";
  
begin  
  process(clk_in) is
  begin
    if (rising_edge(clk_in)) then
      tog_r_i <= not tog_r_i;
      if (tog_r_i='0') then
        d_in_0 <= d_in;
      else
        d_in_1 <= d_in;
      end if;        
    end if;
    if (falling_edge(clk_in)) then
      tog_f_i <= tog_r_i;
    end if;
  end process;

  tog_r_u <= tog_r_i;
  tog_f_u <= tog_f_i;

  
  clk_in_bad_u <= clk_in_bad;
  rst2_u       <= rst2;
  
--  tog_thru: cdc_thru
--    generic map (
--      W=>4)
--    port map (
--      in_data(0)  => tog_r_i,
--      in_data(1)  => tog_f_i,
--      in_data(2)  => clk_in_bad,
--      in_data(3)  => rst2,
--      
--      out_data(0) => tog_r_u,
--      out_data(1) => tog_f_u,
--      out_data(2) => clk_in_bad_u,
--      out_data(3) => rst2_u); -- unclocked

  d0_thru: cdc_thru
    generic map (
      W=>W)
    port map (
      in_data  => d_in_0,
      out_data => d_in_0_u);
  d1_thru: cdc_thru
    generic map (
      W=>W)
    port map (
      in_data  => d_in_1,
      out_data => d_in_1_u);
  
  err_r <= tog_r xor tog_r_exp;
  err_f <= tog_f xor tog_f_exp;


  
  rst <= clk_in_bad_u or clk_out_bad;  
  process(clk_out, rst) is
  begin
    if (rst='1') then
      rst2 <= '1';
    elsif (rising_edge(clk_out)) then
      rst2 <= '0';
    end if;
  end process;

  
  process(clk_out) is
  begin
    if (rising_edge(clk_out)) then
      
      -- sample the rising and falling edge toggles
      -- clock jitter should affect only one of these.
      tog_r_p   <= tog_r_u;
      tog_f_p   <= tog_f_u;

      tog_r     <= not tog_r_p;
      tog_f     <= not tog_f_p;
      
      tog_r_exp <= not tog_r; -- expected
      tog_f_exp <= not tog_f; -- expected

      -- ctr provides hysterisis.  It counts up or down votes.
      if (rst2_u='1') then
        ctr       <= "100";
        ctr_at0   <= '0';
        ctr_atlim <= '0';
        outsel    <= '0';
        changed_i <= '0';
      else
        -- fall errors vote to use rise
        if (ctr_atlim='1') then
          ctr       <= "100";
          ctr_at0   <= '0';
          ctr_atlim <= '0';
        elsif ((not err_r and err_f and not ctr_atlim)='1') then
          ctr       <= std_logic_vector(unsigned(ctr)+1);
          ctr_at0   <= '0';
          ctr_atlim <= ctr(2) and ctr(1) and not ctr(0);
        -- rise errors vote to use fall
        elsif ((   err_r and not err_f and not ctr_at0)='1') then
          ctr       <= std_logic_vector(unsigned(ctr)-1);
          ctr_atlim <= '0';
          ctr_at0   <= not ctr(2) and not ctr(1) and ctr(0);
        end if;

        changed_i  <= ctr_atlim or ctr_at0;
        if (ctr_atlim='1') then -- use rise
          outsel <= not tog_r;
        elsif (ctr_at0='1') then -- use fall
          outsel <= not tog_f;
        else -- hold prior
          outsel <= not outsel;
        end if;

      end if;
      
      if (outsel='0') then
        d_out_i <= d_in_0_u;
      else
        d_out_i <= d_in_1_u;
      end if;
    end if;
  end process;
  d_out <= d_out_i;
  changed <= changed_i;
end RTL;
