1) create ngc file for chipscope.
 mkdir implementation
 cd implementation
 coregen -p ../pcores/sata_v1_00_a/hdl/verilog/cdc/coregen.cgp   -b ../pcores/sata_v1_00_a/hdl/verilog/cdc/chipscope_icon3.xco
 coregen -p ../pcores/sata_v1_00_a/hdl/verilog/cdc/coregen.cgp   -b ../pcores/sata_v1_00_a/hdl/verilog/cdc/chipscope_ila_128x1.xco
 cd ../

2) create bitstream.
 xps -nw *.xmp
  save make
  exit
 make -f ss*.make

3) testing in hardware.
 connect a serial cable. 
