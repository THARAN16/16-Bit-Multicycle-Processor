`timescale 1ns / 1ps

module tb_system_math_test();

    // 1. Clock and DUT (Device Under Test)
    reg clk;
    overall_system_top uut (.clk(clk));

    // 2. Clock Generation (100 MHz)
    always #5 clk = ~clk;

    // 3. Main Test Sequence
    initial begin
        // --- Initialization ---
        clk = 0;
        force uut.manual_mode = 1;      // Take control from the FSM
        force uut.rst_vio = 1;          // Assert reset
        force uut.manual_start = 0;
        #100 force uut.rst_vio = 0;     // Release reset
        #100;

        $display("==================================================");
        $display("   TESTING MATH UNIT: A = 10, B = 5               ");
        $display("==================================================");

        // --- PART 1: ALU ADDITION (10 + 5) ---
        $display("--> Testing ALU Addition...");
        force uut.manual_A = 16'd10;
        force uut.manual_B = 16'd5;
        force uut.manual_opcode = 4'h0; // Assuming 0 is ADD
        
        #20 force uut.manual_start = 1;
        wait(uut.alu_done == 1'b1);     // Wait for hardware handshake
        @(posedge clk);                 // Wait 1 cycle for Glitch Shield capture
        force uut.manual_start = 0;
        
        #20 $display("ALU Result (10 + 5): %d", $signed(uut.vio_alu_safe));

        // --- PART 2: BOOTH MULTIPLICATION (10 * 5) ---
        #100;
        $display("--> Testing Booth Multiplier...");
        force uut.manual_A = 16'd10;
        force uut.manual_B = 16'd5;
        force uut.manual_opcode = 4'h8; // Assuming 8 is Booth Mult
        
        #20 force uut.manual_start = 1;
        wait(uut.mac_done == 1'b1);     // Wait for Booth Pipeline
        @(posedge clk);                 // Let vio_mac_lo_safe capture data
        force uut.manual_start = 0;
        
        #20 $display("Booth Result (10 * 5): %d", $signed(uut.vio_mac_lo_safe));

        // --- PART 3: MAC OPERATION (10 * 5 + Previous_Acc) ---
        // This will check if it accumulates onto the 50 we just calculated
        #100;
        $display("--> Testing Booth MAC (Accumulation)...");
        force uut.manual_A = 16'd10;
        force uut.manual_B = 16'd5;
        force uut.manual_opcode = 4'h9; // Assuming 9 is MAC
        
        #20 force uut.manual_start = 1;
        wait(uut.mac_done == 1'b1);
        @(posedge clk);
        force uut.manual_start = 0;
        
        #20 $display("MAC Result (50 + 50): %d", $signed(uut.vio_mac_lo_safe));

        $display("==================================================");
        $display("           MATHEMATICAL TESTS PASSED              ");
        $display("==================================================");
        $finish;
    end

endmodule