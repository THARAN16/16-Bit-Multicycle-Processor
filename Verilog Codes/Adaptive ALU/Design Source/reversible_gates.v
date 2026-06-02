`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.02.2026 20:49:15
// Design Name: 
// Module Name: reversible_gates
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

module feynman_gate (
    input  wire a,
    input  wire b,
    output wire p,
    output wire q
);
    assign p = a;
    assign q = a ^ b;
endmodule

module toffoli_gate (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire p,
    output wire q,
    output wire r
);
    assign p = a;
    assign q = b;
    assign r = c ^ (a & b);
endmodule


module peres_gate (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire p,
    output wire q,
    output wire r
);
    assign p = a;
    assign q = a ^ b;
    assign r = (a & b) ^ c;
endmodule

// ----------------------------------------------------------------------------
// Fredkin Gate (CSWAP)
// Quantum Cost: 5
// Function: P = A, Q = if(A) then C else B, R = if(A) then B else C
// ----------------------------------------------------------------------------
module fredkin_gate (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire p,
    output wire q,
    output wire r
);
    assign p = a;
    assign q = (~a & b) | (a & c);
    assign r = (a & b) | (~a & c);
endmodule


module reversible_full_adder_1bit (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    // Internal wires
    wire p1, q1, r1;
    wire p2, q2, r2;
    
    
    peres_gate pg1 (
        .a(a),
        .b(b),
        .c(1'b0),
        .p(p1),      // Garbage: A
        .q(q1),      // A XOR B
        .r(r1)       // A AND B
    );
    
    // Second Peres gate: generates SUM and COUT
    peres_gate pg2 (
        .a(q1),      // A XOR B
        .b(cin),
        .c(r1),      // A AND B
        .p(p2),      // Garbage: A XOR B
        .q(q2),      // SUM = (A XOR B) XOR Cin
        .r(r2)       // COUT = (A.B) XOR ((A XOR B).Cin)
    );
    
    assign sum = q2;
    assign cout = r2;
    
endmodule

// ----------------------------------------------------------------------------
// 16-bit Reversible Ripple Carry Adder
// Total Quantum Cost: 128 (16 adders × 8)
// Function: Performs 16-bit addition using reversible full adders
// ----------------------------------------------------------------------------
module reversible_adder_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout
);
    // Carry chain
    wire [16:0] carry;
    
    assign carry[0] = cin;
    
    // Instantiate 16 reversible full adders
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : adder_array
            reversible_full_adder_1bit rfa (
                .a(a[i]),
                .b(b[i]),
                .cin(carry[i]),
                .sum(sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate
    
    assign cout = carry[16];
    
endmodule


module reversible_logic_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [1:0]  op_select,  // 00=AND, 01=OR, 10=XOR, 11=NOT
    output reg  [15:0] result
);
    // Internal result wires for each operation
    wire [15:0] and_out;
    wire [15:0] or_out;
    wire [15:0] xor_out;
    wire [15:0] not_out;
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : logic_array
            
            // AND operation using Toffoli gate (c=0)
            wire toff_p, toff_q, toff_r;
            toffoli_gate toff_and (
                .a(a[i]),
                .b(b[i]),
                .c(1'b0),
                .p(toff_p),
                .q(toff_q),
                .r(toff_r)    // Result: A AND B
            );
            assign and_out[i] = toff_r;
            
            // XOR operation using Feynman gate
            wire feyn_p, feyn_q;
            feynman_gate feyn_xor (
                .a(a[i]),
                .b(b[i]),
                .p(feyn_p),
                .q(feyn_q)    // Result: A XOR B
            );
            assign xor_out[i] = feyn_q;
            
            // NOT operation using Feynman gate (a=1)
            wire not_p, not_q;
            feynman_gate feyn_not (
                .a(1'b1),
                .b(a[i]),
                .p(not_p),
                .q(not_q)     // Result: NOT A
            );
            assign not_out[i] = not_q;
            
            // OR operation using DeMorgan's Law: A OR B = NOT(NOT(A) AND NOT(B))
            assign or_out[i] = ~(~a[i] & ~b[i]);
            
        end
    endgenerate
    
    // Multiplexer to select operation
    always @(*) begin
        case (op_select)
            2'b00:   result = and_out;
            2'b01:   result = or_out;
            2'b10:   result = xor_out;
            2'b11:   result = not_out;
            default: result = 16'h0000;
        endcase
    end
    
endmodule
