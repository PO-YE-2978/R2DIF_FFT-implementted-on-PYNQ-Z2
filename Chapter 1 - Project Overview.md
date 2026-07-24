Chapter 1 - Project Overview
===
## 1.1 為什麼要做這個專案？
* 本專案的目標，是從零開始設計一個可在 FPGA 上運行的 64-point FFT IP Core，並透過 PYNQ 平台，使用 Python 控制 FPGA 完成 FFT 運算。
* 實作內容不使用 FFT IP，而是自行設計 Verilog RTL 以實現 FFT 演算法與控制架構，因此能夠深入理解 FFT 硬體設計的每一個細節。
* 專案最終成果如下圖所示：
<p align="center">
  <img width="512" height="294" alt="image" src="https://github.com/user-attachments/assets/2ecac8ec-6d9f-42db-9b9f-cbe990f4515f" />
  <br />
  <em> Fig 1.1 Overall Structure</em>
</p>

* 主要內容涵蓋
  * Digital Circuit Design
  * Algorithm Design and implementation
  * DSP
  * FPGA-based SoC Design
  * Computer Architecture
  * Python and Verilog
  * Hardware/Software Co-design
---
## 1.2 本專案的學習目標
本次專案的主要學習目標是透過python控制AXI register，進而引出我們設計好的FFT IP並驗證。因此，完成本專案後，應該能回答以下問題 : 
* FFT
  * FFT 跟 DFT 的差別 ?
  * 何謂 Butterfly calculation, twiddle factor ?
  * DIF 與 DIT 差別 ? 為何要進行 bit reverse 等 ?
* Hardware
  * 如何在硬體上實現 FFT (如 butterfly PE, FSM stage design等) ?
  * BRAM 怎麼存資料、運用 ?
  * Address 如何決定、產生 ?
* FPGA
  * 如何 Package IP ?
  * Block Design 內部的線要怎麼拉 ?
  * 有哪一些 Peripheral IP 需要使用、功能是什麼 ?
* PYNQ
  * PYNQ 的基本概念 ?
  * Overlay 是什麼 ?
  * Python 如何控制 register、MMIO 怎麼運作?
---
## 1.3 系統規格
<div align="center">
  
| 項目 | 規格 |
| :--: | :--: |
| FFT size | 64 point |
| Algorithm | R2 DIF FFT |
| Architecture | Single Butterfly PE |
| Memory | Single BRAM |
| Data Width | 16 bit imag + 16 bit real |
| Output | 64 complex data |
| Interface | AXI4 Lite |
| Platform | PYNQ Z2 |

</div>

#### 1. Why 64 point FFT ?  
   設計上可選更多Point的FFT (如128、256...)，但更多點代表需要更大的 BRAM 空間和 twiddle factor ROM。在我們的專案中，主要是想了解整體的運作流程。從FFT實作的角度來看上，將sampling point數量增加單純是stage變多，對於核心的演算法來說並無改變。因此使用 64-point 專注於架構設計，而不會因資源過多增加除錯難度。
#### 2. Why Radix-2 (R2) ?
  FFT 有很多不同拆解 radix 的方式，包括 R2、R4 和 Mixed radix 等。在本次實作中，我們使用最基礎的R2，最主要的原因是方便理解且容易實現。
#### 3. Why DIF (Decimation-In-Frequency) ?
  在 Dataflow Architecture 上，FFT 主要分成 DIF(Decimation-In-Frequency) 和 DIT(Decimation-In-Time)。選擇 DIF 的主要有下 : 
  * 輸入資料可直接以自然順序寫入 BRAM，不需要一開始就做 bit-reversal。
  * Butterfly 的加減法先進行，再乘上 Twiddle Factor，便於搭配單一 Butterfly PE 與單一 BRAM 的資料流。
  * 對於「每個 stage 讀取兩筆資料、運算後再寫回同一塊 BRAM」的架構，控制流程相對直觀。
  值得注意的是，DIF FFT 最後輸出的結果會是 bit-reversed 的順序，因此後續 python 驗證時需要重勳排列。
#### 4. Why Single BRAM
  在硬體上有許多設計架構，包括 Memory-Based Architecture、Pipeline Architecture、Fully Parallel Architecture等。本次使用 Single BRAM + Single Butterfly PE 的原因如下 : 
  * 控制邏輯清楚：每次從 BRAM 讀出兩筆資料，完成 Butterfly 運算後再寫回原位置。
  * 容易理解資料流：資料如何讀、如何寫、如何跨越不同 Stage，一目了然。
  缺點是速度相較Pipeline等架構更慢。然而，我們的核心目標在於優先理解架構，而非追求最高效能，因此採用此設計。
---
## 1.4 開發流程
  後續章節將依照實際開發流程逐步完成整個系統：
  1. FFT 理論
  2. 設計 Butterfly PE
  3. 設計 Twiddle ROM
  4. 設計 Address Generator
  5. 設計 Controller FSM
  6. 整合為 FFT Core
  7. 加入 AXI4-Lite 介面
  8. Vivado Package IP
  9. 建立 Block Design
  10. 匯出 .bit 與 .hwh
  11. PYNQ Overlay
  12. Python 控制 FFT
  13. 功能驗證與除錯
---
## 1.5 Chapter Review
  本章建立了Project的核心目的與架構，要點整理如下 : 
  * 本專案不是單純「寫一個 FFT」，而是完成一個可重複使用的 FFT IP Core。
  * 選擇 64-point、Radix-2 DIF、Single BRAM、Single Butterfly PE，是為了在硬體資源與學習價值之間取得平衡。
  * 最終目標是讓 Python 透過 AXI4-Lite 控制 FPGA 上的 FFT，而不是直接在軟體中實作 FFT。
  * 整個流程涵蓋 DSP、數位電路、FPGA 設計、Vivado、AXI 匯流排以及 PYNQ 軟硬體整合，是一個完整的 SoC 開發實例。

