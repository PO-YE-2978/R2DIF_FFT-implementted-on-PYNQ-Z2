Chapter 9 - Vivado 建立 AXI Wrapper 和 SoC Design Flow
===
在前面的章節中，我們介紹到 FFT Core + AXI4-Lite Wrapper = 可以被 PYNQ 控制的 FPGA IP。而本章將會說明如何藉由 Block Design 將 PS (ARM Processor) 、PL (FFT Core IP) 
和 AXI 介面等相關 IP 串聯起來，完成整個 SoC 架構。完整的開發流程如下 : 

<p align="center">
  Verilog FFT -> Vivado IP Package -> Block Design -> Zynq PS + AXI -> Export Hardware -> PYNQ Overlay -> Python Control
</p>

## 9.1 Block Design 前置確認步驟
1. 在 create project 中，確認 Default Part 中按 ```boards``` 選擇的是 PYNQ Z2 板子。 
2. 將 FFT_top 包裝成 AXI IP 前要先確認 FFT 功能正常 (否則後續 Debug 會較麻煩，Error 可能出自於 FFT Algorithm、AXI 或 PYNQ 等)。
   > 測試功能是否正確可先寫 testbench 再驗證波型。
3. 主頁中點選 Setting -> IP -> Repository，確認 FFT IP 是否已經加入。(若沒有，手動加入並點選 Refresh-All)

