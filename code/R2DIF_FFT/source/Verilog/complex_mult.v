`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/15 14:07:02
// Design Name: 
// Module Name: complex_mult
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


module complex_mult(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    
    // 將輸入與輸出打包成 32-bit (高 16 位虛部, 低 16 位實部)
    input  wire [31:0] data_in,     // Data A (A_r, A_i)
    input  wire [31:0] twiddle_in,  // Twiddle W (W_r, W_i)
    output reg  [31:0] data_out     // Output P (P_r, P_i)
);

    // 1. 解構輸入
    wire signed [15:0] br = data_in[15:0];
    wire signed [15:0] bi = data_in[31:16];
    wire signed [15:0] wr = twiddle_in[15:0];
    wire signed [15:0] wi = twiddle_in[31:16];

    // 2. Stage 1: 乘法器暫存器 (有助於時序收斂，自動推論 DSP48)
    reg signed [31:0] t1, t2, t3, t4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t1 <= 32'd0; t2 <= 32'd0; t3 <= 32'd0; t4 <= 32'd0;
        end else if (en) begin
            t1 <= br * wr;
            t2 <= bi * wi;
            t3 <= br * wi;
            t4 <= bi * wr;
        end
    end

    // 3. Stage 2: 加減法與右移 15 位 (手動做簡易飽和)
    wire signed [32:0] pr_full = t1 - t2;
    wire signed [32:0] pi_full = t3 + t4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'd0;
        end else if (en) begin
            // 實部簡易防正溢位 (檢查是否大於等於 +1.0)
            if (pr_full >= 33'sh000008000) 
                data_out[15:0] <= 16'h7FFF;
            else 
                data_out[15:0] <= pr_full[30:15];

            // 虛部簡易防正溢位
            if (pi_full >= 33'sh000008000) 
                data_out[31:16] <= 16'h7FFF;
            else 
                data_out[31:16] <= pi_full[30:15];
        end
    end

endmodule
