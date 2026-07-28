Chapter 8 - 將 FFT Core 封裝成 AXI4-Lite IP
===
在前面 Chapter 中，我們完成了 FFT Accelerator 本體，此時 FPGA 內部已經可以完成
> Input data -> 64-point FFT -> Output data

本章我們將探討如何用外部的 Python (PYNQ) 要如何控制這個 Verilog FFT。

## 8.1 AXI Interface
1. What is AXI Interface ?
   
   AXI 是 ARM 公司提出的一種高效能、高頻寬、低延遲的通訊協議，旨在支持複雜系統 (SoC, System on Chip) 中的高數據傳輸，能高效連結 CPU、內存控制器、外部設備和其他高性能組件。*引用自https://blog.csdn.net/weixin_39366560/article/details/138369932

   在我們的架構中，使用 AXI 的主要目的是讓 PS (Processing System, 即 ARM CPU) 和 PL (Programmable Logic, 即 FFT Core IP) 能夠互相交流。流程如下 :
   > Python -> PS (ARM Processor) -> AXI Interface -> PL (Custom IP) -> FFT Core

* AXI 介面分成 Master 和 Slave 端，其中 : 
  > ARM Processor 屬於 AXI Master 端，負責發送 address、寫入資料和讀取資料。
  
  > FFT IP 屬於 AXI Slave 端，負責接收 command 並提供 register。

2. AXI 協議差異 :

    AXI 主要分成三個變種，包括 AXI4、AXI4-Lite 和 AXI4-Stream。其中:
    * AXI4 : 適用於高性能地址映射通信。
    * AXI4-Lite (本專案使用) : 用於簡單、低吞吐量的控制接口。
    * AXI4-Stream : 用於無地址、連續傳輸的資料流。
  
   本質上來說，AXI4-Lite 就是 Memory Mapped Register，也就是 FPGA IP 裡面有一排 register。例如
   <div align="center">
     
   | Address | Function |
   | :--: | :--: |
   | 0x00 | Control Register |
   | 0x04 | Status Register |
   | 0x08 | Input Data |
   | 0x0C | Output Data |
   
   </div>

   若 Python 寫 ```fft.write(0x00,1)```，則等同於讓 control_reg = 1。

3. IP Package 流程 :
   1. 第一步先建立好 FFT Project (板子選 PYNQ Z2)，接著在 ```Tools```中點選```create and package new IP```後，在選```Package your current project```即可創建。
   2. Defalut 會產生 myip_v1_0.v 和 myip_v1_0_S00_AXI.v，此處我們將名稱改為 my_fft_top_ip，也就是 my_fft_top_ip_v1_0.v 和 my_fft_top_ip_v1_0_S00_AXI.v
      > my_fft_top_ip_v1_0.v 是最外層 wrapper，負責宣告 IP 的外部 port 並把 AXI register 和外部訊號接起來
      
      > 而 my_fft_top_ip_v1_0_S00_AXI.v 是處理 AXI slave register 和 user logic 的地方，包含 AXI read/write FSM 和 slave registers 等。
   3. 首先在這兩個 ip package file 中補上 BRAM 的 port (詳見 code)
      > 我們的架構中，data 是先存入 BRAM，接著讓 FFT 以 Dual Port 的型式將資料進行讀寫，最後 python 看的是 BRAM 中的結果。
   
      > 又因為 BRAM 獨立於我們的電路，因此算是外部 port，因此在 package 時需要保留腳位已進行溝通。
   4. 在```my_fft_top_ip_v1_0.v```的 ```my_fft_top_ip_v1_0_S00_AXI_inst``` (instance) 中補上 BRAM Port。
   5. 在```my_fft_top_ip_v1_0_S00_AXI.v``` 的底部補上控制訊號，同時加入我們的 FFT_top module。
      > 值得注意的是，在 default 產生的 code 中，我們將 2'h1   : reg_data_out <= slv_reg1; 的 slv_reg1 改成 output result。
   6. 在 Package IP 的地方，確定所有 Package Steps 皆有綠色的勾 (否則照提示點選直到完成) 後，在 Review and Package 中點選 Re-Package IP 後即包裝完成。

   * Package 過程的 code 部分較為複雜，可先查看 Half_Adder Project 中 package 的方法再進行延伸。

4. 
