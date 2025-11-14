VERILATOR = verilator
TOP = top

VERILOG = rtl/top.v
TB_CPP  = tb/verilator_main.cpp
GOLDEN_C = inputs/golden_model.c

sim:
	@echo "Running Verilator build..."

	$(VERILATOR) --cc $(VERILOG) --exe \
		$(TB_CPP) \
		$(GOLDEN_C) \
		-Mdir obj_dir \
		--top-module $(TOP) \
		-CFLAGS "-Iinputs" \
		--trace

	$(MAKE) -C obj_dir -f V$(TOP).mk V$(TOP)

	@echo "Running simulation..."
	./obj_dir/V$(TOP)

clean:
	rm -rf obj_dir results/*.csv inputs/golden_exec
