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
   * 回顧 Chapter 3 - 3.6 所示，我們的 addr_generator.v module 為 FFT Memory Controller 的核心。其概念是藉由 stage 不同推算出對應的 distance，找到 butterfly 和 twiddle factor 所需要的 address。 I/O 如下 :
     > Input : stage、butterfly index
     
     > Output : addr_a, addr_b, twiddle_addr

2. Distance Calculation :

   * Stage Distance Difference (Xa 與 Xb address 的距離)
     如同前面所述，每經過一個 stage，Distance 就會除二，從 32 開始到 1。除此之外，每經過 1 個 stage，所有 Group 也會拆分成兩個部分 (前半和後半) : 具體如下 :
     <div align="center">
     
     | Stage | Distance | Group |
     | :--: | :--: | :--: |
     | 0 | 32 | 0-63 |
     | 1 | 16 | 0-31, 32-63 |
     | 2 | 8 | 0-15, 16-31, 32-47, 48-63|
     | 3 | 4 | 0-7, 8-15, 16-23, 24-31, ... , 56-63| 
     | 4 | 2 | 0-3, 4-7, 8-11, 12-15, ... , 60-63| 
     | 5 | 1 | 0-1, 2-3, 4-5, 6-7, ... , 62-63|
   
   </div>
   
     * Butterfly Pair Address Mapping
       
       每個 stage 都有不同的 group，分別對應到 data pair 如何選擇。以 Stage 1 為例，因為 distance 為 16，又因 group 分成兩組，故在 stage 1 送入 butterfly 的 pair (Xa, Xb) 為 :
       > (x0, x16), (x1, x17), ..., (x15, x31), (x32, x48), ..., (x47, x63)

       共計 32 組。
       
     * 公式如下 :
  
       For addr_a and addr_b in same Group : 
       <p align="center">
         addr_a = butterfly_index
       </p>

       <p align="center">
         addr_b = butterfly_index + Distance
       </p>

3. 硬體實作 :
   * Address Generator Structure :
     > Stage Counter -> Butterfly Counter -> Address Logic -> BRAM Address

   * Stage Counter 與 Butterfly Counter 關係 :

     Initially Stage 和 butterfly 皆為 0，接著 butterfly++ 直到 butterfly=31，而後在進行下一個 Stage (stage++)，最後做完 Stage = 5, butterfly = 31 即完成。

   * Address Generator 與 FSM 關係 :
     > controller_fsm -> stage counter ->  addr_generator -> BRAM address

     完整流程 :
       > Step 1 : FSM READ，接著 Address Generator 輸出 addr_a, addr_b
       > Step 2 : BRAM 輸出 Xa, Xb
       > Step 3 : Butterfly 計算 Ya, Yb
       > Step 4 : Memory Write Back
       > Step 5 : Counter Update

   * Memory Address 與 PYNQ 的關係
     
     PYNQ 會透過 AXI 介面操作 BRAM，Python 只負責寫 input、啟動 FFT 和讀 output。架構如下 : 
     > Python -> AXI Register -> FFT Controller -> BRAM

## 6.3 Chapter Review
本章分析了 Memory 和 address generator 在這個 project 的重要性，其核心概念在於如何正確運用 BRAM 並找到對應地址放入 Butterfly 中運算。所述硬體概念與 RTL code 對應表如下 : 
