`timescale 1ns / 1ps

// --- 1. Program Counter ---
module program_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        load,
    input  wire [15:0] load_value,
    output reg  [15:0] pc
);
    always @(posedge clk or posedge rst) begin
        if (rst)         pc <= 16'd0;
        else if (load)   pc <= load_value;
        else if (enable) pc <= pc + 1;
    end
endmodule

// --- 2. Instruction Decoder ---
module instruction_decoder (
    input  wire [15:0] instruction,
    output wire [3:0]  opcode,
    output wire [2:0]  rd,
    output wire [2:0]  rs,
    output wire [2:0]  rt,
    output wire [2:0]  immediate
);
    assign opcode    = instruction[15:12];
    assign rd        = instruction[11:9];
    assign rs        = instruction[8:6];
    assign rt        = instruction[5:3];
    assign immediate = instruction[2:0];
endmodule

// --- 3. Data Memory ---
module data_memory (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [15:0] address,
    input  wire [15:0] write_data,
    output wire [15:0] read_data
);
    reg [15:0] memory [0:255];
    integer i;
    
    // FIX: Initialize data memory to 0 to clear XXXX!
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 16'd0;
        end
    end
    
    always @(posedge clk) begin
        if (write_enable) memory[address[7:0]] <= write_data;
    end
    
    assign read_data = memory[address[7:0]];
endmodule