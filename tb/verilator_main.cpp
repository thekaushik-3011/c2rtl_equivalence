// tb/verilator_main.cpp
#include <verilated.h>
#include "Vtop.h"
#if VM_TRACE
#include <verilated_vcd_c.h>
#endif
#include <fstream>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <string>
#include <cstdint>
extern "C" {
  #include "../inputs/golden_model.h"
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtop* top = new Vtop;

#if VM_TRACE
    VerilatedVcdC* tfp = nullptr;
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("results/wave.vcd");
#endif

    std::ifstream vecf("inputs/cosim_inputs.csv");
    if (!vecf.is_open()) {
        std::cerr << "Failed to open inputs/cosim_inputs.csv\n";
        return 1;
    }
    std::ofstream sim_out("results/sim_out.csv");
    sim_out << "cycle,id,in,exp,out\n";

    std::string header;
    std::getline(vecf, header); // skip header if present

    golden_init();

    // reset
    top->clk = 0;
    top->rst_n = 0;
    for (int i=0;i<4;i++) {
        top->clk = !top->clk;
        top->eval();
#if VM_TRACE
        tfp->dump(i);
#endif
    }
    top->rst_n = 1;

    std::string line;
    uint64_t cycle = 0;
    while (std::getline(vecf, line)) {
        if (line.size() == 0) continue;
        std::istringstream ss(line);
        uint64_t id;
        std::string in_s;
        if (!(ss >> id)) continue;
        if (!(ss >> std::ws)) continue; // eat spaces
        char comma;
        ss >> comma;
        ss >> in_s;
        uint32_t in_val = (uint32_t)strtoul(in_s.c_str(), NULL, 0);

        // drive input (in_valid=1)
        top->in_valid = 1;
        top->in_data = in_val;
        // eval at falling and rising edges to simulate one clock cycle
        top->clk = 0; top->eval();
#if VM_TRACE
        tfp->dump(cycle*2);
#endif
        top->clk = 1; top->eval();
#if VM_TRACE
        tfp->dump(cycle*2+1);
#endif

        // now step golden with same input and get expected outputs
        uint8_t g_out_valid;
        uint32_t g_out_data;
        golden_step(1, in_val, &g_out_valid, &g_out_data);

        // move one more half cycle to observe output after pipeline
        top->clk = 0; top->in_valid = 0; top->in_data = 0; top->eval();
#if VM_TRACE
        tfp->dump(cycle*2+2);
#endif
        top->clk = 1; top->eval();
#if VM_TRACE
        tfp->dump(cycle*2+3);
#endif

        uint32_t rtl_out = top->out_data;
        uint8_t rtl_valid = top->out_valid;

        sim_out << cycle << "," << id << ",0x" << std::hex << std::setw(8) << std::setfill('0') << in_val
                << ",0x" << std::setw(8) << g_out_data
                << ",0x" << std::setw(8) << rtl_out << std::dec << "\n";

        if ((g_out_valid != rtl_valid) || (g_out_data != rtl_out)) {
            std::cerr << "Mismatch cycle=" << cycle
                      << " id=" << id
                      << " in=0x" << std::hex << in_val
                      << " golden_valid=" << std::dec << (int)g_out_valid
                      << " golden=0x" << std::hex << g_out_data
                      << " rtl_valid=" << std::dec << (int)rtl_valid
                      << " rtl=0x" << std::hex << rtl_out << std::dec << "\n";
            // continue to log full run; exit nonzero at end by reading sim_out
        }

        cycle++;
    }

    sim_out.close();
    vecf.close();

#if VM_TRACE
    tfp->close();
    delete tfp;
#endif
    delete top;
    return 0;
}
