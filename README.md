# RTL_C Co-simulation Example - 32-bit Streaming Accumulator

This repository contains a minimal but robust flow to prove C ↔ RTL equivalence
for a streaming accumulator example.

Structure:
- `rtl/top.v` – simple RTL: when `in_valid` is high, adds `in_data` to internal sum and
  after one cycle asserts `out_valid` with `out_data = sum`.
- `inputs/golden_model.c/h` – cycle-accurate golden C model with `golden_init()` and `golden_step()`.
- `tb/tb.sv` – SystemVerilog testbench (for HDL simulators).
- `tb/verilator_main.cpp` – Verilator cosim harness: drives RTL and calls golden_step() per cycle.
- `scripts/gen_vectors.py` – vector generator.
- `scripts/compare_csv.py` – comparator for golden vs sim outputs.
- `scripts/run_cosim.sh` – runs full flow using Verilator.

Requirements:
- Verilator (for cosim) or any SV simulator if you adapt the testbench.
- g++ and gcc for compiling harness and golden.
- Python 3 for vector gen and comparison.

See `docs/spec.md` for the interface and mapping.

