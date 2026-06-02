`timescale 1ns / 1ps

module risc_processor_adaptive_top (
    input  wire clk,
    input  wire rst,
    output wire halt,
    
    // Power monitoring outputs
    output wire alu_power_saved,
    output wire alu_isolation_active,
    output wire [15:0] debug_pc,
    output wire [2:0]  debug_state
);

    // Internal Wires
    wire [15:0] pc_wire, instruction_out, mem_read_data;
    wire [15:0] operand_a, operand_b, alu_result, mac_lo, mac_hi, hi_out, lo_out;
    wire [3:0]  opcode;
    wire [2:0]  rd, rs, rt, imm, state;
    reg  [15:0] ir_reg;

    // FSM Control Wires
    wire pc_enable, ir_enable, reg_write, mem_read, mem_write;
    wire alu_start, alu_done, alu_carry, alu_zero, alu_neg, alu_ovf;
    wire mac_start, mac_mode, mac_done, mac_ovf;

    assign debug_pc = pc_wire;
    assign debug_state = state;

    // --- 1. Program Counter ---
    program_counter pc_inst (
        .clk(clk), .rst(rst), .enable(pc_enable),
        .load(1'b0), .load_value(16'd0), .pc(pc_wire)
    );

    // --- 2. Instruction Memory & Latch ---
    instruction_memory_adaptive imem (.address(pc_wire), .instruction(instruction_out));
    
    always @(posedge clk) begin
        if (ir_enable) ir_reg <= instruction_out;
    end

    // --- 3. Instruction Decoder ---
    instruction_decoder decode_inst (
        .instruction(ir_reg), .opcode(opcode),
        .rd(rd), .rs(rs), .rt(rt), .immediate(imm)
    );

    // --- 4. Control FSM ---
    control_fsm_adaptive fsm_inst (
        .clk(clk), .rst(rst), .opcode(opcode),
        .alu_done(alu_done), .mac_done(mac_done),
        .state(state), .pc_enable(pc_enable), .ir_enable(ir_enable),
        .reg_write(reg_write), .alu_start(alu_start), .mac_start(mac_start),
        .mac_mode(mac_mode), .mem_read(mem_read), .mem_write(mem_write), .halt(halt)
    );

    // --- 5. Register File ---
    wire is_mac_op = (opcode == 4'h8 || opcode == 4'h9);
    wire [15:0] reg_write_data = (opcode == 4'hA) ? mem_read_data : alu_result;

    register_file_adaptive regfile (
        .clk(clk), .rst(rst),
        .read_addr_a(rs), .read_addr_b(rt),
        .read_data_a(operand_a), .read_data_b(operand_b),
        .write_enable(reg_write && !is_mac_op),
        .write_addr(rd), .write_data(reg_write_data),
        .write_hi(is_mac_op && mac_done),
        .write_lo(is_mac_op && mac_done),
        .hi_in(mac_hi), .lo_in(mac_lo),
        .hi_out(hi_out), .lo_out(lo_out)
    );

    // --- 6. Adaptive Reversible ALU ---
    // Translate processor opcode (0-7) to ALU opcode (0-7). They map 1:1 in your design!
    wire [3:0] translated_alu_op = opcode; 

    adaptive_alu_top alu (
        .clk(clk), .rst(rst),
        .operand_a(operand_a), .operand_b(operand_b),
        .alu_op(translated_alu_op), .start(alu_start),
        .result(alu_result), .carry_out(alu_carry),
        .zero_flag(alu_zero), .negative_flag(alu_neg),
        .overflow_flag(alu_ovf), .done(alu_done),
        .power_saved(alu_power_saved), .isolation_active(alu_isolation_active)
    );

    // --- 7. Booth MAC ---
    booth_mac_16bit mac (
        .clk(clk), .rst(rst),
        .multiplicand(operand_a), .multiplier(operand_b),
        .accumulator(lo_out), .start(mac_start), .mac_mode(mac_mode),
        .result_lo(mac_lo), .result_hi(mac_hi),
        .done(mac_done), .overflow(mac_ovf)
    );

    // --- 8. Data Memory ---
    data_memory dmem (
        .clk(clk), .write_enable(mem_write),
        .address(operand_b), .write_data(operand_a),
        .read_data(mem_read_data)
    );

endmodule