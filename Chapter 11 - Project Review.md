Chapter 11 - 整體專案回顧與未來優化方向
===
本次專案我們已經完整建立一套 64-point FFT FPGA Accelerator System。從最初的 FFT Algorithm，一路發展到 Python → AXI → FPGA → FFT Hardware → Output。
整個流程涵蓋了 FPGA Accelerator 開發中所需的各種概念，包括 :
* DSP 演算法硬體化
* RTL 設計
* Memory Architecture
* FSM Controller
* IP Integration
* AXI Interface
* PYNQ Software Control

本章將針對整個專案架構、設計思維、目前架構優缺點以及未來可以如何優化等進行回顧探討。

## 11.1 FFT Accelerator 架構總覽
回顧 Chapter 10 的流程圖，我們可以將整個架構由上至下分成三個區塊 : 
<div align="center">
  
| Layer | 功能 | 細節描述 |
| :--: | :--: | :--: | 
| Software Layer | 負責 Python、PYNQ、Jupyter Notebook | 載入 bitstream、啟動 FFT、傳送 I/O |
| Interface Layer | 負責 AXI4-Lite | 讓 ARM 與 FPGA 溝通、處理 Register Mapping 和 Start / Done Control 等 |
| Hardware Layer | 負責 FFT Computation | 包括各個 sub-module 如 Butterfly、Address Generator |
</div>

## 11.2 RTL Module 分析與功能整理
1. fft_top.v
   * 目的 : 整合全部 FFT Core 的 Top Module。
     > 負責連接所有子模組、定義 I/O interface 並整合 datapath 與 control。
2. controller_fsm.v
   * 目的 : 控制 FFT，決定什麼時間應該做什麼事。
     > 負責 State transition、stage 或 butterfly counter 以及 enable signal 等。
3. addr_generator.v
   * 目的 : 產生 Butterfly PE 和 Twiddle Rom 所需要的 memory address。
     > 包括 addr_a、addr_b 和 twiddle_addr。
4. fft_butterfly.v
   * 目的 : 核心的運算單元。
     > 公式 : Ya = Xa + Xb, Yb = (Xa - Xb) * W
5. complex_mult.v
   * 目的 : 負數乘法。
     > 例如 (a+jb)(c+jd) => (ac−bd)+j(ad+bc)
6. twiddle_rom.v
   * 目的 : 避免重複算 twiddle factor，用一個 ROM 將全部可能的值先存起來。
7. BRAM
   * 目的 : 儲存 I/O Data 和 Intermediate result。

## 11.3 架構選擇
1. 為何使用 Radix-2 DIF :
   1. 主要原因是架構簡單，方便作為第一次學習的訓練。
   2. 64 point 數量足夠，能有效練習 FFT 概念。
   3. Butterfly 規則固定，i.e.每個 stage 都使用同一個 PE。
   4. 適合 FPGA (R2 剛好 match Dual Port Memory 等)。
2. 為何使用 Single BRAM Architecture :
   1. 主要原因亦是架構相對簡單，同時可以練習到如何使用 BRAM、timing 和 address mapping 等議題，後續方便延伸。
      > 優點 : LUT 少、DSP 少、BRAM 少，但缺點是 delay 高。
3. 目前架構優缺點分析
   * 優點 :
      * 硬體資源低 (只需要一個 Butterfly PE 和少量 BRAM)。
      * 架構容易理解。
      * 容易驗證 (每個 stage 都可以單獨測試)。
   * 缺點 :
      * Throughput 較低 (因為一次只有一個 Butterfly)。
      * Latency 高 (64-point FFT 需要 6 × 32 = 192 次 butterfly)。
      * Memory access overhead (大量時間花在 read/write BRAM)。
4. 未來優化方向
   1. Pipeline FFT ( Read/Write 同時也計算 butterfly)。
      > 增加 throughtput，但設計複雜度和 debug 難度提升)。
   2. 增加 Butterfly PE 數量。
      > 用更多的硬體資源換速度。
   3. 學習用 AXI-Stream。
      > 目前採用 AXI4-Lite，以後若需要大量資料傳輸，則建議可以改用 DMA + AXI-Stream 進行高速訊號處理。

## 11.4 SoC 執行流程
1. Step 1 : Python 傳送 input 到 BRAM
   > Python -> AXI -> BRAM
2. Step 2 : Start Signal Trigger
   > Python 發送 start
3. Step 3 : FFT 開始
   > IDLE -> READ -> WAIT -> CALCULATE -> WRITE... 直到完成所有 6 stages × 32  = 192 次 butterfly。
4. Step 4 : done signal
   > FSM ->STATUS register -> Python
5. Step 5 : Python 讀 output 並與 sw_fft 比較差異。

* Knowledge Map :
  * DSP Theory
  * FFT Algorithm
  * Hardware Mapping
  * Butterfly Design
  * Memory Architecture
  * FSM Controller
  * AXI IP Design
  * Vivado Integration
  * PYNQ Control
  * FPGA Accelerator

## 11.5 Final Summary
這次 64-point FFT 專案學到的，不只是如何寫 FFT，更重要的是學習如何將一個數學演算法轉換成可以在 FPGA 上高速運行的硬體系統。Starting from chapter 1, we have gone through : 
<p align="center">
  Mathematical Algorithm -> Hardware Architecture -> RTL Implementation -> Memory Scheduling -> Control Design -> IP Packaging -> Software Interface -> System Verification
</p>
這也是 IC Design 中最核心的能力 : 
<p align="center">
  Algorithm → Architecture → Circuit → System
</p>


透過這個專案，我們已經接觸到：
  * DSP Hardware Accelerator
  * RTL Design
  * FPGA Memory Architecture
  * Digital System Design
  * AXI Interface
  * Embedded FPGA System
    
這套流程與概念，未來不只適用於 FFT，也可以延伸到
  * CNN Accelerator
  * AI Engine
  * Image Processing
  * Baseband Accelerator
  * Wireless Communication
等領域。

最終的系統流程圖如下 : 
<div align="center">
  <img width="512" height="294" alt="image" src="https://github.com/user-attachments/assets/fef1eb0f-78f1-4c23-bacf-ab9e6a745907" />
</div>
