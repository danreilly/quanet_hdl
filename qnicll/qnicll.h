#ifndef _QNICLL_
#define _QNICLL_
/*

  interface between application code
  and the qnic "low level" library

 */

#include <sys/types.h>


// Error codes
// 
#define QNICLL_ERR_NONE   (0)
// 0 means no error.  This will never change.
#define QNICLL_ERR_MISUSE (1)
// MISUSE means the calling code is mis-using the library.  For
// example, if it calls a request to set something while library is
// already busy handling a prior request.  Indicates a bug in calling
// code.
#define QNICLL_ERR_BUG    (2)
// BUG should never happen, probably indicates a hardware failure (such
// as communication failure).  Or a bug in the low-level library.

#define QNICLL_ERR_OUTOFMEM  (3)

// Data formats
//
// Note that tx and rx formats may be different.
// The qnicll may be implemented on top of other libraries,
// for example, Analog Devices libiio.  Qnicll does not waste time re-arranging
// data, so calling code needs to know how data is formatted.
#define QNICLL_DATA_FORMAT_QUERRY (0)
//
#define QNICLL_DATA_FORMAT_LIBIIO (1)
// This format is defined by what Analog Devices's libiio uses
// Means that the data is an array of signed LE (little endian) 16-bit values.
// channel valus alternate.  For rx, I and Q.  For tx, intensity and phase.
#define QNICLL_DATA_FORMAT_PCI_HIRES (2)
// This format is used by (Young's) PCI interface HDL
// Data is an array of signed LE 16-bit IM values.
// four intensity values alternate with four phase values
#define QNICLL_DATA_FORMAT_PCI_LORES (3)
// This format is used by (Young's) PCI interface HDL
// Data is an array of signed LE 16-bit IM values.
// eight intensity values alternate with eight phase values
#define QNICLL_DATA_FORMAT_SYMBOLS_2  (4)
// implies the use of (Young's) symbol tables.
// bpsk? IM? ... TBD
#define QNICLL_DATA_FORMAT_SYMBOLS_4  (5)
// implies the use of (Young's) symbol tables.
// used with QPSK
#define QNICLL_DATA_FORMAT_SYMBOLS_16 (6)
// implies the use of (Young's) symbol tables.
// QAM
 

// Modes
//
// For diagrams of these see Gregs HNIC spiral p5 draft a.pptx
#define QNICLL_MODE_QUERRY (0)
#define QNICLL_MODE_CDM (1)
// CDM is lidar-like detection of link impedance.  Involves
// correlation of recieved samples with transmitted header.
#define QNICLL_MODE_MEAS_NOISE (2)
// Noise measurement involve vacum state measurements.
// The "fast" rxq_sw alternates as in Haley Weinstein's paper.
#define QNICLL_MODE_LINK_LOOPBACK (3)
// LINK_LOOPBACK is the mode for a remote qnic to be used when the
// local qnic is characterizing the link.  However, this doesn't
// interrupt the classical communication lnk.
#define QNICLL_MODE_QSDC (4)
// not implemented yet

#define QNICLL_RX_STATUS_OK   (0)
#define QNICLL_RX_STATUS_TIMO (1)



// Optical Modulation Formats
// (Currently only one. There will be more in the future)
#define QNICLL_MODULATION_IM (1)




#define QNICLL_SW_TX      (1)
#define QNICLL_SW_RX      (2)
#define QNICLL_SW_REFLECT (3)


// Init structure for libiio based qnicll
// Used for happy camper only
typedef struct qnicll_init_info_libiio_st {
  char ipaddr[32]; // ip address of ZCU106 board
  char usbdev[32]; // device name of S750 board
} qnicll_init_info_libiio_t;


int qnicll_init(void *init_info);
// desc: initializes the library.
// input: init_st: one of qnicll_init_info_* structures.
//        depends on implementation
// returns: one of QNICLL_ERR_*

int qnicll_done(void);
// desc: call when done using the library, if you want to be tidy.
//       Or don't ever call it!

char *qnicll_error_desc(void);
// Desc: returns description of the last error, if any, if there was one.
//       If no error happened, do not call this function.
//       If no error happened, and you call this function, return value is undefined.  
//       Not all errors have descriptions, so this may return "".  
//       Contents may change after every qnicll call.
//       Don't try to free the string.

  
  