## 9.2 Block Design Flow (SoC Structure Data Flow)
確認前面步驟都是正確的後，接下來就可以把 IP 串在一起了。
1. 主頁中點選 ```create block design```， default name 維持 design_1 即可。
2. 左邊生成的 Diagram 中，加入以下 IP :
   <div align="center">
     
     | IP Block | 意義 | 作用 |
     | :--: | :--: | :--: |
     | ZYNQ7 Processing System | ARM CPU | 執行 PYNQ、控制 FFT |
     | Processor System Reset | 系統 Reset 管理 | 確保所有 IP 正確初始化 |
     | AXI SmartConnect | AXI bus 匯流排交換器 | 將 CPU 連到 FFT IP、BRAM Controller |
     | AXI BRAM Controller | AXI ↔ BRAM 介面轉換 | 讓 CPU 能讀寫 BRAM |
     | Block Memory Generator | BRAM | 儲存 FFT Input、中間結果、Output |
     | bram_switch_v1_0 | BRAM 控制權切換器 | 決定 CPU 或 FFT 誰控制 BRAM |
     | my_fft_top_ip_v1_0 | FFT Accelerator | 執行 64-point FFT 計算 |
   
   </div>

  * ZYNQ : 我們 SoC 的 CPU，主要工作負責執行 Python、控制 FPGA，流程 : 
    > Python -> ARM CPU -> AXI Bus ->FFT IP
  * Processor System Reset : 讓所有 IP 都在正確的時間 Reset。
    > 若沒有 reset : FSM 可能從 State3 開始，或 BRAM 仍保留舊資料，故 Reset IP 會先等 Clock Ready -> 解除 Reset -> 所有 IP 開始工作。
  * AXI SmartConnect : AXI Bus，決定 CPU 現在要跟哪一個 IP 溝通。
    > 若沒有 BRAM (其他IP等)，FFT 可以直接連 CPU，就不需要 AXI Bus。但我們的架構有 BRAM，CPU 需要同時控制 FFT 和 BRAM，因此需加入 AXI Bus。
  * AXI BRAM Controller : 將 CPU 的指令轉成 BRAM address，讓 BRAM 能讀寫出正確資料。流程 : 
    > AXI Address -> BRAM Address -> BRAM Enable -> Write Enable -> BRAM Data
  * Block Memory Generator : BRAM，包含 Port A 和 Port B。
    > Port A :  前面接 bram_switch_v1_0 (Multiplexer），決定 Port A 是由 AXI BRAM Controller 還是 FFT IP 控制。
    
    > Port B : 沒有經過 Switch，直接拉到 FFT Core。
  * bram_switch_v1_0 : 這部分是我們另外寫的 (另一個獨立於 FFT Core 的 Verilog code，包裝方法如 Chapter 8 所示)，因為 BRAM Port A 一次只能收一組控制訊號，但 CPU 和 FFT IP 都需
    要使用 (CPU 要寫 Input、讀 Output data, FFT 則是計算 Intermediate result，兩者都是 BRAM 的 Master)，因此需要一個 switch (MUX) 決定現在 BRAM 接收誰的訊號。
    > FFT 開始前 : switch mode 為 CPU；等 FFT 開始後，switch mode 為 FFT；計算完成以後，switch mode 再切回 CPU。
    
    > 我們現在用的 Dual Port BRAM 其實可以 CPU 接 port A，FFT 接 port B。但在我們的設計上，port A 和 B 是為了讓 butterfly PE 同時讀兩筆資料而設計，
    因此我們在 port A 加 switch 決定 Master，port B 保留直接與 FFT 相接。
  * my_fft_top_ip_v1_0 : 我們上一章包裝過的 FFT Core IP。

  這樣的架構下，Data Flow 主要可以分成三個階段 : 
  
  <div align="center">
    
  | | Stage | Data Flow | Port A Owner |
  | :--: | :--: |:--: | :--: |
  | Phase 1 | CPU Loading (FFT 未開始, switch 為 CPU) | CPU -> Port A -> BRAM | CPU （AXI BRAM Controller）|
  | Phase 2 | FFT Running (Switch 轉成 FFT) | FFT -> Port A + Port B -> BRAM | FFT Core |
  | Phase 3 | CPU Reading (Switch 切回 CPU) | BRAM -> Python | CPU （AXI BRAM Controller）|

  </div>

## 9.3 Block IP Detail
1. 需要手動拉線的 IP :
前面已介紹整體的資料流概念，但在點選 ```Run Connection Automation```前，我們需要將特別設計的線先拉在一起，包括
  * AXI BRAM Controller -> bram_switch_v1_0
  * my_fft_top_ip_v1_0 -> bram_switch_v1_0
  * bram_switch_v1_0 -> Block Memory Generator
  * my_fft_top_ip_v1_0 -> Block Memory Generator

2. I/O 說明 :
   基本上命名相當直觀，在了解 Data Flow 的情況下，將相同名稱連在一起即可。其中，每個 IP 最主要的訊號線包括 :
   <div align="center">
    
    | 名稱 | 意義 | 功能 |
    | :--: | :--: |:--: |
    | XXX_addr_a | Port A XXX element operating address | 要操作哪一個 Memory Address |
    | XXX_wrdata_a| Port A XXX element write data | 如果現在是寫入，則要寫入的內容 |
    | XXX_rddata_a | Port A XXX element read data | BRAM 回傳的資料 |
    | XXX_we_a | Port A XXX element write enable | 現在是否為 Write |
    | XXX_en_a| Port A XXX element enable | XXX element 是否啟動 |
    | XXX_clk_a | Port A XXX element clock | XXX element Clock |
    | XXX_rst_a | Port A XXX element reset | XXX element Reset |

    </div>

最後點選```Run Block Automation```、```Run Connection Automation```，會自動將 clock 和 reset 訊號線等自動拉再一起 (若有些IP漏掉則手動接上)。
> 舉例來說，PS 端提供 M_AXI_GP0 (Master AXI)，而 FFT Core 則有 S_AXI (Slave AXI)，自動繞線後兩者就會接在一起。
接線結果如下圖所示 :
<p align="center">
  <img width="1557" height="773" alt="image" src="https://github.com/user-attachments/assets/c300ea28-2c4a-46a1-bdd8-a19ed2c03f87" />
</p>

## 9.4 Address Assignment and Final Check
Diagram 設計完後，點選旁邊的 Address Editor，應該會看到下圖 : 
<p align="center">
  <img width="500" height="110" alt="image" src="https://github.com/user-attachments/assets/dca8a62c-c6fe-4dd0-8a1c-6a409d2fd4de" />
</p>

1. axi_bram_ctrl_0 (AXI BRAM Controller)
   * 屬於 memory type 的 slave，其中 offset address 指的是對於 CPU 而言，BRAM 存的位置 (0x4000_0000 ~ 0x4000_1FFF) 共 8k Byte (2048 words)。
     > 舉例來說，當 CPU 讀 0x4000_0000，AXI BRAM Controller 就會將其轉換成 BRAM Address = 0 (第 0 個 element)。
   * 寫 python 時，我們會用```MMIO(0x40000000,8192)```代表 Memory 所在位置跟大小。若寫```mmio.write(4,999)```，就代表 CPU 對 addr 0x40000004 寫 999，i.e. BRAM[1] = 999。
2. FFT IP
   * 屬於 AXI Register 的 slave，也就是會將 slv_reg0 map 到 0x43C00000，slv_reg1 到 0x43C00004 ... 以此類推。
     > 因為 slv_reg[0] = start，因此若在 python 寫 ```fft.write(0,1)``，代表 CPU 對 addr 0x43C00000 寫 1，也就是 fft 開始的意思。
     
此觀念即為 Memory Mapping : CPU 看的是 0x40000000，而 BRAM 看到 Address = 0，也就是透過 AXI BRAM Controller 進行 Address Translation。這部分對應到 PYNQ 中提供的 MMIO (Memory Mapped I/O) function。這也是為什麼 Vivado 的 Address Editor 對 SoC 設計非常重要，它定義了每個 AXI Slave 在 CPU 記憶體空間中的位置。

確認完這些點後，對這個 block design (design_1) 右鍵，點```Create HDL Wrapper``` -> ```Let Vivado manager wrapper and auto-update```。
接著選 Generate Bitstream，並將 design_1_wrapper.bit (描述FPGA配置) 和 design_1.hwh (用於硬體描述) 存起來，就可以進入 PYNQ Overlay 了。

## 9.5 Chapter Review
本章主要介紹了 Block Design 的內容和步驟，包括我們整個專案的 data flow、各個 IP 功能與如何連線等等。對於完整 SoC FPGA Accelerator 的開發流程而言，不是只有寫 Verilog 而已，更要了解
<p align="center">
  Algorithm -> RTL -> IP -> AXI -> Vivado System -> PYNQ Software
</p>

等一系列繁瑣細節。下一章開始我們將介紹 PYNQ Overlay、python data transmittion 並進行驗證和結果分析。
