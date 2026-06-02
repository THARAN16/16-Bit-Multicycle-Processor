## ============================================================================
## PROPOSED ADAPTIVE RISC PROCESSOR TIMING CONSTRAINTS 
## Target Board: Artix-7 Nexys Video
## Frequency: 50 MHz (20ns period) 
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
## 2. Input Delays 
## ----------------------------------------------------------------------------
# Reset input
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports rst]
set_input_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports rst]

## ----------------------------------------------------------------------------
## 3. Output Delays (ALL PROCESSOR OUTPUTS)
## ----------------------------------------------------------------------------
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.000 [get_ports {halt alu_power_saved alu_isolation_active debug_pc[*] debug_state[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min 1.000 [get_ports {halt alu_power_saved alu_isolation_active debug_pc[*] debug_state[*]}]

## ----------------------------------------------------------------------------
## 4. False Path Constraints
## ----------------------------------------------------------------------------
# Reset is asynchronous - timing doesn't matter for the physical button press
set_false_path -from [get_ports rst]

## ----------------------------------------------------------------------------
## 5. I/O Standards & Board Configuration
## ----------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports halt]
set_property IOSTANDARD LVCMOS33 [get_ports alu_power_saved]
set_property IOSTANDARD LVCMOS33 [get_ports alu_isolation_active]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_pc[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug_state[*]}]

# Nexys Video specific configuration voltage properties
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## ----------------------------------------------------------------------------
## 6. Optional: Bitstream Configuration
## ----------------------------------------------------------------------------
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]