#ifndef _CLI_H_
#define _CLI_H_

#include "qnicll.h"
#include "qnicll_internal.h"

// these use QNICLL_ERR return codes
int cli_connect(char *hostname, qnicll_set_err_fn err_fn);
int cli_set_probe_qty(int *probe_qty);
int cli_set_probe_pd_samps(int *pd_samps);
int cli_set_probe_len_bits(int *probe_len_bits);
int cli_set_tx_always(int *en);
int cli_tx(int tx_en);
int cli_disconnect(void);

#endif
