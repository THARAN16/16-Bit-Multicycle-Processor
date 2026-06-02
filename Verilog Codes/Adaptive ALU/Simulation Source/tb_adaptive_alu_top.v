// ============================================================================
// File: tb_small_numbers.v
// Description: Simple testbench - Only small ADD/SUB (power saved)
// ============================================================================
`timescale 1ns / 1ps

module tb_adaptive_alu_top;

    // Signals
    reg         clk;
    reg         rst;
    reg  [15:0] operand_a;
    reg  [15:0] operand_b;
    reg  [3:0]  alu_op;
    reg         start;
    
    wire [15:0] result;
    wire        done;
    wire        power_saved;
    
    // Instantiate ALU
    adaptive_alu_top uut (
        .clk(clk),
        .rst(rst),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_op(alu_op),
        .start(start),
        .result(result),
        .done(done),
        .power_saved(power_saved)
    );
    
    // Clock - 25 MHz
    initial begin
        clk = 0;
        forever #20 clk = ~clk;
    end
    
    // Test
    initial begin
        $display("========================================");
        $display("Small Numbers Test (Power Saved)");
        $display("========================================");
        
        // Reset
        rst = 1;
        start = 0;
        #100;
        rst = 0;
        #40;
        
        // TEST 1: Small ADD
        $display("\nTEST 1: ADD 18 + 52");
        operand_a = 16'h0012;  // 18
        operand_b = 16'h0034;  // 52
        alu_op = 4'b0000;      // ADD
        start = 1;
        #40;
        start = 0;
        wait(done);
        #40;
        $display("Result: 0x%04X (70)", result);
        $display("Power Saved: %b", power_saved);
        
        // TEST 2: Small SUB
        #100;
        $display("\nTEST 2: SUB 255 - 170");
        operand_a = 16'h00FF;  // 255
        operand_b = 16'h00AA;  // 170
        alu_op = 4'b0001;      // SUB
        start = 1;
        #40;
        start = 0;
        wait(done);
        #40;
        $display("Result: 0x%04X (85)", result);
        $display("Power Saved: %b", power_saved);
        
        // TEST 3: Small ADD
        #100;
        $display("\nTEST 3: ADD 100 + 50");
        operand_a = 16'h0064;  // 100
        operand_b = 16'h0032;  // 50
        alu_op = 4'b0000;      // ADD
        start = 1;
        #40;
        start = 0;
        wait(done);
        #40;
        $display("Result: 0x%04X (150)", result);
        $display("Power Saved: %b", power_saved);
        
        // TEST 4: Small SUB
        #100;
        $display("\nTEST 4: SUB 200 - 100");
        operand_a = 16'h00C8;  // 200
        operand_b = 16'h0064;  // 100
        alu_op = 4'b0001;      // SUB
        start = 1;
        #40;
        start = 0;
        wait(done);
        #40;
        $display("Result: 0x%04X (100)", result);
        $display("Power Saved: %b", power_saved);
        
        #200;
        $display("\n========================================");
        $display("All Tests Complete!");
        $display("All operations should show Power Saved = 1");
        $display("========================================");
        $finish;
    end
   

endmodule
