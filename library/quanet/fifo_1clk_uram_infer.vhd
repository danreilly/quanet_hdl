
-- fifo_1c2p_uram_infer
-- single clock dual port fifo made of Ultra RAM, inferred

library ieee;
use ieee.std_logic_1164.all;
entity fifo_1clk_uram_infer is
  generic (
    C_AWIDTH : in integer := 12;
    C_DWIDTH : in integer := 72;
    C_NBPIPE : in integer := 3);
  port (
    clk: in std_logic;
    rst: in std_logic;

    -- Port A
    w    : in  std_logic;                              
    din  : in  std_logic_vector(C_DWIDTH-1 downto 0); 
    full : out std_logic;

    r        : in  std_logic;
    dout     : out std_logic_vector(C_DWIDTH-1 downto 0);
    dout_vld : out std_logic;
    mt       : out std_logic);
end fifo_1clk_uram_infer;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture struct of fifo_1clk_uram_infer is

  component uram_infer is
    generic (
      C_AWIDTH : in integer := 12;
      C_DWIDTH : in integer := 72;
      C_NBPIPE : in integer := 3);
    port (
      clk: in std_logic;

      -- Port A
      wea     : in std_logic;
      mem_ena : in std_logic;
      dina    : in std_logic_vector(C_DWIDTH-1 downto 0); 
      addra   : in std_logic_vector(C_AWIDTH-1 downto 0);
      douta   : out std_logic_vector(C_DWIDTH-1 downto 0); 

      -- Port b 
      web     : in std_logic;
      mem_enb : in std_logic;
      dinb    : in std_logic_vector(C_DWIDTH-1 downto 0); 
      addrb   : in std_logic_vector(C_AWIDTH-1 downto 0);
      doutb   : out std_logic_vector(C_DWIDTH-1 downto 0));
  end component;

  signal waddr, raddr: std_logic_vector(C_AWIDTH-1 downto 0);
  signal w_i, r_i, full_i: std_logic := '0';
  signal mt_i: std_logic := '1';

  type a_addr_t is array(0 to  C_NBPIPE-1) of std_logic_vector(C_AWIDTH-1 downto 0);
  signal waddr_a, raddr_a: a_addr_t;
  signal w_dlyd, r_dlyd: std_logic_vector(C_NBPIPE+1 downto 0) := (others=>'0');
  
begin

  w_i <= w and not full_i and not rst;
  r_i <= r and not mt_i   and not rst;
  full <= full_i;
  mt   <= mt_i;



  process(clk)
  begin
    if (rising_edge(clk)) then
      
      
      if (rst='1') then
        waddr <= (others=>'0');
      elsif (w_i='1') then
        waddr <= (std_logic_vector(unsigned(waddr)+1));
      end if;
      if (rst='1') then
        w_dlyd <= (others=>'0');
      else        
        w_dlyd(0)  <= w_i;
        w_dlyd(C_NBPIPE+1 downto 1) <= w_dlyd(C_NBPIPE downto 0);
      end if;
      waddr_a(0) <= waddr;
      for i in 1 to C_NBPIPE-1 loop
        waddr_a(i) <= waddr_a(i-1);
      end loop;
      

      if (rst='1') then
        raddr  <= (others=>'0');
      elsif (r_i='1') then
        raddr <= (std_logic_vector(unsigned(raddr)+1));
      end if;
      if (rst='1') then
        r_dlyd <= (others=>'0');
      else
        r_dlyd(0) <= r_i;
        r_dlyd(C_NBPIPE+1 downto 1) <= r_dlyd(C_NBPIPE downto 0);
      end if;        

      if (rst='1') then
        mt_i <= '1';
      -- not sure if the fall of mt must be delayed after w_i, but it's safe at least
      elsif (w_dlyd(C_NBPIPE)='1') then
        mt_i <= '0';
      -- not sure if I must use waddr_a here
      elsif ((r_i and u_b2b(unsigned(raddr)+1=unsigned(waddr_a(C_NBPIPE-1))))='1') then
        mt_i <= '1';
      end if;
      
      if ((rst or r_i)='1') then
        full_i <= '0';
      elsif ((w_i and u_b2b(unsigned(raddr)=unsigned(waddr)+2))='1') then
        full_i <= '1';
      end if;
      
    end if;
  end process;
  dout_vld <= r_dlyd(C_NBPIPE+1);
  
  uram_i: uram_infer
    generic map (
      C_AWIDTH => C_AWIDTH,
      C_DWIDTH => C_DWIDTH,
      C_NBPIPE => C_NBPIPE)
    port map(
      clk => clk,

      -- Port A
      wea     => '1',
      mem_ena => w_i,
      dina    => din,
      addra   => waddr,
--    douta   => unused,

      -- Port b 
      web     => '0',
      mem_enb => '1',
      dinb    => (others=>'0'),
      addrb   => raddr,
      doutb   => dout);
      
end struct;  
