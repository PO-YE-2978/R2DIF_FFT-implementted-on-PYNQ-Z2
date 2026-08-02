`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/16 14:07:43
// Design Name: 
// Module Name: fft_top
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

module fft_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,       // 啟動 FFT 運算 (高電平或單脈衝)
    output wire        busy,        // FFT 運算中旗標
    output wire        done,        // FFT 完成脈衝

    // 外部 Data BRAM 介面 - Port A (相容 Vivado BRAM Controller)
    output wire [31:0] bram_addr_a,  // 32-bit 位址線 (含 Byte 對齊)
    output wire [31:0] bram_wrdata_a,// 寫入 BRAM Port A 的資料
    input  wire [31:0] bram_rddata_a,// 從 BRAM Port A 讀出的資料
    output wire        bram_en_a,    // Port A 致能
    output wire [3:0]  bram_we_a,    // Port A 寫入致能 (4-bit Byte write enable)

    // 外部 Data BRAM 介面 - Port B (相容 Vivado BRAM Controller)
    output wire [31:0] bram_addr_b,  // 32-bit 位址線 (含 Byte 對齊)
    output wire [31:0] bram_wrdata_b,// 寫入 BRAM Port B 的資料
    input  wire [31:0] bram_rddata_b,// 從 BRAM Port B 讀出的資料
    output wire        bram_en_b,    // Port B 致能
    output wire [3:0]  bram_we_b     // Port B 寫入致能 (4-bit Byte write enable)
);

    // ==========================================================
    // 1. 內部連線訊號宣告
    // ==========================================================
    wire [2:0]  stage;
    wire [4:0]  b_idx;
    wire        pe_en;
    
    wire [5:0]  addr_a;
    wire [5:0]  addr_b;
    wire [4:0]  twiddle_addr;
    wire [31:0] twiddle_data;
    
    wire        bram_wea_ctrl;
    wire        bram_web_ctrl;

    // ==========================================================
    // 2. 外部 BRAM 訊號轉換 (Byte-addressing & Write-enable 擴展)
    // ==========================================================
    // 位址左移 2 位元，對齊 32-bit (4-byte) 邊界
    assign bram_addr_a   = {24'd0, addr_a, 2'b00};
    assign bram_addr_b   = {24'd0, addr_b, 2'b00};
    
    // 將 1-bit 的寫入控制，擴展為 BRAM 要求的 4-bit 寫入遮罩 (全寫入)
    assign bram_we_a     = {4{bram_wea_ctrl}};
    assign bram_we_b     = {4{bram_web_ctrl}};

    // ==========================================================
    // 3. 例化 Controller FSM (控制器狀態機)
    // ==========================================================
    controller_fsm u_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .busy       (busy),
        .done       (done),
        .stage      (stage),
        .b_idx      (b_idx),
        .pe_en      (pe_en),
        .bram_ena   (bram_en_a),
        .bram_wea   (bram_wea_ctrl),
        .bram_enb   (bram_en_b),
        .bram_web   (bram_web_ctrl)
    );

    // ==========================================================
    // 4. 例化 Address Generator (位址產生器)
    // ==========================================================
    addr_generator u_addr_gen (
        .stage        (stage),
        .b_idx        (b_idx),
        .addr_a       (addr_a),
        .addr_b       (addr_b),
        .twiddle_addr (twiddle_addr)
    );

    // ==========================================================
    // 5. 例化 Twiddle ROM (旋轉因子唯讀記憶體)
    // ==========================================================
    twiddle_rom u_twiddle_rom (
        .clk          (clk),
        .en           (pe_en),
        .addr         (twiddle_addr),
        .twiddle_data (twiddle_data)
    );

    // ==========================================================
    // 6. 例化 Butterfly PE (蝴蝶運算單元)
    // ==========================================================
    fft_butterfly u_pe (
        .clk         (clk),
        .rst_n       (rst_n),
        .en          (pe_en),
        .data_a_in   (bram_rddata_a), // 讀出資料 A
        .data_b_in   (bram_rddata_b), // 讀出資料 B
        .twiddle_in  (twiddle_data),  // 旋轉因子
        .data_a_out  (bram_wrdata_a), // 寫回資料 A'
        .data_b_out  (bram_wrdata_b)  // 寫回資料 B'
    );

endmodule
