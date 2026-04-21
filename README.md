# 8×8 Systolic Array AI Accelerator — Zynq UltraScale+ ZCU104

An 8×8 systolic array AI accelerator implemented in SystemVerilog on Xilinx Zynq UltraScale+ ZCU104, achieving **1.7 GOPS** at **6 mW PL logic power** (~283 GOPS/W efficiency) with full AXI-Stream PS-PL integration. Targets INT8 matrix multiplication for transformer inference acceleration, verified across behavioral, post-synthesis, and post-implementation simulation.

**Author:** Anil Sanneboyina
**LinkedIn:** [linkedin.com/in/sanneboyina-anil](https://linkedin.com/in/sanneboyina-anil)
**ASIC Companion Project:** [pe-asic-sky130](https://github.com/AnilS454/pe-asic-sky130) — PE implemented in SkyWater 130nm PDK

---

## Key Results

| Metric                   | Value           |
|--------------------------|-----------------|
| Target Frequency         | 100 MHz         |
| Worst Negative Slack (WNS)| +4.006 ns      |
| Worst Hold Slack (WHS)   | +0.010 ns       |
| Failing Endpoints        | 0 / 14,060      |
| LUT Utilization          | 3,681 (1.60%)   |
| Flip Flops               | 5,107 (1.11%)   |
| Total On-Chip Power      | 3.362 W         |
| PL Logic Power           | **6 mW**        |
| Peak Throughput          | **1.7 GOPS**    |
| Power Efficiency (PL)    | **~283 GOPS/W** |

> Total power is dominated by Zynq PS at 2.639 W. The systolic array fabric (PL logic) consumes only **6 mW**.

---

## Architecture

### Processing Element (PE)

Single-cycle INT8 MAC unit — the core building block of the array:

```
psum <= psum + (a_in * b_in)
```

Each PE:
- Accepts 8-bit signed inputs `a_in`, `b_in` with valid signals
- Accumulates partial sum in a 32-bit register (matching hardware overflow behavior)
- Passes data to neighboring PEs every clock cycle via registered outputs

### Systolic Array — Wave-Skew Dataflow

```
A[0] →  PE(0,0) → PE(0,1) → PE(0,2) → ...
          ↓          ↓          ↓
A[1] →  PE(1,0) → PE(1,1) → PE(1,2) → ...
          ↓          ↓          ↓
         ...
        B[0]       B[1]       B[2]
          ↓          ↓          ↓
```

- Row data (A matrix) flows left → right
- Column data (B matrix) flows top → bottom
- Inputs are skewed diagonally (wave-skew scheduling) so each PE receives its correct operands exactly when needed
- Each PE accumulates its partial product independently — no broadcast, no shared bus

### AXI-Stream FSM Controller

3-state FSM managing PS-to-PL data transfer:

```
LOADING → COMPUTING → STREAMING
```

- **LOADING:** Accepts input matrices from ARM PS via AXI-Stream
- **COMPUTING:** Systolic array performs matrix multiplication
- **STREAMING:** Output matrix streamed back to PS via AXI DMA
- Zero-copy data transfer between ARM PS and PL fabric using Xilinx AXI DMA IP

### Block Design

```
Zynq PS → AXI Interconnect → AXI DMA → systolic_axi_top
```

Full block design available in `bd/design_1.bd`. Exported from Vivado 2023.2.

---

## Performance Analysis

### Cycle-Accurate Latency (Wave-Skew Dataflow)

For an 8×8 systolic array with wave-skew input scheduling at 100 MHz:

| Phase              | Cycles           | Description                              |
|--------------------|------------------|------------------------------------------|
| Input skewing      | 2N − 2 = **14**  | Diagonal wave-front propagation delay    |
| Computation        | N = **8**        | All 64 PEs accumulating simultaneously   |
| Output drain       | N = **8**        | Partial sums streaming out               |
| **Total latency**  | **~30 cycles**   | **= 300 ns per 8×8 INT8 matrix multiply**|

> Latency confirmed from post-implementation functional simulation waveforms.

### Throughput & Efficiency

| Metric                   | Value            | Notes                                     |
|--------------------------|------------------|-------------------------------------------|
| Clock Frequency          | 100 MHz          | WNS = +4.006 ns — headroom for higher clocks |
| Latency per 8×8 multiply | **300 ns**       | 30 cycles × 10 ns                         |
| MACs per operation       | **512**          | 8 × 8 × 8                                |
| Peak Throughput          | **1.7 GOPS**     | 512 MACs / 300 ns                         |
| PL Logic Power           | **6 mW**         | Systolic array fabric only (Vivado report)|
| **Power Efficiency**     | **~283 GOPS/W**  | PL-only; PS baseline excluded             |

### Hardware vs Software Comparison

Software baseline: scalar INT8 matmul on ARM Cortex-A53 (Zynq PS, 1.2 GHz), compiled with `-O0` (no SIMD/NEON auto-vectorization), representing raw CPU compute cost without hardware offload.

| Platform                       | Latency (8×8 INT8 multiply) | Notes                          |
|--------------------------------|-----------------------------|--------------------------------|
| ARM Cortex-A53 scalar (-O0)    | ~600–800 ns (estimated)     | ~512+ cycles + loop overhead   |
| **Systolic Array (PL fabric)** | **300 ns**                  | 30 cycles @ 100 MHz            |
| **Estimated Speedup**          | **~2–2.5×**                 | Over unoptimized scalar ARM    |

Benchmark C code for PS-side timing measurement is included in `benchmark/benchmark_matmul.c` for physical board validation.

> **Note on simulation-only results:** This project was implemented and verified entirely in Vivado 2023.2 simulation (behavioral, post-synthesis, and post-implementation). Hardware numbers are derived from simulation cycle counts at the target clock. Physical board validation on the ZCU104 is the immediate next step.

### Design Tradeoff: Non-Pipelined Architecture

The current PE is a **non-pipelined single-cycle MAC** — each PE completes one multiply-accumulate per clock, and a new operation does not begin until the previous result is fully drained.

**Why this choice:** A non-pipelined implementation gives clean, fully isolated per-operation results — making functional verification straightforward and waveform-readable. This was the correct first-pass design decision: verify correctness before optimizing throughput.

**Pipelining as future work:** Adding pipeline registers between PE rows would allow new matrix inputs to enter during the drain phase of the current operation.
- Expected sustained throughput improvement: **~2–3×** for back-to-back operations
- Area cost: additional N×N flip-flops for inter-row pipeline registers
- Timing impact: adds ~N pipeline stages of latency but dramatically improves throughput

---

## Implementation Results

### Timing

![Timing Summary](docs/timing.png)

### Clock

![Clock Summary](docs/clock.png)

### Resource Utilization

![Utilization](docs/utilization.png)

### Power

![Power Summary](docs/power.png)

---

## Simulation Results

All three simulation stages were completed to match industry-standard verification flow.

### Behavioral Simulation

Verifies RTL functional correctness. Wave-skew input scheduling visible — inputs arrive diagonally skewed. Final accumulated outputs match expected values at cycle ~30.

![Behavioral Simulation](docs/sim_behavioral.png)

### Post-Synthesis Functional Simulation

Verifies the synthesized netlist matches RTL behavior. Confirms no functional changes were introduced during synthesis optimization.

![Post-Synthesis Simulation](docs/sim_post_synthesis.png)

### Post-Implementation Functional Simulation

Gate-level simulation with real timing back-annotation from place-and-route. Confirms timing-correct operation at 100 MHz on xczu7ev-ffvc1156-2-e fabric.

![Post-Implementation Simulation](docs/sim_post_implementation.png)

---

## Verification Coverage

| Testbench                        | What It Validates                                               |
|----------------------------------|-----------------------------------------------------------------|
| `tb_PE.v`                        | Single MAC unit: accumulation, overflow behavior, zero inputs   |
| `tb_systolic_2x2.v`              | 2×2 array: wave-skew timing, PE-to-PE data propagation          |
| `tb_systolic_nxn.v`              | 8×8 full array: identity matrix, known-value matrices           |
| `tb_systolic_top.sv`             | Top-level: reset behavior, valid signal propagation             |
| `tb_systolic_axi_wrapper.sv`     | AXI-Stream handshake: TVALID/TREADY protocol, FSM transitions   |

All testbenches verified at three simulation stages: behavioral → post-synthesis → post-implementation.

---

## Repository Structure

```
systolic_array_fpga/
├── rtl/
│   ├── PE.v                       # Single-cycle INT8 MAC Processing Element
│   ├── systolic_nxn_array.v       # Parameterized NxN systolic array
│   ├── systolic_controller.sv     # AXI-Stream FSM — Load → Compute → Stream
│   ├── systolic_top.sv            # Top-level — array + controller
│   ├── systolic_axi_wrapper.sv    # AXI-Stream interface wrapper
│   └── systolic_axi_top.v         # Verilog top for IP packaging
├── tb/
│   ├── tb_PE.v                    # PE unit testbench
│   ├── tb_systolic_2x2.v          # 2×2 array testbench
│   ├── tb_systolic_nxn.v          # NxN array testbench
│   ├── tb_systolic_top.sv         # Top-level testbench
│   └── tb_systolic_axi_wrapper.sv # AXI wrapper testbench
├── bd/
│   └── design_1.bd                # Vivado block design
├── benchmark/
│   └── benchmark_matmul.c         # ARM Cortex-A53 software baseline (PS-side)
├── docs/
│   ├── timing.png
│   ├── power.png
│   ├── utilization.png
│   ├── clock.png
│   ├── sim_behavioral.png
│   ├── sim_post_synthesis.png
│   └── sim_post_implementation.png
└── .gitignore
```

---

## Tools Used

| Tool              | Version  | Purpose                                           |
|-------------------|----------|---------------------------------------------------|
| Xilinx Vivado     | 2023.2   | Synthesis, Implementation, Simulation             |
| Xilinx XSim       | 2023.2   | Behavioral and post-implementation simulation     |
| Zynq UltraScale+  | xczu7ev-ffvc1156-2-e | Target device                        |

---

## What's Next

- [ ] Physical board validation on ZCU104 — run `benchmark_matmul.c` on PS, measure real speedup
- [ ] Pipelined PE design — pipeline registers between rows for sustained throughput improvement
- [ ] Scale to 16×16 array — evaluate LUT/FF utilization scaling and timing closure
- [ ] NEON-optimized software baseline — compare hardware against ARM SIMD for a tighter benchmark
- [ ] Connect to real transformer attention kernel — feed actual BERT/ViT attention weights
