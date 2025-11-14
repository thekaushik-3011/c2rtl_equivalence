#!/usr/bin/env python3
# scripts/compare_csv.py
import csv, sys

def load(path):
    with open(path, newline='') as f:
        r = csv.reader(f)
        header = next(r)
        rows = [row for row in r if row]
    return header, rows

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: compare_csv.py <golden.csv> <sim_out.csv>")
        sys.exit(2)
    _, g = load(sys.argv[1])
    _, s = load(sys.argv[2])
    mismatches = 0
    n = min(len(g), len(s))
    for i in range(n):
        # golden filed order: cycle,id,in,exp,out  (we wrote exp==out for golden run)
        g_exp = g[i][3].lower().lstrip("0x")
        s_out = s[i][4].lower().lstrip("0x")
        if g_exp != s_out:
            mismatches += 1
            print(f"Mismatch idx {i} id_g={g[i][1]} id_s={s[i][1]}")
            print(" golden:", g[i])
            print(" sim   :", s[i])
            if mismatches >= 20:
                break
    if mismatches == 0:
        print("OK: no mismatches")
    else:
        print(f"{mismatches} mismatches")
        sys.exit(1)
