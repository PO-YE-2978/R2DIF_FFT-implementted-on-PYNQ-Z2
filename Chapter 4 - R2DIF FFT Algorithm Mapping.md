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

## 4.2 64-point FFT Stage 數量
FFT 的 stage 數 :
<p align = "center">
  $\log_2 \bf(N)$
</p>
在我們的 case 中，一共有$\log_2(64)=6$個stage。
