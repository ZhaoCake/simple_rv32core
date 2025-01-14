# 简单RISC-V处理器

这是一个基于 RISC-V 指令集架构的简单五级流水线处理器实现。

目前进度是将要进行完整指令测试。

---

## 特点

- 支持 RV32I 基本整数指令集
- 五级流水线架构（IF/ID/EX/MEM/WB）
- 实现数据相关和控制相关处理
- 支持字节/半字/字访问
- 使用 Verilog HDL 实现
- 包含完整的测试框架

## 目录结构

```
.
├── rtl/                    # RTL设计文件
│   ├── core/              # 处理器核心模块
│   │   ├── fetch.v       # 取指级
│   │   ├── decode.v      # 译码级
│   │   ├── execute.v     # 执行级
│   │   ├── regfile.v     # 寄存器堆
│   │   └── pipeline_ctrl.v # 流水线控制
│   ├── memory/           # 存储器模块
│   │   ├── inst_mem.v    # 指令存储器
│   │   └── data_mem.v    # 数据存储器
│   └── top.v             # 顶层模块
├── sim/                   # 仿真文件
│   ├── tb/               # 测试文件
│   │   ├── top_tb.v     # 顶层测试
│   │   └── ...          # 其他模块测试
│   └── hex/              # 测试程序
│       └── inst.hex      # 指令存储器初始化文件
└── scripts/              # 编译和仿真脚本
    ├── compile.sh        # 编译脚本
    └── simulate.sh       # 仿真脚本
```

## 开发环境

- Icarus Verilog (iverilog)
- GTKWave
- GNU Make

## 编译和仿真

1. 编译所有模块：
```bash
make
```

2. 运行所有测试：
```bash
make test
```

3. 查看波形：
```bash
make wave
```

## 支持的指令

[ ] 未完全实现，需要测试完善。

## 流水线架构

1. IF (取指)：从指令存储器获取指令
2. ID (译码)：解码指令并读取寄存器
3. EX (执行)：执行ALU运算或地址计算
4. MEM (访存)：访问数据存储器
5. WB (写回)：将结果写回寄存器堆

## 数据相关处理

- 实现寄存器转发
- 实现流水线暂停
- 处理加载-使用相关

## 控制相关处理

- 分支预测：始终预测不跳转
- 分支判断在EX阶段完成
- 错误预测时刷新流水线

## 许可证

[MIT License](./LICENSE)

## 贡献

欢迎提交 Issue 和 Pull Request！