#!/usr/bin/env bash
set -euo pipefail
mkdir -p results inputs

# 1) gen vectors (if missing)
if [ ! -f inputs/cosim_inputs.csv ]; then
  echo "Generating vectors..."
  python3 scripts/gen_vectors.py --out inputs/cosim_inputs.csv --mode=random --count=256 --seed=42
fi

# 2) produce golden results CSV (optional, used for compare)
gcc -O2 -Iinputs inputs/golden_model.c -o inputs/golden_exec
./inputs/golden_exec inputs/cosim_inputs.csv results/golden.csv || true

# 3) run verilator build and sim
make sim

# 4) compare results
python3 scripts/compare_csv.py results/golden.csv results/sim_out.csv || true

echo "Done. See results/*.csv and results/wave.vcd (if traced)."
