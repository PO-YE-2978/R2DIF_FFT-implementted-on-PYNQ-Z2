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

<p align="center">
 | I/O port | Name | Functionality |
 | :--: | :--: | :--: |
 | Input | start | FFT Triggering signal |
 | Output | busy | FFT_is_running flag |
 | Output | done | Check if FFT is done |
</p>

上述的 signal 都會透過 AXI register 與 PYNQ python 直接溝通，確定現在硬體的情況。

## 3.3 BRAM Interface
---
在我們建立的 BRAM 中，選擇使用 Dual port 的原因是這樣 fft_butterfly 一次就可以同時讀兩個 input。以 first stage 為例，若使用 dual port 則可以同一時間讀 x0, x32，不用分開讀 => 速度提高。具體建立的流程如下 : 
1. 在IP catalog 中找到 Block Memory Generator 並點選
2. 在 component name 中改名後，將 "Single Port RAM" 改成 "Ture Dual Port RAM"
3. 到 Port A Option 和 Port B Option 中將 "Primitives Output Register" 關掉 (減少一個cycle)
4. "Enable Port Type" 都改成 "Always Enable"
