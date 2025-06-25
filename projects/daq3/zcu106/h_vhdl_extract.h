// h_vhdl_extract.h
// hardware access constants
// This file was automatically generated
// by Register Extractor (ver 4.14) on Tue Jun 24 20:56:31 2025
// compile version Mon Jun 16 10:25:20 2025
// current dir:  C:\reilly\proj\quanet\quanet_hdl\projects\daq3\zcu106
// DO NOT MODIFY THIS FILE!

// source files:
//    ../../scripts/..\..\..\quanet_hdl\library\quanet\global_pkg.vhd
//    ../../scripts/..\..\..\quanet_hdl\library\quanet_dac\quanet_dac.vhd
//    ../../scripts/..\..\..\quanet_hdl\library\quanet_adc\quanet_adc.vhd

#ifndef __H_VHDL_EXTRACT_H__
#define __H_VHDL_EXTRACT_H__


// version constants
#define H_VHDL_EXTRACT_VER (4)
#define H_VHDL_EXTRACT_SUBVER (14)
#define H_VHDL_EXTRACT_DATE "Tue Jun 24 20:56:31 2025"
#define H_VHDL_EXTRACT_DIR "C:\reilly\proj\quanet\quanet_hdl\projects\daq3\zcu106"


// all extracted constants
          // -- std_logic_vector(31 downto 0) := x"8fffffff");
          // -- std_logic_vector(31 downto 0) := x"80000000";  -- start addr in DDR
          // -- std_logic_vector(G_BODY_CHAR_POLY)'length;
#define H_QSDC_SYMS_PER_FR_W (9)
#define H_CORR_MEM_D_W (16)
#define H_CORR_DISCARD_LSBS (4)
#define H_CTR_W (4)
#define H_PASS_W (6)
#define H_CORR_MAG_W (10)
#define H_MAX_SLICES (4)
#define H_BODY_LEN_W (10)
#define H_CIPHER_W (2)
          // -- cipher bits per asamp (aka "chip")
#define H_BODY_CHAR_POLY (0x080001)
#define H_FRAME_QTY_W (16)
#define H_OSAMP_W (2)
#define H_HDR_LEN_W (8)
#define H_QSDC_FRAME_CYCS_W (12)
#define H_FRAME_PD_CYCS_W (24)
#define H_FWVER (2)

// regextractor can handle more than one register space
#define H_NUM_REGSPACES (2)

// max register offset per regspace, indexed by regspace:
#define H_MAX_REG_OFFSETS_INIT {10, 8}
// num registers per regspace, indexed by regspace:
#define H_NUM_REGS_INIT {11, 9}

// inferred register locations and fields
//   opt_old_consts 0

//
// register space DAC
//

#define H_DAC (0)
#define H_DAC_NUM_REGS       (11)
#define H_DAC_MAX_REG_OFFSET (10)

#define H_DAC_FR1                      0x00000000  /* 0 */
#define H_DAC_FR1_REG_W                0x00000400  /* 0xffffffff  r  */
#define H_DAC_FR1_FRAME_PD_MIN1        0x00000300  /* 0x00ffffff   w */
                                       // r 0xffffffff
                                       // w 0x00ffffff

#define H_DAC_FR2                      0x00001000  /* 1 */
#define H_DAC_FR2_REG_W                0x00001400  /* 0xffffffff  r  */
#define H_DAC_FR2_FRAME_QTY_MIN1       0x00001200  /* 0x0000ffff   w */
#define H_DAC_FR2_PM_DLY_CYCS          0x000010d0  /* 0x003f0000   w */
                                       // r 0xffffffff
                                       // w 0x003fffff

