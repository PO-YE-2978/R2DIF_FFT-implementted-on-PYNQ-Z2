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

## 3.2 Top Module : fft_top.v
---
