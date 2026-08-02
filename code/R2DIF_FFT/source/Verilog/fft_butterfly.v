`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/15 14:12:55
// Design Name: 
// Module Name: fft_butterfly
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

module fft_butterfly (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    
    // 輸入資料 (格式：[31:16] Imag, [15:0] Real)
    input  wire [31:0] data_a_in,   // 輸入 A
    input  wire [31:0] data_b_in,   // 輸入 B
    input  wire [31:0] twiddle_in,  // 旋轉因子 W
    
    // 同步輸出資料 (Latency = 2 cycles)
    output wire [31:0] data_a_out,  // 輸出 A' = A + B
    output wire [31:0] data_b_out   // 輸出 B' = (A - B) * W
);

    // ==========================================================
    // 1. 解構輸入資料
    // ==========================================================
    wire signed [15:0] ar = data_a_in[15:0];
    wire signed [15:0] ai = data_a_in[31:16];
    wire signed [15:0] br = data_b_in[15:0];
    wire signed [15:0] bi = data_b_in[31:16];

    // ==========================================================
    // 2. 組合邏輯：計算 A + B 與 A - B (加上防溢位飽和)
    // ==========================================================
    // 加減法時寬度擴展至 17-bit 防止溢位
    wire signed [16:0] sum_r = ar + br;
    wire signed [16:0] sum_i = ai + bi;
    wire signed [16:0] diff_r = ar - br;
    wire signed [16:0] diff_i = ai - bi;

    // 飽和處理至 16-bit 有號數
    function [15:0] sat_add_sub;
        input signed [16:0] val;
        begin
            if (val[16:15] == 2'b01) begin
                sat_add_sub = 16'h7FFF; // 正溢位飽和
            end else if (val[16:15] == 2'b10) begin
                sat_add_sub = 16'h8000; // 負溢位飽和
            end else begin
                sat_add_sub = val[15:0];
            end
        end
    endfunction

    // 飽和後的加減法結果
    wire [31:0] sat_sum  = {sat_add_sub(sum_i),  sat_add_sub(sum_r)};
    wire [31:0] sat_diff = {sat_add_sub(diff_i), sat_add_sub(diff_r)};

    // ==========================================================
    // 3. A' 路徑：延遲 2 個週期 (對齊複數乘法器的延遲)
    // ==========================================================
    reg [31:0] sum_delay_1;
    reg [31:0] sum_delay_2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_delay_1 <= 32'd0;
            sum_delay_2 <= 32'd0;
        end else if (en) begin
            sum_delay_1 <= sat_sum;     // 第 1 級延遲
            sum_delay_2 <= sum_delay_1; // 第 2 級延遲
        end
    end

    assign data_a_out = sum_delay_2;

    // ==========================================================
    // 4. B' 路徑：呼叫複數乘法器計算 (A - B) * W (Latency = 2)
    // ==========================================================
    complex_mult u_mult (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (en),
        .data_in    (sat_diff),   // 輸入為 (A - B) 的飽和值
        .twiddle_in (twiddle_in), // 旋轉因子
        .data_out   (data_b_out)  // 2 週期後輸出 B'
    );

endmodule