#define H_DAC_CTL                      0x00002000  /* 2 */
#define H_DAC_CTL_REG_W                0x00002400  /* 0xffffffff  r  */
#define H_DAC_CTL_BODY_LEN_MIN1_CYCS   0x00002140  /* 0x000003ff   w -- set with hdr_len */
#define H_DAC_CTL_OSAMP_MIN1           0x0000204a  /* 0x00000c00   w -- oversampling: 0=1,1=2,3=4 */
#define H_DAC_CTL_IRQ                  0x0000202c  /* 0x00001000   w */
#define H_DAC_CTL_QSDC_IS_DPSK         0x00002033  /* 0x00080000   w -- 0=psk, 1=dpsk */
#define H_DAC_CTL_BODY_IS_QPSK         0x00002034  /* 0x00100000   w -- 0=bpsk, 1=qpsk */
#define H_DAC_CTL_ALICE_TXING          0x00002035  /* 0x00200000   w -- set for qsdc */
#define H_DAC_CTL_TX_DBITS             0x00002037  /* 0x00800000   w -- alice transmits data */
#define H_DAC_CTL_ALICE_SYNCING        0x00002039  /* 0x02000000   w -- means i am alice, doing sync */
#define H_DAC_CTL_MEMTX_CIRC           0x0000203a  /* 0x04000000   w -- circular xmit from mem */
#define H_DAC_CTL_TX_0                 0x0000203b  /* 0x08000000   w -- header contains zeros */
#define H_DAC_CTL_TX_ALWAYS            0x0000203c  /* 0x10000000   w -- used for dbg to view on scope */
#define H_DAC_CTL_CIPHER_EN            0x0000203e  /* 0x40000000   w -- bob sets to scramble frame bodies */
#define H_DAC_CTL_TX_UNSYNC            0x0000203f  /* 0x80000000   w -- probaly will go away */
                                       // r 0xffffffff
                                       // w 0xdeb81fff

#define H_DAC_STATUS                   0x00003000  /* 3 */
#define H_DAC_STATUS_GTH_STATUS        0x00003080  /* 0x0000000f  r  */
#define H_DAC_STATUS_FWVER             0x00003084  /* 0x000000f0  r  */
#define H_DAC_STATUS_DAC_TX_IN_CNT     0x000030c8  /* 0x00003f00  r  */
#define H_DAC_STATUS_DAC_RST_AXI       0x0000302e  /* 0x00004000  r  */
                                       // r 0x00007fff
                                       // w 0x00000000

#define H_DAC_IM                       0x00004000  /* 4 */
#define H_DAC_IM_BODY                  0x00004200  /* 0x0000ffff   w */
#define H_DAC_IM_REG_W                 0x00004400  /* 0xffffffff  r  */
#define H_DAC_IM_HDR                   0x00004210  /* 0xffff0000   w */
                                       // r 0xffffffff
                                       // w 0xffffffff

#define H_DAC_HDR                      0x00005000  /* 5 */
#define H_DAC_HDR_LFSR_RST_ST          0x00005160  /* 0x000007ff   w -- often x50f */
#define H_DAC_HDR_REG_W                0x00005400  /* 0xffffffff  r  */
#define H_DAC_HDR_LEN_MIN1_CYCS        0x0000510c  /* 0x000ff000   w -- in cycles, minus 1   */
#define H_DAC_HDR_IM_DLY_CYCS          0x00005094  /* 0x00f00000   w */
#define H_DAC_HDR_IM_PREEMPH           0x00005039  /* 0x02000000   w -- use im preemphasis */
#define H_DAC_HDR_SAME_HDRS            0x0000503a  /* 0x04000000   w -- tx all the same hdr */
#define H_DAC_HDR_USE_LFSR             0x0000503b  /* 0x08000000   w -- header contains lfsr */
                                       // r 0xffffffff
                                       // w 0x0efff7ff

#define H_DAC_DMA                      0x00006000  /* 6 */
#define H_DAC_DMA_REG_W                0x00006400  /* 0xffffffff  r  */
                                       // r 0xffffffff
                                       // w 0x00000000

#define H_DAC_PCTL                     0x00007000  /* 7 */
#define H_DAC_PCTL_CLR_CNTS            0x0000703e  /* 0x40000000  rw */
#define H_DAC_PCTL_GTH_RST             0x0000703f  /* 0x80000000  rw */
                                       // r 0xffffffff
                                       // w 0xffffffff

#define H_DAC_QSDC                     0x00008000  /* 8 */
#define H_DAC_QSDC_REG_W               0x00008400  /* 0xffffffff  r  */
#define H_DAC_QSDC_SYMS_PER_FRAME_MIN1 0x00008120  /* 0x000001ff   w */
#define H_DAC_QSDC_SYM_CYCS_MIN1       0x0000808c  /* 0x0000f000   w -- duration of QSDC data symbol */
#define H_DAC_QSDC_QSD_POS_MIN1_CYCS   0x00008190  /* 0x0fff0000   w -- offset of data in frame */
                                       // r 0xffffffff
                                       // w 0x0ffff1ff

