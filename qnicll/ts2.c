
#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include <stdlib.h>
#include <errno.h>
#include "myiio.h"
#include "cli.h"
#include <iio.h>
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

#include "qnicll.h"

char errmsg[256];
void err(char *str) {
  printf("ERR: %s\n", str);
  printf("     %s\n", qnicll_error_desc());
  printf("     errno %d\n", errno);
  exit(1);
}

/*
void set_blocking_mode(struct iio_buffer *buf, int en) {
  int i;
  i=iio_buffer_set_blocking_mode(buf, en); // default is blocking.
  if (i) {
    printf("set block ret %d\n", i);
    err("cant set blocking");
  }
}
*/

#define NSAMP (1024)

/*
void chan_en(struct iio_channel *ch) {
  iio_channel_enable(ch);
  if (!iio_channel_is_enabled(ch))
    err("chan not enabled");
}
*/
#define DAC_N (256)
#define SYMLEN (4)
#define PAT_LEN (DAC_N/SYMLEN)
#define ADC_N (1024*8*4)



void delme_pause(char *prompt) {
  char buf[256];
  if (prompt && prompt[0])
    printf("%s > ", prompt);
  else
    printf("hit enter > ");
  scanf("%[^\n]", buf);
  getchar();
}

double ask_num(char *prompt, double dflt) {
  char buf[32];
  int n;
  double v;
  printf("%s (%g)> ", prompt, dflt);
  n=scanf("%[^\n]", buf);
  getchar();
  if (n==1)
    n=sscanf(buf, "%lg", &v);
  if (n!=1) v=dflt;
  return v;
}

