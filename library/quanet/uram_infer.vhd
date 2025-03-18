
-- This code opbtained from Vivado Languate Template
-- VHDL / Synthesis Constructs / Coding Examples /
--     RAM / UltraRAM / True Dual Port / Non Byte-write

--  Xilinx UltraRAM True Dual Port Mode.  This code implements 
--  a parameterizable UltraRAM block with write/read on both ports in 
--  No change behavior on both the ports . The behavior of this RAM is 
--  when data is written, the output of RAM is unchanged w.r.t each port. 
--  Only when write is inactive data corresponding to the address is 
--  presented on the output port.

library ieee;
use ieee.std_logic_1164.all;
entity uram_infer is
  generic (
    C_AWIDTH : in integer := 12;
    C_DWIDTH : in integer := 72;
    C_NBPIPE : in integer := 3);
  port (
    clk: in std_logic;

    -- Port A
    wea :  in std_logic;                              
    mem_ena : in  std_logic;                          
    dina :  in std_logic_vector(C_DWIDTH-1 downto 0); 
    addra : in  std_logic_vector(C_AWIDTH-1 downto 0);
    douta : out std_logic_vector(C_DWIDTH-1 downto 0); 

    -- Port b 
    web       : in  std_logic;                              
    mem_enb   :  in std_logic;                          
    dinb      :  in std_logic_vector(C_DWIDTH-1 downto 0); 
    addrb     :  in std_logic_vector(C_AWIDTH-1 downto 0);
    doutb     : out std_logic_vector(C_DWIDTH-1 downto 0));
end uram_infer;

library ieee;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
architecture struct of uram_infer is

  signal goo: std_logic;
--  type foo_t is integer;
  type apps is range 0 to 100;  
  subtype pipe_en_t is std_logic_vector(C_NBPIPE downto 0);
  
  type mem_t is array(integer range 0 to 2**C_AWIDTH-1)
    of std_logic_vector(C_DWIDTH-1 downto 0);
  
  type pipe_data_t is array(integer range 0 to C_NBPIPE-1)
    of std_logic_vector(C_DWIDTH-1 downto 0);

  shared variable mem : mem_t;

  signal memrega : std_logic_vector(C_DWIDTH-1 downto 0);              
  signal mem_pipe_rega : pipe_data_t;    -- Pipelines for Memory
  signal mem_en_pipe_rega : pipe_en_t;     -- Pipelines for Memory enable  

  signal memregb : std_logic_vector(C_DWIDTH-1 downto 0);              
  signal mem_pipe_regb : pipe_data_t;    -- Pipelines for Memory
  signal mem_en_pipe_regb, bvld: pipe_en_t;     -- Pipelines for Memory enable  
  attribute ram_style : string;

  attribute ram_style of mem : variable is "ultra";

begin
  
-- RAM : Read has one latency, Write has one latency as well.
  process(clk)
  begin
    if(clk'event and clk='1')then
      if(mem_ena = '1') then
        if(wea = '1') then
          mem(to_integer(unsigned(addra))) := dina;
        else
          memrega <= mem(to_integer(unsigned(addra)));
        end if;
      end if;
    end if;
  end process;

  -- The enable of the RAM goes through a pipeline to produce a
  -- series of pipelined enable signals required to control the data
  -- pipeline.
  process(clk)
  begin
    if(clk'event and clk = '1') then
      mem_en_pipe_rega(0) <= mem_ena;
      for i in 0 to C_NBPIPE-1 loop
        mem_en_pipe_rega(i+1) <= mem_en_pipe_rega(i);
      end loop;
    end if;
  end process;

  -- RAM output data goes through a pipeline.
  process(clk)
  begin
    if(clk'event and clk = '1') then
      if(mem_en_pipe_rega(0) = '1') then
        mem_pipe_rega(0) <= memrega;
      end if;
      for i in 0 to C_NBPIPE-2 loop
        if(mem_en_pipe_rega(i+1) = '1') then
          mem_pipe_rega(i+1) <= mem_pipe_rega(i);
        end if;
      end loop;
    end if;
  end process;

  process(clk)
  begin
    if(clk'event and clk = '1') then
      if(mem_en_pipe_rega(C_NBPIPE) = '1' ) then
        douta <= mem_pipe_rega(C_NBPIPE-1);
      end if;
    end if;    
  end process;


  process(clk)
  begin
    if(clk'event and clk='1')then
      if(mem_enb = '1') then
        if(web = '1') then
          mem(to_integer(unsigned(addrb))) := dinb;
        else
          memregb <= mem(to_integer(unsigned(addrb)));
        end if;
      end if;
    end if;
  end process;

-- The enable of the RAM goes through a pipeline to produce a
-- series of pipelined enable signals required to control the data
-- pipeline.
  process(clk)
  begin
    if(clk'event and clk = '1') then
      mem_en_pipe_regb(0) <= mem_enb;
      for i in 0 to C_NBPIPE-1 loop
        mem_en_pipe_regb(i+1) <= mem_en_pipe_regb(i);
      end loop;
    end if;
  end process;

-- RAM output data goes through a pipeline.
  process(clk)
  begin
    if(clk'event and clk = '1') then
      if(mem_en_pipe_regb(0) = '1') then
        mem_pipe_regb(0) <= memregb;
      end if;
      for i in 0 to C_NBPIPE-2 loop
        if(mem_en_pipe_regb(i+1) = '1') then
          mem_pipe_regb(i+1) <= mem_pipe_regb(i);
        end if;
      end loop;
    end if;
  end process;

  process(clk)
  begin
    if(clk'event and clk = '1') then
      if(mem_en_pipe_regb(C_NBPIPE) = '1') then
        doutb <= mem_pipe_regb(C_NBPIPE-1);
      end if;
    end if;    
  end process;
  
end architecture struct;