#define H_DAC_SER                      0x00009000  /* 9 */
#define H_DAC_SER_TX_DATA              0x00009100  /* 0x000000ff  rw */
#define H_DAC_SER_RST                  0x00009028  /* 0x00000100  rw */
#define H_DAC_SER_RX_R                 0x00009029  /* 0x00000200  rw */
#define H_DAC_SER_TX_W                 0x0000902a  /* 0x00000400  rw */
#define H_DAC_SER_SET_PARAMS           0x0000902b  /* 0x00000800  rw */
#define H_DAC_SER_XON_XOFF_EN          0x0000902c  /* 0x00001000  rw */
#define H_DAC_SER_PARITY               0x0000904d  /* 0x00006000  rw */
#define H_DAC_SER_SET_FLOWCTL          0x0000902f  /* 0x00008000  rw */
#define H_DAC_SER_REFCLK_DIV_MIN1      0x00009210  /* 0xffff0000  rw */
#define H_DAC_SER_RX_DATA              0x00009111  /* 0x01fe0000  r  */
#define H_DAC_SER_TX_FULL              0x00009039  /* 0x02000000  r  */
#define H_DAC_SER_TX_MT                0x0000903a  /* 0x04000000  r  */
#define H_DAC_SER_RX_VLD               0x0000903b  /* 0x08000000  r  */
                                       // r 0x0fffffff
                                       // w 0xffffffff

#define H_DAC_DBG                      0x0000a000  /* 10 */
#define H_DAC_DBG_SER_FRAME_ERR        0x0000a027  /* 0x00000080  r  */
#define H_DAC_DBG_SER_PARITY_ERR       0x0000a028  /* 0x00000100  r  */
#define H_DAC_DBG_SER_SAW_XOFF_TIMO    0x0000a029  /* 0x00000200  r  */
#define H_DAC_DBG_SER_TX_OVF           0x0000a02a  /* 0x00000400  r  */
#define H_DAC_DBG_SER_RX_OVF           0x0000a02b  /* 0x00000800  r  */
#define H_DAC_DBG_SER_CTR              0x0000a08c  /* 0x0000f000  r  */
#define H_DAC_DBG_SER_CLR_CTRS         0x0000a037  /* 0x00800000  rw */
#define H_DAC_DBG_SER_CTR_SEL          0x0000a058  /* 0x03000000  rw */
#define H_DAC_DBG_SER_CLR_ERRS         0x0000a03e  /* 0x40000000  rw */
                                       // r 0xfff0ff80
                                       // w 0xfff00000

//
// register space ADC
//

#define H_ADC (1)
#define H_ADC_NUM_REGS       (9)
#define H_ADC_MAX_REG_OFFSET (8)

#define H_ADC_ACTL                  0x10000000  /* 0 */
#define H_ADC_ACTL_AREG_W           0x10000400  /* 0xffffffff  r  */
#define H_ADC_ACTL_MEAS_NOISE       0x10000021  /* 0x00000002   w */
#define H_ADC_ACTL_TXRX_EN          0x10000022  /* 0x00000004   w */
#define H_ADC_ACTL_SAVE_AFTER_PWR   0x10000023  /* 0x00000008   w */
#define H_ADC_ACTL_OSAMP_MIN1       0x10000044  /* 0x00000030   w */
#define H_ADC_ACTL_SEARCH           0x10000026  /* 0x00000040   w */
#define H_ADC_ACTL_CORRSTART        0x10000027  /* 0x00000080   w */
#define H_ADC_ACTL_ALICE_TXING      0x10000028  /* 0x00000100   w */
#define H_ADC_ACTL_ALICE_SYNCING    0x10000029  /* 0x00000200   w */
#define H_ADC_ACTL_SAVE_AFTER_INIT  0x1000002b  /* 0x00000800   w */
#define H_ADC_ACTL_LFSR_RST_ST      0x1000016c  /* 0x007ff000   w */
#define H_ADC_ACTL_IQ_REBALANCE     0x10000118  /* 0xff000000   w -- fixed prec 0 .. 1.9 */
                                       // r 0xffffffff
                                       // w 0xff7ffbfe

#define H_ADC_STAT                  0x10001000  /* 1 */
#define H_ADC_STAT_DMA_XFER_REQ_RC  0x10001020  /* 0x00000001  r  -- for dbg */
#define H_ADC_STAT_ADC_RST_AXI      0x10001021  /* 0x00000002  r  */
#define H_ADC_STAT_DMA_WREADY_CNT   0x10001084  /* 0x000000f0  r  */
#define H_ADC_STAT_SAVE_GO_CNT      0x10001088  /* 0x00000f00  r  */
#define H_ADC_STAT_XFER_REQ_CNT     0x1000108c  /* 0x0000f000  r  */
#define H_ADC_STAT_ADC_RST_CNT      0x10001090  /* 0x000f0000  r  */
#define H_ADC_STAT_DAC_TX_CNT       0x10001094  /* 0x00f00000  r  */
#define H_ADC_STAT_FWVER            0x10001098  /* 0x0f000000  r  */
                                       // r 0x0ffffff3
                                       // w 0x00000000

