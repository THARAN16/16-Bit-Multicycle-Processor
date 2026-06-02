`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.02.2026 20:50:31
// Design Name: 
// Module Name: lzd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// ============================================================================
// File: lzd.v
// Description: Leading Zero Detector and Operand Isolation Logic
// Function: Detects when upper byte [15:8] is all zeros for power optimization
// Author: [Your Name]
// Date: [Date]
// ============================================================================

// ----------------------------------------------------------------------------
// Leading Zero Detector Module
// Detects if both operands have zero upper bytes [15:8]
// Outputs isolation control and power saved indicator
// ----------------------------------------------------------------------------
module lzd (
    input  wire [15:8] operand_a_high, // Only take the upper byte
    input  wire [15:8] operand_b_high,
    output wire        isolation_enable,
    output wire        power_saved
);
    assign isolation_enable = ~( (operand_a_high == 8'h00) & (operand_b_high == 8'h00) );
    assign power_saved = ~isolation_enable;
endmodule

// ----------------------------------------------------------------------------
// Operand Isolation Module
// Forces upper byte [15:8] to zero when isolation is active
// Lower byte [7:0] always passes through
// ----------------------------------------------------------------------------
module operand_isolator (
    input  wire [15:0] data_in,
    input  wire        enable,
    output wire [15:0] data_out
);
    // Lower byte [7:0] always passes through unchanged
    assign data_out[7:0] = data_in[7:0];
    
    // Upper byte [15:8] is gated by enable signal
    // When enable = 0: upper byte forced to 0 (isolated, power saved)
    // When enable = 1: upper byte passes through normally
    assign data_out[15:8] = data_in[15:8] & {8{enable}};
    
endmodule
