module MCU(
	input logic clk,reset,
	output logic [7:0] w_q
	//output logic [7:0] port_b_out
);
	
	logic load_mar, load_pc, load_ir, load_w, sel_alu, ram_en, sel_bus, reset_ir;
	logic btfsc_skip_bit, btfss_skip_bit, btfsc_btfss_skip_bit, aluout_zero;
	logic load_port_b, push, pop;
	logic [1:0] sel_RAM_mux; 
	logic [2:0] sel_bit, sel_pc;
	logic [4:0] op;
	logic [7:0] alu, ram_out, mux1_out, databus, RAM_mux, bcf_mux, bsf_mux, port_b_out;
	logic [10:0] pc_q, pc_next, mar_q, Stack_q, w_change, k_change;
	logic [13:0] Rom_out, ir_q;
	typedef enum {T0,T1,T2,T3,T4,T5,T6} state_t;
	state_t ps, ns;
	
	assign w_change = {3'b0, w_q} - 1;
	assign k_change = {ir_q[8], ir_q[8], ir_q[8:0]} - 1;

	// 使用多功器 選擇下一個指令的位址 
	// 如果sel_pc = 0，PC會被設定為PC+1(正常執行下個指令，不進行跳躍)
	// 如果sel_pc = 1，PC會被設定為GOTO指令的位址
	// 如果sel_pc = 2，PC會被設定為堆疊pop出來的指令位址
	// 如果sel_pc = 3，PC會被設定為PC+相對定址
	// 如果sel_pc = 4，PC會被設定為PC+相對定址with w
	// assign pc_next = sel_pc ? ir_q[10:0] : pc_q + 1;
	always_comb
	begin
		unique case(sel_pc)
			3'b000: pc_next =  pc_q + 1;
			3'b001: pc_next = ir_q[10:0];
			3'b010: pc_next = Stack_q;
			3'b011: pc_next = pc_q + k_chang;
			3'b100: pc_next = pc_q + w_change;
		endcase
	end
	
	// 用來保存目前指令的位址(為了在return時回到要執行的指令)
	Stack Stack1(
		.clk(clk),
		.reset(reset),
		.stack_in(pc_q),
		.push(push),
		.pop(pop),
		.stack_out(Stack_q)
	);
	
	// PC T2 將下一筆PC值載入(pc_q + 1)
	always_ff @(posedge clk)
	begin
		if(reset) pc_q <= #1 11'b0;
		else if (load_pc) pc_q <= #1 pc_next;
	end
	
	// MAR(memmory address register) T1 
	// 將PC值給ROM 去找他對應要執行的指令
	always_ff @(posedge clk)
	begin
		if(reset) mar_q <= #1 11'b0;
		else if (load_mar) mar_q <= #1 pc_q;
	end
	
	// use Program_Rom
	// 會輸出翻譯過的組合語言(機器碼)
	Program_Rom Program_Rom1(	
		.Rom_addr_in(mar_q),
		.Rom_data_out(Rom_out)
	);
	
	//ir_q T3
	always_ff @(posedge clk)
	begin
		if(reset || reset_ir) ir_q <= #1 14'b0;
		else if (load_ir) ir_q <= #1 Rom_out;
	end
	
	//ALU
	always_comb
	begin
		unique case(op)
			4'h0: alu = mux1_out + w_q;
			4'h1: alu = mux1_out - w_q;
			4'h2: alu = mux1_out & w_q;
			4'h3: alu = mux1_out | w_q;
			4'h4: alu = mux1_out ^ w_q;
			4'h5: alu = mux1_out;
			4'h6: alu = mux1_out + 1;
			4'h7: alu = mux1_out - 1;
			4'h8: alu = 0;
			4'h9: alu = ~mux1_out;
			4'hA: alu = {mux1_out[7], mux1_out[7:1]};
			4'hB: alu = {mux1_out[6:0], 1'b0};
			4'hC: alu = {1'b0, mux1_out[7:1]};
			4'hD: alu = {mux1_out[6:0], mux1_out[7]};
			4'hE: alu = {mux1_out[0], mux1_out[7:1]};
			4'hF: alu = {mux1_out[3:0], mux1_out[7:4]};
		endcase
	end
	
	// instruction set
	// decode machine code 
	logic MOVELW, ADDLW, SUBLW, ANDLW, IORLW, XORLW;
	logic ADDWF, ANDWF, CLRF, CLRW, COMF, DECF, GOTO;
	logic INCF, IORWF, MOVF, MOVWF, SUBWF, XORWF;
	logic BCF, BSF, BTFSC, BTFSS, DECFSZ, INCFSZ;
	logic ASRF, LSLF, LSRF, RLF, RRF, SWAPF, CALL, RETURN;
	logic BRA, BRW, NOP;
	// immediate_addressing
	assign MOVELW = ir_q[13:8] == 6'h30; // 將立即數傳送到W
	assign ADDLW = ir_q[13:8] == 6'h3e;  // 立即數和W相加後傳回W
	assign SUBLW = ir_q[13:8] == 6'h3c;  // 立即數減去W的內容後傳回W
	assign ANDLW = ir_q[13:8] == 6'h39;  // 立即數和W作邏輯與運算後傳回W
	assign IORLW = ir_q[13:8] == 6'h38;  // 立即數和W作邏輯或運算後傳回W
	assign XORLW = ir_q[13:8] == 6'h3a;  // 立即數和W作邏輯異或運算後傳回W
	//register_addressing
	assign ADDWF = ir_q[13:8] == 6'h07;  // W和F相加 0:w 1:ram
	assign ANDWF = ir_q[13:8] == 6'h05;  // W和F做邏輯與運算 0:w 1:ram
	assign CLRF = ir_q[13:7] == 7'b0000011;  // 將F清零
	assign CLRW = ir_q[13:2] == 12'b000001000000;  // 將W清零
	assign COMF = ir_q[13:8] == 6'h09; // 將F反向
	assign DECF = ir_q[13:8] == 6'h03;  // F遞減1
	assign GOTO = ir_q[13:11] == 3'b101;  // 跳到指定的指令
	// register_addressing more
	assign INCF = ir_q[13:8] == 6'h0a;  // F遞增1 0:w 1:ram
	assign IORWF = ir_q[13:8] == 6'h04;  // W和F做邏輯或運算 0:w 1:ram
	assign MOVF = ir_q[13:8] == 6'h08;  // 傳送F 0:w 1:ram
	assign MOVWF = ir_q[13:7] == 7'b0000001;  // 將W的內容傳到F
	assign SUBWF = ir_q[13:8] == 6'h02;  // F減去W 0:w 1:ram
	assign XORWF = ir_q[13:8] == 6'h06;  // W和F做XOR運算 0:w 1:ram
	
	// 讓 第sel_bit個bit 變成0/1
	assign BCF = ir_q[13:10] == 4'b0100;
	assign BSF = ir_q[13:10] == 4'b0101;
	// conditional jump
	// 如果記憶體位址(f)的第某一個(b)bit為0/1，下一個指令不執行
	assign BTFSC = ir_q[13:10] == 4'b0110; 
	assign BTFSS = ir_q[13:10] == 4'b0111;
	// 把記憶體位址為f的值-1/+1，如果為0下一個指令不執行
	assign DECFSZ = ir_q[13:8] == 6'h0b; 
	assign INCFSZ = ir_q[13:8] == 6'h0f;
	// register_addressing rotate
	assign ASRF = ir_q[13:8] == 6'h37;   // {mux1_out[7], mux1_out[7:1]}; 保留sign bit
	assign LSLF = ir_q[13:8] == 6'h35;   // {mux1_out[6:0], 1'b0}; // 左移
	assign LSRF = ir_q[13:8] == 6'h36;   // {1'b0, mux1_out[7:1]}; // 右移
	assign RLF = ir_q[13:8] == 6'h0d;    // {mux1_out[6:0], mux1_out[7]}; // 左旋轉
	assign RRF = ir_q[13:8] == 6'h0c;    // {mux1_out[0], mux1_out[7:1]}; // 右旋轉
	assign SWAPF = ir_q[13:8] == 6'h0e;  // {mux1_out[3:0], mux1_out[7:4]};
	// call and return
	assign CALL = ir_q[13:11] == 3'b100; // Call Subroutine = push pc + goto ...
	assign RETURN = ir_q[13:0] == 14'b00000000001000; // Return from Subroutine = pop
	// 相對定址
	assign BRA = ir_q[13:9] == 5'b11001; // 跳到指定的label
	assign BRW = ir_q == 14'b00000000001011; // 跳到指定的位址
	assign NOP = ir_q == 14'b00000000000000; // 不做事
	
	//BTFSC, BTFSS的跳躍
	assign btfsc_skip_bit = ram_out[sel_bit] == 0;
	assign btfss_skip_bit = ram_out[sel_bit] == 1;
	assign btfsc_btfss_skip_bit = (BTFSC&btfsc_skip_bit)|(BTFSS&btfss_skip_bit);
	
	
	single_port_ram_128x8 single_port_ram_128x8(
		.data(databus),
		.addr(ir_q[6:0]),
		.ram_en(ram_en),
		.clk(clk),
		.q(ram_out)
	);
	
	// 控制要做運算的資料要從哪裡來
	// sel_alu = 0，ir_q[7:0] 立即定址的常數
	// sel_alu = 1，ram_out 由ir_q[6:0]決定的記憶體位址的值
	assign mux1_out = sel_alu ? RAM_mux : ir_q[7:0];
	
	// 控制要傳入RAM的資料要從哪裡來
	// sel_bus = 0，alu
	// sel_bus = 1，w_q
	assign databus = sel_bus ? w_q : alu;
	
	// BSF BCF
	assign sel_bit = ir_q[9:7];
	// aluout_zero = ~|alu = (alu == 0) 這幾種寫法都可以
	assign aluout_zero = (alu == 0)? 1'b1: 1'b0;
	// RAM_mux
	always_comb
	begin
		unique case(sel_RAM_mux)
			0: RAM_mux = ram_out;
			1: RAM_mux = bcf_mux;
			2: RAM_mux = bsf_mux;	
		endcase
	end
	
	// bcf_mux 讓第sel_bit個bit變成0
	// ex: M[0x25] <= M[0x25] & 8'b1111_0111
	always_comb
	begin
		case(sel_bit)
			3'b000: bcf_mux = ram_out & 8'b1111_1110;
			3'b001: bcf_mux = ram_out & 8'b1111_1101;
			3'b010: bcf_mux = ram_out & 8'b1111_1011;
			3'b011: bcf_mux = ram_out & 8'b1111_0111;
			3'b100: bcf_mux = ram_out & 8'b1110_1111;
			3'b101: bcf_mux = ram_out & 8'b1101_1111;
			3'b110: bcf_mux = ram_out & 8'b1011_1111;
			3'b111: bcf_mux = ram_out & 8'b0111_1111;
		endcase
	end
	
	// bsf_mux 讓第sel_bit個bit變成1
	// ex: M[0x25] <= M[0x25] | 8'b1111_0111
	always_comb
	begin
		case(sel_bit)
			3'b000: bsf_mux = ram_out | 8'b0000_0001;
			3'b001: bsf_mux = ram_out | 8'b0000_0010;
			3'b010: bsf_mux = ram_out | 8'b0000_0100;
			3'b011: bsf_mux = ram_out | 8'b0000_1000;
			3'b100: bsf_mux = ram_out | 8'b0001_0000;
			3'b101: bsf_mux = ram_out | 8'b0010_0000;
			3'b110: bsf_mux = ram_out | 8'b0100_0000;
			3'b111: bsf_mux = ram_out | 8'b1000_0000;
		endcase
	end	

	// PORTB: 1. 為PIC對外的連接 I/O Port 2. 位址為0D 3. 可以為Input or Output
	always_ff @(posedge clk) begin
		if(reset) port_b_out <= 0;
		else if(load_port_b) port_b_out <= #1 databus;
	end
	assign addr_port_b = (ir_q[6:0] == 7'h0d);
	
	always_ff @(posedge clk) begin
		if(load_w) w_q <= #1 alu;
	end
	
	// FSM
	always_ff @(posedge clk)
	begin
		if(reset) ps <= T0;
		else ps <= ns;
	end
	
	//controller for fetch(T1~T3) and execute(T4~T6)
	always_comb
	begin	
		ns = T0;
		load_mar = 0;
		load_pc = 0;
		load_ir = 0;
		op = 0;
		load_w = 0;
		sel_pc = 0;
		sel_alu = 0;
		ram_en = 0;
		sel_bus = 0;
		sel_RAM_mux = 0;
		load_port_b = 0;
		push = 0;
		pop = 0;
		reset_ir = 0;
		case(ps)
			T0:
			begin 
				ns = T1;
			end
			T1:
			begin 
				load_mar = 1;
				load_pc = 1;
				ns = T2;
			end
			T2:
			begin 
				ns = T3;
			end
			T3:
			begin 
				load_ir = 1;
				ns = T4;
			end
			T4:
			begin 
				if(MOVELW) 
					begin
						op = 5;
						load_w = 1;
					end
				else if(ADDLW)
					begin
						op = 0;
						load_w = 1;
					end
				else if(SUBLW)
					begin
						op = 1;
						load_w = 1;
					end	
				else if(ANDLW)
					begin
						op = 2;
						load_w = 1;
					end		
				else if(IORLW)
					begin
						op = 3;
						load_w = 1;
					end	
				else if(XORLW)
					begin
						op = 4;
						load_w = 1;
					end	
				else if(ADDWF)
					begin
						op = 0;
						sel_alu = 1;
						if(ir_q[7])
							ram_en = 1;
						else
							load_w = 1;
					end
				else if(ANDWF)
					begin
						op = 2;
						sel_alu = 1;
						if(ir_q[7])
							ram_en = 1;
						else
							load_w = 1;
					end	
				else if(CLRF)
					begin
						op = 8;
						ram_en = 1;
					end
				else if(CLRW)
					begin
						op = 8;
						load_w = 1;
					end
				else if(COMF)
					begin
						op = 9;
						sel_alu = 1;
						if(ir_q[7])
							ram_en = 1;
						else
							load_w = 1;
					end	
				else if(DECF)
					begin
						op = 7;
						sel_alu = 1;
						if(ir_q[7])
							ram_en = 1;
						else
							load_w = 1;
					end
				else if(INCF)
					begin
						op = 6;
						sel_alu = 1;
						if(ir_q[7])
							begin
								ram_en = 1;
								sel_bus = 0;
							end
						else
							load_w = 1;
					end
				else if(IORWF)
					begin
						op = 3;
						sel_alu = 1;
						if(ir_q[7])
							begin
								ram_en = 1;
								sel_bus = 0;
							end
						else
							load_w = 1;
					end		
				else if(MOVF)
					begin
						op = 5;
						sel_alu = 1;
						if(ir_q[7])
							begin
								ram_en = 1;
								sel_bus = 0;
							end
						else
							load_w = 1;
					end	
				else if(MOVWF)
					begin
						sel_bus = 1;
						if(addr_port_b)
							load_port_b = 1;
						else
							ram_en = 1;
					end	
				else if(SUBWF)
					begin
						op = 1;
						sel_alu = 1;
						if(ir_q[7])
							begin
								ram_en = 1;
								sel_bus = 0;
							end
						else
							load_w = 1;
					end	
				else if(XORWF)
					begin
						op = 4;
						sel_alu = 1;
						if(ir_q[7])
							begin
								ram_en = 1;
								sel_bus = 0;
							end
						else
							load_w = 1;
					end	
				else if(BCF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 1;
						op = 5;
						sel_bus = 0;
						ram_en = 1;					
					end		
				else if(BSF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 2;
						op = 5;
						sel_bus = 0;
						ram_en = 1;					
					end	
				else if(ASRF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 0;
						op = 4'hA;
						if(ir_q[7])
							begin
								sel_bus = 0;
								ram_en = 1;
							end	
						else
							load_w = 1;
					end
				else if(LSLF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 0;
						op = 4'hB;
						if(ir_q[7])
							begin
								sel_bus = 0;
								ram_en = 1;
							end	
						else
							load_w = 1;
					end	
				else if(LSRF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 0;
						op = 4'hC;
						if(ir_q[7])
							begin
								sel_bus = 0;
								ram_en = 1;
							end	
						else
							load_w = 1;
					end
				else if(RLF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 0;
						op = 4'hD;
						if(ir_q[7])
							begin
								sel_bus = 0;
								ram_en = 1;
							end	
						else
							load_w = 1;
					end	
				else if(RRF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 0;
						op = 4'hE;
						if(ir_q[7])
							begin
								sel_bus = 0;
								ram_en = 1;
							end	
						else
							load_w = 1;
					end	
				else if(SWAPF)
					begin
						sel_alu = 1;
						sel_RAM_mux = 0;
						op = 4'hF;
						if(ir_q[7])
							begin
								sel_bus = 0;
								ram_en = 1;
							end	
						else
							load_w = 1;
					end		
				else if(NOP)
					begin
						
					end
				else if(CALL)
					begin
						push = 1;
					end
				load_mar = 1;
				load_pc = 1;
				ns = T5;
			end
			T5:	
			begin
				if(GOTO)
					begin
						sel_pc = 1;
						load_pc = 1;
					end
				else if(CALL)
					begin
						sel_pc = 1;
						load_pc = 1;				
					end
				else if(RETURN)
					begin
						sel_pc = 2;
						load_pc = 1;
						pop = 1;
					end
				else if(BRA)
					begin
						load_pc = 1;
						sel_pc = 3;
					end
				else if(BRW)
					begin
						load_pc = 1;
						sel_pc = 4;
					end
				ns = T6;
			end
			T6:
			begin
				if(GOTO)
					begin
						reset_ir = 1;
					end
				else if(CALL)
					begin
						reset_ir = 1;
					end
				else if(RETURN)
					begin
						reset_ir = 1;
					end
				else if(DECFSZ)
					begin
						sel_alu = 1;
						op = 7;
						if(ir_q[7])
							begin
								ram_en = 1;
								sel_bus = 0;
							end
						else
							load_w = 1;
						if(aluout_zero == 1)
							begin
								reset_ir = 1;
							end
					end
				else if(INCFSZ)
					begin
						sel_alu = 1;
						op = 6;
						if(ir_q[7])
							begin
								ram_en = 1;
								sel_bus = 0;
							end
						else
							load_w = 1;
						if(aluout_zero == 1)
							begin
								reset_ir = 1;
							end
					end
				else if(BTFSC)
					begin
						if(btfsc_btfss_skip_bit == 1)
							begin
								reset_ir = 1;
							end	
					end
				else if(BTFSS)
					begin
						if(btfsc_btfss_skip_bit == 1)
							begin
								reset_ir = 1;
							end	
					end
				else if(BRA)
					begin
						reset_ir = 1;
					end
				else if(BRW)
					begin
						reset_ir = 1;
					end
				load_ir = 1;
				ns = T4;
			end				
		endcase
	end
	
endmodule