int qnicll_set_mode(int mode);
// desc: invokes settings appropriate for specified mode. (optical switches,
//   voa settings, bias feedback goals, etc.  If called before prior set_mode finishes
// inputs: mode: requested mode. one of QNICLL_MODE_*.
// returns: one of QNICLL_ERR_*
//          If mode is invalid or not supported, returns QNICLL_ERR_MISUSE.



int qnicll_set_txc_voa_atten_dB(double *atten_dB);
// desc: sets transmit classical optical attenuation in units of dB
//       Within the valid range, granularity of valid settings is better than 0.1 dB.
// inputs: atten_dB: requested attenuation in units of dB, typically 0
//                   to 60 but max attenuation is implementation and calibration
//                   dependent.  Boot-up default setting is something reasonable.
//                   (probably max atten)
// sets: atten_dB: set to the new actual effective attenuation.
// returns: one of QNICLL_ERR_* (after attenuation is achieved)

int qnicll_set_tx_pwr_dBm(double *pwr_dBm);
// desc: sets transmit classical optical power in units of dBm
//       Depends on calibration of qnic.  Makes use of same underlying code
//       as qnicll_set_txc_voa_atten_dB().
//       Within the valid range, granularity of valid settings is better than 0.1 dB.
// inputs: pwr_dBm: requested power in units of dBm
// sets: pwr_dBm: set to the new actual power
// returns: one of QNICLL_ERR_* (after power is achieved)



int qnicll_set_txq_voa_atten_dB(double *atten_dB);
// desc: sets transmit quantum optical attenuation in units of dB.
// inputs: atten_dB: requested attenuation in units of dB.
// sets: atten_dB: set to the new actual effective attenuation.
// returns: one of QNICLL_ERR_* (after attenuation is achieved)



int qnicll_set_rx_voa_atten_dB(double *atten_dB);
// desc: sets receiver attenuation (after the receiver EDFA).
// inputs: atten_dB: requested attenuation in units of dB.
// sets: atten_dB: set to the new actual effective attenuation.



typedef struct qnicll_im_status_st {
  int lock;        // 0=unlocked, 1=locked
  int tx_pct;      // measured transmission as a percent. 0 to 100.
  int lock_dur_ms; // duration feedback has been continuously locked, in ms
} qnicll_im_status_t;


int qnicll_set_txq_im_goal_pct(int goal_pct, qnicll_im_status_t *im_status);
// desc: Sets goal for transmit intensity modulator (IM) bias feedback.
// input: goal_pct: requested goal.  Typically 0, 50 or 100.
// sets: im_status structure
// returns: one of QNICLL_ERR_* (after goal is reached or timedout)

int qnicll_get_txq_im_status(qnicll_im_status_t *im_status);
// Desc: measures the status of the intensity modulator (IM) bias feebdack.
//       included for debug
// returns: one of QNICLL_ERR_*




int qnicll_set_rxq_polctl_setting_idx(int *idx);
// desc: sets receiver polarization control to one of a set of
//       pre-calibrated settings.  These settings result in orthogonal
//       polarization transformations.
// inputs: idx: 0,1, or 2.
// sets: idx: set to setting index actually being used.
// returns: one of QNICLL_ERR_* (after polarization has been set)

int qnicll_get_rxq_polctl_setting_idx(int *idx);
// sets: idx: set to setting index actually being used.
// returns: one of QNICLL_ERR_* (after polarization has been set)

int qnicll_set_sample_rate_Hz(double *fsamp_Hz);
// desc: sets or querries the sampling rate of the ADCs/DACs.
// input: fsamp_Hz: requested sampling rate.  or 0 to querry only.
// sets:  fsamp_Hz: actuall effective sampling rate.  
//        for now expect this to be 1.233333333e9
// returns: one of QNICLL_ERR_*






#define QNICLL_DATASRC_LFSR (1)
// means probe (aka header) is generated from lfsr by HDL
#define QNICLL_DATASRC_CUSTOM (2)
// host must write data to be transmitted as the probe.
// (This is what John calls SOURCE_EXTERNAL)
#define QNICLL_DATASRC_TRNG_ALG1 (3)
// Probe is generated from a true random number generator,
// and those bits are expanded according to proprietary algorithm 1 by HDL.
// Not implemented yet, but ultimately we may want something like this.

