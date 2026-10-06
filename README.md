# AHB
# Multi-Master AMBA AHB (v2.0) Bus Interconnect & Subsystem

A synthesizable, multi-master AMBA AHB (v2.0) compliant bus interconnect designed in Verilog HDL. The subsystem features a centralized priority-based bus arbiter, a Master-to-Slave (M2S) multiplexer, an address decoder with pipelined response routing, dual synchronous SRAM slaves, and an automated file-driven verification testbench implemented for AMD Xilinx Vivado.

---

## 📌 Architecture Overview

Unlike AHB-Lite, which only supports a single master, this full AMBA AHB architecture integrates a central arbiter to resolve simultaneous bus contention between multiple bus masters (e.g., CPU Core and DMA Controller).
<img width="1224" height="1285" alt="AHB Multi-Master Interconnect Diagram" src="https://github.com/user-attachments/assets/eb3e7b83-d1a4-4ff6-b3fd-89c07890193e" />

## RTL Netlist
<img width="1920" height="1032" alt="Screenshot 2026-10-06 113502" src="https://github.com/user-attachments/assets/4e60f368-2ded-46b2-9b33-7edfc7d44979" />



## 🔑 Key Features

* **Multi-Master Arbitration:** Central arbiter handling `HBUSREQ`, `HLOCK`, `HGRANT`, and driving `HMASTER[3:0]`.
* **Pipelined Bus Protocol:** Full overlap of address and data phases for zero-wait sequential throughput.
* **Master-to-Slave Multiplexing:** Dynamic routing of control/write data based on granted master ID.
* **Dual SRAM Memory Slaves:** Zero-wait word-addressable synchronous memory models.
* **Default Error Slave:** ARM-compliant two-cycle `ERROR` response termination on accesses to unmapped memory space.
* **Decoupled Verification:** File-driven testbench using Verilog `$fopen` / `$fgets` / `$sscanf` to parse test suites from plain text without recompiling RTL.

---

## 🗺️ Memory Map Specification

| Device | Base Address | End Address | Size | Data Width | Latency / Wait States |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **AHB Slave 0 (SRAM 0)** | `0x0000_0000` | `0x0000_FFFF` | 64 KB | 32-bit | 0 wait states (`HREADYOUT=1`) |
| **AHB Slave 1 (SRAM 1)** | `0x2000_0000` | `0x2000_FFFF` | 64 KB | 32-bit | 0 wait states (`HREADYOUT=1`) |
| **Unmapped Memory** | *All other regions* | — | — | — | 2-cycle `ERROR` (`HRESP=1`) |

---

## 📁 Repository Organization

├── rtl/
│   ├── ahb_arbiter.v          # Central bus arbiter & priority logic
│   ├── ahb_m2s_mux.v          # Master-to-Slave multiplexer
│   ├── ahb_interconnect.v     # Address decoder & response multiplexer
│   ├── ahb_sram_slave.v       # Synchronous SRAM memory slave model
│   └── ahb_system_top.v       # Subsystem top wrapper
├── sim/
│   ├── tb_ahb_file_open.v     # Multi-master file-driven testbench
│   └── testcases.txt          # Real-time stimulus vectors & assertions
├── docs/                      # Subsystem architecture diagrams & waveforms
├── .gitignore                 # Excludes Vivado compilation artifacts
└── README.md                  # Project documentation

🧪 Verification & Real-Time Test Cases
The test suite evaluates functional correctness, contention handling, memory limits, and signal integrity.

Test Vector Format (testcases.txt)
Plaintext
# Columns: <MASTER_ID: 0/1> <CMD: W/R> <ADDR (Hex)> <DATA (Hex)> <WAIT_CYCLES (Dec)>
0   W   00000010    DEADBEEF    0
0   R   00000010    DEADBEEF    0
1   W   20000040    CAFEBABE    0
1   R   20000040    CAFEBABE    0

Verified Test Categories:
Basic Sanity: Isolated write and read operations to dedicated slaves from Master 0 and Master 1.

Cross-Slave Interleaving: Master 0 targeting Slave 1; Master 1 targeting Slave 0.

Contention & Priority Resolution: Simultaneous bus requests handled according to priority without dropping cycles.

Read-After-Write (RAW) Hazard: Back-to-back read at the same address immediately following a write.

Boundary Limit Checks: Upper boundary access at 0x0000_03FC and 0x2000_03FC.

Bit-Walking Integrity: Toggle patterns (0x00000001, 0x80000000, 0x55555555, 0xAAAAAAAA, 0xFFFFFFFF) to detect stuck-at faults.


🛠️ Simulation & Build Instructions (AMD Xilinx Vivado)
Option 1: Via Vivado GUI
Open Vivado and create a new RTL Project.

Add all Verilog source files in rtl/ under Design Sources.

Add sim/tb_ahb_file_open.v under Simulation Sources.

Set ahb_system_top as the Top Design Module.

Set tb_ahb_file_open as the Top Simulation Module.

Copy testcases.txt into the simulation execution directory:


Plaintext
<project_directory>/<project_name>.sim/sim_1/behav/xsim/testcases.txt
Click Run Simulation -> Run Behavioral Simulation.

Option 2: Automated Batch Execution (Vivado TCL)
Run Vivado directly from your terminal:

Bash
vivado -mode tcl -source run_vivado.tcl

📈 Sample Simulation Results
##WAVEFORM
<img width="1920" height="1032" alt="Screenshot 2026-10-06 113536" src="https://github.com/user-attachments/assets/fe16448a-7e82-4cc4-9939-071f489e72c9" />

##TCL

<img width="1920" height="1032" alt="Screenshot 2026-10-06 113543" src="https://github.com/user-attachments/assets/2bf463ff-efcd-42e0-a9c4-7697ae5ee43d" />


Plaintext
======================================================================
     STARTING MULTI-MASTER AHB SIMULATION USING $fopen METHOD         
======================================================================
[85000 ns]  [PASS] Test #02 | Master 0 READ @ 0x00000000 | Match: 0x12345678
[125000 ns] [PASS] Test #04 | Master 1 READ @ 0x20000000 | Match: 0x87654321
[165000 ns] [PASS] Test #06 | Master 0 READ @ 0x20000010 | Match: 0xaaaabbbb
[205000 ns] [PASS] Test #08 | Master 1 READ @ 0x00000010 | Match: 0xccccdddd
[285000 ns] [PASS] Test #13 | Master 0 READ @ 0x00000040 | Match: 0xa0a0a0a0
[325000 ns] [PASS] Test #14 | Master 1 READ @ 0x20000040 | Match: 0xb1b1b1b1
======================================================================
                         TEST SUMMARY REPORT                          
======================================================================
 Total Read Checks: 18
 Passed:            18
 Failed:            0
 STATUS:            >>> ALL MULTI-MASTER TESTS PASSED <<<
======================================================================
