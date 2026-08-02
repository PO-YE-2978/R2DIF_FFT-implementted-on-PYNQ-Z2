本專案主要使用的是 R2DIF_FFT 資料夾，而 Half_adder 則是用一個簡單的 module 測試完整的 data flow 是否可以運行。其中，資料夾內包含 : 
* ip_repo
  > 用來幫助 Vivado 辨識我們包裝的 IP。
* source
  * bd
    > block design 的相關資料 (如 .tcl)。
  * IP
    > BRAM switch 是額外寫並包成 IP 的，此處另附。
  * PYNQ
    > 在 PYNQ Z2 上使用需要的檔案。
    * .bit 跟 .hwh 需改成同名, i.e.
      * half adder 改成 : half_adder.bit, half_adder.hwh。
      * fft 改成 : r2dif_fft.bit, r2dif_fft.hwh。
    * FFT 的 python code 只需看最後一個 block。
  * Verilog
    > module code。
