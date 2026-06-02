`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.02.2026 14:31:11
// Design Name: 
// Module Name: tbmac
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

module tb_booth_mac_advanced;
    // ------------------------------------------------------------------------
    // 1. SIGNAL DECLARATIONS
    // ------------------------------------------------------------------------
    reg clk, rst, start, mac_mode;
    reg [15:0] multiplicand, multiplier, accumulator;
    wire [15:0] result_lo, result_hi;
    wire done, overflow;

    // ------------------------------------------------------------------------
    // 2. UNIT UNDER TEST (UUT)
    // ------------------------------------------------------------------------
    booth_mac_16bit dut (
        .clk(clk), 
        .rst(rst), 
        .multiplicand(multiplicand), 
        .multiplier(multiplier),
        .accumulator(accumulator), 
        .start(start), 
        .mac_mode(mac_mode),
        .result_lo(result_lo), 
        .result_hi(result_hi), 
        .done(done), 
        .overflow(overflow)
    );

    // ------------------------------------------------------------------------
    // 3. CLOCK GENERATION (50MHz / 20ns Period)
    // ------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // ------------------------------------------------------------------------
    // 4. SYNCHRONIZED TIMING TASK
    // ------------------------------------------------------------------------
    task run_mac_op(input [15:0] a, input [15:0] b, input [15:0] acc, input mode);
        begin
            // Align to negative edge for setup stability
            @(negedge clk);
            multiplicand = a; 
            multiplier = b; 
            accumulator = acc; 
            mac_mode = mode;
            
            // Pulse start for exactly one full cycle to ensure 
            // the Operand Isolation gate captures the inputs.
            start = 1;
            @(negedge clk);
            start = 0;
            
            // Wait for hardware handshake (done signal)
            wait(done == 1'b1);
            repeat(2) @(posedge clk); // Observation window
        end
    endtask

    // ------------------------------------------------------------------------
    // 5. TEST STIMULUS (Specified Values)
    // ------------------------------------------------------------------------
    initial begin
        // Reset Phase: Ensure rst is low before calling tasks
        rst = 1; start = 0; mac_mode = 0;
        multiplicand = 0; multiplier = 0; accumulator = 0;
        #100;
        rst = 0; 
        #40;

        $display("--- TEST 1: BASIC MULTIPLICATION (6 * 5) ---");
        run_mac_op(16'h0006, 16'h0005, 16'h0000, 0);

        $display("--- TEST 2: HIGH VALUES (32767 * 32767) ---");
        // Result HI: 3FFF | LO: 0001
        run_mac_op(16'h7FFF, 16'h7FFF, 16'h0000, 0);

        $display("--- TEST 3: MAC TEST (32767 * 32767 + 16) ---");
        // Result HI: 3FFF | LO: 0011
        run_mac_op(16'h7FFF, 16'h7FFF, 16'h0010, 1);

        $display("--- TEST 4: CONTINUOUS ACCUMULATION ---");
        // Step A: 2 * 3 + 0 = 6
        run_mac_op(16'h0002, 16'h0003, 16'h0000, 1);
        // Step B: 4 * 5 + 6 = 26 (Hex 1A)
        run_mac_op(16'h0004, 16'h0005, result_lo, 1);

        $display("SIMULATION COMPLETE");
        #100 $finish;
    end

    // ------------------------------------------------------------------------
    // 6. INTERNAL MONITORING
    // ------------------------------------------------------------------------
    always @(posedge done) begin
        $display("--------------------------------------------------");
        $display("Time: %0t | Mode: %b | OVF: %b", $time, mac_mode, overflow);
        // Confirms if the State-Based gating is allowing data through
        $display("GATED -> Active A: %04X | Active B: %04X", dut.active_multiplicand, dut.active_multiplier);
        $display("MATH  -> Prod: %08X | MAC_Res: %09X", dut.product, dut.mac_result_comb);
        $display("OUT   -> HI: %04X | LO: %04X", result_hi, result_lo);
        $display("--------------------------------------------------");
    end

    // Power verification check: Multiplier should be zero when IDLE
    always @(posedge clk) begin
        if (dut.state == 2'b00 && dut.product != 32'd0) begin
            $display("POWER WARNING at %0t: Gate leaked data while IDLE!", $time);
        end
    end

endmodule
