<h1 align="center">PIC16F1826 MCU Core (SystemVerilog RTL)</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Language-SystemVerilog-00599C?style=for-the-badge" alt="SystemVerilog">
  <img src="https://img.shields.io/badge/Architecture-2--Stage%20Pipeline-red?style=for-the-badge" alt="Pipeline">
  <img src="https://img.shields.io/badge/Verification-ModelSim-yellow?style=for-the-badge" alt="ModelSim">
</p>

## Project Overview
This repository contains the RTL (Register-Transfer Level) implementation of the **Microchip PIC16F1826** Microcontroller Core. Written entirely in SystemVerilog, this project features a custom **2-stage pipeline architecture** designed to execute the PIC16 instruction set efficiently.

**Key Highlights:**
- **Hardware Architecture**: Implemented complete CPU datapaths including ALU, Controller, Program Counter (PC), Instruction Register (IR), Memory Address Register (MAR), and a hardware Stack.
- **2-Stage Pipelining**: Designed a Fetch-Execute pipeline to optimize instruction throughput.
- **Hazard Resolution**: Handled control hazards during branching instructions (`CALL`, `RETURN`) by dynamically inserting `NOP` to flush the pipeline.

### Hardware Architecture 

The core is designed with a separate Program ROM and Data RAM datapath.

<img width="765" height="883" alt="image" src="https://github.com/user-attachments/assets/8fd469e6-49de-4440-9643-2aac614b2806" />

**Core Components:**
- **Program ROM (11-bit Addr / 14-bit Data):** Dedicated instruction memory fetching 14-bit wide opcodes with an 11-bit address space.
- **Data SRAM (128x8):** A single-port 128-byte RAM (`single_port_ram_128x8`) utilizing 7-bit addressing for efficient data storage and retrieval.
- **FSM-based Controller:** Implements a Finite State Machine (FSM) to decode the 14-bit instructions and orchestrate pipeline control signals (e.g., `sel_alu`, `sel_pc`, `load_w`).
- **ALU (Arithmetic Logic Unit):** 8-bit streamlined datapath. Designed for direct bit-manipulation and branching evaluation without relying on a dedicated Status Register.
- **Hardware Stack (11-bit Depth):** Dedicated hardware stack supporting `push` and `pop` operations to precisely track the Program Counter (PC) during subroutine `CALL` and `RETURN` instructions.

### Supported Instruction Set

The CPU successfully decodes and executes a subset of the standard PIC16F1826 datasheet specifications:

#### 1. Immediate Addressing
- `MOVLW`, `ADDLW`, `SUBLW`, `ANDLW`, `IORLW`, `XORLW`
#### 2. Register Addressing 
- `ADDWF`, `ANDWF`, `IORWF`, `SUBWF`, `XORWF` (Supports `d=0` for W register, `d=1` for RAM)
- `CLRF`, `CLRW`, `COMF`, `DECF`, `INCF`, `MOVF`, `MOVWF`
- Bit-oriented: `BCF`, `BSF`

#### 3. Conditional Jump & Branching 
- `BTFSC`, `BTFSS`, `DECFSZ`, `INCFSZ`
- `GOTO`, `CALL`, `RETURN`

#### 4. Register Addressing Rotate 
- `ASRF` (Arithmetic Right Shift, preserves sign bit)
- `LSLF` (Logical Left Shift)
- `LSRF` (Logical Right Shift)
- `RLF` (Rotate Left)

### RTL Verification & Pipeline Testing 

The core has been rigorously verified using testbenches targeting specific pipeline behaviors and hazard conditions.

#### Test Case: Control Hazard Handling (CALL / RETURN)

<img width="1541" height="359" alt="image" src="https://github.com/user-attachments/assets/250b74e7-10ce-48a3-a67b-289fc5299983" />



**Verification Details:**
Tested the behavior of `CALL` and `RETURN` instructions. Since these instructions cause a jump in the PC, a control hazard occurs. The logic analyzer waveform confirms that at `T6`, the next fetched instruction is correctly overridden and changed to a `NOP` (No Operation) to maintain pipeline integrity.

#### Test Case 2: Comprehensive Datapath & Conditional Skip
<img width="1060" height="430" alt="image" src="https://github.com/user-attachments/assets/d7e0cc22-43e6-445d-8c4e-305519ce3eef" />



**Verification Details:**
This test validates the complete interaction between the ALU, Data SRAM, and the Hazard Unit:
1. **ALU & Memory Integrity:** The waveform demonstrates accurate data transitions in the W register (`w_q`) and SRAM (`single_port_ram`) across consecutive `ADD`, `SUB`, and `MOV` instructions.
2. **Bit Manipulation & Conditional Skips:** Successfully executed `bcf` (Bit Clear f) followed by `btfsc` (Bit Test, Skip if Clear). The pipeline correctly evaluates the bit status and flushes the subsequent instruction if the condition is met.
3. **Dynamic Relative Branching:** Validated the `BRW` (Branch with W) instruction, proving the core can dynamically compute `PC + W` and resolve the control path seamlessly.

### Repository Structure
- `RTL/` : SystemVerilog RTL source codes (`MCU.sv`, `Program_Rom.sv`, etc.)
- `Testbench/` : Testbench files for simulation
