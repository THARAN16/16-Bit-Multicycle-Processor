## ============================================================================
## REFINED VIVADO TIMING CONSTRAINTS FOR BOOTH MAC UNIT
## Target: 50 MHz (20ns period) | Clean Console (Zero Warnings)
## ============================================================================

## ----------------------------------------------------------------------------
## 1. CLOCK DEFINITION
## ----------------------------------------------------------------------------
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

## ----------------------------------------------------------------------------
## 2. INPUT DELAY CONSTRAINTS
## Explicitly defining Max (Setup) and Min (Hold) times to silence XDCH-2
## ----------------------------------------------------------------------------
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports {rst start mac_mode multiplicand[*] multiplier[*] accumulator[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports {rst start mac_mode multiplicand[*] multiplier[*] accumulator[*]}]

## ----------------------------------------------------------------------------
## 3. OUTPUT DELAY CONSTRAINTS
## Explicitly defining Max (Setup) and Min (Hold) times to silence XDCH-2
## ----------------------------------------------------------------------------
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports {done overflow result_lo[*] result_hi[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports {done overflow result_lo[*] result_hi[*]}]

## ----------------------------------------------------------------------------
## 0. CONFIGURATION VOLTAGE (Fixes the CFGBVS Warning)
## Tells Vivado the board uses 3.3V for its configuration bank
## ----------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## ============================================================================
## END OF BOOTH MAC CONSTRAINTS - 50 MHz
## ============================================================================