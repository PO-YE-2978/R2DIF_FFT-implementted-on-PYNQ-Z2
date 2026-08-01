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
   * 產生完測試訊號後，下一步就要將 data 寫入 BRAM，流程如下 :
     > Python -> MMIO -> 0x40000000 + i × 4 -> AXI BRAM Controller -> BRAM Address = i -> Block Memory
   ```python
    for i, sample in enumerate(x_q15):
      bram.write(i * 4, pack_q15(sample.real, sample.imag))
   ```
   * 如同上一章講過的，AXI BRAM Controller 會自動將收到的 Byte Address 轉換成 BRAM 看得懂的 Word Address。

7. 啟動 FFT

   FFT 啟動採用的是 Memory-Mapped Register 控制 : 
     1. 首先 Reset 後，在解除 Reset ( 重置系統 ) :
     ```python
       fft.write(CTRL, SOFT_RESET)
       fft.write(CTRL, 0)
     ```
     2. 寫資料進 BRAM ( 第 6 點 ) :
     ```python
      for i, sample in enumerate(x_q15):
        bram.write(i * 4, pack_q15(sample.real, sample.imag))
     ```
     3. 開始 FFT :
     ```python
      fft.write(CTRL, SOFT_RESET)
      fft.write(CTRL, 0)
     ```
     4. 後續執行步驟 :
        > IDLE -> LOAD -> BUTTERFLY -> NEXT STAGE -> DONE

8. Done Bit Reading
   
   Python 不知道 FFT 什麼時候做完。因此利用 ```while true``` loop 搭配 time out 設定偵測 :
   ```python
    while True:
      status = fft.read(STAT)
      if status & DONE_MASK:
          break
      if time.monotonic() > deadline:
          raise TimeoutError(f"FFT timeout: 0x{status:08X}")
      time.sleep(0.001)
   ```

9. 讀回 FFT 結果

   當第 8 步 DONE = 1 跳出迴圈後 (FFT 完成)，Python 透過 bram.read(...) 再讀回 64 筆資料。流程 : 
   > BRAM -> AXI BRAM Controller -> MMIO -> Python
   
   ```python
    hw_raw = np.array([
      unpack_q15(bram.read(i * 4) & 0xFFFFFFFF)
      for i in range(N)
    ])
   ```
10. Bit-Reversal
    * 前面說過我們的 FFT 採用 Radix-2 DIF。其特性就是 Output 為 Bit-Reversed, for example :
      > Input : [ 0 1 2 3 4 5 6 7] , Output [ 0 4 2 6 1 5 3 7 ]
    * 因此我們寫一個 bit reversed function 重新排列並得到 output : 
    ```python
      hw_fft = np.array([
        hw_raw[bit_reverse(k)]
        for k in range(N)
      ])
    ```

11. 與 NumPy FFT 比較
    * 在 python 端計算 FFT 採用內建 function : ```np.fft.fft()```。
    * 計算 error = hw_fft - sw_fft 並看差異。(以 square function 為例，Max absolute error: 0.00029509)。
    * 最後利用 matplotlib 將相關資料以圖片的方式匯出，下方以 Input 為 square function 的測試結果 :
      <div align="center">
        <img width="1211" height="780" alt="image" src="https://github.com/user-attachments/assets/13f89e5c-b62b-49f6-8720-123431b5f8dc" />
      </div>
    * 從圖中可看到，上方為 Input pattern，下方是 output result。如同我們的預期，output 是 sinc function ( FFT 結果滿足共軛對稱，N = 32 為 Nyquist frequency, 其中 X[1] 對應 X[63], 
      X[2] 對應 X[62] 以此類推直到 X[31] 對應 X[33]。若要看起來像 sinc，我們可以把 X[33] ~ X[63] 移動到左側，即可看到標準的 sinc function, i,e, 中心點為 0 Hz)。
      細看可以發現，sw_fft 的 結果 與 hw_fft 幾乎重疊，說明我們硬體與軟體成功對應。

## 10.3 完整 SoC Data Flow
整個 Python 驗證流程可以總結如下 : 
<p align="center">
  Python Program -> Generate Test Signal -> Float → Q1.15 Conversion -> Pack Real / Imaginary -> 
</p>

<p align="center">
 Write BRAM (MMIO) -> AXI BRAM Controller -> Block Memory Generator -> FFT Hardware Accelerator -> BRAM Output Data -> 
</p>

<p align="center">
 Read BRAM (MMIO) -> Bit-Reversal Reordering -> Compare with NumPy FFT -> Plot & Verify Correctness
</p>

## 10.4 Chapter Review
本章完成了整個專案的最後一步：Hardware/Software Co-Verification。透過 PYNQ 的 MMIO 介面，Python 不僅負責產生測試訊號，也負責將資料寫入 BRAM、控制 FFT IP 的啟動與重置、等待運算完成、讀回結果，最後利用 NumPy FFT 作為 Golden Reference 進行驗證。從系統層級來看，這個流程展示了一個典型 SoC FPGA Accelerator 的工作軌跡：CPU（ARM）負責控制與管理資料流，AXI Bus 負責軟硬體之間的溝通，而 FPGA 中的 FFT Accelerator 專注於高速運算。這正是硬體/軟體協同設計（Hardware/Software Co-design）的核心思想，也是本專案最重要的學習成果之一。
