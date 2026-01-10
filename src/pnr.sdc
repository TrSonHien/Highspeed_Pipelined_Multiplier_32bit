source src/common.sdc

set_clock_uncertainty -setup 1.5 [get_clocks clk]
set_clock_uncertainty -hold 0.3 [get_clocks clk]

set_max_transition 0.5 [current_design]
