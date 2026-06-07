# five-stage-riscv-cpu

A 5-stage pipelined RISC-V processor implemented in Verilog.

## Features

- IF, ID, EX, MEM and WB stages
- Separate instruction and data memories
- Support for:
  - ADD
  - SUB
  - AND
  - OR
  - LD
  - SD

## Current Limitations

- No forwarding for data hazards
- No hazard detection to introduce stalls
- No branch handling for dealing with control hazards

## Project Structure

```
rtl/
    RISCV_PIPELINE.v

testbench/
    RISCV_PIPELINE_tb.v

docs/
    pipeline.png
    waveform1.png
```

## Future Improvements

- Forwarding unit
- Hazard detection unit
- Branch handling
- Branch prediction