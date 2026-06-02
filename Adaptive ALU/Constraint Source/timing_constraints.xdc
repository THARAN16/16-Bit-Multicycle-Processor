## ----------------------------------------------------------------------------
## 1. Clock Definition
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN Y9      [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

create_clock -period 15.000 -name sys_clk_pin -waveform {0.000 7.500} [get_ports clk]

## ----------------------------------------------------------------------------
## 2. Input Timing Constraints
## ----------------------------------------------------------------------------
set_input_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {operand_a[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports {operand_a[*]}]

set_input_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {operand_b[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports {operand_b[*]}]

set_input_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {alu_op[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports {alu_op[*]}]

set_input_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports start]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports start]

set_input_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports rst]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports rst]

## ----------------------------------------------------------------------------
## 3. Output Timing Constraints - Data
## ----------------------------------------------------------------------------
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {result[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports {result[*]}]

set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports done]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports done]

## ----------------------------------------------------------------------------
## 4. Output Timing Constraints - Flags (Fixes TIMING #1, #2, #3, #4)
## ----------------------------------------------------------------------------
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports carry_out]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports carry_out]

set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports negative_flag]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports negative_flag]

set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports overflow_flag]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports overflow_flag]

set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports zero_flag]
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports zero_flag]

## ----------------------------------------------------------------------------
## 5. Load Estimation
## ----------------------------------------------------------------------------
set_load -pin_load 10.0 [get_ports {result[*]}]
set_load -pin_load 10.0 [get_ports carry_out]
set_load -pin_load 10.0 [get_ports negative_flag]
set_load -pin_load 10.0 [get_ports overflow_flag]
set_load -pin_load 10.0 [get_ports zero_flag]
set_load -pin_load 10.0 [get_ports done]