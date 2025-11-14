// inputs/golden_model.c
#include "golden_model.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static uint32_t sum;
static uint8_t in_valid_d;
static uint32_t in_data_d;

void golden_init(void) {
    sum = 0;
    in_valid_d = 0;
    in_data_d = 0;
}

void golden_step(uint8_t in_valid, uint32_t in_data, uint8_t *out_valid, uint32_t *out_data) {
    // pipeline behavior must match RTL. We'll apply same ordering:
    // - capture pipelined registers
    // - if in_valid, sum += in_data (mod 32)
    // - out_valid = previous in_valid (in_valid_d)
    // - if out_valid, out_data = sum

    // update pipeline registers (but keep previous values for outputs)
    uint8_t prev_in_valid_d = in_valid_d;
    uint32_t prev_sum = sum;

    // update sum as RTL does on same cycle as sampling
    if (in_valid) {
        sum = prev_sum + in_data; // modulo 2^32 by uint32_t wrap-around
    }

    // shift pipeline: sample input into delayed registers
    in_valid_d = in_valid;
    in_data_d = in_data;

    // produce outputs matching RTL: out_valid = prev in_valid_d (before we updated in_valid_d)
    *out_valid = prev_in_valid_d;
    if (prev_in_valid_d) {
        // RTL outputs sum (which has just been updated above to include the new input).
        // Because of ordering, prev_sum + in_data == new sum when prev_in_valid_d==1,
        // but the pipeline relation is matched by the ordering used here.
        *out_data = sum;
    } else {
        *out_data = 0;
    }
}

// helper to parse hex prefix "0x"
static uint32_t parse_hex(const char *s) {
    if (!s) return 0;
    return (uint32_t)strtoul(s, NULL, 0);
}

int golden_run_csv(const char *in_csv, const char *out_csv) {
    FILE *inf = fopen(in_csv, "r");
    if (!inf) {
        perror("fopen input");
        return 1;
    }
    FILE *outf = fopen(out_csv, "w");
    if (!outf) {
        perror("fopen output");
        fclose(inf);
        return 1;
    }

    // consume header if present
    char line[256];
    if (!fgets(line, sizeof(line), inf)) {
        fclose(inf);
        fclose(outf);
        return 1;
    }
    // if first line contains "id" assume header, else rewind
    if (strstr(line, "id") == NULL) {
        fseek(inf, 0, SEEK_SET);
    }

    fprintf(outf, "cycle,id,in,exp,out\n");

    golden_init();
    unsigned long cycle = 0;
    unsigned long id;
    char in_s[64];

    while (fgets(line, sizeof(line), inf)) {
        if (sscanf(line, "%lu,%63s", &id, in_s) >= 1) {
            uint32_t in = parse_hex(in_s);
            uint8_t out_valid;
            uint32_t out_data;
            // call golden per vector: drive in_valid=1 for each vector (streaming)
            golden_step(1, in, &out_valid, &out_data);
            // Note: If you want to emulate idle cycles, adapt the CSV format.
            fprintf(outf, "%lu,%lu,0x%08x,0x%08x,0x%08x\n", cycle, id, in, out_data, out_data);
            cycle++;
            // Optionally insert zero-valid cycles between vectors if desired
            // e.g., golden_step(0, 0, &out_valid, &out_data);
        }
    }

    fclose(inf);
    fclose(outf);
    return 0;
}


