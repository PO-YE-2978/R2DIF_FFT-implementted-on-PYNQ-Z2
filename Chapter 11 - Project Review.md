Chapter 11 - 整體專案回顧與未來優化方向
===
本次專案我們已經完整建立一套 64-point FFT FPGA Accelerator System。從最初的 FFT Algorithm，一路發展到 Python → AXI → FPGA → FFT Hardware → Output。
整個流程涵蓋了 FPGA Accelerator 開發中所需的各種概念，包括 :
* DSP 演算法硬體化
* RTL 設計
* Memory Architecture
* FSM Controller
* IP Integration
* AXI Interface
* PYNQ Software Control

本章將針對整個專案架構、設計思維、目前架構優缺點以及未來可以如何優化等進行回顧探討。

## 11.1 FFT Accelerator 架構總覽
回顧 Chapter 10 的流程圖，我們可以將整個架構由上至下分成三個區塊 : 
<div align="center">
  
| Layer | 功能 | 細節描述 |
| :--: | :--: | :--: | 
| Software Layer | 負責 Python、PYNQ、Jupyter Notebook | 載入 bitstream、啟動 FFT、傳送 I/O |
| Interface Layer | 負責 AXI4-Lite | 讓 ARM 與 FPGA 溝通、處理 Register Mapping 和 Start / Done Control 等 |
| Hardware Layer | 負責 FFT Computation | 包括各個 sub-module 如 Butterfly、Address Generator |
</div>
