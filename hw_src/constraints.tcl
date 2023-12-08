#**************************************************************
# IP synthesis timing constraints template
#**************************************************************
# Library time unit
set lib_time_unit 1e-12
set lib_time_mult_factor [expr 1e-9 / $lib_time_unit]

#**************************************************************
# CLOCKS
#**************************************************************
#CLK
set clk250MFreq 250 ;#250Mhz
set clk250MPeriod [expr (1000.0 / $clk250MFreq) * $lib_time_mult_factor]
create_clock -name "CLK" -p $clk250MPeriod -w [list 0 [expr $clk250MPeriod / 2]]  [get_ports CLK]
# set_dont_touch_network "CLK"

# SCK
set sck20MFreq 20 ;#20Mhz
set sck20MPeriod [expr (1000.0 / $sck20MFreq) * $lib_time_mult_factor]
create_clock -name "SCK" -p $sck20MPeriod -w [list 0 [expr $sck20MPeriod / 2]]  [get_ports SCK]

set_clock_groups -asynchronous -group "CLK" -group "SCK"

#*************************************************************
# Set drive and load constraints
#*************************************************************

set_clock_latency 		0.5 		[all_clocks]
set_clock_uncertainty 	0.2	        [all_clocks]
set_clock_transition    0.2         [all_clocks]

set_load 0.050 [all_outputs]

#*************************************************************
# IO timing
#*************************************************************
set_input_delay  [expr 5]  -network_latency_included -max -clock "SCK" -clock_fall [get_ports MOSI]
set_input_delay  [expr -5] -network_latency_included -min -clock "SCK" -clock_fall [get_ports MOSI]
set_output_delay [expr 5]  -network_latency_included -max -clock "SCK" [get_ports MISO]
set_output_delay [expr -5] -network_latency_included -min -clock "SCK" [get_ports MISO]

#*************************************************************
# Exceptions
#*************************************************************
set_false_path		-through [get_ports RST] 	
set_false_path		-through [get_ports AERIN_ADDR] 
set_false_path		-through [get_ports AERIN_REQ] 
set_false_path		-through [get_ports AERIN_ACK]   	
set_false_path		-through [get_ports AEROUT_ADDR] 
set_false_path		-through [get_ports AEROUT_REQ] 
set_false_path		-through [get_ports AEROUT_ACK] 
set_false_path		-through [get_ports SCHED_FULL] 
