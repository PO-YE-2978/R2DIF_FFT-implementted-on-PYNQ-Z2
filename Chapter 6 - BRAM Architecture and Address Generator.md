Chapter 7 - BRAM Memory Architecture 與 Address Generator 設計分析
===
在前面的章節，我們已經完成：
* FFT 演算法拆解
* Radix-2 DIF Stage 分析
* Butterfly PE 設計
* Fixed-point 數值格式
本章節將接續介紹 Memory Architecture + Address Generation。

## 7.1 BRAM Size
Chapter 3 - 3.5 中有說明 BRAM Width = 32 的原因是我們每一筆 data 佔 32 bits。又因為總共是 64 point 的 FFT，因此 Depth = 64。這樣一來總共的 Memory 大小為

<p align="center">
  32 * 64 = 2048 bits = 256 bytes  
</p>
