# Design Specification - Streaming Accumulator

Interface (top module `top`):
- `input wire clk`      : clock
- `input wire rst_n`    : active-low reset (0 = reset)
- `input wire in_valid` : when high, `in_data` is sampled and added
- `input wire [31:0] in_data`
- `output reg out_valid`: pulses high one cycle after input accepted (pipeline latency = 1)
- `output reg [31:0] out_data`: running sum (32-bit unsigned) reported when `out_valid` pulses

Behavior:
- On reset, `sum = 0`. On each cycle where `in_valid==1`, `sum = (sum + in_data) & 32'hFFFFFFFF`.
- After sampling `in_data`, the DUT asserts `out_valid` in next cycle and presents `out_data = sum` from that cycle.
- All arithmetic is unsigned modulo 2^32.

Equivalence mapping:
- Golden C : cycle-accurate model with identical pipeline latency and reset semantics.
- RTL : `top.v` described above.

Test vector CSV format (inputs/cosim_inputs.csv):
- Header: `id,in`
- Rows: `0,0x00000001`
- The golden harness produces expected outputs; the Verilator C++ harness calls the golden model per-cycle to compare RTL outputs live.