int qnicll_set_probe_datasrc(int *datasrc);
// desc: determines how the probe is generated
// inputs: datasrc: requested datasrc. one of QNICLL_DATASRC_*
// sets: datasrc: the datsrc actually being used.
// returns: one of QNICLL_ERR_*

int qnicll_reset_tx_datasrc(void);
// desc: resets the quantum transmit datasrc.  Depends on current datasrc:
//       QNICLL_DATASRC_LFSR -> resets the lfsr
//       QNICLL_DATASRC_CUSTOM -> Not sure yet what this does!  Maybe
//                                      it rewinds the fifo
//       QNICLL_DATASRC_TRNG_ALG1 -> resets the data expansion algorithm
// returns: one of QNICLL_ERR_*


int qnicll_set_symbol_map(void *table, int samps_per_sym, int samp_data);
// desc: sets Young's symbol table.
// returns: one of QNICLL_ERR_*

int qnicll_set_probe_tx_format(int *format);
// desc: sets or querries the format used for
//       qnicll_set_probe_tx_data()
//       when you are using QNICLL_PROBE_DATASRC_CUSTOM.
//       Note that the rx format may be different.
// input: format: requested format. one of QNICLL_FORMAT_*  Set to zero to just do a querry.
// sets:  format: actual effective transmit format.
// returns: one of QNICLL_ERR_*

int qnicll_idx_t2p(int format, int ch, int t_idx);
int qnicll_idx_p2t(int format, int ch, int p_idx);
// desc: converts temporal index to positional index and vice versus, according to format.
// inputs: ch: 0=intensity or I,  1 =phase or Q.
//         t_idx: temporal index
//         p_idx: positional index within buffer

int qnicll_set_tx_data(void *buf, size_t buf_sz);
// desc: sets data used for QNICLL_PROBE_DATASRC_CUSTOM.
//       Must be formatted according to format returned from
//       qnicll_set_probe_tx_format().
// inputs: buf: buffer of data
//         buf_sz: size of data
// returns: one of QNICLL_ERR_*



			  
int qnicll_set_probe_pd_samps(int *probe_pd_samps);
// desc: sets the duration of one "probe period".
//       Typically this should be equal to the round trip
//       optical path length of the link.  It may be longer.
//       If shorter, some reflections might be ignored.
//
//       Probe period might have to be a multiple of some some
//       number of samples, typically 4.  If the requested period
//       is not, qnicll will round it down.
//
// inputs: probe_pd_samps: requested number of samples per "probe period".
// sets:  probe_pd_samps: actual number of samples per "probe period".
//        In units of time this is probe_pd_samps/fsamp_Hz.
//        Depending on the implementation, the value may be limited
//        or restricted to multiples of some factor.
// returns: one of QNICLL_ERR_*

int qnicll_set_probe_len_bits(int *probe_len_bits);
// desc: sets the length of the probe, in units of bits.
//       Typically we use 32..128 bits.
// inputs: probe_len_bits: requested length of the probe in units of bits.
// sets:   probe_len_bits: actual new length of the probe
// returns: one of QNICLL_ERR_*

int qnicll_set_probe_tx_modulation(int *modulation, int *osamp_factor);
// desc: Sets the optical modulation used by the nic to transmit its probes.
//       The modulation determines bits per symbol.
//       Currently only IM (intensity modulation) is implemented,
//       but QPSK, QAM, etc may eventually be possible.
//       Depending on implementation, may make underlying call to
//       qnicll_set_symbol_map() (as per Young's HDL)
// 
//       Also sets the oversampling factor used by the qnic.
//       Currently, only 4 is implemented.
//       
// inputs: modulation: one of QNICLL_MODULATION_*
//         osamp_factor: requested oversampling factor.  samples per symbol.
// sets: modulation: the actual new modulation
//       osamp_factor: the actual new oversampling factor
// returns: one of QNICLL_ERR_*

int qnicll_set_qsdc_data_modulation(int *modulation, int *osamp_factor);
// desc: Sets the optical modulation used for the QSDC data.
//       The QSDC header is generated using the "probe" modulation,
//       but the data might use a different modulation.
//
//       Currently not implemented


