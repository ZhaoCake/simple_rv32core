#!/bin/bash

# 仿真脚本
cd build

# 运行寄存器堆测试
./regfile_sim

# 运行取指级测试
./fetch_sim

# 运行译码级测试
./decode_sim

# 运行执行级测试
./execute_sim

# 运行流水线控制测试
./pipeline_ctrl_sim

# 运行存储器测试
./memory_sim

# 运行处理器核心测试
./riscv_core_sim

# 如果使用GTKWave查看波形
if [ -f "riscv_core.vcd" ]; then
    gtkwave riscv_core.vcd
fi 