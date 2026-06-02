`timescale 1ns / 1ps

// ============================================================================
// TOP MODULE: 16-bit Booth MAC with True Iron Curtain & Pipelining
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
    localparam IDLE = 3'd0, PIPE_WAIT = 3'd1, MULTIPLY = 3'd2, ACCUMULATE = 3'd3, COMPLETE = 3'd4;
    
    reg [2:0] state, next_state;
    reg [15:0] accumulator_reg;
    wire [31:0] product;
    
    // ========================================================================
    // OPTIMIZATION 1: True "Iron Curtain" Flip-Flops for Zero Glitch Power
    // ========================================================================
    reg [15:0] active_multiplicand;
    reg [15:0] active_multiplier;
    reg        active_mac_mode;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_multiplicand <= 16'd0;
            active_multiplier   <= 16'd0;
            active_mac_mode     <= 1'b0;
        end else if (state == IDLE && start) begin
            // The gates ONLY open when a new operation officially starts!
            // Otherwise, the Booth Encoders are completely frozen.
            active_multiplicand <= multiplicand;
            active_multiplier   <= multiplier;
            active_mac_mode     <= mac_mode;
        end
    end

    // Instantiate Internal Multiplier 
    booth_16x16_mult multiplier_unit (
        .clk(clk),
        .rst(rst),
        .multiplicand(active_multiplicand), 
        .multiplier(active_multiplier),     
        .product(product)
    );
    
    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end
    
    // Next State Logic
    always @(*) begin
        case (state)
            IDLE:       next_state = start ? PIPE_WAIT : IDLE;
            PIPE_WAIT:  next_state = MULTIPLY; 
            MULTIPLY:   next_state = active_mac_mode ? ACCUMULATE : COMPLETE;
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
                
                PIPE_WAIT: begin
                    // Wait 1 cycle for Adder Tree pipeline registers
                end
                
                MULTIPLY: begin
                    if (!active_mac_mode) begin
                        result_lo <= product[15:0];
                        result_hi <= product[31:16];
                        done <= 1'b1;
                    end
                end
                
                ACCUMULATE: begin
                    // OPTIMIZATION 2: Synchronous Accumulation (Improves WNS)
                    // Uses the DSP block's internal post-adder capabilities
                    {overflow, result_hi, result_lo} <= $signed({product[31], product}) + 
                                                        $signed({{17{accumulator_reg[15]}}, accumulator_reg});
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
// INTERNAL MODULE: Pipelined Booth Multiplier Core
// ============================================================================
module booth_16x16_mult (
    input  wire        clk,   
    input  wire        rst,   
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
    
    // ========================================================================
    // OPTIMIZATION 3: Targeted DSP Directives for the Adder Tree
    // ========================================================================
    // Level 1: 8 to 4 
    (* use_dsp = "yes" *) wire [32:0] L1_sum0 = {pp0[31], pp0} + {pp1[31], pp1};
    (* use_dsp = "yes" *) wire [32:0] L1_sum1 = {pp2[31], pp2} + {pp3[31], pp3};
    (* use_dsp = "yes" *) wire [32:0] L1_sum2 = {pp4[31], pp4} + {pp5[31], pp5};
    (* use_dsp = "yes" *) wire [32:0] L1_sum3 = {pp6[31], pp6} + {pp7[31], pp7};
    
    // Level 2: Pipeline Stage
    reg [33:0] L2_sum0_reg, L2_sum1_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            L2_sum0_reg <= 34'd0;
            L2_sum1_reg <= 34'd0;
        end else begin
            L2_sum0_reg <= {L1_sum0[32], L1_sum0} + {L1_sum1[32], L1_sum1};
            L2_sum1_reg <= {L1_sum2[32], L1_sum2} + {L1_sum3[32], L1_sum3};
        end
    end
    
    // Level 3: 2 to 1 
    (* use_dsp = "yes" *) wire [34:0] final_sum = {L2_sum0_reg[33], L2_sum0_reg} + {L2_sum1_reg[33], L2_sum1_reg};
    
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
            3'b011:         pp = a << 1;
            3'b100:         pp = a_neg << 1;
            3'b101, 3'b110: pp = a_neg;
            default:        pp = 32'sd0;
        endcase
    end
endmodule