// inputs/golden_model.c - 4-tap FIR Filter
#include "golden_model.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// FIR coefficients (fixed-point: 16-bit, scale 2^12)
static const int16_t COEFF[4] = {819, 1638, 2048, 1638};  // Approximates [0.2, 0.4, 0.5, 0.4]

static int16_t buffer[4];    // Circular buffer for last 4 samples
static uint8_t buf_idx;      // Current write position
static uint8_t in_valid_d;   // Pipeline delay register
static int16_t in_data_d;    // Pipeline delay register
static int64_t acc;          // Accumulator for MAC operations
static uint8_t mac_stage;    // MAC pipeline stage counter

void golden_init(void) {
    for (int i = 0; i < 4; i++) buffer[i] = 0;
    buf_idx = 0;
    in_valid_d = 0;
    in_data_d = 0;
    acc = 0;
    mac_stage = 0;
}

void golden_step(uint8_t in_valid, uint32_t in_data, uint8_t *out_valid, uint32_t *out_data) {
    // Extract 16-bit signed input from lower 16 bits
    int16_t sample = (int16_t)(in_data & 0xFFFF);
    
    uint8_t prev_in_valid_d = in_valid_d;
    uint8_t will_output = 0;
    int32_t result = 0;
    
    // === STAGE 1: Input sampling ===
    if (in_valid) {
        buffer[buf_idx] = sample;
        buf_idx = (buf_idx + 1) & 0x3;  // Wrap around: 0->1->2->3->0
    }
    
    // === STAGE 2: MAC operation (takes 4 cycles) ===
    if (prev_in_valid_d && mac_stage < 4) {
        // Multiply-accumulate: read from buffer in reverse order
        uint8_t read_idx = (buf_idx - 1 - mac_stage) & 0x3;
        acc += (int64_t)buffer[read_idx] * COEFF[mac_stage];
        mac_stage++;
        
        if (mac_stage == 4) {
            // MAC complete, scale down from fixed-point
            result = (int32_t)(acc >> 12);  // Divide by 2^12
            acc = 0;
            mac_stage = 0;
            will_output = 1;
        }
    } else if (!prev_in_valid_d) {
        mac_stage = 0;
        acc = 0;
    }
    
    // Pipeline input for next cycle
    in_valid_d = in_valid;
    in_data_d = sample;
    
    // === OUTPUTS ===
    *out_valid = will_output;
    *out_data = will_output ? (uint32_t)(result & 0xFFFF) : 0;
}

// CSV runner (same structure as before)
static int16_t parse_signed16(const char *s) {
    if (!s) return 0;
    long val = strtol(s, NULL, 0);
    return (int16_t)(val & 0xFFFF);
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

    char line[256];
    if (!fgets(line, sizeof(line), inf)) {
        fclose(inf); fclose(outf);
        return 1;
    }
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
            int16_t in = parse_signed16(in_s);
            uint8_t out_valid;
            uint32_t out_data;
            
            golden_step(1, (uint32_t)in, &out_valid, &out_data);
            
            fprintf(outf, "%lu,%lu,0x%04x,0x%04x,0x%04x\n", 
                    cycle, id, in & 0xFFFF, out_data & 0xFFFF, out_data & 0xFFFF);
            cycle++;
        }
    }

    fclose(inf);
    fclose(outf);
    return 0;
}