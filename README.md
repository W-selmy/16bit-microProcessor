# Modular 16-bit Microprocessor (VHDL)

A professional, modular VHDL implementation of a simple 16-bit microprocessor designed for **Spartan 6** FPGAs.

## Project Architecture
The design is split into discrete, testable components:
- **`microprocessor.vhd`**: Structural top-level connecting all modules.
- **`processor_control_unit.vhd`**: Main Finite State Machine (FSM).
- **`alu.vhd`**: 16-bit Arithmetic Logic Unit (ADD, SUB, INC, PASS).
- **`pc.vhd`**: 12-bit Program Counter.
- **`acc.vhd`**: 16-bit Accumulator with flag generation (Zero, Sign).
- **`ir.vhd`**: 16-bit Instruction Register.
- **`cpu_pkg.vhd`**: Global constants and opcode definitions.

## Instruction Set
| Mnemonic | Opcode | Action |
| :--- | :--- | :--- |
| **LDA addr** | `0000` | ACC ← mem[addr] |
| **STO addr** | `0001` | mem[addr] ← ACC |
| **ADD addr** | `0010` | ACC ← ACC + mem[addr] |
| **SUB addr** | `0011` | ACC ← ACC - mem[addr] |
| **JMP addr** | `0100` | PC ← addr |
| **JGE addr** | `0101` | if ACC ≥ 0 then PC ← addr |
| **JNE addr** | `0110` | if ACC ≠ 0 then PC ← addr |
| **STP**      | `0111` | Halt processor |

## Simulation (ModelSim)
To run the full system simulation, use the following compilation order in ModelSim:

1. `vcom cpu_pkg.vhd`
2. `vcom alu.vhd pc.vhd acc.vhd ir.vhd processor_control_unit.vhd`
3. `vcom microprocessor.vhd tb_microprocessor.vhd`
4. `vsim work.tb_microprocessor`
5. `add wave -recursive *`
6. `run 1000ns`

## Verification
The testbench (`tb_microprocessor.vhd`) includes a memory model pre-loaded with a test program that calculates `5 + 3`, stores the result, and then stops.
