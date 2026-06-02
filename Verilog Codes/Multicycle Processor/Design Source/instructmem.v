`timescale 1ns / 1ps

module instruction_memory_adaptive (
    input  wire [15:0] address,
    output wire [15:0] instruction
);
    reg [15:0] memory [0:255];
    integer i;
    
    initial begin
        for (i = 0; i < 256; i = i + 1) memory[i] = 16'd0;
        
        // FORMAT: [15:12] Opcode | [11:9] Rd | [8:6] Rs | [5:3] Rt | [2:0] Imm
        memory[0]  = 16'b0000_001_010_011_000; // ADD R1, R2, R3 -> R1 = 15
        memory[1]  = 16'b0001_100_010_011_000; // SUB R4, R2, R3 -> R4 = 5
        memory[2]  = 16'b0010_101_010_011_000; // AND R5, R2, R3 -> R5 = 0
        memory[3]  = 16'b0011_110_010_011_000; // OR  R6, R2, R3 -> R6 = 15
        memory[4]  = 16'b0100_111_010_011_000; // XOR R7, R2, R3 -> R7 = 15
        memory[5]  = 16'b0110_001_010_000_000; // SHL R1, R2     -> R1 = 20
        memory[6]  = 16'b0111_100_010_000_000; // SHR R4, R2     -> R4 = 5
        memory[7]  = 16'b1000_000_010_011_000; // MULT --, R2, R3 -> LO = 50
        memory[8]  = 16'b1001_000_010_011_000; // MAC --, R2, R3  -> LO = 100
        memory[9]  = 16'b1111_000_000_000_000; // HALT
    end
    
    assign instruction = memory[address[7:0]];
endmodule