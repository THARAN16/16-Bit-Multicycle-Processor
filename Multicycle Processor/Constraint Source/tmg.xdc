## ============================================================================
## REFINED VIVADO TIMING CONSTRAINTS - 1.5V CONFIGURATION
## Target: 50 MHz (20ns period) | IO Standard: LVCMOS15
## ============================================================================

## ----------------------------------------------------------------------------
## 0. CONFIGURATION VOLTAGE (Fixes CFGBVS #1 Warning)
## ----------------------------------------------------------------------------
# These properties tell Vivado the configuration bank is powered at 1.5V.
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 1.5 [current_design]

## ----------------------------------------------------------------------------
## 1. CLOCK DEFINITION - 50 MHz
## ----------------------------------------------------------------------------
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

## ----------------------------------------------------------------------------
## 2. IO STANDARDS (Updated to 1.5V)
## ----------------------------------------------------------------------------
# Set all inputs to 1.5V logic thresholds
set_property IOSTANDARD LVCMOS15 [get_ports {clk rst start mac_mode}]
set_property IOSTANDARD LVCMOS15 [get_ports {multiplicand[*] multiplier[*] accumulator[*]}]

# Set all outputs to 1.5V logic thresholds
set_property IOSTANDARD LVCMOS15 [get_ports {done overflow result_lo[*] result_hi[*]}]

## ----------------------------------------------------------------------------
## 3. INPUT DELAY CONSTRAINTS
## ----------------------------------------------------------------------------
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports {rst start mac_mode multiplicand[*] multiplier[*] accumulator[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports {rst start mac_mode multiplicand[*] multiplier[*] accumulator[*]}]

## ----------------------------------------------------------------------------
## 4. OUTPUT DELAY CONSTRAINTS
## ----------------------------------------------------------------------------
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports {done overflow result_lo[*] result_hi[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports {done overflow result_lo[*] result_hi[*]}]

## ============================================================================
## END OF BOOTH MAC CONSTRAINTS - 1.5V
## ============================================================================