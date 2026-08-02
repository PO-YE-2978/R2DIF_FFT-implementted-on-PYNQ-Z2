`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/15 14:25:09
// Design Name: 
// Module Name: addr_generator
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

module addr_generator (
    input  wire [2:0]  stage,       // 目前 FFT 階段 (0 ~ 5)
    input  wire [4:0]  b_idx,       // 蝴蝶運算計數器 (0 ~ 31)
    
    output reg  [5:0]  addr_a,      // 輸出的 Data BRAM 位址 A
    output reg  [5:0]  addr_b,      // 輸出的 Data BRAM 位址 B
    output reg  [4:0]  twiddle_addr // 輸出的 Twiddle ROM 位址 (0 ~ 31)
);

    // ==========================================================
    // 1. 組合邏輯：根據 stage 插入 0 / 1 產生 addr_a 與 addr_b
    // ==========================================================
    always @(*) begin
        case (stage)
            3'd0: begin
                addr_a = {1'b0, b_idx[4:0]};
                addr_b = {1'b1, b_idx[4:0]};
            end
            3'd1: begin
                addr_a = {b_idx[4], 1'b0, b_idx[3:0]};
                addr_b = {b_idx[4], 1'b1, b_idx[3:0]};
            end
            3'd2: begin
                addr_a = {b_idx[4:3], 1'b0, b_idx[2:0]};
                addr_b = {b_idx[4:3], 1'b1, b_idx[2:0]};
            end
            3'd3: begin
                addr_a = {b_idx[4:2], 1'b0, b_idx[1:0]};
                addr_b = {b_idx[4:2], 1'b1, b_idx[1:0]};
            end
            3'd4: begin
                addr_a = {b_idx[4:1], 1'b0, b_idx[0]};
                addr_b = {b_idx[4:1], 1'b1, b_idx[0]};
            end
            3'd5: begin
                addr_a = {b_idx[4:0], 1'b0};
                addr_b = {b_idx[4:0], 1'b1};
            end
            default: begin
                addr_a = 6'd0;
                addr_b = 6'd0;
            end
        endcase
    end

    // ==========================================================
    // 2. 組合邏輯：根據 stage 計算旋轉因子 ROM 的位址 (k)
    // ==========================================================
    always @(*) begin
        case (stage)
            3'd0: twiddle_addr = b_idx[4:0];          // k = b_idx
            3'd1: twiddle_addr = {b_idx[3:0], 1'b0};   // k = b_idx[3:0] << 1
            3'd2: twiddle_addr = {b_idx[2:0], 2'b00};  // k = b_idx[2:0] << 2
            3'd3: twiddle_addr = {b_idx[1:0], 3'b000}; // k = b_idx[1:0] << 3
            3'd4: twiddle_addr = {b_idx[0],   4'b0000};// k = b_idx[0] << 4
            3'd5: twiddle_addr = 5'd0;                // k = 0
            default: twiddle_addr = 5'd0;
        endcase
    end

endmodule
