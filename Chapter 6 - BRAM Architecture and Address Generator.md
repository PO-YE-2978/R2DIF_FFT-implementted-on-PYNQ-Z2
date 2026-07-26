Chapter 6 - BRAM Memory Architecture 與 Address Generator 設計分析
===
在前面的章節，我們已經完成：
* FFT 演算法拆解
* Radix-2 DIF Stage 分析
* Butterfly PE 設計
* Fixed-point 數值格式
本章節將接續介紹 Memory Architecture + Address Generation。

## 6.1 BRAM Analysis
1. Why using BRAM :
   * 回顧我們的 FFT，設計上需要 6 個 stages 來完成，而每個 stage 需要 intermediate storage 將中間的結果暫存，因此 BRAM 同時負責：儲存 Input、Stage result 和 Output 的作用。

2. BRAM Size
   * Chapter 3 - 3.4 中有說明 BRAM Width = 32 的原因是我們每一筆 data 佔 32 bits。又因為總共是 64 point 的 FFT，因此 Depth = 64。這樣一來總共的 Memory 大小為

   <p align="center">
     32 * 64 = 2048 bits = 256 bytes  
   </p>

   * 實際上 256 bytes 不大，可以直接在verilog 上寫 ```reg [31:0] fft_data [0:63];``` ，這樣 synthesis 出來的電路可能變成 LUT RAM，就達不到我們練習 BRAM 的主要目的了。

3. Why Setting Dual Port :
   設置 dual port 的主要目的是要讓 butterfly PE 能同時讀取 Xa、Xb。若使用 single port 的話則需要更多 cycle 完成 :
   <div align="center">
     
     | Cycle | Single Port | Dual Port |
     | :--: | :--: | :--: |
     | 1 | read x0 | read (x0, x32) |
     | 2 | read x32 | wait |
     | 3 | wait | calculate |
     | 4 | calculate | calculate |
     | 5 | calculate | write (x0, x32) |
     | 6 | write x0 | - |
     | 7 | write x32 | - |
   </div>

5. BRAM Read Timing
   * BRAM 有 1 個 cycle 的 Latency ( Block Memory Generator 生成時將 "Primitives Output Register" 取消勾選)。因此在設計 FSM 時要注意 Read 完後要等待一個 cycle 才能抓到正確資料。
     
## 6.2 Address Generator
1. 目的 : 
