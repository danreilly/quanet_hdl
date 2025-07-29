-- unfortunately the XPM library requires licenses for both SystemVerilog and SVA assertions.
-- msimpevsimvlog

library ieee;
use ieee.std_logic_1164.all;
entity rom_xpm is
  generic (
    FNAME: string;
    LATENCY: integer; -- 1 = norm, 2 = additional output reg
    D_W: integer := 16;
    A_W: integer := 6);
  port (
    clk  : in  std_logic;
    rd   : in  std_logic; -- OPTIONAL.  does not really cause a read.  but times dout_vld.
    addr     : in  std_logic_vector(A_W-1 downto 0);
    dout_vld : out std_logic; -- OPTIONAL.
    dout     : out std_logic_vector(D_W-1 downto 0));
end rom_xpm;
    

library ieee;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
library xpm;
use xpm.vcomponents.all;

architecture struct of rom_xpm is

-- XPM_MEMORY instantiation template for Single Port ROM configurations
-- Refer to the targeted device family architecture libraries guide for XPM_MEMORY documentation
-- =======================================================================================================================

-- Parameter usage table, organized as follows:
-- +---------------------------------------------------------------------------------------------------------------------+
-- | Parameter name       | Data type          | Restrictions, if applicable                                             |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Description                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- +---------------------------------------------------------------------------------------------------------------------+
-- | ADDR_WIDTH_A         | Integer            | Range: 1 - 20. Default value = 6.                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify the width of the port A address port addra, in bits.                                                        |
-- | Must be large enough to access the entire memory from port A, i.e. &gt;= $clog2(MEMORY_SIZE/READ_DATA_WIDTH_A).     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | AUTO_SLEEP_TIME      | Integer            | Range: 0 - 15. Default value = 0.                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Must be set to 0                                                                                                    |
-- | 0 - Disable auto-sleep feature                                                                                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | CASCADE_HEIGHT       | Integer            | Range: 0 - 64. Default value = 0.                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | 0- No Cascade Height, Allow Vivado Synthesis to choose.                                                             |
-- | 1 or more - Vivado Synthesis sets the specified value as Cascade Height.                                            |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | ECC_BIT_RANGE        | String             | Default value = 7:0.                                                    |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | This parameter is only used by synthesis. Specify the ECC bit range on the provided data.                           |
-- | "7:0" - it specifies lower 8 bits are ECC bits.                                                                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | ECC_MODE             | String             | Allowed values: no_ecc, both_encode_and_decode, decode_only, encode_only. Default value = no_ecc.|
-- |---------------------------------------------------------------------------------------------------------------------|
-- |                                                                                                                     |
-- |   "no_ecc" - Disables ECC                                                                                           |
-- |   "encode_only" - Enables ECC Encoder only                                                                          |
-- |   "decode_only" - Enables ECC Decoder only                                                                          |
-- |   "both_encode_and_decode" - Enables both ECC Encoder and Decoder                                                   |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | ECC_TYPE             | String             | Allowed values: none, ECCHSIAO32-7, ECCHSIAO64-8, ECCHSIAO128-9, ECCH32-7, ECCH64-8. Default value = none.|
-- |---------------------------------------------------------------------------------------------------------------------|
-- | This parameter is only used by synthesis. Specify the algorithm used to generate the ecc bits outside the XPM Memory.|
-- | XPM Memory does not performs ECC operation with this parameter.                                                     |
-- |                                                                                                                     |
-- |   "none" - No ECC                                                                                                   |
-- |   "ECCH32-7" - 32 bit ECC Hamming algorithm is used                                                                 |
-- |   "ECCH64-8" - 64 bit ECC Hamming algorithm is used                                                                 |
-- |   "ECCHSIAO32-7" - 32 bit ECC HSIAO algorithm is used                                                               |
-- |   "ECCHSIAO64-8" - 64 bit ECC HSIAO algorithm is used                                                               |
-- |   "ECCHSIAO128-9" - 128 bit ECC HSIAO algorithm is used                                                             |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | IGNORE_INIT_SYNTH    | Integer            | Range: 0 - 1. Default value = 0.                                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | 0 - Initiazation file if specified will applies for both simulation and synthesis                                   |
-- | 1 - Initiazation file if specified will applies for only simulation and will ignore for synthesis                   |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | MEMORY_INIT_FILE     | String             | Default value = none.                                                   |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify "none" (including quotes) for no memory initialization, or specify the name of a memory initialization file-|
-- | Enter only the name of the file with .mem extension, including quotes but without path (e.g. "my_file.mem").        |
-- | File format must be ASCII and consist of only hexadecimal values organized into the specified depth by              |
-- | narrowest data width generic value of the memory. Initialization of memory happens through the file name specified only when parameter|
-- | MEMORY_INIT_PARAM value is equal to "".                                                                             |
-- | When using XPM_MEMORY in a project, add the specified file to the Vivado project as a design source.                |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | MEMORY_INIT_PARAM    | String             | Default value = 0.                                                      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify "" or "0" (including quotes) for no memory initialization through parameter, or specify the string          |
-- | containing the hex characters. Enter only hex characters with each location separated by delimiter (,).             |
-- | Parameter format must be ASCII and consist of only hexadecimal values organized into the specified depth by         |
-- | narrowest data width generic value of the memory.For example, if the narrowest data width is 8, and the depth of    |
-- | memory is 8 locations, then the parameter value should be passed as shown below.                                    |
-- | parameter MEMORY_INIT_PARAM = "AB,CD,EF,1,2,34,56,78"                                                               |
-- | Where "AB" is the 0th location and "78" is the 7th location.                                                        |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | MEMORY_OPTIMIZATION  | String             | Allowed values: true, false. Default value = true.                      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify "true" to enable the optimization of unused memory or bits in the memory structure. Specify "false" to      |
-- | disable the optimization of unused memory or bits in the memory structure.                                          |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | MEMORY_PRIMITIVE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Designate the memory primitive (resource type) to use-                                                              |
-- | "auto"- Allow Vivado Synthesis to choose                                                                            |
-- | "distributed"- Distributed memory                                                                                   |
-- | "block"- Block memory                                                                                               |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | MEMORY_SIZE          | Integer            | Range: 2 - 150994944. Default value = 2048.                             |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify the total memory array size, in bits.                                                                       |
-- | For example, enter 65536 for a 2kx32 ROM.                                                                           |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | MESSAGE_CONTROL      | Integer            | Range: 0 - 1. Default value = 0.                                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify 1 to enable the dynamic message reporting such as collision warnings, and 0 to disable the message reporting|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | RAM_DECOMP           | String             | Allowed values: auto, area, power. Default value = auto.                |
-- |---------------------------------------------------------------------------------------------------------------------|
-- |  Specifies the decomposition of the memory.                                                                         |
-- |  "auto" - Synthesis selects default.                                                                                |
-- |  "power" - Synthesis selects a strategy to reduce switching activity of RAMs and maps using widest configuration possible.|
-- |  "area" - Synthesis selects a strategy to reduce RAM resource count.                                                |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | READ_DATA_WIDTH_A    | Integer            | Range: 1 - 4608. Default value = 32.                                    |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify the width of the port A read data output port douta, in bits.                                               |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | READ_LATENCY_A       | Integer            | Range: 0 - 100. Default value = 2.                                      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify the number of register stages in the port A read data pipeline. Read data output to port douta takes this   |
-- | number of clka cycles.                                                                                              |
-- | To target block memory, a value of 1 or larger is required- 1 causes use of memory latch only; 2 causes use of      |
-- | output register. To target distributed memory, a value of 0 or larger is required- 0 indicates combinatorial output.|
-- | Values larger than 2 synthesize additional flip-flops that are not retimed into memory primitives.                  |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | READ_RESET_VALUE_A   | String             | Default value = 0.                                                      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify the reset value of the port A final output register stage in response to rsta input port is assertion.      |
-- | For example, to reset the value of port douta to all 0s when READ_DATA_WIDTH_A is 32, specify 32HHHHh0.             |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | RST_MODE_A           | String             | Allowed values: SYNC, ASYNC. Default value = SYNC.                      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Describes the behaviour of the reset                                                                                |
-- |                                                                                                                     |
-- |   "SYNC" - when reset is applied, synchronously resets output port douta to the value specified by parameter READ_RESET_VALUE_A|
-- |   "ASYNC" - when reset is applied, asynchronously resets output port douta to zero                                  |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | SIM_ASSERT_CHK       | Integer            | Range: 0 - 1. Default value = 0.                                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
-- | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | USE_MEM_INIT         | Integer            | Range: 0 - 1. Default value = 1.                                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify 1 to enable the generation of below message and 0 to disable generation of the following message completely.|
-- | "INFO - MEMORY_INIT_FILE and MEMORY_INIT_PARAM together specifies no memory initialization.                         |
-- | Initial memory contents will be all 0s."                                                                            |
-- | NOTE: This message gets generated only when there is no Memory Initialization specified either through file or      |
-- | Parameter.                                                                                                          |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | USE_MEM_INIT_MMI     | Integer            | Range: 0 - 1. Default value = 0.                                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify 1 to expose this memory information to be written out in the MMI file.                                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | WAKEUP_TIME          | String             | Allowed values: disable_sleep, use_sleep_pin. Default value = disable_sleep.|
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specify "disable_sleep" to disable dynamic power saving option, and specify "use_sleep_pin" to enable the           |
-- | dynamic power saving option                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+

