Chapter 8 - 將 FFT Core 封裝成 AXI4-Lite IP
===
在前面 Chapter 中，我們完成了 FFT Accelerator 本體，此時 FPGA 內部已經可以完成
> Input data -> 64-point FFT -> Output data

本章我們將探討如何用外部的 Python (PYNQ) 要如何控制這個 Verilog FFT。

## 8.1 AXI Interface
