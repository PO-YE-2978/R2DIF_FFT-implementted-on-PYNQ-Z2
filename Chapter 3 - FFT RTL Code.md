Chapter 3 - FFT RTL Code analysis in detailed
===
本章將會進入到實際的 Verilog code 設計，包括了解每個 module 的功能、接線、資料流等等。

## 3.1 Modules that we used
---
首先回顧 Chapter 2 中 2.6 的 block diagram，我們會使用到的 module 包括
* fft_top.v
  * controller_fsm.v
  * addr_generator.v
  * fft_butterfly.v
    * complex_multi.v
    * twiddle_rom.v

分開設計而不寫在一起的原因是這樣比較好 Debug，同時也會讓程式碼更有規則和架構性。以下將一步步介紹每個 module 的內容，程式碼可參考 "code" folder。

## 3.2 Top Module : fft_top.v Interface
---
Top Module 的主要功能是負責整合所有 module。其中的 I/O Interface 如下表所示

<div align="center">
 
| I/O port | Name | Functionality |
| :--: | :--: | :--: |
| Input | start | FFT Triggering signal |
| Output | busy | FFT_is_running flag |
| Output | done | Check if FFT is done |
</div>

上述的 signal 都會透過 AXI register 與 PYNQ python 直接溝通，確定現在硬體的情況。

## 3.3 BRAM Interface
---
在我們建立的 BRAM 中，選擇使用 Dual port 的原因是這樣 fft_butterfly 一次就可以同時讀兩個 input。以 first stage 為例，若使用 dual port 則可以同一時間讀 x0, x32，不用分開讀 => 速度提高。具體建立的流程如下 : 
1. 在IP catalog 中找到 Block Memory Generator 並點選
2. 在 component name 中改名後，將 "Single Port RAM" 改成 "Ture Dual Port RAM"
3. 到 Port A Option 和 Port B Option 中將 "Primitives Output Register" 關掉 (減少一個cycle)
4. "Enable Port Type" 都改成 "Always Enable"
5. "Write Width" 和 "Read Width" 改成 32 (bit)

* 第五點中改成 32 的原因是 : 根據前面定義，每個點包含 32 bit data (16 bit imag + 16 bit real part)。這樣每筆 data 就會佔有 4 byte 的空間。
## 3.4 BRAM Address Mapping
---
在 PYNQ Z2 board 中，所使用的 CPU 和 AXI BUS 為 32 bit 的 Byte address。因為我們每筆 data 佔 4 byte， 所以若要選擇對應的 bram value，需要在原先的 bram address 上再乘 4 (shift left 2 bit)。舉例來說，原先要取第 0 個和第 1 個 point 的 value，此時 bram address 就應該是 0x0 和 0x4 。而在後續的 address generator 中，我們用來選擇 bram address 的 index (addr_a) 共有 6 bit (因為 $log_264 = 6$ 個stage)。綜上所述，為了對其 32 bit 的 AXI interface，我們最後再輸出的 address 應該包裝成

<p align="center">
  {24'd0, addr_a, 2'b00}
</p>

## 3.5 Controller FSM Architecture
---
此 module 為控制整個 FFT 的核心，主要的 stage 有 6 個，包括 S_IDLE S_READ S_WAIT1 S_WAIT2 S_WRITE S_DONE。以下將分別介紹各個 stage 的作用 :
1. State 1：S_IDLE
   > Initial state. 當 "start" 訊號開始。 State transition 到 S_READ。
2. State 2：S_READ
   > 目的 : 啟動 BRAM Read。
   > 控制 "bram_ena" 和 "bram_enb" 使 Port A 讀 Xa、Port B 讀 Xb 並放入 Butterfly PE。
3. State 3：S_WAIT1 / S_WAIT2
   > 目的 : 等 BRAM 讀資料。
   * BRAM 是 synchronous memory 而非 combinational memory，也就是給出 address 後需要等 clock latency 後才能得到 data。
4. State 4：S_WRITE
   > 目的 : Butterfly PE 算完 Ya 和 Yb, 之後寫回 BRAM。
5. State 5：S_DONE
   > 目的 : FFT 算完，通知 PYNQ / Software。

## 3.6 Address Generator
--- 
* 目的 : 用以計算此時要放入 Butterfly PE Value 的 address。
* 透過 "stage" 和 "b_idx" 產生 "addr_a", "addr_b", "twiddle_addr"。
  > FFT 每個 stage 需要的偏移量不同。以我們的例子為例，Stage 0 distance = 32, Stage 1 distance = 16 ...

## 3.7 Butterfly PE
---
* 目的 : 將 Xa, Xb 和 twiddle factor W 做運算，得到 output Ya, Yb。
* 包含 : Addition, Subtraction, Complex multiplier

## 3.8 Complex Multiplier
* 目的 : 計算複數乘法 : 即 $(a+jb)(c+jd)$, 其中 real part 為 $ac-bd$, imaginary part 為 $ad+bc$ 。

## 3.9 Twiddle ROM
* 目的 : 儲存 twiddle factor $\bf{W}_N^k$ 的 value。

## 3.10 Chapter Review
本章建立了一個完整 R2 DIF Single Memory Based FFT 所需要的 module，其中
* controller_fsm 決定時間
* addr_generator 決定位址
* butterfly 決定數學運算
* BRAM 提供資料儲存
* twiddle_rom 提供旋轉係數

具體的 Dataflow 如下

<p align="center">
Start -> Controller FSM -> Address Generator -> BRAM Read -> Xa , Xb -> Butterfly PE
 -> Complex Multiply -> BRAM WriteBack -> Next butterfly -> Next stage -> ... -> done
</p>
