library ieee;
use ieee.std_logic_1164.all;

entity quanet_sfp is
  port (
    tx_p : out std_logic;
    tx_n : out std_logic;
    rx_p : in std_logic;
    rx_n : in std_logic;

    txclk_out : out std_logic;
    gtrefclk : in std_logic;


    
    s_axi_aclk: in std_logic;
    s_axi_aresetn: in std_logic;
    
    -- wr addr chan
    s_axi_awaddr : in std_logic_vector(15 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;
    
    -- wr data chan
    s_axi_wdata  : in std_logic_vector(31 downto 0);
    s_axi_wvalid : in std_logic;
    s_axi_wstrb  : in std_logic_vector(3 downto 0);  -- ignored
    s_axi_wready : out std_logic;
    s_axi_awprot : in std_logic_vector(2 downto 0);    
    
    -- wr rsp chan
    s_axi_bresp: out std_logic_vector(1 downto 0);
    s_axi_bvalid: out std_logic;
    s_axi_bready: in std_logic;

    s_axi_araddr: in std_logic_vector(15 downto 0);
    s_axi_arprot : in std_logic_vector(2 downto 0);
    s_axi_arvalid: in std_logic;
    s_axi_arready: out std_logic;
    
    s_axi_rdata: out std_logic_vector(31 downto 0);
    s_axi_rresp: out std_logic_vector(1 downto 0);
    s_axi_rvalid: out std_logic;
    s_axi_rready: in std_logic);
end quanet_sfp;


library work;
use work.util_pkg.ALL;
use work.cdc_samp_pkg.ALL;
use work.axi_reg_array_pkg.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

architecture RTL of quanet_sfp is
  
  constant REG_STATUS: integer := 0;
  constant REG_CTL   : integer := 1;
  constant REG_DAC   : integer := 2;
  constant REG_DBG   : integer := 3;
  
  component my_gth_wrap is
  generic (
    DRPCLK_PD_NS: integer);
  port (
    drp_sel_pll : in std_logic;
    drp_sel_gt  : in std_logic;
    drp_addr   : in std_logic_vector(9 downto 0);
    drp_clk    : in std_logic;
    drp_din    : in std_logic_vector(15 downto 0);
    drp_dout   : out std_logic_vector(15 downto 0); 
    drp_en     : in std_logic; 
    drp_rdy    : out std_logic; 
    drp_we     : in std_logic;
    
    txdata: in std_logic_vector(31 downto 0);
    txusrclk_out: out std_logic;
    rxdata: out std_logic_vector(31 downto 0);
    rxusrclk_out: out std_logic;
    
    tx_p : out std_logic;
    tx_n : out std_logic;
    rx_p : in std_logic;
    rx_n : in std_logic;

    soft_reset_tx: in std_logic;
    soft_reset_rx: in std_logic;
    tx_fsm_reset_done : out std_logic;
    rx_fsm_reset_done : out std_logic;

    gtrefclk : in std_logic;

    -- what about eyescantrigger? must enable port in wiz
    
    eyescanreset_in : in std_logic;
    rxrate_in: in std_logic_vector ( 2 downto 0 );
    txdiffctrl_in : in std_logic_vector ( 4 downto 0 );    
    txpostcursor_in : in std_logic_vector ( 4 downto 0 );
    txprecursor_in : in std_logic_vector ( 4 downto 0 );
    rxlpmen_in : in std_logic;
    
--    extref : in std_logic;
--    sel_extref: in std_logic;

    qpllrefclklost: out std_logic;
    qplllock: out std_logic);   
  end component;

  component lfsr_w 
  generic(
    W: in integer;     -- number of bits to produce per cycle
    CP: in std_logic_vector);
  port (
    d_o: out std_logic_vector(W-1 downto 0); -- valid the cycle after rst or en
    en : in std_logic;
    
    d_i: in std_logic_vector(W-1 downto 0);
    ld : in std_logic; -- loads d_i.  If 0 BER, this syncs lfsr

    rst_st: in std_logic_vector(CP'LENGTH-1 downto 0);
    rst: in std_logic;                  -- a syncronous reset
    err: out std_logic;
    clk: in std_logic);
  end component;

  component in_system_ibert_0
    port (
      drpclk_o : out std_logic_vector(0 downto 0);
      gt0_drpen_o : out std_logic;
      gt0_drpwe_o : out std_logic;
      gt0_drpaddr_o : out std_logic_vector(9 downto 0);
      gt0_drpdi_o : out std_logic_vector(15 downto 0);
      gt0_drprdy_i : in std_logic;
      gt0_drpdo_i : in std_logic_vector(15 downto 0);
      eyescanreset_o : out std_logic_vector(0 downto 0);
      rxrate_o : out std_logic_vector(2 downto 0);
      txdiffctrl_o : out std_logic_vector(4 downto 0);
      txprecursor_o : out std_logic_vector(4 downto 0);
      txpostcursor_o : out std_logic_vector(4 downto 0);
      rxlpmen_o : out std_logic_vector(0 downto 0);
      rxoutclk_i : in std_logic_vector(0 downto 0);
      clk : in std_logic );
  end component;
  
  signal txclk, rxclk, tx_rst_done, rx_rst_done, lfsr_rst, axi_rst, qplllock: std_logic;
  signal txdata, rxdata: std_logic_vector(31 downto 0);

--  signal tx_rst_done_i, rx_rst_done_i, qplllock_i: std_logic;
  signal stat_i: std_logic_vector ( 2 downto 0 );
  
  signal eyescanreset, rxlpmen : std_logic;
  signal rxrate: std_logic_vector ( 2 downto 0 );
  signal txdiffctrl, txpostcursor : std_logic_vector ( 4 downto 0 );
  signal txprecursor : std_logic_vector ( 4 downto 0 );

  signal gth_status: std_logic_vector(3 downto 0);

  signal drp_sel_pll, drp_sel_gt, drp_en, drp_rdy, drp_we, drp_clk: std_logic;
  signal drp_addr   : std_logic_vector(9 downto 0);
  signal drp_din, drp_dout: std_logic_vector(15 downto 0);

  signal reg_r, reg_w :  axi_reg_array_t;
  signal reg_r_pulse, reg_w_pulse : axi_reg_sel_t;
  signal reg_status_r, reg_status_w,
         reg_ctl_r, reg_ctl_w,
         reg_dbg_r, reg_dbg_w,
         reg_drp_r, reg_drp_w
    : std_logic_vector(31 downto 0);
  
begin

  axi_rst <= not     s_axi_aresetn;
  ara: axi_reg_array
    generic map(
      A_W => 16)
    port map(
      -- connect these to system
      axi_clk => s_axi_aclk,
      axi_rst => axi_rst,
      
      -- wr addr chan
      awaddr   => s_axi_awaddr,
      awvalid  => s_axi_awvalid,
      awready  => s_axi_awready,
      
      -- wr data chan
      wdata   => s_axi_wdata,
      wvalid  => s_axi_wvalid,
      wstrb   => s_axi_wstrb,
      wready  => s_axi_wready,
      
      -- wr rsp chan
      bresp  => s_axi_bresp,
      bvalid => s_axi_bvalid,
      bready => s_axi_bready,

      araddr  => s_axi_araddr,
      arvalid => s_axi_arvalid,
      arready => s_axi_arready,
      
      rdata => s_axi_rdata,
      rresp => s_axi_rresp,
      rvalid => s_axi_rvalid,
      rready => s_axi_rready,

      -- connect these to your main vhdl code
      reg_w  => reg_w,
      reg_r  => reg_r,
      -- use the following for register access "side effects"
      reg_w_pulse  => reg_w_pulse,
      reg_r_pulse  => reg_r_pulse);
  -- This gives meaningful names to registers
  -- so that we don't need to refer to them by numbers
  reg_status_w <= reg_w(REG_STATUS);
  reg_ctl_w    <= reg_w(REG_CTL);
  reg_adc_w    <= reg_w(REG_ADC);
  reg_dac_w    <= reg_w(REG_DAC);
  reg_r(REG_STATUS) <= reg_status_r;
  reg_r(REG_CTL)    <= reg_ctl_r;
  reg_r(REG_ADC)    <= reg_adc_r;
  reg_r(REG_DAC)    <= reg_dac_r;

  status_samp: cdc_samp
    generic map( W => 3)
    port map(
      in_data(0) => tx_rst_done,  
      in_data(1) => rx_rst_done,
      in_data(2) => qplllock,
      out_data   => stat_i,
      out_clk    => axi_clk);
  reg_status_r(2 downto 0) <= stat_i;
  reg_status_r(3) <= '1';


  

  -- txclk might be 10G/40=250MHz.
  lfsr_rst <= not tx_rst_done;  
  lfi: lfsr_w
    generic map(
      W => 32,
      CP => x"100400003")
    port map (
      d_o => txdata, -- valid the cycle after rst or en
      en => '1',
    
      d_i => (others=>'0'),
      ld => '0',

      rst_st => (others => '1'),
      rst  => lfsr_rst,       -- a syncronous reset
--      err  => : out std_logic;
      clk  => txclk);
  txclk_out <= txclk;
  
  gth_i: my_gth_wrap
    generic map(
      DRPCLK_PD_NS => 10)
    port map(
      drp_sel_pll => '0',
      drp_sel_gt  => '0',
      drp_addr    => drp_addr,
      drp_clk     => s_axi_aclk,
      drp_din     => drp_din,
      drp_dout    => drp_dout,
      drp_en      => drp_en,
      drp_rdy     => drp_rdy,
      drp_we      => drp_we,

      txdata       => txdata,
      txusrclk_out => txclk,
      rxdata       => rxdata,
      rxusrclk_out => rxclk,
 
      eyescanreset_in => eyescanreset,
      rxrate_in       => rxrate,
      txdiffctrl_in   => txdiffctrl,
      txpostcursor_in => txpostcursor,
      txprecursor_in  => txprecursor,
      rxlpmen_in      => rxlpmen,
     
      tx_p => tx_p,
      tx_n => tx_n,
      rx_p => rx_p,
      rx_n => rx_n,

      soft_reset_tx => '0',
      soft_reset_rx => '0',
      tx_fsm_reset_done => tx_rst_done,
      rx_fsm_reset_done => rx_rst_done,
      
--    extref : in std_logic;
--    sel_extref: in std_logic;

--    qpllrefclklost: out std_logic;
      qplllock => qplllock,
      
      gtrefclk => gtrefclk);   

  ibert_i : in_system_ibert_0
    port map (
      drpclk_o(0)   => drp_clk,
      gt0_drpen_o   => drp_en,
      gt0_drpwe_o   => drp_we,
      gt0_drpaddr_o => drp_addr,
      gt0_drpdi_o   => drp_din,
      gt0_drprdy_i  => drp_rdy,
      gt0_drpdo_i   => drp_dout,
      
      eyescanreset_o(0) => eyescanreset,
      rxrate_o          => rxrate,
      txdiffctrl_o      => txdiffctrl,
      txprecursor_o     => txprecursor,
      txpostcursor_o    => txpostcursor,
      rxlpmen_o(0)      => rxlpmen,
      
      rxoutclk_i(0)     => rxclk,
      clk => s_axi_aclk);
  
end RTL;
