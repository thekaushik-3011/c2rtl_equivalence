#ifndef GOLDEN_MODEL_H
#define GOLDEN_MODEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void golden_init(void);
void golden_step(uint8_t in_valid, uint32_t in_data,
                 uint8_t *out_valid, uint32_t *out_data);

int golden_run_csv(const char *in_csv, const char *out_csv);

#ifdef __cplusplus
}
#endif

#endif
