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
