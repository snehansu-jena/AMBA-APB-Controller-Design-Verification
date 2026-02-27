# AMBA APB Protocol Implementation in Verilog

🚀 A clean, synthesizable, and protocol-accurate implementation of the **AMBA Advanced Peripheral Bus (APB)** using **Verilog HDL**.

This repository is built to demonstrate **real RTL design skills**

---

## 📌 Overview

The **Advanced Peripheral Bus (APB)** is part of the AMBA architecture and is commonly used to interface low-bandwidth peripherals such as GPIO, UART, timers, and control registers.

This project implements:
- APB Master (Controller)
- APB Slave
- Read and Write transactions
- FSM-based protocol handling

The design strictly follows **APB timing and handshaking rules**.

---

## ⚙️ Key Features

✔ APB-compliant SETUP and ACCESS phases  
✔ FSM-based control logic  
✔ Read and write operation support  
✔ Synchronous, synthesizable RTL  
✔ Clean signal naming and structure  
✔ Beginner-friendly but interview-ready  

---

## 🧠 APB Transaction Flow

IDLE → SETUP → ACCESS → IDLE


- **IDLE**: Bus inactive
- **SETUP**: PSEL asserted, address/control stable
- **ACCESS**: PENABLE asserted, data transfer occurs
- **IDLE**: Transaction completes

---

## 🧩 Design Description

### 🔹 APB Master
- Generates control signals: `PSEL`, `PENABLE`, `PWRITE`
- Drives address and write data
- Controls transaction sequencing using FSM

### 🔹 APB Slave
- Samples address and write data
- Drives read data during read transactions
- Responds according to APB timing

---




---

## 🧪 Simulation & Verification

- Testbench written in **Verilog**
- Validates both read and write transactions
- Waveform-based verification using GTKWave / Vivado / Questa


🎯 Why This Project Is Useful
- Shows protocol-level RTL understanding

- Demonstrates FSM design

- Suitable for VLSI / RTL / DV engineer portfolios

- Strong base for SystemVerilog or UVM extensions

🔮 Planned Improvements
 - PSLVERR support

- Multiple slave support

- Parameterized data/address width

- SystemVerilog Assertions (SVA)

- UVM-based verification environment

 

## 👨‍💻 Author
- Snehansu Jena
- Electronics & Instrumentation Branch
- Odisha University and Technology and Research 

