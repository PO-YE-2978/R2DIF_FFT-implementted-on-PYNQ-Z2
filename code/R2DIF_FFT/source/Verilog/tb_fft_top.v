`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/16 14:15:51
// Design Name: 
// Module Name: tb_fft_top
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

module tb_fft_top;

    // ==========================================================
    // 1. 訊號宣告與時脈產生
    // ==========================================================
    reg clk;
    reg rst_n;
    reg start;
    wire busy;
    wire done;

    // 連接 fft_top 與 mock_bram 的線路
    wire [31:0] bram_addr_a;
    wire [31:0] bram_wrdata_a;
    wire [31:0] bram_rddata_a;
    wire bram_en_a;
    wire [3:0]  bram_we_a;

    wire [31:0] bram_addr_b;
    wire [31:0] bram_wrdata_b;
    wire [31:0] bram_rddata_b;
    wire bram_en_b;
    wire [3:0]  bram_we_b;

    // 產生 100MHz 系統時脈 (週期 10ns)
    always #5 clk = ~clk;

    // ==========================================================
    // 2. 例化待測模組 (UUT) - FFT Top
    // ==========================================================
    fft_top uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .busy          (busy),
        .done          (done),
        
        .bram_addr_a   (bram_addr_a),
        .bram_wrdata_a (bram_wrdata_a),
        .bram_rddata_a (bram_rddata_a),
        .bram_en_a     (bram_en_a),
        .bram_we_a     (bram_we_a),
        
        .bram_addr_b   (bram_addr_b),
        .bram_wrdata_b (bram_wrdata_b),
        .bram_rddata_b (bram_rddata_b),
        .bram_en_b     (bram_en_b),
        .bram_we_b     (bram_we_b)
    );

    // ==========================================================
    // 3. 例化模擬的雙埠 BRAM (暫存器行為級模型)
    // ==========================================================
    mock_bram u_bram (
        .clk      (clk),
        .addr_a   (bram_addr_a),
        .wrdata_a (bram_wrdata_a),
        .rddata_a (bram_rddata_a),
        .en_a     (bram_en_a),
        .we_a     (bram_we_a),
        
        .addr_b   (bram_addr_b),
        .wrdata_b (bram_wrdata_b),
        .rddata_b (bram_rddata_b),
        .en_b     (bram_en_b),
        .we_b     (bram_we_b)
    );

    // ==========================================================
    // 4. 測試主流程
    // ==========================================================
    integer i;
    reg signed [15:0] out_real;
    reg signed [15:0] out_imag;

    initial begin
        // 初始化訊號
        clk = 0;
        rst_n = 0;
        start = 0;

        // 1. 系統重設
        #100;
        rst_n = 1;
        #20;

        // 2. 寫入時域測試資料：脈衝訊號 x[0] = 1.0, 其它為 0
        // 在 Q1.15 中：1.0 趨近於 16'h7FFF, 0.0 為 16'h0000
        $display("[TB] ===== 正在載入測試資料 (Impulse Input) 至 BRAM =====");
        for (i = 0; i < 64; i = i + 1) begin
            if (i == 0) begin
                u_bram.ram[i] = {16'h0000, 16'h7FFF}; // [31:16] Imag = 0, [15:0] Real = +0.9999 7FFF
            end else begin
                u_bram.ram[i] = 32'h0000_0000;         // 其餘填 0
            end
        end
        #20;

        // 3. 發送 start 訊號啟動 FFT
        $display("[TB] 發送啟動脈衝 (start = 1)...");
        start = 1;
        #10;
        start = 0;

        // 4. 等待 FSM 運算結束 (偵測 done 訊號的上升緣)
        $display("[TB] FFT 核心計算中，靜候 done 訊號...");
        @(posedge done);
        #20;

        // 5. 輸出最終結果至 Console 視窗
        $display("\n[TB] ===== FFT 計算完成！讀取 BRAM 結果 =====");
        $display("--------------------------------------------------");
        $display(" 索引 (k) |   記憶體原始資料 (HEX)   |  實部 (Real)  |  虛部 (Imag)");
        $display("--------------------------------------------------");
        for (i = 0; i < 64; i = i + 1) begin
            out_real = u_bram.ram[i][15:0];
            out_imag = u_bram.ram[i][31:16];
            $display("  %2d     |       0x%08X       |    %6d     |    %6d", i, u_bram.ram[i], out_real, out_imag);
        end
        $display("--------------------------------------------------");
        
        // 6. 簡易結果驗證
        if (u_bram.ram[0][15:0] > 16'h7F00) begin
            $display("[TB] >>> SUCCESS: FFT 運算輸出正確，脈衝頻譜分佈均勻！");
        end else begin
            $display("[TB] >>> ERROR: 輸出數值異常，請檢查管線與定址時序。");
        end

        $display("[TB] 測試結束。");
        $finish;
    end

endmodule

// ==============================================================
// 5. 行為級雙埠 BRAM 模擬模組 (1-Cycle Read Latency)
// ==============================================================
module mock_bram (
    input  wire        clk,
    input  wire [31:0] addr_a,
    input  wire [31:0] wrdata_a,
    output reg  [31:0] rddata_a,
    input  wire        en_a,
    input  wire [3:0]  we_a,
    
    input  wire [31:0] addr_b,
    input  wire [31:0] wrdata_b,
    output reg  [31:0] rddata_b,
    input  wire        en_b,
    input  wire [3:0]  we_b
);
    // 宣告 64 個 32-bit 的記憶體陣列
    reg [31:0] ram [0:63];
    
    // Port A 讀寫控制 (位址 addr_a[7:2] 用於將 32-bit Byte Address 轉回 6-bit 陣列索引)
    always @(posedge clk) begin
        if (en_a) begin
            if (we_a != 4'b0000) begin
                ram[addr_a[7:2]] <= wrdata_a;
            end
            rddata_a <= ram[addr_a[7:2]];
        end
    end
    
    // Port B 讀寫控制
    always @(posedge clk) begin
        if (en_b) begin
            if (we_b != 4'b0000) begin
                ram[addr_b[7:2]] <= wrdata_b;
            end
            rddata_b <= ram[addr_b[7:2]];
        end
    end
endmodule
