`timescale 1ns / 1ps

module tb_booth_mac_16bit();

    // 1. Signals
    reg         clk;
    reg         rst;
    reg  [15:0] multiplicand;
    reg  [15:0] multiplier;
    reg  [15:0] accumulator;
    reg         start;
    reg         mac_mode;
    
    wire [15:0] result_lo;
    wire [15:0] result_hi;
    wire        done;
    wire        overflow;

    // Combine HI and LO for easy viewing in the console
    wire [31:0] full_result = {result_hi, result_lo};

    // 2. Instantiate the Unit Under Test (UUT)
    booth_mac_16bit uut (
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

    // 3. Clock Generation (100 MHz)
    always #5 clk = ~clk;

    // 4. Reusable Task for executing a Math Operation
    task run_math;
        input [15:0] a;
        input [15:0] b;
        input [15:0] acc;
        input        mode; // 0 = Mult, 1 = MAC
        begin
            // Set inputs
            multiplicand = a;
            multiplier   = b;
            accumulator  = acc;
            mac_mode     = mode;
            
            // Trigger the module
            @(posedge clk);
            start = 1;
            
            // Wait for the module to finish computing
            wait(done == 1'b1);
            
            // Print the result to the TCL Console
            if (mode == 0)
                $display("MULT: %0d * %0d = %0d", $signed(a), $signed(b), $signed(full_result));
            else
                $display("MAC:  %0d * %0d + %0d = %0d", $signed(a), $signed(b), $signed(acc), $signed(full_result));
            
            // Drop start and wait a cycle before the next test
            @(posedge clk);
            start = 0;
            @(posedge clk);
        end
    endtask

    // 5. Test Sequence
    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        multiplicand = 0;
        multiplier = 0;
        accumulator = 0;
        start = 0;
        mac_mode = 0;

        // Apply Reset
        #20;
        rst = 0;
        #20;
        
        $display("============================================");
        $display("   STARTING BOOTH MAC PIPELINE SIMULATION   ");
        $display("============================================");

        // Test 1: Simple Positive Multiplication (10 * 5 = 50)
        run_math(16'd10, 16'd5, 16'd0, 0);

        // Test 2: Positive * Negative Multiplication (12 * -4 = -48)
        run_math(16'd12, -16'd4, 16'd0, 0);

        // Test 3: Negative * Negative Multiplication (-7 * -8 = 56)
        run_math(-16'd7, -16'd8, 16'd0, 0);

        // Test 4: MAC Operation (10 * 10 + 150 = 250)
        run_math(16'd10, 16'd10, 16'd150, 1);

        // Test 5: MAC with negative accumulator (20 * 3 + (-100) = -40)
        run_math(16'd20, 16'd3, -16'd100, 1);
        
        // Test 6: Zero Power Isolation Check (Inputs change, but start is 0)
        // You can check the waveform here to ensure the internal Booth 
        // Encoders do not toggle when 'start' is low!
        @(posedge clk);
        multiplicand = 16'hFFFF;
        multiplier = 16'hAAAA;
        #30;

        $display("============================================");
        $display("               TESTS COMPLETE               ");
        $display("============================================");
        $finish;
    end

endmodule