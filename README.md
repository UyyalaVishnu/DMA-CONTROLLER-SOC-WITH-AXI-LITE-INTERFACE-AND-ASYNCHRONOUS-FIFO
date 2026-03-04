# DMA Controller SoC with AXI-Lite Interface and Asynchronous FIFO

## Overview
This project implements a Direct Memory Access (DMA) Controller System-on-Chip (SoC) with an AXI-Lite control interface and asynchronous FIFO for high-performance data transfer operations. The design includes CDC (Clock Domain Crossing) techniques for reliable data synchronization and comprehensive physical design implementation.

## Project Description
A specialized DMA controller designed to manage memory-to-memory and memory-to-peripheral data transfers efficiently using ARM's AXI-Lite protocol for control signaling and asynchronous FIFO buffers for reliable data movement between different clock domains.

## Key Features
- **AXI-Lite Control Interface**: Industry-standard ARM protocol for configuration and status registers
- **Asynchronous FIFO**: Dual-clock FIFO for reliable data transfer between different clock domains
- **CDC (Clock Domain Crossing)**: Metastability-safe synchronization techniques
- **Full SoC Implementation**: Including synthesis, place & route, and timing closure
- **Comprehensive Design Flow**: From RTL to physical implementation

## Project Structure

### Documentation
- **README.md** - This file, project overview and guidance
- **DMA_SoC PROJECT REPORT.pdf** - Comprehensive project documentation and analysis
- **DMA_SoC_CODE.docx** - Detailed code documentation and implementation details
- **test_bench_code.docx** - Testbench code and verification documentation

### Design Resources
- **AXI DMA Controller Block Diagram.jpeg** - High-level system architecture visualization
- **CDC.jpeg** - Clock Domain Crossing implementation diagram
- **elaborate_design.jpeg** - Elaborated design schematic

### Implementation & Analysis Reports
- **synthesis.jpeg** - Synthesis results summary
- **synthesis_report.jpeg** - Detailed synthesis report
- **cts_report.jpeg** - Clock Tree Synthesis report
- **floorplanning.rpt** - Floorplan analysis and placement results
- **routing.jpeg** - Routing visualization
- **Routing.csv** - Detailed routing metrics and statistics
- **stimulation_results.jpeg** - Simulation and verification results

## Design Specifications

### Control Interface
- AXI-Lite protocol for slave interface configuration
- Programmable control registers
- Status monitoring capabilities

### Data Path
- Asynchronous FIFO for clock domain independence
- Multi-word data transfer support
- Configurable data width and depth

### Synchronization
- CDC techniques for reliable cross-domain signaling
- Gray code counters for FIFO pointers
- Metastability-safe handshake logic

## Physical Implementation
- Complete netlist synthesis
- Place & Route with timing closure
- Floor planning and optimization
- Comprehensive routing analysis

## Getting Started
Refer to the PDF report and code documentation for:
- Detailed implementation guidelines
- Configuration parameters
- Usage examples and test vectors
- Simulation and verification procedures

## Additional Resources
See the included JPEG diagrams and reports for:
- System architecture overview
- Design verification results
- Physical implementation metrics
- Timing and performance analysis

---
*Last Updated: March 2026*