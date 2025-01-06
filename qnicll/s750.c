

#include <sys/types.h>
#include <fcntl.h>
#include <stdio.h>
#include "s750.h"
#include <unistd.h>


typedef struct s750_state_st {
  int fd;
} s750_state_t;
static s750_state_t st={0};


char cmd[256];
qnicll_set_err_fn *my_err_fn;

#define BUG(MSG) return(*my_err_fn)(MSG, QNICLL_ERR_BUG);


int s750_connect(char *devname, qnicll_set_err_fn *err_fn) {
  st.fd=open(devname, O_RDWR, 0);
  my_err_fn = err_fn;
}

char *do_cmd(int fd, char *cmd) {
  return cmd;
}

int do_cmd_get_doub(char *cmd, double *d) {
  int n;
  double t;
  char *rsp;
  rsp = do_cmd(st.fd, cmd);
  n = sscanf(rsp,"%lg", &t);
  if (n!=1) BUG("bad double rsp from s750");
  *d = t;
  return 0;
}

int s750_set_txc_voa_atten_dB(double *atten_dB) {
  int e;
  double d;
  sprintf(cmd, "txc %.2f\n", *atten_dB);
  e = do_cmd_get_doub(cmd, &d);
  if (e) return e;
  *atten_dB = d;
  return 0;
}

int s750_set_txq_voa_atten_dB(double *atten_dB) {
// desc: sets transmit quantum optical attenuation in units of dB.
// inputs: atten_dB: requested attenuation in units of dB.
// sets: atten_dB: set to the new actual effective attenuation.
// returns: one of QNICLL_ERR_* (after attenuation is achieved)
  return 0;  
}


int s750_set_rx_voa_atten_dB(double *atten_dB) {
// desc: sets receiver attenuation (after the receiver EDFA).
// inputs: atten_dB: requested attenuation in units of dB.
// sets: atten_dB: set to the new actual effective attenuation.
  return 0;  
}

int s750_disconnect(void){
  close(st.fd);
  return 0;  
}

int s750_set_txsw(int setting) {
  sprintf(cmd, "txsw %d\n", !!setting);
  do_cmd(st.fd, cmd);  
}

int s750_set_rxsw(int setting) {
  sprintf(cmd, "rxsw %d\n", !!setting);
  do_cmd(st.fd, cmd);  
}

