# goals for this repository

Retarget Analog Devices's libiio and HDL to make the DAQ3 board work with the zcu106.

Test various hardware configurations


# THIS VERSION

This version implements the ADC fifo using URAM instead of thr PL DDR4.  It's smaller and can only capture 350ms of consecutive samples.  It uses 32 of the 96 avaialbe URAMs.

This version does not drive the SFP.




# objects

Copy this to /boot/BOOT.BIN on your SD card:

`quanet_hdl/nucrypt_boot_objs/zcu106_BOOT.BIN`

Copy this to the /boot/system.dtb on your SD card: (dont name it devicetree.dtb)

`quanet_hdl/nucrypt_boot_objs/zynqmp-zcu106-fmcdaq3.dtb`



# summary of changes made to HDL

This HDL was copied from Analog Device's repository, and then modified
to suit our needs.  To implement our lidar-like CDM function, we need
the ADC to start capturing at time deterministically related to when
the DAC outputs a "probe".  To implement rapid two-level noise
measurements, our hardware features an optical switch that operates at
~100kHz to alternately block or pass light to the detectors, and this
control signal must also be driven deterministically to when the ADC
begins capturing samples.  So we had to change `library/util_dacfifo`
and `library/xilinx/axi_adcfifo`.

We also added a set of register `library/quanet_regs` to be able to
configure these new features.  These regs are imported/exported to axi_adcfifo
and util_dacfifo.  This requires making connections in
`projects/common/daq3_bd.tcl`, which is a bit inconvenient but not yet
terribly complicated.  Usually in block designs, each IP gets its own
register space on the AXI bus, but we we hesitant to make changes to
the existing register sets, so we made a new one.  But we could have
added the regs to util_dacfifo and axi_adcfifo since they doesn't
already have any regs.  axi_adcfifo has an axi interface for
streaming, but no regs.

We wanted to keep the HDL compatible with AD's libiio C API:
https://analogdevicesinc.github.io/libiio/v0.25/libiio/index.html
So we conditionally delayed the start of the DMA after the rise of the
dma_req signal (which would normally start the DMA immediately).  Our
idea was that first, software writes probe (header) content to the
fifo in `util_dacfifo.v` as a result of `iio_buffer_push(dac_buf)` but this is
not yet transmitted to the DAC.  Or more often, software would elect to generate
probes from an LFSR, and not even call `iio_channel_write()` or `iio_buffer_push(dac_buf)`.
Later, software calls `iio_buffer_refill(adc_buf)`.  This asserts `dma_req` in
`axi_adcfifo`, and this is passed deterministically from the ADC clock domain
to the DAC clock domain, and triggers `dac_utilfifo` to generate a pre-determined
number of probes.

Actually, and I don't yet know how necessary it is, the `util_dacfifo` only
commences probes in "probe commencement opportunity" cycles, which occour
periodically at the probe period.  This is to ensure a deterministic latency
(even after `iio_buffer_destroy()` and `iio_device_create_buffer()`, which together
start a new DMA session) to the DAC analog output, in case widenings or
narrowings of the data width occur further down the datapath out through the GTXs.
So the this "confirmed probe commencement signal" is sent back from the DAC clock
domain to the ADC clock domain in `axi_adcfifo`, at which time, the ADC samples are stored.


# porting Kuiper Linux to the ZCU106

I got my 2022_r2 linux image from  
https://wiki.analog.com/resources/tools-software/linux-software/adi-kuiper_images/release_notes  
This is about building Kuiper linux:  
https://wiki.analog.com/resources/tools-software/linux-drivers-all  
https://wiki.analog.com/resources/tools-software/linux-build/generic/zynqmp  

On my VM I installed lex, bison, U-boot-tools, and  libssl-dev.
I also installed Vitis 2023.2
Then I cloned the AD Linux sources:
```
git clone -b 2022_r2  https://github.com/analogdevicesinc/linux.git
```
Then I created the file:
linux/arch/arm64/boot/dts/xilinx/zynqmp-zcu106-fmcdaq3.dts
Which is based on a copy of the zcu102 dts.  I copied this to:  
quanet_hdl/nucrypt_boot_objs/zynqmp-zcu106-fmcdaq3.dts  
Note: I did not make a full copy of the kuiper linux source tree on this repository.  

