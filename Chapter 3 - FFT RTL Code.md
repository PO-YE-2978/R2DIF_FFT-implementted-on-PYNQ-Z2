FFT RTL Code analysis in detailed
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
