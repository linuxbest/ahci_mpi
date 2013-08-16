set binopt {-logic}
set hexopt {-literal -hex}
set ascopt {-literal -asc}

eval add wave -noupdate -divider {"{1} $1"}
eval add wave -noupdate $binopt ${1}${ps}MPMC_Clk
eval add wave -noupdate $binopt ${1}${ps}MPMC_Rst

eval add wave -noupdate $binopt ${1}${ps}PIM${2}_AddrReq
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_AddrAck
eval add wave -noupdate $hexopt ${1}${ps}PIM${2}_Addr
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_RNW
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_Size
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_RdModWr

eval add wave -noupdate $hexopt ${1}${ps}PIM${2}_WrFIFO_Data
eval add wave -noupdate $hexopt ${1}${ps}PIM${2}_WrFIFO_BE
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_WrFIFO_Push
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_WrFIFO_Empty
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_WrFIFO_AlmostFull
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_WrFIFO_Flush

eval add wave -noupdate $hexopt ${1}${ps}PIM${2}_RdFIFO_Data
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_RdFIFO_Pop
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_RdFIFO_RdWdAddr
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_RdFIFO_Flush
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_RdFIFO_Empty
eval add wave -noupdate $binopt ${1}${ps}PIM${2}_RdFIFO_Latency
