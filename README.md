# Parameterized ALU with Synchronous FIFO and I2C LCD Controller

## Description

A fully parameterized Verilog ALU system integrated with a synchronous FIFO buffer and a custom I2C LCD Controller, utilizing a robust clock-enable architecture.

The project processes data fed through a synchronous FIFO buffer, manages the entire data pipeline via a dedicated Finite State Machine (FSM), converts the binary execution results into ASCII format, and streams them to an I2C-based LCD display.

---

## System Architecture

The design is modular and consists of the following key components:

### `top_module`
Structural top-level module integrating the control path and data path.

### `clk_divider`
Generates a single-cycle clock enable pulse from the 50 MHz master clock to maintain a single clock domain and eliminate clock skew caused by internally generated clocks.

### `button_debouncer`
Filters mechanical switch bouncing using a synchronous clock-enable mechanism.

### `fifo_sync_param`
Fully parameterized synchronous FIFO utilizing `$clog2` for automatic pointer width calculation based on the configured FIFO depth.

### `alu_param`
Parameterized Arithmetic Logic Unit supporting:

- Addition
- Subtraction
- Multiplication
- Bitwise OR
- Bitwise XOR
- Bitwise AND

Operations are selected using a 6-bit one-hot encoded opcode.

### `control_fsm`
Finite State Machine responsible for:

- Waiting for user input
- Reading operands from the FIFO
- Allowing execution stabilization
- Controlling the LCD display sequence

### `bin_to_ascii`
16-bit Binary-to-ASCII converter implementing the **Double Dabble (Shift-and-Add-3)** algorithm, producing a dynamic 5-digit decimal representation.

### `lcd_i2c_controller`
Custom I2C Master controller that formats:

- Operand A
- Operand B
- Operation symbol
- 5-digit result

and transmits them sequentially to an I2C LCD module.

---

## Key Hardware Concepts Demonstrated

### Deterministic Synchronous Design
- Single master clock domain
- Clock Enable architecture
- No internally generated clocks
- Elimination of clock skew

### Scalability & Parameterization
- Extensive use of configurable parameters
- Dynamic hardware scaling through:
  - `DATA_WIDTH`
  - `DEPTH`
  - `$clog2`

### Zero-Padding Alignment
Compile-time bit extension ensuring:

- Correct arithmetic width matching
- No elaboration-time simulation errors
- Support for up to 16-bit multiplication results

### Automated Verification
Self-checking testbench featuring:

- FIFO fill/empty stress testing
- Automatic ALU result verification
- Runtime comparison against expected values

---

## Development Environment

| Tool | Description |
|------|-------------|
| HDL | Verilog (IEEE 1364-2001) |
| Simulation | Siemens / Mentor QuestaSim |
| Synthesis | Intel Quartus Prime |
| FPGA Target | Intel Cyclone V |

---

## Repository Structure

```text
├── rtl/
│   ├── top_module.v
│   ├── alu_param.v
│   ├── fifo_sync_param.v
│   ├── control_fsm.v
│   ├── clk_divider.v
│   ├── button_debouncer.v
│   ├── bin_to_ascii.v
│   └── lcd_i2c_controller.v
│
├── tb/
│   └── tb_top_module.v
│
└── README.md
```

> Adjust the folder names above if your repository uses a different structure.

---

## Running the Simulation

### 1. Clone the Repository

```bash
git clone https://github.com/YourUsername/ALU_FIFO_I2C_Project_VERILOG.git
cd ALU_FIFO_I2C_Project_VERILOG
```

---

### 2. Speed Up the Simulation (Recommended)

The I2C interface normally operates at approximately **100 kHz**, making full simulations relatively slow.

To accelerate simulation:

Open:

```text
clk_divider.v
```

Change:

```verilog
9'd499
```

to:

```verilog
9'd1
```

> **Important:** Restore the value to `9'd499` before synthesizing the design in Quartus. Otherwise, the physical LCD will not correctly decode the I2C transmission.

---

### 3. Compile

Using QuestaSim / ModelSim:

```tcl
vlog *.v
```

---

### 4. Run the Testbench

```tcl
vsim work.tb_top_module
run -all
```

After completion, the testbench prints a structured summary indicating:

- Total number of executed test vectors
- FIFO verification status
- ALU verification status
- Overall pass/fail result

---

## Features

- Fully parameterized design
- Single-clock synchronous architecture
- Clock Enable methodology
- Parameterized FIFO
- Parameterized ALU
- Binary-to-ASCII conversion
- Custom I2C LCD Controller
- Self-checking testbench
- FPGA-ready implementation

---

## License

This project is released under the **MIT License**.
