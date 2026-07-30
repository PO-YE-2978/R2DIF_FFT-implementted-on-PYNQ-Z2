Chapter 7 - Controller FSM Design：從 State Machine 到 FFT Execution Flow
===
在前面章節中，我們已經完成
  * FFT Data Path 的分析 (BRAM -> Butterfly PE -> BRAM)
  * Address Generator 如何產生資料位置
  * Butterfly 如何完成 FFT 運算
  * Twiddle ROM 如何提供旋轉因子
此處我們將介紹如何將這些概念串聯起來 (Controller FSM)

## 7.1 FSM 在 FFT 中的角色和設計概念
一個好的設計應將 Control Path (FSM) 和 Data Path (前面的所有 module) 拆開設計。所謂的 Control Path 單純處理資料在什麼時間應該做什麼，而 Data path 則是負責資料如何運算。
在我們的架構中，進行一次 FFT 的 Butterfly 需要包括以下步驟 : 
1. 取得 input (Xa, Xb)
2. 等待 BRAM data
3. 執行 butterfly
4. 寫回結果
5. 更新 counter

因此一個 Butterfly operation 可以拆成
 > IDLE -> READ -> WAIT -> CALCULATE -> WRITE -> UPDATE -> DONE

## 7.2 State Analysis
1. State : IDLE
   * 功能 : 等待 FFT 啟動。
     > Reset 結束後進入 IDLE state，同時 busy = 0, done = 0 (見 Chapter 3 - 3.2). 當 start = 1 後進入 READ state。
     
2. State : READ
   * 功能 : 啟動 BRAM read。
     > 提供 addr_a 和 addr_b，並輸出 bram_en_a = 1 bram_en_b = 1。
     
3. State : Wait
   * 在我們的設計中，BRAM 實際操作時會有 1 個 cycle 的 read latency，因此若要讀取正確資料，需要多等一個 cycle。
   * 功能：等待 BRAM output valid。
     > 舉例來說
     
     <div align="center">
      
     | Cycle | State | Action |
     | :--: | :--: | :--: |
     | 0 | READ | sending address |
     | 1 | WAIT | wait memory to read |
     | 2 | CALCULATE | start calculating |
     
     </div>
4. State : CALCULATE
   * 功能 : 啟動 Butterfly PE 進行計算。
     > 輸入 Xa, Xb 和 Twiddle Factor，並計算出 Ya, Yb。
   * 此時 controller 只負責讓 butterfly_enable = 1。

5. State : WRITE
   * 功能 : 將 Butterfly 算完的資料寫回 BRAM。
     > 控制 bram_we_a = 1, bram_we_b = 1 並將 Ya 和 Yb 寫回 addr_a, addr_b。

6. State : UPDATE
   * 功能 : Butterfly 完成後更新 Butterfly Counter 和 stage counter。
     > Butterfly counter : 若 butterfly < 31，則 butterfly++ 並回到 READ 執行下一組。
     > Stage counter : 若 butterfly == 31，則 Stage Counter++ 且 butterfly = 0 再回到 READ。
     > 當 stage = 5, butterfly = 31 時說明 FFT 已完成，此時跳入 state : DONE。

7. State : DONE
   * 功能 : 代表 FFT 全部完成。輸出 done = 1 並通知 PYNQ。

* Busy Signal Design :
  
  在 FFT 執行期間，我們設置 busy = 1，流程上如下 :
   > start -> busy=1 -> FFT running -> done -> busy=0

* FSM 與 Address Generator 的關係 :
  
  Controller FSM 會提供 stage counter 和 butterfly counter 的值給 address generator，之後再由 address generator 產生 addr_a, addr_b 和 twiddle_addr 等。因此
   > FSM 不計算 address，它只提供 current state。
  
   > Address Generator 負責如何將 current state 轉成 memory address。
    
 * FSM 與 Butterfly PE 的關係 :
   
   Controller 會送 enable signal 讓 Butterfly PE 計算 Ya = Xa + Xb 和 Yb = (Xa-Xb) * W。在分工上 :
    > {FSM、Address Generator、Butterfly、BRAM} 分別處理 {時間、地址、運算、資料} 的工作。

## 7.3 Chapter Review
本章介紹的 Controller FSM 中各個 state 的意義以及 Controller 如何與其他 module 進行交互。此外，透過介紹 FSM 的 state transition，我們也再次複習本專案使用的完整 FFT 流程。在我們的 64-point FFT 當中，總共需要 6 stages × 32 butterflies = 192 次 FSM operation。下一章將會討論如何將 FFT Core 封裝成 AXI4-Lite IP。
