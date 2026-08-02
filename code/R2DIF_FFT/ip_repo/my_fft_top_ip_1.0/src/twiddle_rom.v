`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/15 13:48:53
// Design Name: 
// Module Name: twiddle_rom
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

module twiddle_rom (
    input  wire        clk,
    input  wire        en,          // ROM 讀取啟用訊號
    input  wire [4:0]  addr,        // 5-bit 位址線 (對應 0 ~ 31 的旋轉因子)
    output reg  [31:0] twiddle_data // [31:16]: Imag (Q1.15), [15:0]: Real (Q1.15)
);

    // 宣告 ROM 記憶體陣列：32 個 32-bit Word
    reg [31:0] rom [0:31];

    // 初始載入 mem 檔案
    // Vivado 合成器會自動識別 $readmemh，並將此陣列映射為 FPGA 內部的 Block RAM 或 Distributed ROM
    initial begin
        //$readmemh("twiddle.mem", rom);
        rom[0]  = 32'h00007FFF;
        rom[1]  = 32'hF3747F62;
        rom[2]  = 32'hE7077D8A;
        rom[3]  = 32'hDAD87A7D;
        rom[4]  = 32'hCF047642;
        rom[5]  = 32'hC3A970E3;
        rom[6]  = 32'hB8E36A6E;
        rom[7]  = 32'hAECC62F2;
        rom[8]  = 32'hA57E5A82;
        rom[9]  = 32'h9D0E5134;
        rom[10]  = 32'h9592471D;
        rom[11]  = 32'h8F1D3C57;
        rom[12]  = 32'h89BE30FC;
        rom[13]  = 32'h85832528;
        rom[14]  = 32'h827618F9;
        rom[15]  = 32'h809E0C8C;
        rom[16]  = 32'h80000000;
        rom[17]  = 32'h809EF374;
        rom[18]  = 32'h8276E707;
        rom[19]  = 32'h8583DAD8;
        rom[20]  = 32'h89BECF04;
        rom[21]  = 32'h8F1DC3A9;
        rom[22]  = 32'h9592B8E3;
        rom[23]  = 32'h9D0EAECC;
        rom[24]  = 32'hA57EA57E;
        rom[25]  = 32'hAECC9D0E;
        rom[26]  = 32'hB8E39592;
        rom[27]  = 32'hC3A98F1D;
        rom[28]  = 32'hCF0489BE;
        rom[29]  = 32'hDAD88583;
        rom[30]  = 32'hE7078276;
        rom[31]  = 32'hF374809E;
    end

    // 同步讀取邏輯 (Read Latency = 1 cycle)
    always @(posedge clk) begin
        if (en) begin
            twiddle_data <= rom[addr];
        end
    end

endmodule
