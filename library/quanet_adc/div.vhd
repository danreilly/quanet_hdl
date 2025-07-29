
library ieee;
use ieee.std_logic_1164.all;
entity div is
  generic (
    DIVIDEND_W: in integer;
    DIVISOR_W: in integer;
    QUO_W: in integer);
  port (
    clk : in std_logic;
    rst : in std_logic;
    dividend: in std_logic_vector(DIVIDEND_W-1 downto 0); -- sampled on go
    divisor: in std_logic_vector(DIVISOR_W-1 downto 0); -- sampled on go
    go:      in std_logic;
    
    quo_vld: out std_logic; -- 1=both quo and remain are valid
    quo:     out std_logic_vector(QUO_W-1 downto 0);
    remain:  out std_logic_vector(DIVISOR_W-QUO_W-1 downto 0);
    divby0:  out std_logic);
end entity div;

library ieee;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
architecture struct of div is
  constant CTR_W: integer := u_bitwid(DIVIDEND_W);
  type st_t is (IDL, ALIGN, RUN);
  signal st: st_t := IDL;
  signal num_i, div_i: std_logic_vector(DIVIDEND_W downto 0); -- see note in ALIGN state
  signal quo_i: std_logic_vector(QUO_W-1 downto 0);  
  signal ctr: std_logic_vector(CTR_W downto 0);  
  signal num_gte_div, quo_ovf, quo_vld_i, divby0_i: std_logic := '0';
begin

  num_gte_div <= u_b2b(unsigned(num_i)>=unsigned(div_i));
  
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      if (rst='1') then
        st <= IDL;
      else
        case (st) is
          when IDL =>
            if (go='1') then
              ctr   <= (others=>'0');
              num_i <= "0"&dividend;
              div_i <= u_extl(divisor, DIVIDEND_W+1);
              quo_i <= (others=>'0');
              quo_ovf <= '0';
              st <= ALIGN;
            end if;
          when ALIGN =>
            -- shift dividend left until it's bigger than numerator.
            -- If divisor were all ones (111), dividend would have to reach one more (1000)
            -- so that's why num_i and div_i are of width DIVIDEND_W+1.
            if (divby0_i='1') then
              st <= IDL;
            elsif (num_gte_div='1') then
              ctr   <= u_inc(ctr);
              div_i <= div_i(DIVIDEND_W-1 downto 0)&"0";
              divby0_i <=  u_b2b(unsigned(ctr)>=DIVIDEND_W);
              -- there are faster detections for divide by zero,
              -- but this is a minimal-resource method.
            else
              st <= RUN;
            end if;
          when RUN =>
            if (num_gte_div='1') then
              num_i <= std_logic_vector(unsigned(num_i) - unsigned(div_i));
              quo_i <= quo_i(QUO_W-2 downto 0)&"1";
            else
              quo_i <= quo_i(QUO_W-2 downto 0)&"0";
            end if;
            quo_ovf <= quo_ovf or quo_i(QUO_W-1);
            div_i <= "0"&div_i(DIVIDEND_W downto 1);
            if (unsigned(ctr)=0) then
              st <= IDL;
            else
              ctr <= u_dec(ctr);
            end if;
        end case;
      end if;
      quo_vld_i <= u_b2b(   ((st=RUN) and (unsigned(ctr)=0))
                         or ((st=ALIGN) and (divby0_i='1')));
    end if;
  end process;

  quo_vld    <= quo_vld_i;
  divby0     <= divby0_i;
  quo        <= quo_i;
  remain     <= num_i(DIVISOR_W-QUO_W-1 downto 0);

end architecture struct;


