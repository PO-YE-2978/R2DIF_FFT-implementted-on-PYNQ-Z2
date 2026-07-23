Chapter 2 - 64-point Radix-2 DIF Single BRAM and Single Butterfly PE FFT Architecture
===
## 2.1 FFT 從演算法轉換成硬體
---
回顧前面提到的架構，我們的目標是設計一個能在 FPGA 上運作的 64-point R2 DIF using single BRAM FFT IP Core。 結構如 Fig2.1 所示 : 
<p align="center">
  <img width="396" height="271" alt="image" src="https://github.com/user-attachments/assets/0c5d0bc0-d6fc-4fa8-897f-76eacef72f3e" />
  <br />
  <em> Fig2.1: 8 point Radix-2 DIF FFT Architecture Diagram</em>
</p>

而在硬體上的運算流程為 :
<p align="center">
  BRAM -> Read 2 samples -> Butterfly PE -> Write result back -> Next address -> Next butterfly ...
</p>
也就是透過少量硬體資源，重複使用 Butterfly 來完成 FFT。以下我將簡述架構中每個 block 的設計機制。

## 2.2 Butterfly Processing Unit (PE)
---
#### For Radix-2 DIF Butterfly：
1. Input :
   <p align="center">
     $\mit{X}_a$,  $\mit{X}_b$, where $\mit{X}_a, \mit{X}_b \subset \Bbb{C}$
   </p>
   
2. Output :
   <p align="center">
     $\mit{Y}_a = \mit{X}_a + \mit{X}_b$ 
   </p>
   <p align="center">
     $\mit{Y}_b = (\mit{X}_a - \mit{X}_b)\mit{W}^k_N \text { , where } \mit{W}^k_N = e^{-j2\pi k/N} \text { is called "Twiddle Factor" }$
   </p>
   
在 Butterfly PE 中，包括複數的加、減和乘法。後續我們會設計一個sub-module "complex_multi"用來處理複數運算。

## 2.3 Twiddle ROM
---
計算 FFT 的過程會需要乘上twiddle factor $\mit{W}^k_N$。由於此factor是一個常數(for each k)，因此我們可以先將所有數值先算好並儲存，需要時再叫出。這樣就不需要每一步都重新算，進而減少硬體資源的浪費。在實作上，我們將values存入registers，接著透過address的方式取出，詳見chapter 3。

## 2.4 Adderss Generator
---
由於我們使用的架構是64point DIF FFT，因此第一個stage需要read (0,32)、(1,33)...，第二個stage則是(0,16)、(1,17)...。為了讓 butterfly PE 能夠計算正確的value，我們需要有 Address Generator 用來控制讀寫位置並產生BRAM Address。
