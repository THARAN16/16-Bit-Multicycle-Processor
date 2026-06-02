## ============================================================================
## ADAPTIVE ALU TIMING CONSTRAINTS - ARTIX-7 NEXYS VIDEO
## 16-bit Adaptive ALU with Reversible Logic, LZD, and Operand Isolation
## Frequency: 50 MHz (20ns period) for comfortable timing margin
## ALL PORTS CONSTRAINED - ZERO WARNINGS
## ============================================================================

## ----------------------------------------------------------------------------
## 1. Physical Clock Definition (Nexys Video Artix-7)
## ----------------------------------------------------------------------------
# Pin R4 is the 100MHz onboard oscillator for the Nexys Video
set_property PACKAGE_PIN R4 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Defining 50MHz (20ns period). Waveform ensures Pulse Width is calculated.
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

## ----------------------------------------------------------------------------
## 2. Input Delays (ALL INPUTS INCLUDING RST)
## ----------------------------------------------------------------------------
# Synchronous inputs
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports {operand_a[*] operand_b[*] alu_op[*] start}]
set_input_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports {operand_a[*] operand_b[*] alu_op[*] start}]

# Reset input (asynchronous but needs constraint to avoid warning)
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports rst]
set_input_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports rst]

## ----------------------------------------------------------------------------
## 3. Output Delays (ALL OUTPUTS)
## ----------------------------------------------------------------------------
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports {result[*] carry_out zero_flag negative_flag overflow_flag done power_saved isolation_active}]
set_output_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports {result[*] carry_out zero_flag negative_flag overflow_flag done power_saved isolation_active}]

## ----------------------------------------------------------------------------
## 4. False Path Constraints (Mark async signals)
## ----------------------------------------------------------------------------
# Reset is asynchronous - timing doesn't matter
set_false_path -from [get_ports rst]

# Power monitoring signals are not timing-critical
set_false_path -to [get_ports power_saved]
set_false_path -to [get_ports isolation_active]

## ----------------------------------------------------------------------------
## 5. I/O Standards & Board Configuration
## ----------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports {operand_a[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {operand_b[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {alu_op[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {result[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports carry_out]
set_property IOSTANDARD LVCMOS33 [get_ports zero_flag]
set_property IOSTANDARD LVCMOS33 [get_ports negative_flag]
set_property IOSTANDARD LVCMOS33 [get_ports overflow_flag]
set_property IOSTANDARD LVCMOS33 [get_ports done]
set_property IOSTANDARD LVCMOS33 [get_ports power_saved]
set_property IOSTANDARD LVCMOS33 [get_ports isolation_active]

# Nexys Video specific configuration voltage properties
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## ----------------------------------------------------------------------------
## 6. Optional: Bitstream Configuration
## ----------------------------------------------------------------------------
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