-- Port usage table, organized as follows:
-- +---------------------------------------------------------------------------------------------------------------------+
-- | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Description                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- +---------------------------------------------------------------------------------------------------------------------+
-- | addra          | Input     | ADDR_WIDTH_A                          | clka    | NA          | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Address for port A read operations.                                                                                 |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | clka           | Input     | 1                                     | NA      | Rising edge | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Clock signal for port A.                                                                                            |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | dbiterra       | Output    | 1                                     | clka    | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Leave open.                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | douta          | Output    | READ_DATA_WIDTH_A                     | clka    | NA          | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Data output for port A read operations.                                                                             |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | ena            | Input     | 1                                     | clka    | Active-high | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Memory enable signal for port A.                                                                                    |
-- | Must be high on clock cycles when read operations are initiated. Pipelined internally.                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | injectdbiterra | Input     | 1                                     | clka    | Active-high | Tie to 1'b0            |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Do not change from the provided value.                                                                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | injectsbiterra | Input     | 1                                     | clka    | Active-high | Tie to 1'b0            |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Do not change from the provided value.                                                                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | regcea         | Input     | 1                                     | clka    | Active-high | Tie to 1'b1            |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Do not change from the provided value.                                                                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rsta           | Input     | 1                                     | clka    | Active-high | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Reset signal for the final port A output register stage.                                                            |
-- | Synchronously resets output port douta to the value specified by parameter READ_RESET_VALUE_A.                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | sbiterra       | Output    | 1                                     | clka    | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Leave open.                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | sleep          | Input     | 1                                     | NA      | Active-high | Tie to 1'b0            |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | sleep signal to enable the dynamic power saving feature.                                                            |
-- +---------------------------------------------------------------------------------------------------------------------+


