Chapter 5 - Butterfly Processing Element (PE) 詳細設計與 Verilog 分析
===
## 5.1 R2 DIF Butterfly I/O and SPEC.
在 butterfly 的運算中，所有 variable ($X_a$, $X_b$, $Y_a$, $Y_b$ 和 $W_N^k$)皆為 complex scalar。具體 I/O 如下表示 :  

* Input : 
<p align="center">
  $X_a, \text{ } X_b$
</p>

* Output :
<p align="center">
  $$
    Y_a = X_a + X_b
  $$
  $$
    Y_b = (X_a - X_b) * W_N^k
  $$
</p>

其中
<p align="center">
  $W_N^k = e^{-j2\pi k/N}$
</p>

而每一筆 data 都會佔 32 bits (16 bit imag part + 16 bit real part)。舉例來說， $X_a$ = 32'h1234_5678, 則 imag = 0x1234, real = 0x5678。
