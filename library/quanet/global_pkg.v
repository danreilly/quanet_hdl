
localparam G_FRAME_PD_W  = 24;

localparam G_FRAME_QTY_W = 16;

localparam G_HDR_LEN_W = 8;

localparam G_OSAMP_W   = 12;

localparam G_BODY_RAND_BITS = 4;

localparam G_BODY_LEN_W = 10;

localparam G_CORR_MAG_W = 10;

// width of correlation values in correlation memory
// could be as high as 18
localparam G_CORR_MEM_D_W = 16;


localparam G_BODY_CHAR_POLY = 21'b010000000000000000001;


  // PASS_W = u_bitwid((2**HDR_LEN_CYCS_W+MAX_SLICES-1)/MAX_SLICES-1)
  localparam G_PASS_W = 6;  // TODO: fix

  localparam G_CTR_W = 4;


