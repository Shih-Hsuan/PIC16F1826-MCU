# PIC16F1826 MCU二級管線架構設計與實現
## 硬體架構圖
![image](https://github.com/user-attachments/assets/396e8a8e-9420-4455-80e9-014ec15d3e11)
## Data sheet
[PIC16(L)F1826/27 Data Sheet](https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/DataSheets/41391D.pdf)
## 支援指令
* Immediate Addressing
  * MOVELW : 將立即數傳送到W
  * ADDLW  : 立即數和W相加後傳回W
  * SUBLW  : 立即數減去W的內容後傳回W
  * ANDLW  : 立即數和W作邏輯與運算後傳回W
  * IORLW  : 立即數和W作邏輯或運算後傳回W
  * XORLW  : 立即數和W作邏輯異或運算後傳回W
* Register Addressing
  * ADDWF : W和F相加 0:w 1:ram
  * ANDWF : 和F做邏輯與運算 0:w 1:ram
  * CLRF  : 將F清零
  * CLRW  : 將W清零
  * COMF  : 將F反向
  * DECF  : F遞減1
  * GOTO  : 跳到指定的指令
  * INCF  : F遞增1 0:w 1:ram
  * IORWF : W和F做邏輯或運算 0:w 1:ram
  * MOVF  : 傳送F 0:w 1:ram
  * MOVWF : 將W的內容傳到F
  * SUBWF : F減去W 0:w 1:ram
  * XORWF : W和F做XOR運算 0:w 1:ram  
  * BCF : 讓第sel_bit個bit 變成0
  * BSF : 讓第sel_bit個bit 變成1
* Conditional Jump
  * BTFSC : 如果記憶體位址(f)的第某一個(b)bit為0，下一個指令不執行
  * BTFSS : 如果記憶體位址(f)的第某一個(b)bit為1，下一個指令不執行
  * DECFSZ = 把記憶體位址為f的值-1，如果為0下一個指令不執行
  * INCFSZ = 把記憶體位址為f的值+1，如果為0下一個指令不執行
* Register Addressing Rotate
  * ASRF  : {mux1_out[7], mux1_out[7:1]}; 保留sign bit
  * LSLF  : {mux1_out[6:0], 1'b0}; // 左移
  * LSRF  : {1'b0, mux1_out[7:1]}; // 右移
  * RLF   : {mux1_out[6:0], mux1_out[7]}; // 左旋轉
  * RRF   : {mux1_out[0], mux1_out[7:1]}; // 右旋轉
  * SWAPF : {mux1_out[3:0], mux1_out[7:4]};
* Call and Return
  * CALL   : Call Subroutine = push pc + goto ...
  * RETURN : Return from Subroutine = pop
* 相對定址
  * BRA : 跳到指定的label
  * BRW : 跳到指定的位址
  * NOP : 不做事	
