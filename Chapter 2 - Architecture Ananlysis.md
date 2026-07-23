Chapter 2 - 64-point Radix-2 DIF Single BRAM and Single Butterfly PE FFT Architecture
===
## 2.1 FFT 從演算法轉換成硬體
---
回顧前面提到的架構，我們的目標是設計一個能在 FPGA 上運作的 64-point R2 DIF using single BRAM FFT IP Core。 示意圖如下所示 : 
<p align="center">
  <img width="396" height="271" alt="image" src="https://github.com/user-attachments/assets/0c5d0bc0-d6fc-4fa8-897f-76eacef72f3e" />
  <br />
</p>
而在硬體上的運算流程為 :
<p align="center">
  BRAM -> Read 2 samples -> Butterfly PE -> Write result back -> Next address -> Next butterfly ...
</p>
也就是透過少量硬體資源，重複使用 Butterfly 來完成 FFT。以下我將簡述架構中每個 block 的設計機制。

## 2.2 Butterfly Processing Unit (PE)
---