Here are the instructions specific to zynqmp:  
https://wiki.analog.com/resources/tools-software/linux-build/generic/zynqmp  
The AD instructions say to copy a build script, which I did and I called `bldu.sh`.  Note that this is different from the zynq build script, I then modified `bldu.sh` so that you just run it and you cant specify any command line arguments, and it will build xilinx\zynqmp-zcu106-fmcdaq3.dtb. (a copy of `bldu.sh` is in my github in nucrypt_build_objs)

Since Vitis has the cross compiler, the next thing to do is to put that on the path:
```
source /tools/Xilinx/Vitis/2023.2/settings64.sh
```
And if you don't do that, the bdlu.sh script will download a different cross compiler (Linaro) and try to use it.  I have not explored that method.  Then I ran the script:
```
./bldu.sh
```
It produced `Image` and `xilinx\zynqmp-zcu106-fmcdaq3.dtb`, both of which I copied to github in `nucrypt_build_objs`.

I built my bitfile inside cygwin.  You can also do this in linux, but I have not tried.
```
cd quanet_hdl/projects/daq3/zcu106
make
```

This produces:

hdl-main/projects/daq3/zcu106/daq3_zcu106.runs/impl/system_top.bit
hdl-main/projects/daq3/zcu106/daq3_zcu106.sdk/system_top.xsa

The bitfile gets put into BOOT.BIN.

There are probably better ways to make the BOOT.BIN, but for now I'm
using a method similar to AD's document on building BOOT.BIN:
https://analogdevicesinc.github.io/hdl/user_guide/build_boot_bin.html
Which says to copy a script and run it.  I did that, modified it, and
named it (on github) as: `projects/daq3/zcu106/build_boot.bat` This
script builds the fsbl.elf and the pmufw.elf file.  Since the PS
configuration seldom changes, these probably don't have to be
recompiled every time the HDL is built, but they are.  I did not build
u-boot.elf.  Both u-boot.elf and bl31.elf can be extracted from the
project folder on the AD Kuiper linux SD Card image.  After you put
the image on an SD card, you can navigate (I used microsoft "File
Explorer") to the boot partition and get the stuff in
`/boot/zynqmp-zcu102-rev10-fmcdaq3` and unpack it.  I put a copy of
that directory on github under nucrypt_boot_objs and unpacked
bootgen_sysfiles.tgz there.  Note that this contains a BOOT.BIN for
the zcu106, but I didn't use that or even try that.  I only wanted the
elf files.  I made my build_boot.bat pull those elf files into the
BOOT.BIN that it builds.  AD's script auto-generates the zynq.bif
file, but I just hand-wrote mine for ease of tweaking.


# Register Spaces

Initially I had made a new IP called quanet_regs, that had a slave axi interface.  It implemented registers
that controlled three other IPs: the util_dacfifo, the axi_adcfifo, and also the quanet_sfp.  I had to make
connections between them in daq_bd.tcl.

Then I changed it so that each IP has its own slave axi interface, and its own set of registers.  While this might make the AXI buses consume more resources, this makes the IPs less interdependent.  It also means less connections have to be made in daq_bd.tcl, which becomes simpler.  It also allows each IP to have its own CDC constraints right there in the source code, as opposed to putting those constraints in yet another separate build file (system_constr.xdc).


# notes on AD's HDL

I found this web page useful:

https://analogdevicesinc.github.io/hdl/library/jesd204/axi_jesd204_rx/index.html#axi-jesd204-rx

Interestingly, AD also offers a Corundum core IP.

https://analogdevicesinc.github.io/hdl/library/corundum/index.html


# qnicll, the low level library

Now in

https://github.com/danreilly/qnicll


