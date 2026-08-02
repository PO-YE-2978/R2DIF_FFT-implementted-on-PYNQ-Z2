`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/16 14:05:29
// Design Name: 
// Module Name: controller_fsm
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

module controller_fsm (
    input  wire        clk,
    input  wire        rst_n,       // 低電平非同步重設
    input  wire        start,       // FFT 啟動訊號 (單脈衝或高電平)
    
    // 系統狀態輸出
    output reg         busy,        // FFT 運算中旗標
    output reg         done,        // FFT 完成單脈衝旗標 (為 PYNQ 傳送的中斷/狀態)
    
    // 傳送給 Address Generator 的指標
    output reg  [2:0]  stage,       // 當前 FFT 階段 (0 ~ 5)
    output reg  [4:0]  b_idx,       // 蝴蝶運算指標 (0 ~ 31)
    
    // 傳送給 Butterfly PE 與 Twiddle ROM 的致能訊號
    output reg         pe_en,       // PE 與 ROM 啟用控制
    
    // 傳送給 Data BRAM 的控制訊號
    output reg         bram_ena,    // Port A 致能
    output reg         bram_wea,    // Port A 寫入致能 (0:讀, 1:寫)
    output reg         bram_enb,    // Port B 致能
    output reg         bram_web     // Port B 寫入致能 (0:讀, 1:寫)
);

    // ==========================================
    // 1. FSM 狀態編碼 (One-Hot / Sequential)
    // ==========================================
    localparam S_IDLE  = 3'd0;
    localparam S_READ  = 3'd1;
    localparam S_WAIT1 = 3'd2;
    localparam S_WAIT2 = 3'd3;
    localparam S_WRITE = 3'd4;
    localparam S_DONE  = 3'd5;

    reg [2:0] current_state, next_state;

    // ==========================================
    // 2. 狀態機主時序邏輯 (State Register)
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // ==========================================
    // 3. 狀態轉移組合邏輯 (Next State Logic)
    // ==========================================
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE: begin
                if (start)
                    next_state = S_READ;
            end
            
            S_READ: begin
                next_state = S_WAIT1;
            end
            
            S_WAIT1: begin
                next_state = S_WAIT2;
            end
            
            S_WAIT2: begin
                next_state = S_WRITE;
            end
            
            S_WRITE: begin
                // 檢查當前 Stage 的 32 個蝴蝶運算是否算完
                if (b_idx == 5'd31) begin
                    // 檢查是否為最後一個 Stage (Stage 5)
                    if (stage == 3'd5)
                        next_state = S_DONE;
                    else
                        next_state = S_READ; // 進入下一 Stage 的第一個蝴蝶運算
                end else begin
                    next_state = S_READ;     // 繼續當前 Stage 的下一組蝴蝶運算
                end
            end
            
            S_DONE: begin
                next_state = S_IDLE;
            end
            
            default: next_state = S_IDLE;
        endcase
    end

    // ==========================================
    // 4. 計數器與指標更新邏輯 (Stage & b_idx)
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage <= 3'd0;
            b_idx <= 5'd0;
        end else begin
            case (current_state)
                S_IDLE: begin
                    if (start) begin
                        stage <= 3'd0;
                        b_idx <= 5'd0;
                    end
                end
                
                S_WRITE: begin
                    if (b_idx == 5'd31) begin
                        b_idx <= 5'd0;
                        if (stage != 3'd5) begin
                            stage <= stage + 3'd1;
                        end
                    end else begin
                        b_idx <= b_idx + 5'd1;
                    end
                end
            endcase
        end
    end

    // ==========================================
    // 5. 輸出控制訊號解碼邏輯 (Output Logic)
    // ==========================================
    always @(*) begin
        // 預設全部關閉，避免產生 Latch
        busy     = 1'b1;
        done     = 1'b0;
        pe_en    = 1'b0;
        bram_ena = 1'b0;
        bram_wea = 1'b0;
        bram_enb = 1'b0;
        bram_web = 1'b0;

        case (current_state)
            S_IDLE: begin
                busy = 1'b0;
            end
            
            S_READ: begin
                // 開啟 BRAM 雙埠讀取與 Twiddle ROM 讀取
                bram_ena = 1'b1;
                bram_enb = 1'b1;
                bram_wea = 1'b0;
                bram_web = 1'b0;
                pe_en    = 1'b1; // 致能 Twiddle ROM 與 PE 準備接收
            end
            
            S_WAIT1: begin
                // BRAM 讀取資料於此週期上升緣有效，PE 正在進行 Stage 1 乘法
                pe_en    = 1'b1;
            end
            
            S_WAIT2: begin
                // PE 正在進行 Stage 2 加減法與飽和處理
                pe_en    = 1'b1;
            end
            
            S_WRITE: begin
                // PE 運算完成，輸出有效！開啟 BRAM 雙埠寫回
                bram_ena = 1'b1;
                bram_enb = 1'b1;
                bram_wea = 1'b1; // 致能寫入
                bram_web = 1'b1; // 致能寫入
                pe_en    = 1'b1;
            end
            
            S_DONE: begin
                busy = 1'b0;
                done = 1'b1; // 發送一個時脈週期的完成脈衝
            end
        endcase
    end

endmodule
