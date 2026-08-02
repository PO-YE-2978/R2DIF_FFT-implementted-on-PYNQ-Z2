# A complete hardware/software co-design project featuring Verilog RTL implementation, AXI4-Lite IP packaging, BRAM-based memory architecture, custom BRAM switch, and PYNQ-based validation of a 64-point Radix-2 DIF FFT accelerator.

## 簡短說明
本專案實作並驗證 一個 64-point Radix-2 Decimation-In-Frequency (R2DIF) FFT 硬體 IP，採用單一資料 BRAM（雙埠）策略，實作於 Xilinx Zynq SoC 平台並以 PYNQ-Z2 板卡進行功能驗證與控制。FFT 核心以 Verilog 撰寫，並封裝為可於 Vivado 中引入的 IP / Overlay，由 PYNQ (Python + Jupyter Notebook) 在 PS 端做控制與驗證。

## 主要特性
- 64-point R2DIF FFT 硬體實作（定點表示）
- 單一 BRAM（雙埠）資料存取架構
- Twiddle ROM 作為旋轉因子儲存
- 封裝為 Vivado IP（可整合至 Zynq block design）
- PYNQ Python 範例 / Notebook 用於載入 bitstream 與測試

## Stack
- 語言：Verilog（RTL）、Jupyter Notebook (python)（驗證 / 教學）
- 開發環境：Xilinx Vivado 2019.2（建立/封裝 IP、產生 bitstream）、PYNQ ver3.1.1（在板上執行 Notebook 驗證）

## 儲存庫重要檔案與目錄
```
Chapter 01 - Project Overview.md
Chapter 02 - Architecture Ananlysis.md
Chapter 03 - FFT RTL Code.md
Chapter 04 - R2DIF FFT Algorithm Mapping.md
Chapter 05 - Butterfly Processing Element (PE).md
Chapter 06 - BRAM Architecture and Address Generator.md
Chapter 07 - FSM Controller Design.md
Chapter 08 - FFT Core Packaging.md
Chapter 09 - AXI Wrapper and SoC Design Flow.md
Chapter 10 - PYNQ Python  FFT IP Control.md
Chapter 11 - Project Review.md
README.md
code/
  Half_adder/           # 範例小模組（功能驗證）
  R2DIF_FFT/
    ip_repo/            # Vivado IP repo metadata (for packaged IP recognition)
    source/
      bd/               # Block design related files (tcl / exported BD)
      IP/               # Additional packaged IP (e.g., BRAM switch)
      PYNQ/             # PYNQ overlay files (.bit, .hwh) and notebooks
      Verilog/          # RTL sources (core implementation)
        addr_generator.v
        butterfly_pe.v
        complex_mult.v
        controller_fsm.v
        fft_butterfly.v
        fft_top.v
        tb_fft_top.v
code/readme.md
```

## 如何協作
- controller_fsm 控制整個 FFT 流程（READ -> PE 計算 -> WRITE），並透過 stage 與 b_idx 引導 addr_generator 產生對應 BRAM 位址與 twiddle ROM 的位址。
- twiddle_rom 提供複數旋轉因子，fft_butterfly / butterfly_pe 使用 complex_mult 及加減器完成每一組蝴蝶運算。
- fft_top 整合上述模組並暴露 BRAM Port A/B 與控制訊號（start / busy / done）給外部（例如 AXI wrapper 或直接 BRAM controller）。

## 版本需求
- Xilinx Vivado 2019.2（版本需支援你的板卡與 IP 開發）
- PYNQ（對應 PYNQ-Z2 image）

## 快速上手（從原始碼到板卡）
1. 在 Vivado 中建立新 project，加入 sources：
   - 將 `code/R2DIF_FFT/source/Verilog/*.v` 加入為 RTL sources。
   - 若使用 IP packaging，依 `code/R2DIF_FFT/ip_repo` 裡的 metadata 封裝 IP 並安裝到 Vivado IP repo。
2. 封裝為 IP：
   - 使用 Vivado 的 "Package IP" 指引，封裝 `fft_top` 作為 AXI peripheral（必要時新增 AXI4-Lite 控制介面或 AXI BRAM / wrapper）。
3. 建立 Block Design：
   - 新增 Zynq7 Processing System、AXI interconnect、BRAM controller 等，並將 FFT IP 與 BRAM 連線。
   - 產生 bitstream（Generate Bitstream）。
4. 部署到 PYNQ：
   - 從 Vivado 取得 `.bit` 與 `.hwh` 檔案 (或從 `code/R2DIF_FFT/source/PYNQ/`取得)，並放到 PYNQ 板的 overlay 目錄下，檔名需一致（例如 `r2dif_fft.bit` 與 `r2dif_fft.hwh`）。
   - 在 PYNQ 上啟動 Notebook，載入 Overlay 並透過 MMIO / 驅動控制 start 與讀取結果（請參閱 Chapter 10 的範例）。

## PYNQ 範例（概念性）
```python
from pynq import Overlay
import time

overlay = Overlay('/home/xilinx/overlays/r2dif_fft/r2dif_fft.bit')
fft_ip = overlay.r2dif_fft  # IP 名稱視 HWH 定義而定

# 範例：啟動並等待完畢（register map 需依實際封裝定義）
fft_ip.write(0x00, 0x1)   # 假設 0x00 控制位，bit0 = start
while not (fft_ip.read(0x00) & 0x2):
    time.sleep(0.001)
# 讀回結果（依實際 BRAM / register map）
```
注意：上述為概念性範例，實際的 base address 與 offsets 依你在 Vivado 中的 AXI 封裝與 register map 而定。請參閱 repo 中的 `Chapter 10 - PYNQ Python  FFT IP Control.md` 取得更詳細的範例與寄存器定義。

## 測試與驗證建議
- 在 PYNQ 板上執行 Notebook，自動化啟動/讀回並計算數值誤差（例如均方根誤差）。

## 注意事項與部署備註
- `code/readme.md` 已提示：`.bit` 與 `.hwh` 檔名需一致，例如：
  - half_adder -> `half_adder.bit`, `half_adder.hwh`
  - fft -> `r2dif_fft.bit`, `r2dif_fft.hwh`
- 請確認 `code/R2DIF_FFT/ip_repo` 的 metadata 與 XML 在你使用的 Vivado 版本中可被識別，否則 Vivado 無法找到自製 IP。

## 參考（repo 內文件）
請參閱 repo 中的章節文件取得更詳細之設計與實作細節：
- Chapter 01 ~ Chapter 11（各章節包含設計理念、映射、PE 設計、BRAM 結構、FSM 控制、IP 封裝與 PYNQ 操作）
