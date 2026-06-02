`timescale 1ns / 1ps

// ============================================================================
// TOP MODULE: 16-bit Booth MAC with Operand Isolation
// ============================================================================
module booth_mac_16bit (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] multiplicand,
    input  wire [15:0] multiplier,
    input  wire [15:0] accumulator,
    input  wire        start,
    input  wire        mac_mode,
    output reg  [15:0] result_lo,
    output reg  [15:0] result_hi,
    output reg         done,
    output reg         overflow
);
    // State Definitions
    localparam IDLE = 2'b00, MULTIPLY = 2'b01, ACCUMULATE = 2'b10, COMPLETE = 2'b11;
    
    reg [1:0] state, next_state;
    reg [15:0] accumulator_reg;
    wire [31:0] product;
    
    // ========================================================================
    // POWER OPTIMIZATION: State-Based Operand Isolation
    // ========================================================================
    wire gate_open = (state == IDLE || state == MULTIPLY || state == ACCUMULATE);
    wire [15:0] active_multiplicand = gate_open ? multiplicand : 16'd0;
    wire [15:0] active_multiplier   = gate_open ? multiplier   : 16'd0;

    // Instantiate Internal Multiplier (Defined Below)
    booth_16x16_mult multiplier_unit (
        .multiplicand(active_multiplicand), 
        .multiplier(active_multiplier),     
        .product(product)
    );
    
    // ========================================================================
    // SIGNED MATH LOGIC (33-bit for Overflow Detection)
    // ========================================================================
    wire [32:0] mac_result_comb;
    assign mac_result_comb = $signed({product[31], product}) + 
                             $signed({{17{accumulator_reg[15]}}, accumulator_reg});
    
    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end
    
    // Next State Logic
    always @(*) begin
        case (state)
            IDLE:       next_state = start ? MULTIPLY : IDLE;
            MULTIPLY:   next_state = mac_mode ? ACCUMULATE : COMPLETE;
            ACCUMULATE: next_state = COMPLETE;
            COMPLETE:   next_state = start ? COMPLETE : IDLE;
            default:    next_state = IDLE;
        endcase
    end
    
    // Output and Accumulator Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_lo <= 16'd0;
            result_hi <= 16'd0;
            done <= 1'b0;
            overflow <= 1'b0;
            accumulator_reg <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    overflow <= 1'b0;
                    if (start) accumulator_reg <= accumulator;
                end
                MULTIPLY: begin
                    if (!mac_mode) begin
                        result_lo <= product[15:0];
                        result_hi <= product[31:16];
                        done <= 1'b1;
                    end
                end
                ACCUMULATE: begin
                    result_lo <= mac_result_comb[15:0];
                    result_hi <= mac_result_comb[31:16];
                    overflow  <= (mac_result_comb[32] != mac_result_comb[31]);
                    done <= 1'b1;
                end
                COMPLETE: begin
                    if (!start) done <= 1'b0;
                end
            endcase
        end
    end
endmodule

// ============================================================================
// INTERNAL MODULE: Structural Booth Multiplier Core
// ============================================================================
module booth_16x16_mult (
    input  wire [15:0] multiplicand,
    input  wire [15:0] multiplier,
    output wire [31:0] product
);
    wire signed [31:0] a_ext = {{16{multiplicand[15]}}, multiplicand};
    wire signed [31:0] a_neg = -a_ext;
    wire [16:0] b_padded = {multiplier, 1'b0};
    
    wire signed [31:0] pp_unshifted [0:7];
    
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin : booth_enc
            booth_encoder enc (
                .a(a_ext),
                .a_neg(a_neg),
                .triplet(b_padded[g*2 +: 3]),
                .pp(pp_unshifted[g])
            );
        end
    endgenerate
    
    wire [31:0] pp0 = pp_unshifted[0];
    wire [31:0] pp1 = pp_unshifted[1] << 2;
    wire [31:0] pp2 = pp_unshifted[2] << 4;
    wire [31:0] pp3 = pp_unshifted[3] << 6;
    wire [31:0] pp4 = pp_unshifted[4] << 8;
    wire [31:0] pp5 = pp_unshifted[5] << 10;
    wire [31:0] pp6 = pp_unshifted[6] << 12;
    wire [31:0] pp7 = pp_unshifted[7] << 14;
    
    // Level 1: 8 to 4
    wire [32:0] L1_sum0 = {pp0[31], pp0} + {pp1[31], pp1};
    wire [32:0] L1_sum1 = {pp2[31], pp2} + {pp3[31], pp3};
    wire [32:0] L1_sum2 = {pp4[31], pp4} + {pp5[31], pp5};
    wire [32:0] L1_sum3 = {pp6[31], pp6} + {pp7[31], pp7};
    
    // Level 2: 4 to 2
    wire [33:0] L2_sum0 = {L1_sum0[32], L1_sum0} + {L1_sum1[32], L1_sum1};
    wire [33:0] L2_sum1 = {L1_sum2[32], L1_sum2} + {L1_sum3[32], L1_sum3};
    
    // Level 3: 2 to 1
    wire [34:0] final_sum = {L2_sum0[33], L2_sum0} + {L2_sum1[33], L2_sum1};
    
    assign product = final_sum[31:0];
endmodule

// ============================================================================
// HELPER MODULE: Booth Encoder
// ============================================================================
module booth_encoder (
    input  wire signed [31:0] a,
    input  wire signed [31:0] a_neg,
    input  wire [2:0] triplet,
    output reg  signed [31:0] pp
);
    always @(*) begin
        case (triplet)
            3'b000, 3'b111: pp = 32'sd0;
            3'b001, 3'b010: pp = a;
            3'b011:          pp = a << 1;
            3'b100:          pp = a_neg << 1;
            3'b101, 3'b110: pp = a_neg;
            default:         pp = 32'sd0;
        endcase
    end
endmodule