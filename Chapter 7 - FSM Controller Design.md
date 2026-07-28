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
 > IDLE -> READ -> WAIT -> CALCULATE -> WRITE -> UPDATE -> NEXT

## 7.2 State Analysis
1. IDLE
   * 功能 : 等待 FFT 啟動。
     > Reset 結束後進入 IDLE state，同時 busy = 0, done = 0. 當 start = 1 後進入 READ state。
2.  
