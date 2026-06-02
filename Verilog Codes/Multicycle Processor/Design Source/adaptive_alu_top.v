`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.02.2026 20:52:36
// Design Name: 
// Module Name: adaptive_alu_top
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
// File: adaptive_alu_top.v
// Description: Top-level wrapper for 16-bit Adaptive ALU
// Integrates: LZD + Operand Isolation + Reversible ALU Core
// This is the main module to instantiate in your processor design
// Author: [Your Name]
// Date: [Date]
// ============================================================================

module adaptive_alu_top (
    // Clock and Reset
    input  wire        clk,
    input  wire        rst,
    
    // Input Operands
    input  wire [15:0] operand_a,
    input  wire [15:0] operand_b,
    
    // Operation Control
    input  wire [3:0]  alu_op,
    input  wire        start,
    
    // Results
    output wire [15:0] result,
    output wire        carry_out,
    output wire        zero_flag,
    output wire        negative_flag,
    output wire        overflow_flag,
    output wire        done,
    
    // Power Optimization Status
    output wire        power_saved,
    output wire        isolation_active
);

    // ========================================
    // Internal Signals
    // ========================================
    wire        isolation_enable;
    wire [15:0] operand_a_isolated;
    wire [15:0] operand_b_isolated;
    
    // ========================================
    // Step 1: Leading Zero Detection
    // ========================================
    
   lzd leading_zero_detector (
        .operand_a_high(operand_a[15:8]),
        .operand_b_high(operand_b[15:8]),
        .isolation_enable(isolation_enable),
        .power_saved(power_saved)
    );
    
    // isolation_active is inverse of isolation_enable
    // When isolation_enable = 0, isolation is active (power saved)
    assign isolation_active = ~isolation_enable;
    
    // ========================================
    // Step 2: Operand Isolation
    // ========================================
    
    operand_isolator isolator_a (
        .data_in(operand_a),
        .enable(isolation_enable),
        .data_out(operand_a_isolated)
    );
    
    operand_isolator isolator_b (
        .data_in(operand_b),
        .enable(isolation_enable),
        .data_out(operand_b_isolated)
    );
    
    // ========================================
    // Step 3: Adaptive ALU Core (Reversible Logic)
    // ========================================
    
    adaptive_alu_core alu_core (
        .clk(clk),
        .rst(rst),
        .operand_a_isolated(operand_a_isolated),
        .operand_b_isolated(operand_b_isolated),
        .alu_op(alu_op),
        .start(start),
        .result(result),
        .carry_out(carry_out),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag),
        .done(done)
    );

endmodule
