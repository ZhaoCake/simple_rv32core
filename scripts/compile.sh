#!/bin/bash

# 编译脚本
mkdir -p build
cd build

# 编译顶层测试
iverilog -y ../rtl/core \
         -y ../rtl/memory \
         ../rtl/top.v \
         ../sim/tb/top_tb.v \
         -o riscv_sim

# 编译寄存器堆测试
iverilog ../rtl/core/regfile.v \
         ../sim/tb/regfile_tb.v \
         -o regfile_sim

# 编译取指级测试
iverilog ../rtl/core/fetch.v \
         ../sim/tb/fetch_tb.v \
         -o fetch_sim

# 编译译码级测试
iverilog ../rtl/core/decode.v \
         ../sim/tb/decode_tb.v \
         -o decode_sim

# 编译执行级测试
iverilog ../rtl/core/execute.v \
         ../sim/tb/execute_tb.v \
         -o execute_sim

# 编译流水线控制测试
iverilog ../rtl/core/pipeline_ctrl.v \
         ../sim/tb/pipeline_ctrl_tb.v \
         -o pipeline_ctrl_sim

# 编译存储器测试
iverilog ../rtl/memory/inst_mem.v \
         ../rtl/memory/data_mem.v \
         ../sim/tb/memory_tb.v \
         -I ../sim/hex \
         -o memory_sim

# 编译处理器核心测试
iverilog -y ../rtl/core \
         -y ../rtl/memory \
         ../rtl/top.v \
         ../sim/tb/riscv_core_tb.v \
         -I ../sim/hex \
         -o riscv_core_sim 