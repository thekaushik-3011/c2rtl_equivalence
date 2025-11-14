#!/usr/bin/env bash
set -euo pipefail
if [ $# -lt 2 ]; then
  echo "Usage: run_golden_csv.sh <in_csv> <out_csv>"
  exit 1
fi
gcc -O2 -Iinputs inputs/golden_model.c -o inputs/golden_exec
./inputs/golden_exec "$1" "$2"
