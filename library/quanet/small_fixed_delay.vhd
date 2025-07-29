component hdr_corr is
generic (
    USE_CORR: integer;
    SAMP_W : integer; -- 12 - width of one sample from one ADC.
small_fixed_delay
    process(clk)
    variable k: integer;
  begin
    if (rising_edge(clk)) then
