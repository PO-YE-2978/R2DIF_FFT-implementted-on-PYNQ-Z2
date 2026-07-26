Chapter 5 - Butterfly Processing Element (PE) 詳細設計與 Verilog 分析
===
## 5.1 R2 DIF Butterfly Function Analysis.
在 butterfly 的 module 中，只有單純的數學運算，同時所有 variable ($X_a$, $X_b$, $Y_a$, $Y_b$ 和 $W_N^k$)皆為 complex scalar。具體 I/O 如下表示 :  

* Input : 
<p align="center">
  $X_a, \text{ } X_b$
</p>

* Output :
<p align="center">
  $$
    Y_a = X_a + X_b
  $$
  $$
    Y_b = (X_a - X_b) * W_N^k
  $$
</p>

其中
<p align="center">
  $W_N^k = e^{-j2\pi k/N}$
</p>

而每一筆 data 都會佔 32 bits (16 bit imag part + 16 bit real part)。舉例來說， $X_a$ = 32'h1234_5678, 則 imag = 0x1234, real = 0x5678。

在硬體實作上，假設
<p align="center">
  $X_a=a+jb, \text{ } X_b=c+jd$
</p>
則

* Addtion : 
  <p align="center">
    $Y_a = X_a + X_b = (a+c)+j(b+d)$
  </p>

* Subtraction : 
  <p align="center">
    $Y_b = (X_a - X_b) * W_N^k = [(a-c)+j(b-d)] * W_N^k$
  </p>

* Mulitplication : 
  <p align="center">
    $X_a * X_b = (ac-bd)+j(ad+bc)$
    
  </p>

對於 multiplication 而言 (算 $Y_b$ 的過程)，我們用 Complex_multi module 來運算。首先，我們用 4 個 register 來存 "ac", "bd", ad", bc"，讓乘法可以 parallel 的運算。接著，code 中還設計了溢位偵測 : 我們的 data 採用 Q1.15 的解讀方式，也就是 1 個sign bit 接 15 個 fractional bits。舉例來說，若
<p align="center">
  $X_a = 0.25-0.5j$
</p>

則經過轉換後可得
<p align="center">
  $Real (X_a) = 0.25 * 2^{16} = 8192 = \text{0x2000}$
</p>

<p align="center">
  $Imag (X_a) = -0.5 * 2^{16} = 16384 = \text{0xC000}$
</p>

## 5.2 Mulitplication Bit Growth and Data Truncation
1. Truncation 目的
   假設 Xa, Xb 皆為 0.9，則相加之後 = 1.8。但 Q1.15 最大只支援到 0.999，因此 FFT 需要處理 Dynamic range。
2. Add/Sub Scaling 方法
   * Method 1 : 每個 stage / 2，即 $Y = (X_a + X_b)/2$
     > 優缺 : 能有效阻止 overflow，但誤差會上升。
   * Method 2 : Dynamic scaling，若結果接近 overflow 臨界點 (+-1) 再進行 shift right。
     > 優缺 : 精確度更高，但控制較為複雜。
   * Method 3 : Bit Growth : 即每經過一個 stage，output bit 數量就加 1 (將 overflow 的值也存入)。
     > 優缺 : 精確度最好 (完整保留)，但在乘法器上的大小需求上會增加。
   * Method 4 : 直接 truncate (本專案採用) => 若相加大於 1 : 直接取 1 ； 同理，相減小於 -1 則直接取 -1。
     > 優缺 : 設計簡單，module 之間通用 16 bit，但精確度可能會下降。
3. Multiplication Scaling
   16 bit * 16 bit 會得到 32 bit (也就是 Q2.30 的結果)，因此 multiplication 取值時只取前面 [30:15] bits 的結果。值得注意的是，若 data 乘上 twiddle factor 後大於 1 (either imag or real part)，則 output 就會從正數變為負數，因此我們需要將其 truncate 成 16'h7FFF ~ 0.999...。

## 5.3 Timing alignment
設計 butterfly PE 的另一個重點是 timing 是否有對上。理想上 input 為 ($X_a$, $X_b$) 同時進入， output ($Y_a$, $Y_b$)同時輸出。但是在計算 $Y_b$ 時因為有乘法的緣故 (Complex_multi)，因此在計算完 $Y_a$ 後需要延遲 cycle 輸出。具體來說，加法減法同步算，差異只有在 Complex_multi function 上的 delay，也就是 : 
> Cycle 1 : 算 "ac", "bd", ad", bc" 

> Cycle 2 : 算 (ac-bd), (ad+bc) 並進行 truncate 與輸出。

因此在 Butterfly output 時我們需要將 "data_a_out" delay 2 個 cycle 才會對其。

## 5.4 Twiddle ROM
Twiddle 單純只是一個 ROM，input 為 address (從 addr_generator module 產生)，output 則是對應的 twiddle factor。在我們的 64 point FFT 當中，總共有 32 個不同 value 的 twiddle factor。這些數值可以先由 python 生成並轉成 32 bit 的數值 (16 bit imag + 16 bit real)後，在手動打入 verilog code。

## 5.5 完整 Butterfly Data flow
1. Step 1 : 取得 Xa, Xb
2. Step 2： Add/Sub (此時已經算出 Ya)
3. Step 3： Twiddle Multiply (將 Sub 的結果乘上 $W_N^k$ 求 Yb，Ya delay 2 cycles)
4. Step 4： Output 得到 Ya, Yb

## 5.6 Algorithm Comparison
<div align="center">
  
  | Pros/Cons | Single Memory | Pipeline |
  | :--: | :--: | :--: |
  | Pros | 架構簡單、容易驗證、適合學習 | throughput 較低 |
  | Cons | throughput 較低 | 資源消耗較大、設計較為困難 |
</div>

與主流的 pipeline 架構相比，我們的設計較為簡單，適合作為第一次的練習。Pipeline 的架構上吞吐量較大，但在硬體的使用上我們僅需要 4 個乘法器，相對於 64 Point pipeline FFT 需要 192 個 PE 而言，在 Area 上就可以佔據很大的優勢，也就達到了低資源 FFT Accelerator。

## 5.7 FPGA vs Python
1. 差異來源
   * Bit Reverse Order
     > DIF FFT 的 output 為 bit reversed，而 Python FFT 出來則是 normal order，因此需要先 reorder。
   * Fixed-point Error
     > FPGA 是 16-bit fixed width data，而 Python 是 64-bit floating point，因此有 quantization noise 。
   * Scaling Difference
     > 我們每一級運算後都有進行 truncation，Python FFT 則沒有 scaling，因此會有誤差。
2. Accuracy 評估方式
   可以透過 Mean Square Error (MSE) 測量兩者之間的誤差進行比較:
   
    <p align="center">
        $MSE = \frac{1}{N} \sum |X_{FPGA} - X_{REF}|^2$
    </p>
    
## 5.8 Chapter Review
本章介紹了 Butterfly PE 的內容，包括 complex 運算、scaling 或 overflow 的處理、timing 控制、 ROM 和 overall data flow 等。這些概念跟 RTL code 的觀念對應如下 : 
<div align="center">
  
  | Concept | RTL Module |
  | :--: | :--: |
  | Butterfly | fft_butterfly.v |
  | Complex multiplication  | complex_mult.v |
  | Twiddle coefficient | twiddle_rom.v |
  | Data scheduling | controller_fsm.v |
  | Memory access | addr_generator.v |
</div>