-- xpm_memory_sprom : In order to incorporate this function into the design,
--       VHDL       : the following instance declaration needs to be placed
--     instance     : in the body of the design code.  The instance name
--   declaration    : (xpm_memory_sprom_inst) and/or the port declarations after the
--       code       : "=>" declaration maybe changed to properly reference and
--                  : connect this function to the design.  All inputs and outputs
--                  : must be connected.

--     Library      : In addition to adding the instance declaration, a use
--   declaration    : statement for the UNISIM.vcomponents library needs to be
--       for        : added before the entity declaration.  This library
--      Xilinx      : contains the component declarations for all Xilinx
--    primitives    : primitives and points to the models that will be used
--                  : for simulation.

--  Please reference the appropriate libraries guide for additional information on the XPM modules.

--  Copy the following two statements and paste them before the
--  Entity declaration, unless they already exist.

  signal lat: std_logic_vector(LATENCY-1 downto 0):=(others=>'0');
begin

   -- This is here to assist with timing.
   process(clk)
   begin
     if (rising_edge(clk)) then
       lat <= lat(LATENCY-1 downto 1)&rd;
    end if;
   end process;
   dout_vld <= lat(LATENCY-1);       
  
   -- xpm_memory_sprom: Single Port ROM
   -- Xilinx Parameterized Macro, version 2023.2
   xpm_memory_sprom_inst : xpm_memory_sprom
     generic map (
      ADDR_WIDTH_A    => A_W,
      AUTO_SLEEP_TIME => 0,           -- DECIMAL
      CASCADE_HEIGHT => 0,            -- DECIMAL
--      ECC_BIT_RANGE => "7:0",         -- String
      ECC_MODE => "no_ecc",           -- String
--      ECC_TYPE => "none",             -- String
--      IGNORE_INIT_SYNTH => 0,         -- DECIMAL
      MEMORY_INIT_FILE => FNAME, --"rom_inf.txt",
      MEMORY_INIT_PARAM => "0",       -- String
      MEMORY_OPTIMIZATION => "true",  -- String
      MEMORY_PRIMITIVE => "auto",     -- String
      MEMORY_SIZE => D_W * 2**A_W,
      MESSAGE_CONTROL => 0,           -- DECIMAL
--      RAM_DECOMP => "auto",           -- String
      READ_DATA_WIDTH_A => D_W,
      READ_LATENCY_A => LATENCY,
      READ_RESET_VALUE_A => "0",      -- String
      RST_MODE_A => "SYNC",           -- String
      SIM_ASSERT_CHK => 0,            -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      USE_MEM_INIT => 1,              -- DECIMAL
      USE_MEM_INIT_MMI => 0,          -- DECIMAL
      WAKEUP_TIME => "disable_sleep")  -- String
   port map (
--      dbiterra => dbiterra,             -- 1-bit output: Leave open.
        douta => dout,                   -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
--        sbiterra => sbiterra,             -- 1-bit output: Leave open.
        addra => addr,                   -- ADDR_WIDTH_A-bit input: Address for port A read operations.
      clka => clk,                     -- 1-bit input: Clock signal for port A.
      ena => '1',                       -- 1-bit input: Memory enable signal for port A. Must be high on clock
                                        -- cycles when read operations are initiated. Pipelined internally.

      injectdbiterra => '0', -- 1-bit input: Do not change from the provided value.
      injectsbiterra => '0', -- 1-bit input: Do not change from the provided value.
      regcea => '1',                 -- 1-bit input: Do not change from the provided value.
      rsta => '0',                     -- 1-bit input: Reset signal for the final port A output register
                                       -- stage. Synchronously resets output port douta to the value specified
                                       -- by parameter READ_RESET_VALUE_A.

      sleep => '0'                   -- 1-bit input: sleep signal to enable the dynamic power saving feature.
   );
				
end architecture struct;
				
