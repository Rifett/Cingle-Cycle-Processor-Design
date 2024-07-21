# Single-cycle Processor Design

## Overview
This project involves designing a simple 32-bit single-cycle RISC-V processor connected to separate instruction and data memories. 
The processor will implement a set of basic and extended instructions and perform specific tasks as described below.

## Basic ISA Design
The processor starts execution from the beginning of the instruction memory (0x00000000). It must implement the following instructions:

| Instruction | Syntax          | Operation                                               |
|-------------|-----------------|---------------------------------------------------------|
| `add`       | `add rd, rs1, rs2`  | `rd ← [rs1] + [rs2]`                                     |
| `addi`      | `addi rd, rs1, imm` | `rd ← [rs1] + imm[11:0]`                                 |
| `and`       | `and rd, rs1, rs2`  | `rd ← [rs1] & [rs2]`                                     |
| `sub`       | `sub rd, rs1, rs2`  | `rd ← [rs1] - [rs2]`                                     |
| `slt`       | `slt rd, rs1, rs2`  | `if [rs1] < [rs2] then rd ← 1; else rd ← 0`              |
| `div`       | `div rd, rs1, rs2`  | `rd ← [rs1] / [rs2]`                                     |
| `rem`       | `rem rd, rs1, rs2`  | `rd ← [rs1] % [rs2]`                                     |
| `beq`       | `beq rs1, rs2, imm` | `if [rs1] == [rs2] go to [PC] + {imm[12:1], '0'}; else go to [PC] + 4` |
| `blt`       | `blt rs1, rs2, imm` | `if [rs1] < [rs2] go to [PC] + {imm[12:1], '0'}; else go to [PC] + 4`  |
| `lw`        | `lw rd, imm(rs1)`   | `rd ← Memory[[rs1] + imm[11:0]]`                         |
| `sw`        | `sw rs2, imm(rs1)`  | `Memory[[rs1] + imm[11:0]] ← [rs2]`                      |
| `lui`       | `lui rd, imm[31:12]`| `rd ← {imm[31:12], '0000 0000 0000'}`                     |
| `jal`       | `jal rd, imm[20:1]` | `rd ← [PC] + 4; go to [PC] + {imm[20:1], '0'}`           |
| `jalr`      | `jalr rd, rs1, imm` | `rd ← [PC] + 4; go to [rs1] + imm[11:0]`                 |

## Extended ISA Design
The processor’s ISA is extended with the following instructions:

| Instruction | Syntax            | Operation                                                 |
|-------------|-------------------|-----------------------------------------------------------|
| `auipc`     | `auipc rd, imm`   | `rd ← [PC] + {imm[31:12], '0000 0000 0000'}`               |
| `sll`       | `sll rd, rs1, rs2`| `rd ← [rs1] << [rs2]`                                      |
| `srl`       | `srl rd, rs1, rs2`| `rd ← (unsigned)[rs1] >> [rs2]`                            |
| `sra`       | `sra rd, rs1, rs2`| `rd ← (signed)[rs1] >> [rs2]`                              |

## Instruction Encoding
Each instruction is encoded in 32 bits, with `rs1`, `rs2`, and `rd` encoded in 5 bits. The following table shows the encoding for each instruction:

| Instruction | Encoding                                             |
|-------------|------------------------------------------------------|
| `add`       | `0000000 rs2 rs1 000 rd 0110011`                     |
| `addi`      | `imm[11:0] rs1 000 rd 0010011`                       |
| `and`       | `0000000 rs2 rs1 111 rd 0110011`                     |
| `sub`       | `0100000 rs2 rs1 000 rd 0110011`                     |
| `slt`       | `0000000 rs2 rs1 010 rd 0110011`                     |
| `div`       | `0000001 rs2 rs1 100 rd 0110011`                     |
| `rem`       | `0000001 rs2 rs1 110 rd 0110011`                     |
| `beq`       | `imm[12\|10:5] rs2 rs1 000 imm[4:1\|11] 1100011`       |
| `blt`       | `imm[12\|10:5] rs2 rs1 100 imm[4:1\|11] 1100011`       |
| `lw`        | `imm[11:0] rs1 010 rd 0000011`                       |
| `sw`        | `imm[11:5] rs1 010 imm[4:0] 0100011`                 |
| `lui`       | `imm[31:12] rd 0110111`                              |
| `jal`       | `imm[20\|10:1\|11\|19:12] rd 1101111`                   |
| `jalr`      | `imm[11:0] rd 1100111`                               |
| `auipc`     | `imm[31:12] rd 0010111`                              |
| `sll`       | `0000000 rs2 rs1 001 rd 0110011`                     |
| `srl`       | `0000000 rs2 rs1 101 rd 0110011`                     |
| `sra`       | `0100000 rs2 rs1 101 rd 0110011`                     |

## Program: Prime Number Checker
The program iterates through an array of numbers and determines if each number is a prime. 
If a number is prime, it is overwritten with 1; otherwise, it is overwritten with 0. 
The program calls a subroutine `prime` to check for primality.

### Prime Subroutine
The subroutine has the following prototype in C:

```c
int prime(unsigned int number);
```

### Assumptions
- Array *size* is stored at address 0x00000004.
- *Starting address* of the array is stored at address 0x00000008 in a memory.


























