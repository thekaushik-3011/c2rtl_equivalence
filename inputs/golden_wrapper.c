// inputs/golden_wrapper.c
#include <stdio.h>
#include "golden_model.h"

int main(int argc, char **argv) {
    if (argc != 3) {
        printf("Usage: golden_exec <input_csv> <output_csv>\n");
        return 1;
    }

    const char *input = argv[1];
    const char *output = argv[2];

    return golden_run_csv(input, output);
}
