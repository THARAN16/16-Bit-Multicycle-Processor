# 16 Bit Multicycle Processor with Adaptive ALU and Booth MAC Unit

![Verilog](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Software](https://img.shields.io/badge/Platform-Xilinx_Vivado-orange.svg)
![FPGA](https://img.shields.io/badge/Hardware-Artix--7_Nexys_Video-red.svg)
![Power](https://img.shields.io/badge/Optimization-Dynamic_Power_Reduction-brightgreen.svg)


> A custom multi-cycle RISC architecture optimized for low power and high speed using Reversible Gates, Operand Isolation, and 3 Stage pipelined Booth MAC.

## 📖 Overview
This project details the design and implementation of a 16-bit multicycle processor optimized to overcome traditional static and dynamic power losses. Bypassing standard-cell datapaths, the execution core relies on a combination of **Reversible Logic Gates** (respecting Landauer's principle to reduce power dissipation) and **Leading Zero Detection (LZD)** for dynamic operand isolation. 

The architecture integrates this adaptive operand-isolated datapath with a high-speed Radix-4 Booth multiplier. Furthermore, it includes a custom Hardware Debugging Wrapper via Xilinx Virtual Input/Output (VIO), allowing for real-time validation and manual execution control directly on the **Artix-7 Nexys Video FPGA Board**.

---

## 📊 Performance Improvements (Artix-7 Synthesis)

Based on post-implementation synthesis on the Artix-7 FPGA, the proposed architecture yields massive improvements over conventional RISC designs. 

| Performance Metric | Conventional RISC | Proposed Custom RISC | Improvement | Visual Comparison (Approx. Scale) |
| :--- | :--- | :--- | :--- | :--- |
| **Total Dynamic Power** | 10.599 mW | **7.586 mW** | **📉 28.4%** | 🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥 (10.6)<br>🟩🟩🟩🟩🟩🟩🟩 (7.6) |
| **Critical Path Delay** | 17.716 ns | **10.857 ns** | **⚡ 38.7%** | 🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥 (17.7)<br>🟩🟩🟩🟩🟩🟩 (10.8) |
| **ALU Dynamic Power** | 3.998 mW | **1.445 mW** | **📉 63.8%** | 🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥 (4.0)<br>🟩🟩🟩 (1.4) |

* **Dynamic Power Reduction:** Achieved a **28.4%** reduction in total dynamic power compared to conventional RISC designs by eliminating idle switching glitches.
* **Speed Enhancement:** Achieved **38.7%** faster operation with a critical path delay reduction from 17.716 ns down to 10.857 ns.
* **ALU Optimization:** The Adaptive ALU utilizing reversible logic and LZD achieved a massive **63.8%** dynamic power reduction specifically within the arithmetic unit.

---

## 🛠️ Core Innovations (Click to Expand)

<details>
<summary><b>1. Adaptive ALU with Reversible Logic</b></summary>
<br>
The arithmetic core replaces standard logic gates with quantum-cost-conscious Reversible Logic (Feynman, Toffoli, and Peres gates). 

* **Leading Zero Detection (LZD):** Monitors the upper 8 bits of incoming operands. If both upper bytes are zero, the Operand Isolator physically gates the upper half of the ALU to `00`, preventing wasted switching glitches in the logic fabric.
</details>

<details>
<summary><b>2. Pipelined 16-bit Booth MAC</b></summary>
<br>
A dedicated high-speed hardware multiplier-accumulator for DSP workloads.

* **Iron Curtain Flip-Flops:** The Booth encoders and multiplier inputs are strictly hardware-gated. They remain completely frozen until an operation officially begins, eliminating idle glitch power.
* **DSP Targeting:** Synthesized using the `(* use_dsp = "yes" *)` directive to ensure multiplication maps directly to dedicated silicon slices rather than fabric LUTs.
</details>

<details>
<summary><b>3. Custom Finite State Machine (FSM)</b></summary>
<br>
A centralized Finite State Machine dynamically manages the processor pipeline and execution actions across 5 active states:
1. `FETCH`
2. `DECODE`
3. `EXECUTE` (Dynamically routes to ALU or MAC based on Opcode)
4. `WRITEBACK`
5. `HALT_ST`
</details>

<details>
<summary><b>4. Real-Time VIO Debugging Shield</b></summary>
<br>
Integrated with Xilinx VIO for on-chip testing.

* **Glitch-Shielded Probes:** The output registers (`vio_alu_safe`, `vio_mac_hi_safe`) are buffered. They only update when execution units flag a `done` state, preventing the VIO from detecting intermediate switching and draining dynamic power.
* **Dual-Mode Operation:** Supports seamless switching between automated instruction memory execution and manual VIO-driven operand injection.
</details>

---

## 📂 Repository Structure

| File | Description |
| :--- | :--- |
| `topofvio.v` | Top-level module integrating the processor and VIO debugging wrapper. |
| `adaptive_alu_top.v` | Wrapper combining the Reversible ALU with LZD and Operand Isolation. |
| `adaptive_alu_core.v` | The arithmetic core utilizing Toffoli, Peres, and Feynman gates. |
| `16bitbooth.v` | Pipelined Radix-4 Booth Multiplier and Accumulator. |
| `reversible_gates.v` | Gate-level definitions for all reversible logic modules. |
| `controlfsm.v` | 5-stage multi-cycle processor control unit. |
| `instructmem.v` | ROM containing the test vector program execution sequence. |
| `auxilarymodule.v` | Program Counter, Instruction Decoder, and Data Memory. |
| `register.v` | General Purpose Register file (R0-R7) plus HI/LO for MAC. |

---

## 🚀 Getting Started

1. Clone this repository.
2. Open **Xilinx Vivado** and create a new RTL project.
3. Add all `.v` source files to the design.
4. Add the `vio_0.xci` IP block to the project (ensure your IP catalog is updated for the **Artix-7 XC7A200T** FPGA).
5. Generate the Bitstream and program the **Nexys Video Board**.
6. Open the **Vivado Hardware Manager** to interact with the processor via the VIO dashboard!

---

## 👨‍💻 RTL and Verification
**THARAN S M**
