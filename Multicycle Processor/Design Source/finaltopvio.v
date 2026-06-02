`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 19:13:25
// Design Name: 
// Module Name: finaltopvio
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

module overall_system_top (
    input  wire       clk,       // Physical R4 pin (Nexys Video)
    input  wire       btn_rst,   // Physical Center Button (BTNC)
    output wire [2:0] led_fsm    // Physical LEDs for FSM State
);

    // --- VIO Control Wires ---
    wire rst_vio, manual_mode, manual_start, manual_clk; 
    wire [3:0] manual_opcode;
    wire [15:0] manual_A, manual_B;

    // --- Internal Data Path Wires ---
    wire [15:0] pc_out, instruction, reg_data_a, reg_data_b;
    wire [15:0] alu_result, mac_lo, mac_hi, mem_out;
    wire [3:0] dec_opcode;
    wire [2:0] rs_addr, rt_addr, rd_addr, imm_val;

    // --- FSM Control Wires ---
    wire [2:0] fsm_state;
    wire pc_enable, ir_enable, reg_write_en, alu_start, mac_start, mac_mode_fsm;
    wire mem_read_en, mem_write_en, halt_fsm;
    wire alu_done, mac_done;

    // ============================================================================
    // PHYSICAL BOARD INTEGRATION
    // ============================================================================
    // Reset triggers if VIO reset is clicked OR physical button is pressed
    wire global_rst = rst_vio | btn_rst; 
    
    // Wire the FSM state directly to the Nexys Video LEDs
    assign led_fsm = fsm_state;

    // The Clock MUX: Core uses VIO manual clock in manual mode, else 50MHz
    // ============================================================================
    // THE CLOCK MUX (Hardware-Optimized BUFGMUX)
    // ============================================================================
    // Forces the clock switch onto the dedicated, low-skew FPGA clock routing network.
    wire core_clk;
   
    BUFGMUX #(
    ) core_clock_mux_inst (
        .O(core_clk),     // Multiplexed clock output
        .I0(clk),         // Clock input 0 (when S=0, use 50MHz board clock)
        .I1(manual_clk),  // Clock input 1 (when S=1, use manual VIO clock)
        .S(manual_mode)   // Clock Select signal
    );
    // ============================================================================
    // OPTIMIZATION 1: VIO Glitch Shielding
    // ============================================================================
    reg [15:0] vio_alu_safe, vio_mac_hi_safe, vio_mac_lo_safe;
    
    // Notice this uses the physical 'clk' so the VIO screen updates instantly!
    always @(posedge clk or posedge global_rst) begin 
        if (global_rst) begin
            vio_alu_safe <= 0; vio_mac_hi_safe <= 0; vio_mac_lo_safe <= 0;
        end else begin
            if (alu_done) vio_alu_safe <= alu_result;
            if (mac_done) begin
                vio_mac_hi_safe <= mac_hi;
                vio_mac_lo_safe <= mac_lo;
            end
        end
    end

    // ============================================================================
    // OPTIMIZATION 2: Hard-Zero Input Gating
    // ============================================================================
    wire [15:0] gated_a = (alu_start || mac_start) ? (manual_mode ? manual_A : reg_data_a) : 16'h0000;
    wire [15:0] gated_b = (alu_start || mac_start) ? (manual_mode ? manual_B : reg_data_b) : 16'h0000;

    // ============================================================================
    // MODULE INSTANTIATIONS
    // ============================================================================

    // VIO MUST stay on the physical 'clk' to communicate with Vivado via USB!
    vio_0 your_vio_inst (
        .clk(clk),
        .probe_in0(vio_alu_safe), .probe_in1(vio_mac_hi_safe), .probe_in2(vio_mac_lo_safe), 
        .probe_in3(reg_data_a),   .probe_in4(reg_data_b),      .probe_in5(mem_out),
        
        .probe_out0(rst_vio),  .probe_out1(manual_mode), .probe_out2(manual_opcode), 
        .probe_out3(manual_A), .probe_out4(manual_B),    .probe_out5(manual_start),
        .probe_out6(manual_clk) // Your magic manual clock button
    );

    program_counter pc_inst (
        .clk(core_clk), .rst(global_rst), .enable(manual_mode ? 1'b0 : pc_enable), 
        .load(1'b0), .load_value(16'd0), .pc(pc_out) 
    );

    instruction_memory_adaptive imem (.address(pc_out), .instruction(instruction));

    instruction_decoder dec_inst (
        .instruction(instruction), .opcode(dec_opcode),
        .rd(rd_addr), .rs(rs_addr), .rt(rt_addr), .immediate(imm_val)
    );

    control_fsm_adaptive fsm_inst (
        .clk(core_clk), .rst(global_rst), .opcode(dec_opcode), 
        .alu_done(alu_done), .mac_done(mac_done), .state(fsm_state), 
        .pc_enable(pc_enable), .ir_enable(ir_enable), .reg_write(reg_write_en), 
        .alu_start(alu_start), .mac_start(mac_start), .mac_mode(mac_mode_fsm), 
        .mem_read(mem_read_en), .mem_write(mem_write_en), .halt(halt_fsm)
    );

    register_file_adaptive regfile (
        .clk(core_clk), .rst(global_rst), .read_addr_a(rs_addr), .read_addr_b(rt_addr),
        .read_data_a(reg_data_a), .read_data_b(reg_data_b),
        .write_enable(reg_write_en), .write_addr(rd_addr), .write_data(alu_result),
        .write_hi(1'b0), .write_lo(1'b0), .hi_in(mac_hi), .lo_in(mac_lo), .hi_out(), .lo_out()
    );

    adaptive_alu_top your_alu_inst (
        .clk(core_clk), .rst(global_rst), .operand_a(gated_a), .operand_b(gated_b),
        .alu_op(manual_mode ? manual_opcode : dec_opcode),
        .start(manual_mode ? (manual_start && manual_opcode < 8) : alu_start),
        .result(alu_result), .done(alu_done),
        .carry_out(), .zero_flag(), .negative_flag(), .overflow_flag(), 
        .power_saved(), .isolation_active()
    );

    booth_mac_16bit your_mac_inst (
        .clk(core_clk), .rst(global_rst), .multiplicand(gated_a), .multiplier(gated_b),
        .accumulator(mac_lo),
        .start(manual_mode ? (manual_start && manual_opcode >= 8) : mac_start),
        .mac_mode(manual_mode ? manual_opcode[0] : mac_mode_fsm), 
        .result_lo(mac_lo), .result_hi(mac_hi), .done(mac_done), .overflow() 
    );

    data_memory dmem (
        .clk(core_clk), .write_enable(mem_write_en), 
        .address(alu_result), .write_data(reg_data_b), .read_data(mem_out)
    );

endmodule
