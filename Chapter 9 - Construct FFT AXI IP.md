Chapter 9 - Vivado 建立 FFT AXI IP 與 PYNQ Overlay 整合流程
===
在前面的章節中，我們介紹到 FFT Core + AXI4-Lite Wrapper = 可以被 PYNQ 控制的 FPGA IP。而本章將會說明如何藉由 Block Design 將 PS (ARM Processor) 、PL (FFT Core IP) 
和 AXI 介面等相關 IP 串聯起來，完成整個 SoC 架構。完整的開發流程如下 : 

<p align="center">
  Verilog FFT -> Vivado IP Package -> Block Design -> Zynq PS + AXI -> Export Hardware -> PYNQ Overlay -> Python Control
</p>

## 9.1 Block Design 前置確認步驟
