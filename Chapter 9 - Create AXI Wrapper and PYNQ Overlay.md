Chapter 9 - Vivado 建立 AXI Wrapper 與 PYNQ Overlay 整合流程
===
在前面的章節中，我們介紹到 FFT Core + AXI4-Lite Wrapper = 可以被 PYNQ 控制的 FPGA IP。而本章將會說明如何藉由 Block Design 將 PS (ARM Processor) 、PL (FFT Core IP) 
和 AXI 介面等相關 IP 串聯起來，完成整個 SoC 架構。完整的開發流程如下 : 

<p align="center">
  Verilog FFT -> Vivado IP Package -> Block Design -> Zynq PS + AXI -> Export Hardware -> PYNQ Overlay -> Python Control
</p>

## 9.1 Block Design 前置確認步驟
1. 在 create project 中，確認 Default Part 中按 ```boards``` 選擇的是 PYNQ Z2 板子。 
2. 將 FFT_top 包裝成 AXI IP 前要先確認 FFT 功能正常 (否則後續 Debug 會較麻煩，Error 可能出自於 FFT Algorithm、AXI 或 PYNQ 等)。
   > 測試功能是否正確可先寫 testbench 再驗證波型。
3. 主頁中點選 Setting -> IP -> Repository，確認 FFT IP 是否已經加入。(若沒有，手動加入並點選 Refresh-All)

## 9.2 Block Design Flow
確認前面步驟都是正確的後，接下來就可以把 IP 串在一起了。
1. 主頁中點選 ```create block design```， default name 維持 design_1 即可。
2. 左邊生成的 Diagram 中，加入以下 IP :
   <div align="center">
     
     | IP Block | 意義 | 作用 |
     | :--: | :--: | :--: |
     | ZYNQ7 Processing System | ARM CPU | 執行 PYNQ、控制 FFT |
     | Processor System Reset | 系統 Reset 管理 | 確保所有 IP 正確初始化 |
     | AXI SmartConnect | AXI bus 匯流排交換器 | 將 CPU 連到 FFT IP、BRAM Controller |
     | AXI BRAM Controller | AXI ↔ BRAM 介面轉換 | 讓 CPU 能讀寫 BRAM |
     | Block Memory Generator | BRAM | 儲存 FFT Input、中間結果、Output |
     | bram_switch_v1_0 | BRAM 控制權切換器 | 決定 CPU 或 FFT 誰控制 BRAM |
     | my_fft_top_ip_v1_0 | FFT Accelerator | 執行 64-point FFT 計算 |
   
   </div>

  * 