int main(void) {
  int num_dev, i, j, k, n, e, itr;
  char name[32], attr[32];
  int pat[PAT_LEN] = {1,1,1,1,0,0,0,0,1,0,1,0,0,1,0,1,
       1,0,1,0,1,1,0,0,1,0,1,0,0,1,0,1,
       1,0,1,0,1,1,0,0,1,0,1,0,0,1,0,1,
       0,1,0,1,0,0,1,1,0,1,0,1,1,0,1,0};
  ssize_t sz, tx_sz;
  const char *r;
  struct iio_context *ctx=0;
  struct iio_device *dac, *adc;
  struct iio_channel *dac_ch0, *dac_ch1, *adc_ch0, *adc_ch1;
  struct iio_buffer *dac_buf, *adc_buf;
  ssize_t adc_buf_sz, left_sz;
  void * adc_buf_p;
  FILE *fp;
  int fd;
  double x, y;
  short int mem[DAC_N];
  short int rx_mem[ADC_N];
  short int corr[ADC_N];
  int fdmem;
  int *m;
  int cap_len_bufs; 
  long long int ll;
  int use_lfsr=1;
  int tx_always=0;
  int tx_0=0;  

  int cap_len_samps, buf_len_samps;
  int num_itr, b_i;
  int *times_s;
  
  int probe_qty=25;
  int probe_len_bits, probe_pd_samps;
  
  printf("hi\n");
  //  ctx = iio_create_local_context();

  qnicll_init_info_libiio_t init_info;
  strcpy(init_info.ipaddr, "10.0.0.5");
  strcpy(init_info.usbdev, "ttyUSB0");
  if (qnicll_init(&init_info)) err("init fail");

  

  int sfp_attn_dB = 0;
  //  sfp_attn_dB = ask_num("sfp_attn (dB)", sfp_attn_dB);
  

  use_lfsr = (int)ask_num("use_lfsr", 1);
  myiio_set_use_lfsr(use_lfsr);

  tx_always = (int)ask_num("tx_always", 0);
  qnicll_dbg_set_tx_always(&tx_always);

  tx_0 = (int)ask_num("tx_0", 0);
  myiio_set_tx_0(tx_0);


  int d;
  d = 2;
  // d=24;
  d = ask_num("probe_pd (us)", d);
  i = myiio_dur_us2samps(d);

  qnicll_set_probe_pd_samps(&i);
  printf("probe_pd_samps %d\n", i);
  //	 myiio_dur_samps2us(st.probe_pd_samps));
  probe_pd_samps=i;


  probe_qty = (int)floor(ADC_N/probe_pd_samps);
  printf("max probes %d\n", probe_qty);
  probe_qty=10;
  i=probe_qty = ask_num("probe_qty", probe_qty);
  qnicll_set_probe_qty(&probe_qty);
  if (probe_qty != i) {
    printf("ERR: probe qty actually %d\n", probe_qty);
    err("fail");
  }

  cap_len_samps = probe_pd_samps * probe_qty;
    
  cap_len_bufs = (int)ceil((double)cap_len_samps / ADC_N);
  printf(" num bufs %d\n", cap_len_bufs);


    
  buf_len_samps = cap_len_samps / cap_len_bufs;
  printf(" buf_len_samps %d\n", buf_len_samps);

  cap_len_samps  = buf_len_samps * cap_len_bufs;


  probe_qty = (int)ceil(cap_len_samps / probe_pd_samps);
  cap_len_samps = probe_qty * probe_pd_samps;
  printf(" cap_len_samps %d\n", cap_len_samps);
    
      //    printf("cap_len_samps %d must be < %d \n", cap_len_samps, ADC_N);
      //    printf("WARN: must increase buf size\n");


   
  printf("using probe_qty %d\n", probe_qty);
    
  //  size of sz is 4!!
  //  printf("size sz is %zd\n", sizeof(ssize_t));
  
  i=128;  
  i = ask_num("probe_len_bits", i);
  qnicll_set_probe_len_bits(&i);
  printf("probe_len_bits %d\n", i);
  probe_len_bits = i;
  
  num_itr=1;
  // num_itr = ask_num("num_itr", 1);
  times_s = (int *)malloc(num_itr*sizeof(int));

  

  memset(mem, 0, sizeof(mem));

  // sin wave burst
  j=0;
  printf("pattern: ");
  for(i=0; i<PAT_LEN; ++i) {
    n=(pat[i]*2-1) * (32768/2);
    if (i<8)
      printf(" %d", n);
    for(k=0;k<SYMLEN;++k)
      mem[j++] = n;
  }
  printf("...\n");
  printf("  %d DAC samps\n", j);
  if (j!=DAC_N) printf("ERR: expected %d\n", DAC_N);
  

  // sys/module/industrialio_buffer_dma/paraneters/max_bloxk_size is 16777216
  // iio_device_set_kernel_buffers_count(?
  //  i = iio_device_get_kernel_buffers_count(dev);
  //  printf("num k bufs %d\n", i);
  
  


  // oddly, this create buffer seems to cause the dac to output
  // a sin wave!!!
  // sample size is 2 * number of enabled channels.
  // printf("dac samp size %zd\n", sz);
  sz = iio_device_get_sample_size(dac);
  dac_buf = iio_device_create_buffer(dac, (ssize_t) DAC_N * sz, false);
  if (!dac_buf) {
    sprintf(errmsg, "cant create dac bufer  nsamp %d", DAC_N);
    err(errmsg);
  }
  


  
  
  // calls convert_inverse and copies data into buffer
  sz = iio_channel_write(dac_ch0, dac_buf, mem, sizeof(mem));
  // returned 256=DAC_N*2, makes sense
  printf("wrote ch0 to dac_buf sz %zd\n", sz);

  

  //  i=iio_buffer_set_blocking_mode(dac_buf, true); // default is blocking.
  //  if (i) err("cant set blocking");


  tx_sz = iio_buffer_push(dac_buf);
  //  printf("pushed %zd\n", tx_sz);  

  fd = open("out/d.raw", O_CREAT | O_WRONLY | O_TRUNC, S_IRWXO);
  if (fd<0) err("cant open d.raw");

  
  for (itr=0;itr<1;++itr) {

    printf("itr %d\n", itr);

    *(times_s + itr) = (int)time(0);
    
    sz = iio_device_get_sample_size(adc);  // sz=4;
    adc_buf_sz = sz * buf_len_samps;
    adc_buf = iio_device_create_buffer(adc, buf_len_samps, false);
    if (!adc_buf)
      err("cant make adc buffer");
    printf("made adc buf size %zd\n", (ssize_t) adc_buf_sz);

    
    //    set_blocking_mode(adc_buf, false); // default is blocking.

    //    myiio_print_adc_status();
    sz = iio_buffer_refill(adc_buf);
    if (sz>0) {
      printf("ERR: prepratory refill %zd\n", sz);
      printf("     did not expect that!!\n");
    }
    //    myiio_print_adc_status();
    
    //    set_blocking_mode(adc_buf, true); // default is blocking.
    

    cli_tx(1);
  
    for(b_i=0; b_i<cap_len_bufs; ++b_i) {
      printf("ref s\n");
      sz = iio_buffer_refill(adc_buf);
      printf("ref e\n");
      if (sz<0) err("cant refill buffer");
      if (sz != adc_buf_sz)
	printf("tried to refill %zd but got %zd\n", adc_buf_sz, sz);
      // pushes double the dac_buf size.
      //myiio_print_adc_status();      

      // iio_buffer_start can return a non-zero ptr after a refill.
      adc_buf_p = iio_buffer_start(adc_buf);
      left_sz = sz;
      while(left_sz>0) {
        sz = write(fd, adc_buf_p, left_sz);
        if (sz<=0) err("write failed");
        if (sz == left_sz) break;
	printf("tried to write %zd but wrote %zd\n", left_sz, sz);
	left_sz -= sz;
	adc_buf_p = (void *)((char *)adc_buf_p + sz);
      }
      
      // printf("wrote %zd\n", sz);
      // dma req will go low.

      
    }

    cli_tx(0);
    
    //    prompt("end loop prompt ");
    //    myiio_print_adc_status();
    
    // printf("adc buf p x%x\n", adc_buf_p);

    /*
    // calls convert and copies data from buffer
    sz = cap_len_samps*2;
    sz_rx = iio_channel_read(adc_ch0, adc_buf, rx_mem_i, sz);
    if (sz_rx != sz)
      printf("ERR: read %zd bytes from buf but expected %zd\n", sz_rx, sz);

    sz_rx = iio_channel_read(adc_ch1, adc_buf, rx_mem_q, sz);
    if (sz_rx != sz)
      printf("ERR: read %zd bytes from buf but expected %zd\n", sz_rx, sz);
    for(i=0; i<4; ++i) {
      printf("%d %d\n",  rx_mem_i[i], rx_mem_q[i]);
    }
    */


    

    //    for(i=1; i<ADC_N; ++i)
    //      rx_mem[i] = (int)sqrt((double)rx_mem_i[i]*rx_mem_i[i] + (double)rx_mem_q[i]*rx_mem_q[i]);

    
    // display rx 
    /*    for(i=1; i<ADC_N; ++i)
      if (rx_mem[i]-rx_mem[i-1] > 100) break;
    if (i>=ADC_N)
      printf("WARN: no signal\n");
    else
      printf("signal at idx %d\n", i);
    
    y = rx_mem[i];
    x = (double)i/1233333333*1e9;
    */


    iio_buffer_destroy(adc_buf);
    

  }
  close(fd);
  //  if (myiio_done()) err("myiio done fail");

  
  qnicll_done();
  
  fp = fopen("out/r.txt","w");
  //  fprintf(fp,"sfp_attn_dB = %d;\n",   sfp_attn_dB);
  fprintf(fp,"use_lfsr = %d;\n",   use_lfsr);
  fprintf(fp,"tx_always = %d;\n",  tx_always);
  fprintf(fp,"tx_0 = %d;\n",  st.tx_0);
  fprintf(fp,"probe_qty = %d;\n",    probe_qty);
  fprintf(fp,"probe_pd_samps = %d;\n", probe_pd_samps);
  
  fprintf(fp,"probe_len_bits = %d;\n", probe_len_bits);
  fprintf(fp,"data_probe = 'i_adc q_adc';\n");
  fprintf(fp,"data_len_samps = %d;\n", cap_len_samps);
  fprintf(fp,"data_in_other_file = 2;\n");
  fprintf(fp,"num_itr = %d;\n", num_itr);
  fprintf(fp,"time = %d;\n", (int)time(0));
  fprintf(fp,"itr_times = [");
  for(i=0;i<num_itr;++i)
    fprintf(fp," %d", *(times_s+i)-*(times_s));
  fprintf(fp, "];\n");

  
  fclose(fp);

  
  return 0;
}

  
