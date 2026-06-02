`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2026 21:48:27
// Design Name: 
// Module Name: controlfsm
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


`timescale 1ns / 1ps

module control_fsm_adaptive (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] opcode,
    input  wire       alu_done,
    input  wire       mac_done,
    
    output reg [2:0]  state,
    output reg        pc_enable,
    output reg        ir_enable,
    output reg        reg_write,
    output reg        alu_start,
    output reg        mac_start,
    output reg        mac_mode,
    output reg        mem_read,
    output reg        mem_write,
    output reg        halt
);

    localparam FETCH = 3'd0, DECODE = 3'd1, EXECUTE = 3'd2, WRITEBACK = 3'd3, HALT_ST = 3'd4;
    reg [2:0] next_state;

    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= FETCH;
        else     state <= next_state;
    end

    // Next State & Output Logic
    always @(*) begin
        // Default Outputs
        pc_enable = 0; ir_enable = 0; reg_write = 0; 
        alu_start = 0; mac_start = 0; mac_mode = 0;
        mem_read = 0; mem_write = 0; halt = 0;
        next_state = state;

        case (state)
            FETCH: begin
                ir_enable = 1;
                pc_enable = 1; // Increment PC
                next_state = DECODE;
            end
            
            DECODE: begin
                if (opcode == 4'hF) next_state = HALT_ST;
                else                next_state = EXECUTE;
            end
            
            EXECUTE: begin
                if (opcode <= 4'h7) begin
                    alu_start = 1; // Trigger Adaptive ALU
                    if (alu_done) next_state = WRITEBACK;
                end 
                else if (opcode == 4'h8 || opcode == 4'h9) begin
                    mac_start = 1; // Trigger Booth MAC
                    mac_mode = (opcode == 4'h9); // 0=MULT, 1=MAC
                    if (mac_done) next_state = WRITEBACK;
                end
                else if (opcode == 4'hA) begin // LOAD
                    mem_read = 1;
                    next_state = WRITEBACK;
                end
                else if (opcode == 4'hB) begin // STORE
                    mem_write = 1;
                    next_state = FETCH;
                end
            end
            
            WRITEBACK: begin
                if (opcode <= 4'hA) reg_write = 1;
                next_state = FETCH;
            end
            
            HALT_ST: begin
                halt = 1;
                next_state = HALT_ST;
            end
        endcase
    end
endmodule
