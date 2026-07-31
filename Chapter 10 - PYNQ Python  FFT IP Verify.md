Chapter 10 - PYNQ Python 驗證 FFT IP：Overlay 載入、資料傳輸與結果分析
===
截至目前為止，我們已經完成

<p align="center">
  FFT RTL -> AXI4-Lite IP -> Vivado Block Design -> Generate Bitstream (.bit + .hwh)
</p>

本章將介紹如何讓軟體控制這個硬體，並且驗證硬體結果是否正確。有關 PYNQ 相關介紹，可在 AMD 的官網查詢，網址如下 : 
https://www.pynq.io/。

至於如何啟用板子或是將檔案上傳，可以參考以下教學網站 : 
https://www.bilibili.com/video/BV1KY4y1x7Mk/?spm_id_from=333.1387.search.video_card.click。

## 10.1 PYNQ 和 Overlay 簡介
1. PYNQ 介紹
   
   PYNQ（Python Productivity for Zynq）是一個由 AMD 推出的開源專案與生產力框架，核心概念為 Python + Zynq。它讓設計人員能透過 Python 語言和 Jupyter Notebooks 環境，直接對嵌入式系統與      FPGA 進行開發與互動控制。其中，Zynq FPGA 內部包含 PS (Processing System, 也就是 ARM Cortex-A9 CPU ) 端和 PL (Programmable Logic, Verilog 如我們的 FFT Core)端。
   其核心的操作概念就是藉由 Python 控制 ARM，而 ARM 透過 AXI 控制 FPGA。

2. Overlay 是什麼 ?
   
   Overlay 是在 PYNQ（Python Productivity for Zynq）框架中，用來設定、擴展和控制 FPGA 可編程邏輯（PL, Programmable Logic）的自訂硬體設計，簡單來說可以想像成 Hardware Library。
   * 舉例來說，在 Jupyter Notebook python 寫  ```overlay = Overlay("r2dif_fft.bit")``` 代表 :
     > 1. 將硬體 (.bit) 下載到 FPGA。 *.bit 包含 BRAM configuration 和 Routing 等。
     > 2. 讀取硬體資訊 (.hwh)。 *.hwh 包含 IP 名稱、AXI address 等。

   * 上一章說明要保留 design_1_wrapper.bit 和 design_1.hwh，匯入 Jupyter Notebook 前需將兩者的名字設為相同。
