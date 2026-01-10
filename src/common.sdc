set_units -time ns -capacitance pF

create_clock -name clk -period 10.0 [get_ports clk]

set_input_delay -max 0.4 -clock clk [get_ports {rst a* b*}]
set_output_delay -max 0.4 -clock clk [get_ports {p*}]

set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 [all_inputs]
set_load 0.03 [all_outputs]
