#!/usr/bin/env python3
# scripts/gen_vectors.py
import argparse, random, os

def gen_random(path, count, seed):
    random.seed(seed)
    with open(path, "w") as f:
        f.write("id,in\n")
        for i in range(count):
            v = random.getrandbits(32)
            f.write(f"{i},0x{v:08x}\n")
    print("Wrote", path)

def gen_unit(path):
    vals = [0, 1, 0xffffffff, 0x7fffffff, 0x80000000, 0xdeadbeef, 0x00000001, 0x00000002]
    with open(path, "w") as f:
        f.write("id,in\n")
        for i, v in enumerate(vals):
            f.write(f"{i},0x{v:08x}\n")
    print("Wrote", path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="inputs/cosim_inputs.csv")
    parser.add_argument("--mode", choices=["random","unit"], default="random")
    parser.add_argument("--count", type=int, default=256)
    parser.add_argument("--seed", type=int, default=12345)
    args = parser.parse_args()
    os.makedirs("inputs", exist_ok=True)
    if args.mode == "unit":
        gen_unit(args.out)
    else:
        gen_random(args.out, args.count, args.seed)