int qnicll_set_probe_qty(int *probe_qty);
// desc: sets the number of probes (or probe periods) to be
//       generated back-to-back in QNICLL_MODE_CDM mode.
//       You may be set it to 1 if you don't mind being inefficient.
// inputs: probe_qty: requested probe quantity
// sets:   probe_qty: set to actual new probe quantity
// returns: one of QNICLL_ERR_*


int qnicll_set_probe_rx_format(int *format);
// desc: sets or querries the format of data returned by
//       qnicll_probe_rx_data().
//       May be different from the tx format.
//       Might or might not actually be settable.
// input: format: requested format.  Set to zero to just do a querry.
// sets:  format: actual effective recieve format.
// returns: one of QNICLL_ERR_*

int qnicll_set_rx_buf_sz(size_t *rx_buf_sz);
// desc: sets the size of rx buffers to be used when recieving
//       probes or noise measurements.
//       Each rx buffer is a continuous region of memory managed
//       by qnicll, the size of which probably corresponds to the
//       length of one DMA transfer.  qnicll may manage multiple
//       rx buffers (when built on top of libiio there are typically
//       four rx buffers).  So the requested buffer size determines
//       the requested DMA transfer size.
//
//       Depending on the implementation, the size might have to be
//       a multiple of some number of bytes.  Typically a multiple of
//       16.  If the requested size is not, qnicll will round it down.
//       There will be some implementation-determined upper limit.
//       Pass rx_buf_sz=SIZE_MAX to request the largest possible size.
//
//       In CDM mode, qnicll imposes
//       rx_buf_sz = n * probe_pd_samps*4
//       where n is some integer as large as possible
//       and n <= probe_tx_qty 
// 
// inputs: rx_buf_sz: requested size of the rx buffer in bytes
// sets:   rx_buf_sz: actual new rx buf size 
// returns: one of QNICLL_ERR_*


int qnicll_rx_start(void);
// desc: Prepares resources for DMA transfers.  Might fail due to
//       lack of resoureces, in whcih case it returns QNICLL_ERR_OUTOFMEM.
//
//       In CDM mode, causes the transmission of probe_tx_qty of back-to-back probes.
//       simultaneously with the capture of I and Q samples.
//       After probe_pd_samps*probe_rx_qty samples received,
//       user-supplied callback will be called.
// returns: one of QNICLL_ERR_*


int qnicll_rx(void **buf, size_t *buf_occ, int *status);
// desc: receives I and Q data.  May be called multiple times.
//       Calling code does not allocate the buffer, nor does it free it.
//       Buffer is freed in next call to qnicll_probe_rx() or in qnicll_probe_stop().
// sets:  buf: pointer to buffer of size rx_buf_sz,
//             as set previously by qnicll_set_rx_buf_sz().
//        buf_occ: occupancy of the buffer in bytes.  May be less than buf_len.
//        status: one of QNICLL_RX_STATUS
// returns: one of QNICLL_ERR_*
  
int qnicll_rx_stop(void);
// desc: may free DMA resources.
// returns: one of QNICLL_ERR_*

int qnicll_get_fqsw_pd_samps(int *pd_samps, int *offset_samps, int *trans_samps);
// desc: gets the period of the square wave driven to the fast quantum switch
//       also gets the starting offset, and how fast it can transition.
// sets:  pd_samps: period of square wave in units of samples.
//                  pd_samps/2 "vacuum" (dark) states follow pd_samps/2 "lit" states.
//        offset_samps: offset of first "vacuum" sample in rx buffer
//                  relative to first sample in first rx buffer
//                  in units of (temporal) samples.
//        trans_samps: number of samples over which the signal might be
//                  in transition.

int qnicll_set_fqsw_en(int en);
// desc: emables the square wave to the fast quantum switch.
//       Used in mode QNICLL_MODE_MEAS_NOISE.

  
int qnicll_set_txc_wl_idx(int *wl_idx);
// desc: sets classical wavelength transmission
// inputs: wl_idx: requested index in set of wavelengths.  0 or 1.
// sets: wl_idx: actual index
// returns: one of QNICLL_ERR_*





// DEBUG FUNCTIONS MAY COME AND GO!!!

int qnicll_dbg_set_tx_always(int *en);
// desc: debug mode in which probe is retransmitted always.



#endif

