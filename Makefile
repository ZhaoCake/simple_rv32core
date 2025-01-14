# 项目根目录 Makefile
RTL_DIR    := rtl
SIM_DIR    := sim
SCRIPTS_DIR := scripts
DOC_DIR    := docs

# 编译器设置
VERILATOR  := verilator
VERILATOR_FLAGS := --cc --trace

# 默认目标
all: compile sim

# 编译RTL
compile:
	@echo "Compiling RTL..."
	@$(SCRIPTS_DIR)/compile.sh

# 运行仿真
sim:
	@echo "Running simulation..."
	@$(SCRIPTS_DIR)/simulate.sh

# 清理
clean:
	@rm -rf build/*
	@rm -rf sim/work/*

.PHONY: all compile sim clean 