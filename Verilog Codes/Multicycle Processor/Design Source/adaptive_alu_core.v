`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.02.2026 20:51:35
// Design Name: 
// Module Name: adaptive_alu_core
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
// File: adaptive_alu_core.v
// Description: 16-bit Adaptive ALU Core with Reversible Logic
// Operations: ADD, SUB, AND, OR, XOR, NOT, SHL, SHR
// Author: [Your Name]
// Date: [Date]
// ============================================================================

module adaptive_alu_core (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] operand_a_isolated,
    input  wire [15:0] operand_b_isolated,
    input  wire [3:0]  alu_op,
    input  wire        start,
    
    output reg  [15:0] result,
    output reg         carry_out,
    output reg         zero_flag,
    output reg         negative_flag,
    output reg         overflow_flag,
    output reg         done
);

    
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NOT  = 4'b0101;
    localparam OP_SHL  = 4'b0110;
    localparam OP_SHR  = 4'b0111;
    
    // ========================================
    // Arithmetic Operations
    // ========================================
    
    // Addition using reversible adder
    wire [15:0] add_sum;
    wire        add_carry;
    
    reversible_adder_16bit adder (
        .a(operand_a_isolated),
        .b(operand_b_isolated),
        .cin(1'b0),
        .sum(add_sum),
        .cout(add_carry)
    );
    
    // Subtraction using 2's complement method (A - B = A + ~B + 1)
    wire [15:0] b_inverted;
    wire [15:0] sub_diff;
    wire        sub_borrow;
    
    // Invert B using Feynman gates for 2's complement
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : invert_b
            feynman_gate inv (
                .a(1'b1),
                .b(operand_b_isolated[i]),
                .p(),  // Unused output
                .q(b_inverted[i])
            );
        end
    endgenerate
    
    // Add inverted B with carry-in = 1 (for 2's complement)
    reversible_adder_16bit subtractor (
        .a(operand_a_isolated),
        .b(b_inverted),
        .cin(1'b1),
        .sum(sub_diff),
        .cout(sub_borrow)
    );
    
    // ========================================
    // Logic Operations
    // ========================================
    
    wire [15:0] and_result;
    wire [15:0] or_result;
    wire [15:0] xor_result;
    wire [15:0] not_result;
    
    // AND operation
    reversible_logic_16bit logic_and (
        .a(operand_a_isolated),
        .b(operand_b_isolated),
        .op_select(2'b00),
        .result(and_result)
    );
    
    // OR operation
    reversible_logic_16bit logic_or (
        .a(operand_a_isolated),
        .b(operand_b_isolated),
        .op_select(2'b01),
        .result(or_result)
    );
    
    // XOR operation
    reversible_logic_16bit logic_xor (
        .a(operand_a_isolated),
        .b(operand_b_isolated),
        .op_select(2'b10),
        .result(xor_result)
    );
    
    // NOT operation (only uses operand A)
    reversible_logic_16bit logic_not (
        .a(operand_a_isolated),
        .b(16'h0000),
        .op_select(2'b11),
        .result(not_result)
    );
    
    // ========================================
    // Shift Operations
    // ========================================
    
    wire [15:0] shl_result;
    wire [15:0] shr_result;
    
    // Shift Left Logical
    assign shl_result = {operand_a_isolated[14:0], 1'b0};
    
    // Shift Right Logical
    assign shr_result = {1'b0, operand_a_isolated[15:1]};
    
    // ========================================
    // Combinational Logic for Operation Selection
    // ========================================
    
    reg [15:0] temp_result;
    reg        temp_carry;
    reg        temp_overflow;
    
    always @(*) begin
        // Default values
        temp_result = 16'h0000;
        temp_carry = 1'b0;
        temp_overflow = 1'b0;
        
        case (alu_op)
            OP_ADD: begin
                temp_result = add_sum;
                temp_carry = add_carry;
                // Overflow: same sign inputs produce different sign output
                temp_overflow = (operand_a_isolated[15] == operand_b_isolated[15]) && 
                               (add_sum[15] != operand_a_isolated[15]);
            end
            
            OP_SUB: begin
                temp_result = sub_diff;
                temp_carry = ~sub_borrow;
                // Overflow: different sign inputs produce wrong sign output
                temp_overflow = (operand_a_isolated[15] != operand_b_isolated[15]) && 
                               (sub_diff[15] != operand_a_isolated[15]);
            end
            
            OP_AND: begin
                temp_result = and_result;
                temp_carry = 1'b0;
                temp_overflow = 1'b0;
            end
            
            OP_OR: begin
                temp_result = or_result;
                temp_carry = 1'b0;
                temp_overflow = 1'b0;
            end
            
            OP_XOR: begin
                temp_result = xor_result;
                temp_carry = 1'b0;
                temp_overflow = 1'b0;
            end
            
            OP_NOT: begin
                temp_result = not_result;
                temp_carry = 1'b0;
                temp_overflow = 1'b0;
            end
            
            OP_SHL: begin
                temp_result = shl_result;
                temp_carry = operand_a_isolated[15];  // MSB shifted out
                temp_overflow = 1'b0;
            end
            
            OP_SHR: begin
                temp_result = shr_result;
                temp_carry = operand_a_isolated[0];   // LSB shifted out
                temp_overflow = 1'b0;
            end
            
            default: begin
                temp_result = 16'h0000;
                temp_carry = 1'b0;
                temp_overflow = 1'b0;
            end
        endcase
    end
    
    // ========================================
    // Sequential Logic - Register Outputs
    // ========================================
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 16'h0000;
            carry_out <= 1'b0;
            zero_flag <= 1'b0;
            negative_flag <= 1'b0;
            overflow_flag <= 1'b0;
            done <= 1'b0;
        end else if (start) begin
            // Store computed results
            result <= temp_result;
            carry_out <= temp_carry;
            overflow_flag <= temp_overflow;
            
            // Calculate status flags
            zero_flag <= (temp_result == 16'h0000);
            negative_flag <= temp_result[15];
            
            // Assert done signal
            done <= 1'b1;
        end else begin
            // Clear done when start is deasserted
            done <= 1'b0;
        end
    end

endmodule
