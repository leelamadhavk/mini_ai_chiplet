# Multi-Chiplet AI Accelerator SoC (v2)

## What changed vs. the original "Mini AI Chiplet System"

| Aspect | Original | Upgraded (this version) |
|---|---|---|
| AI compute | Single combinational multiply `Y = W*X + B` | Pipelined single-neuron perceptron: `Y = ReLU(Σ Wi·Xi + B)` over 4 inputs |
| Chiplet interconnect | Plain wires | Valid/ready handshake protocol (mirrors real chiplet-to-chiplet links such as UCIe) |
| CPU chiplet | Wire pass-through | FSM-based streaming controller that sequences 4 activation/weight pairs |
| Memory chiplet | Combinational pass-through | Real synchronous scratchpad RAM with auto-incrementing write pointer + addressable host readback |
| Verification | Fixed 3-vector testbench, manual check | Self-checking testbench covering a normal case, a larger case, and a case that exercises the ReLU clamp |
| Target flow | EDA Playground / Icarus only | Vivado project: behavioral sim (xsim) → synthesis → implementation → Pblock floorplanning → utilization/timing reports |

## Architecture

```
              valid/ready handshake         valid pulse
   ┌──────────────┐   X,W,B,last    ┌──────────────┐   Y    ┌──────────────┐
   │  CPU chiplet │ ───────────────▶│  AI chiplet   │───────▶│ MEMORY chiplet│
   │ (FSM streamer)│◀─────ready─────│ (MAC + ReLU)  │        │ (scratchpad RAM)│
   └──────────────┘                 └──────────────┘        └──────┬───────┘
                                                                    │ RD_ADDR (host readback)
                                                                    ▼
                                                                 RESULT
```

- **CPU chiplet** (`cpu_chiplet.v`): on `start`, streams `NUM_INPUTS` (X, W) pairs one per cycle to the AI chiplet, asserting `last_out` on the final tap.
- **AI chiplet** (`ai_chiplet.v`): accumulates `X*W` across the stream, adds the bias on the last tap, applies ReLU, and raises `valid_out` for exactly one cycle with the result.
- **Memory chiplet** (`memory_chiplet.v`): every AI result is written to the next free address automatically; a host can read any stored result back via `rd_addr`.
- **Top level** (`mini_ai_chiplet_soc.v`): wires the three chiplets together and exposes `RESULT`, `RESULT_VALID`, and `BUSY` to the outside world.

## Verified behavior (hand-traced against the testbench)

| Inference | X | W | Bias | Result | Notes |
|---|---|---|---|---|---|
| 1 | [1,2,3,4] | [1,1,1,1] | 0 | 10 | basic sum |
| 2 | [5,4,6,2] | [3,2,4,1] | 2 | 51 | non-trivial weights |
| 3 | [1,1,1,1] | [1,1,1,1] | -60 | 0 | negative pre-activation → ReLU clamps to 0 |

## Files

- `rtl/cpu_chiplet.v`, `rtl/ai_chiplet.v`, `rtl/memory_chiplet.v`, `rtl/mini_ai_chiplet_soc.v` — design sources
- `sim/tb_mini_ai_chiplet_soc.v` — self-checking testbench

## Possible next steps (good "future work" talking points)

- Widen the AI chiplet to a 4-neuron layer (systolic array) instead of a single neuron
- Add real back-pressure (the AI chiplet is currently always-ready) once the memory chiplet can fill up
- Wrap the SoC in an AXI-Lite interface so a Zynq PS (ARM core) can drive it as a memory-mapped peripheral
- Add a UART loader so weights can be updated without recompiling

## Resume framing

- "Designed and verified a multi-chiplet AI accelerator SoC in Verilog implementing a pipelined MAC-based neuron with ReLU activation, connected via a valid/ready chiplet interconnect protocol."
- "Synthesized and implemented the design in Xilinx Vivado, using Pblock floorplanning to physically partition chiplet logic across the FPGA fabric, and analyzed post-implementation timing and resource utilization."
- "Built a self-checking Verilog testbench exercising nominal, scaled, and activation-clamping (ReLU) test cases."
