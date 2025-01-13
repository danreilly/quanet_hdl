
#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include <stdlib.h>
#include <errno.h>
#include <iio.h>
#include <math.h>
#include <sys/mman.h>
#include "qnicll.h"



void err(int e, char *msg) {
  printf("ERR: %d\n", e);
  if (msg && msg[0])
    printf(      while calling %s\n", msg);
  printf(      %s\n", qnicll_get_errmsg());
  printf("     errno %d\n", errno);
  exit(1);
}
#define C(CALL, MSG) {int e=CALL; if (e) err(e, MSG);}


void cdc(void) {
  int mope;



  mode=QNICLL_MODE_QDC;
  C(qnicll_set_mode(&mode));

  qnicll_init_info_libiio_t init_info;
  strcpy(init_info.ipaddr, "10.0.0.5");
  strcpy(init_info.usbdev, "ttyUSB0");
  C(qnicll_init(&init_info), "init");

  
}
