if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/tb" }

set binopt {-logic}
set hexopt {-literal -hex}

eval add wave -noupdate -divider {"top-level ports"}
eval add wave -noupdate $binopt $tbpath${ps}sys_clk
eval add wave -noupdate $binopt $tbpath${ps}sys_rst

eval add wave -noupdate $binopt $tbpath${ps}RXP0_IN
eval add wave -noupdate $binopt $tbpath${ps}RXN0_IN
eval add wave -noupdate $binopt $tbpath${ps}TXP0_OUT
eval add wave -noupdate $binopt $tbpath${ps}TXN0_OUT

eval add wave -noupdate $binopt $tbpath${ps}refclk
eval add wave -noupdate $binopt $tbpath${ps}refclkout
eval add wave -noupdate $binopt $tbpath${ps}plllkdet
eval add wave -noupdate $binopt $tbpath${ps}dcm_locked

eval add wave -noupdate $binopt $tbpath${ps}clk0${ps}TILE0_REFCLK_PAD_P_IN
eval add wave -noupdate $binopt $tbpath${ps}clk0${ps}TILE0_REFCLK_PAD_N_IN
