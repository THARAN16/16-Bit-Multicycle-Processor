`timescale 1ns / 1ps

module register_file_adaptive (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  read_addr_a,
    input  wire [2:0]  read_addr_b,
    output wire [15:0] read_data_a,
    output wire [15:0] read_data_b,
    input  wire        write_enable,
    input  wire [2:0]  write_addr,
    input  wire [15:0] write_data,
    input  wire        write_hi,
    input  wire        write_lo,
    input  wire [15:0] hi_in,
    input  wire [15:0] lo_in,
    output wire [15:0] hi_out,
    output wire [15:0] lo_out
);
    reg [15:0] registers [0:7];
    reg [15:0] HI, LO;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            registers[0] <= 16'd0;
            registers[1] <= 16'd0;
            registers[2] <= 16'd10;  // R2 = 10
            registers[3] <= 16'd5;   // R3 = 5
            registers[4] <= 16'd0;
            registers[5] <= 16'd0;
            registers[6] <= 16'd0;
            registers[7] <= 16'd0;
            HI <= 16'd0;
            LO <= 16'd0;
        end else begin
            if (write_enable) registers[write_addr] <= write_data;
            if (write_hi) HI <= hi_in;
            if (write_lo) LO <= lo_in;
        end
    end
    
    assign read_data_a = registers[read_addr_a];
    assign read_data_b = registers[read_addr_b];
    assign hi_out = HI;
    assign lo_out = LO;
endmodule