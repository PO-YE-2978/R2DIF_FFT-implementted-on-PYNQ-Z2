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

  * ZYNQ : 我們 SoC 的 CPU，主要工作負責執行 Python、控制 FPGA，流程 : 
    > Python -> ARM CPU -> AXI Bus ->FFT IP
  * Processor System Reset : 讓所有 IP 都在正確的時間 Reset。
    > 若沒有 reset : FSM 可能從 State3 開始，或 BRAM 仍保留舊資料，故 Reset IP 會先等 Clock Ready -> 解除 Reset -> 所有 IP 開始工作。
  * AXI SmartConnect : AXI Bus，決定 CPU 現在要跟哪一個 IP 溝通。
    > 若沒有 BRAM (其他IP等)，FFT 可以直接連 CPU，就不需要 AXI Bus。但我們的架構有 BRAM，CPU 需要同時控制 FFT 和 BRAM，因此需加入 AXI Bus。
  * AXI BRAM Controller : 將 CPU 的指令轉成 BRAM address，讓 BRAM 能讀寫出正確資料。流程 : 
    > AXI Address -> BRAM Address -> BRAM Enable -> Write Enable -> BRAM Data
  * Block Memory Generator : BRAM，包含 Port A 和 Port B。
    > Port A :  前面接 bram_switch_v1_0 (Multiplexer），決定 Port A 是由 AXI BRAM Controller 還是 FFT IP 控制。
    
    > Port B : 沒有經過 Switch，直接拉到 FFT Core。
  * bram_switch_v1_0 : 這部分是我們另外寫的，因為 BRAM 一次只能收一組控制訊號，但 CPU 和 FFT IP 都需要使用，因此需要一個 switch 決定現在 BRAM 接收誰的訊號。
    > FFT 開始前 : switch mode 為 CPU；等 FFT 開始後，switch mode 為 FFT；計算完成以後，switch mode 再切回 CPU。
  * my_fft_top_ip_v1_0 : 我們上一章包裝過的 FFT Core IP。
    
