# DMA Controller with AXI4-Lite Interface and Asynchronous FIFO

DMA Controller with AXI-LITE PROTOCOL and Asynchronous FIFO

Overview
--------
This repository contains a hardware design for a DMA (Direct Memory Access) controller that exposes an AXI4-Lite control/status register interface and connects to data paths through an asynchronous FIFO for safe clock-domain crossing. The design is suitable for SoC integration where a lightweight register interface is required to program DMA transfers while data flows across different clock domains.

Key features
------------
- AXI4-Lite slave control/status register interface for configuration and control
- Asynchronous FIFO for crossing producer/consumer clock domains
- Start/stop, source/destination address, transfer length registers
- Interrupt request generation on transfer complete / error
- Parameterizable data bus width and FIFO depth
- Simple, synthesizable RTL (Verilog/SystemVerilog)

Block diagram (conceptual)
--------------------------

  CPU/AXI-Lite Master
        |
  [AXI4-Lite] <--- control/status registers ---> DMA Controller ---> Async FIFO ---> Data Consumer
                                        |                                 ^
                                        |                                 |
                                Source/Destination                        Data Producer
                                   Addresses

Repository layout
-----------------
- /rtl/        — RTL sources (Verilog or SystemVerilog). Place DMA controller and FIFO source files here.
- /sim/        — Simulation testbenches and scripts (iverilog/questa/vcs examples).
- /tb/         — Example testbenches for functional verification.
- /docs/       — Design notes, timing considerations, register maps, and any diagrams.
- /examples/   — Integration examples or SoC top-level wrappers.

Register map (example)
----------------------
This is an example register map; update to match the implementation in /rtl.

0x00 — CONTROL (RW)
- bit [0]  : START (write 1 to start transfer)
- bit [1]  : STOP  (write 1 to stop)
- bit [2]  : IRQ_EN (enable interrupts)

0x04 — STATUS (RO)
- bit [0]  : BUSY
- bit [1]  : IRQ
- bit [2]  : ERROR

0x08 — SRC_ADDR (RW)
0x0C — DST_ADDR (RW)
0x10 — TRANSFER_LEN (RW) — number of beats/bytes depending on configuration

AXI4-Lite interface signals (typical)
-------------------------------------
- AWADDR, AWPROT, AWVALID, AWREADY
- WDATA, WSTRB, WVALID, WREADY
- BRESP, BVALID, BREADY
- ARADDR, ARPROT, ARVALID, ARREADY
- RDATA, RRESP, RVALID, RREADY

Asynchronous FIFO interface (example)
-------------------------------------
Producer side (write domain):
- wr_clk, wr_rst_n
- wr_en, wr_data, wr_full

Consumer side (read domain):
- rd_clk, rd_rst_n
- rd_en, rd_data, rd_empty

Typical usage
-------------
1. Bring the DMA controller out of reset.
2. Program SRC_ADDR, DST_ADDR and TRANSFER_LEN via AXI-Lite writes.
3. Enable interrupts (optional) and assert START.
4. DMA reads from source and writes through the asynchronous FIFO into the consumer domain.
5. DMA sets STATUS.BUSY until transfer completes; on completion it raises IRQ if enabled.
6. Clear IRQ and check STATUS/ERROR fields as needed.

Simulation
----------
- Use the files in /sim/ and /tb/ to simulate basic transfer scenarios, clock domain crossings, and corner cases (e.g., FIFO full/empty during transfers).
- Recommended simulators: iverilog + vvp for quick checks, or ModelSim/Questa/VCS for more advanced simulations.

Synthesis and implementation
----------------------------
- The design targets FPGA/ASIC flows; ensure FIFO primitives or vendor-specific wrappers are used for large FIFOs for better timing and resource utilization.
- Constraint clocks and cross-domain timing must be set up properly for asynchronous FIFOs.

Testing checklist
-----------------
- Functional test: single transfer, multiple back-to-back transfers
- Corner cases: zero-length, FIFO full, FIFO empty, burst boundaries (if applicable)
- Reset behavior across both clock domains
- Interrupt assertion and clearing behavior

Contributing
------------
Contributions are welcome. Please:
1. Open an issue to discuss larger changes.
2. Submit pull requests with clear descriptions and tests.

License
-------
This repository is provided under the MIT License. See LICENSE file for details, or add one if not present.

Maintainer
----------
UyyalaVishnu

Notes
-----
- This README is a generic integration guide. Update the register map, signal names, and examples to exactly match the RTL in /rtl before using the design in production.
