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
   
   PYNQ（Python Productivity for Zynq）是一個由 AMD 推出的開源專案與生產力框架，核心概念為 Python + Zynq。它讓設計人員能透過 Python 語言和 Jupyter Notebooks 環境，直接對嵌入式系統     與 FPGA 進行開發與互動控制。其中，Zynq FPGA 內部包含 PS (Processing System, 也就是 ARM Cortex-A9 CPU ) 端和 PL (Programmable Logic, Verilog 如我們的 FFT Core)端。
   其核心的操作概念就是藉由 Python 控制 ARM，而 ARM 透過 AXI 控制 FPGA。

2. Overlay 是什麼 ?
   
   Overlay 是在 PYNQ（Python Productivity for Zynq）框架中，用來設定、擴展和控制 FPGA 可編程邏輯（PL, Programmable Logic）的自訂硬體設計，簡單來說可以想像成 Hardware Library。
   * 舉例來說，在 Jupyter Notebook python 寫  ```overlay = Overlay("r2dif_fft.bit")``` 代表 :
     > 1. 將硬體 (.bit) 下載到 FPGA。 *.bit 包含 BRAM configuration 和 Routing 等。
     > 2. 讀取硬體資訊 (.hwh)。 *.hwh 包含 IP 名稱、AXI address 等。

   * 上一章說明要保留 design_1_wrapper.bit 和 design_1.hwh，匯入 Jupyter Notebook 前需將兩者的名字設為相同。

## 10.2 FFT 驗證流程和 Python 角色:
  在我們的 SoC 架構中，Python 並非直接控制 FPGA，而是透過 MMIO (Memory Mapped I/O, 見前一章) 對 AXI Register 以及 BRAM 做 Memory Mapping 存取。流程圖如下 : 
  <p align="center">
    <img width="512" height="294" alt="image" src="https://github.com/user-attachments/assets/515e5668-4a26-4cfa-bab5-33ec33dc4b3d" />
  </p>

  後續的介紹將以順著 code 的形式一步步說明如何實現 Hardware/Software Co-Verification。
  
1. 建立 MMIO 介面
   * 上一章我們說 FFT 的 base address = 0x43C00000, BRAM 則是 0x40000000。此處我們透過 MMIO 建立 Python 與 FPGA 的連線方便後續控制: 
   ```python
    FFT_BASE = 0x43C00000
    BRAM_BASE = 0x40000000

    fft = MMIO(FFT_BASE,0x10000) // base address = 0x4300_0000, 大小為 0x10000
    bram = MMIO(BRAM_BASE,0x1000) // base address = 0x4000_0000, 大小為 0x1000
   ```
2. FFT Register 控制和定義
   * 此處說明 FFT Register 的位置，Python 只需要控制這些 Signal 即可，儲存的位置可以直接與我們的 packaging 對應 (Chapter 8.2.7)
   ```python
    CTRL=0x00           // Control Register 的位置，也就是 Chapter 8 中的 slv_reg0[0]
    STAT=0x04           // State Register 的位置，也就是 Chapter 8 中的 slv_reg1[0]

    START=0x01          // Start 存在 Control Register 的 bit 0 
    SOFT_RESET=0x02     // Soft_reset 存在 Control Register 的 bit 1 

    DONE_MASK=0x02      // DONE 存在 State Register 的 bit 1 
   ```
3. Fixed-point Q1.15
   * 之前說過我們的 Hardware 採用 Q1.15。為了有相同輸入，我們會也將 Python 的 floating point 轉成 16-bit Fixed Point。
   ```python
    q15_int() // 將 value mapped 到 [-32768, 32767]
   ```
4. Real and Imaginary value packaging
   * 如同之前所講，最終 output value 會是 32-bit Word (16 bit Imag + 16 bit Real)，此處寫一個 function 將兩者 cascade 在一起。
   ```python
    pack_q15() // 輸出為 [16 bit Imag + 16 bit Real]
   ```
5. 測試訊號產生
   * 最簡單驗證的測試訊號包括 :
     <div align="center">
      
     | Input Pattern | Output Pattern |
     | :--: | :--: |
     | Constant | DC Impluse |
     | Square wave | Sinc Function |
     | Sinc Function | Square wave |
     
     </div>
    * Code 上可參考 ```Generate real-valued input...``` block。
6. 將資料寫入 BRAM
