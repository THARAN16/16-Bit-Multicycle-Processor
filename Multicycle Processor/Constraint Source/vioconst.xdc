## ============================================================================
## UNIFIED PROCESSOR VIO CONSTRAINTS - NEXYS VIDEO (20ns TIMING)
## ============================================================================

# 1. Physical Clock (Pin R4) - Constrained to 20ns (50 MHz) to pass timing
set_property PACKAGE_PIN R4 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

# 2. VIO Timing Exceptions
# Ignore timing analysis on the asynchronous manual reset from the VIO
set_false_path -through [get_nets -hierarchical *rst_vio*]

# 3. Voltage & Configuration (Prevents Bitstream DRC Warnings)
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]