#define H_ADC_CSTAT                 0x10002000  /* 2 */
#define H_ADC_CSTAT_PROC_SEL        0x10002080  /* 0x0000000f   w */
#define H_ADC_CSTAT_PROC_DOUT       0x10002400  /* 0xffffffff  r  */
                                       // r 0xffffffff
                                       // w 0x0000000f

#define H_ADC_FR1                   0x10003000  /* 3 */
#define H_ADC_FR1_AREG_W            0x10003400  /* 0xffffffff  r  */
#define H_ADC_FR1_FRAME_PD_MIN1     0x10003300  /* 0x00ffffff   w -- in cycles */
#define H_ADC_FR1_NUM_PASS_MIN1     0x100030d8  /* 0x3f000000   w */
                                       // r 0xffffffff
                                       // w 0x3fffffff

#define H_ADC_FR2                   0x10004000  /* 4 */
#define H_ADC_FR2_AREG_W            0x10004400  /* 0xffffffff  r  */
#define H_ADC_FR2_HDR_LEN_MIN1_CYCS 0x10004100  /* 0x000000ff   w */
#define H_ADC_FR2_FRAME_QTY_MIN1    0x10004210  /* 0xffff0000   w */
                                       // r 0xffffffff
                                       // w 0xffff00ff

#define H_ADC_HDR                   0x10005000  /* 5 */
#define H_ADC_HDR_AREG_W            0x10005400  /* 0xffffffff  r  */
#define H_ADC_HDR_PWR_THRESH        0x100051c0  /* 0x00003fff   w */
#define H_ADC_HDR_THRESH            0x1000514e  /* 0x00ffc000   w */
                                       // r 0xffffffff
                                       // w 0x00ffffff

#define H_ADC_SYNC                  0x10006000  /* 6 */
#define H_ADC_SYNC_AREG_W           0x10006400  /* 0xffffffff  r  */
#define H_ADC_SYNC_DLY_CYCS         0x10006300  /* 0x00ffffff   w */
#define H_ADC_SYNC_INIT_THRESH_D16  0x10006118  /* 0xff000000   w */
                                       // r 0xffffffff
                                       // w 0xffffffff

#define H_ADC_PCTL                  0x10007000  /* 7 */
#define H_ADC_PCTL_CLR_CTRS         0x10007020  /* 0x00000001   w */
#define H_ADC_PCTL_PROC_CLR_CNTS    0x10007028  /* 0x00000100   w */
                                       // r 0xffffffff
                                       // w 0xffffffff

#define H_ADC_DBG                   0x10008000  /* 8 */
#define H_ADC_DBG_AREG_W            0x10008400  /* 0xffffffff  r  */
#define H_ADC_DBG_SAVE_AFTER_HDR    0x10008020  /* 0x00000001   w */
#define H_ADC_DBG_HOLD              0x10008021  /* 0x00000002   w */
                                       // r 0xffffffff
                                       // w 0x00000003
// initializer for h_baseaddr array
#define H_BASEADDR_INIT { 0  /* for DAC */, \
		0  /* for ADC */}


// register constants:  
//   space 31:28
//   reg   27:12
// field constants:
//   space 31:28
//   reg   27:12
//   bwid  9:5
//   bpos  4:0

// register & field constant conversion & macros
#define H_CONST(s,r,w,p)  (((s&0xf)<<28) | ((r&0xffff)<<12) | ((w&0x3f)<<5) | (p&0x1f))
#define H_2SPACE(c)    (c>>28 & 0xf)
#define H_2REG(c)      (c>>12 & 0xffff)
#define H_2BWID(c)     (c>>5 & 0x3f)
#define H_2BPOS(c)     (c>>0 & 0x1f)
#define H_2VMASK(c)    ((H_2BWID(c)==32)?~0:~(~0<<H_2BWID(c)))
#define H_2MASK(c)     (H_2VMASK(c)<<H_2BPOS(c))
// the following are to access offsets from reg addr or bit position
#define H_2REGOFF(c,i)  ((c&~0xffff000) | (((H_2REG(c)+i)&0xffff)<<12))
#define H_2BPOSOFF(c,i) ((c&~0x1f) | ((H_2BPOS(c)+i)&0x1f))

#define H_EXT(c, rv)    ((rv >> H_2BPOS(c)) & H_2VMASK(c))
#define H_INS(c, rv, v) ((rv & ~H_2MASK(c)) | ((v & H_2VMASK(c)) << H_2BPOS(c)))




#endif
