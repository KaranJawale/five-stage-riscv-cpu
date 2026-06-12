# five-stage-riscv-cpu

A 5-stage pipelined RISC-V processor implemented in Verilog.

## Current Features

- IF, ID, EX, MEM and WB stages
- Separate instruction and data memories.
- Support for:
  - ADD
  - SUB
  - AND
  - OR
  - LD
  - SD
- Handling of Data Hazards in the EX stage through forwarding.

## Current Status

Current implementation is a behavioral pipelined RISC-V processor.

## Current Limitations

* No hazard detection to introduce stalls.
* No branch handling.
* No branch handling for dealing with control hazards.
* Not implemented Synthesizable control logic(structural modelling).
* Instruction and data caches.

---

## Project Structure

```
rtl/
    RISCV_CPU.v

testbench/
    RISCV_CPU_tb.v

docs/
    waveform1.png
    pipeline.png
```

---

## Development Log

### 2026-06-12

* Reorganized the project structure.
* Implemented forwarding of ALU results to dependent instructions in the EX stage.
* Successfully verified forwarding functionality through simulation.

### 2026-06-07

* Created the repository.
* Implemented the first behavioral model of the 5-stage pipelined processor.
* Added instruction flow through IF, ID, EX, MEM, and WB stages.
* Added support for basic R-type instructions and Memory instructions.

---

## References

* David A. Patterson and John L. Hennessy,
  *Computer Organization and Design: RISC-V Edition*

---

## License

MIT License
