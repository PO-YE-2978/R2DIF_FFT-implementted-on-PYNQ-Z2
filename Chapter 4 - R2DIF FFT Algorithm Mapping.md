Chapter 4 - Radix-2 DIF FFT Algorithm Mapping to Hardware
===
前面 Chapter 2、3 我們已經知道
* FFT 可以拆成 Butterfly
* Butterfly 是硬體核心
* FSM 控制時間
* Address Generator 控制資料位置
* BRAM 儲存中間結果

但具體而言FFT 演算法中的「第幾層(stage)」、「哪兩個資料運算」、「Twiddle Factor 使用哪一個」，如何轉換成 FPGA 可以執行的控制訊號等議題仍未說明。因此本章節會將所有流程串聯起來，包括 : 
<p align="center">
  Mathematical FFT -> Stage / Butterfly Mapping -> Address Generator -> FSM Control -> RTL Hardware
</p>

## 4.1 R2 DIF FFT 基本概念
常見的 FFT 架構分成 DIT (Decimation-In-Time，即時域拆分) 和 DIF (Decimation-In-Frequency，即頻域拆分)，比較表如下 : 
<div align="center">
  
  |  | DIT | DIF|
  | :--: | :--: | :--: |
  | Input | bit-reversed | normal order |
  | Output | normal order | bit-reversed |
</div>

本專案本專案採用 DIF 的原因是在硬體上，Input 可以直接寫入 BRAM，不需要先做 input reordering。

## 4.2 64-point FFT Stage 和 Butterfly 數量
FFT 的 stage 數 :
<p align = "center">
  $\log_2 \bf(N)$
</p>
在我們的 case 中，一共有 log<sub>2</sub>(64) = 6 個 stage。又因為每個 stage 需要運算 N/2 次 butterfly，因此總共運行 butterfly 的次數達到 :
<p align = "center">
  $(64/2) * 6 = 192$
</p>
在我們的架構中，並沒有 192 個 butterfly PE，而是用一個 butterfly PE 重複使用 192 次 => resource sharing。

## 4.3 Butterfly Dataflow (stage 0)
DIF stage 0 的 distance = N/2 = 64/2 = 32。因此送入 butterfly (Xa, Xb) 的 data 應該為
<p align = "center">
  (x0, x32), (x1, x33),(x2, x34), ..., (x31, x63)
</p>

在我們的 hardware 中，addr 0 對應到 x0，addr 1 對應到 x1 ... 以此類推到 addr 63 對應 x63。當第一次進行 butterfly 時，addr_a =0, addr_b =32，此時 BRAM 中 Port A -> x0, Port B -> x32。送如 butterfly PE 後，會得到 y0, y32，並寫回 addr 0,addr 32 (x0, x32)。下一次 addr_a=1,  addr_b=33 ... 以此類推。

## 4.4 Stage Distance 如何改變？
DIF 每經過一個 stage，distance 減半，即 : 
<div align="center">
  
  | Stage | Distance | Corresponded Pairs |
  | :--: | :--: | :--: |
  | 0 | 32 | (x0, x32), (x1, x33) ...|
  | 1 | 16 | (x0, x16), (x1, x17) ...|
  | 2 | 8 | (x0, x8), (x1, x9) ...|
  | 3 | 4 | (x0, x4), (x1, x5) ...|
  | 4 | 2 | (x0, x2), (x1, x3) ...|
  | 5 | 1 | (x0, x1), (x2, x3) ...|
</div>

## 4.5 addr_generator I/O
換句話說，distance 會根據 stage 不同而改變。因此，在我們的 addr_generator module 中，會將
<p align = "center">
  (stage, butterfly_index)
</p>

轉成
<p align = "center">
  addr_a, addr_b, twiddle_addr
</p>

舉例來說，當 stage = 0, butterfly_index = 5 時，因為 stage 0 對應的 distance = 32，因此輸出的 addr_a = 5, addr_b = 5+32 = 37。而 twiddle_addr 則會到 twiddle_rom module 中找到需要的 twiddle factor (W5)。

## 4.6 FSM stage control
FSM 中設計了兩個主要的 counter，包括 : 
<div align="center">
  
  | Counter type | Range | Functionality |
  | :--: | :--: | :--: |
  | Stage counter | 0~5 | 目前 FFT 第幾層 |
  | Butterfly Counter | 0~31 | 目前 stage 中第幾個 butterfly |
  
</div>

流程上而言，initially stage counter = 0, butterfly counter = 0。接著 butterfly counter 開始往上數到31，然後 stage counter +1、butterfly counter 從 0 再開始數，以此類推直到 stage=5, butterfly=31 => 完成 FFT。與 FSM 架構對應 :
1. Step 1 : Address Generator (產生 addr_a, addr_b)
2. Step 2 : BRAM READ (讀 Xa, Xb)
3. Step 3 : Wait (等 BRAM latency)
4. Step 4 : Butterfly (計算 Ya, Yb)
5. Step 5 : Write Back (寫回 addr_a, addr_b)
6. Step 6 : Update (butterfly_counter++)

* DIF FFT 的輸出是 bit reversal，因此在後續 python 驗證時除了寫``` numpy.fft.fft() ``` 外，還需要將 bit reverse 後再與硬體進行比較。

## 4.7 Chapter Review
本章節介紹了 stage、address、FSM 等相關議題。在這裡，FFT 硬體不是把公式直接寫成 Verilog，而是由
> FFT Algorithm
> Stage decomposition
> Butterfly scheduling
> Address generation
> FSM timing
> Hardware execution

等等組成。而我們的架構是 6 stages x 32 butterflies = 192 次 Butterfly operation using only single Butterfly PE，也就是利用時間換取硬體面積，以有限資源完成複雜演算法。下一張會介紹 Butterfly PE 的詳細內容。
