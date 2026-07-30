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
換句話說，我們首先會將time domain 64 個 sampling point 存到 Memory中，接著根據 address 取出 corresponded value 放入 Butterfly PE 運算，接著再將算好的值存回去，以此類推直到所有64個點全部都算完後再輸出。這樣的設計下，我們的 BRAM 會同時存有 input 和 Intermediate result。此處優點在於 memory usage 和 routing complexity 可降低，整體難度較為簡單，但缺點會造成速度較慢。也就是可透過少量硬體資源 (重複使用 Butterfly PE) 來完成 FFT。以下我將簡述架構中每個 block 的設計機制，詳細 Verilog design 請見 chapter 3。

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

## 2.5 Controller FSM
---
這個部分是整個 FFT 控制的核心，例如 FFT 需要知道現在的 state、是否讀寫完成、第幾個 butterfly 等資訊。而在我們設計的 64 point FFT 當中，主要藉由 1 個 Butterfly PE, 1 個 controller 和 1 個 Memory 構成並重複使用。因此我們會設計多個 state 告訴 FFT 現在應該執行那一步。

## 2.6 Top Level Architecture
---
完整的 block diagram 如 Fig2.2 所示
<p align="center">
  <img width="341" height="265" alt="image" src="https://github.com/user-attachments/assets/0ba2f726-cb5b-4d76-8d2b-79bee660245c" />
  <br />
  <em> Fig2.2 Block diagram of our FFT Module</em>
</p>

## 2.7 Chapter Review
---
本章將 FFT Algorithm 拆分成多個可實例化的 Module，包括可重複使用的 Butterfly PE、FSM Control Uint、Address Generator 和 BRAM 等。下一章開始會詳細介紹每個 module 的細節。
