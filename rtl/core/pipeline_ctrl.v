/****************************************
* RISC-V 流水线控制模块
* 
* 功能：
* 1. 数据冒险检测与处理
* 2. 控制冒险检测与处理
* 3. 生成流水线控制信号
* 
* 数据冒险类型：
* - RAW: 读后写
* - WAW: 写后写
* - WAR: 写后读
* 
* 控制冒险：
* - 分支预测错误
* - 跳转指令
****************************************/

module pipeline_ctrl (
    input  wire        clk,          // 时钟信号
    input  wire        rst_n,        // 复位信号（低电平有效）
    
    // 数据冒险检测接口
    input  wire [ 4:0] id_rs1,       // ID阶段rs1地址
    input  wire [ 4:0] id_rs2,       // ID阶段rs2地址
    input  wire [ 4:0] ex_rd,        // EX阶段目标寄存器地址
    input  wire [ 4:0] mem_rd,       // MEM阶段目标寄存器地址
    input  wire        ex_reg_write, // EX阶段寄存器写使能
    input  wire        mem_reg_write,// MEM阶段寄存器写使能
    
    // 控制冒险检测接口
    input  wire        branch_taken, // 分支成立信号
    input  wire        jump,         // 跳转指令信号
    
    // 前递控制接口
    output reg  [ 1:0] forward_a,    // rs1数据前递控制
    output reg  [ 1:0] forward_b,    // rs2数据前递控制
    
    // 流水线控制接口
    output reg         if_stall,     // IF阶段暂停
    output reg         id_stall,     // ID阶段暂停
    output reg         ex_stall,     // EX阶段暂停
    output reg         if_flush,     // IF阶段刷新
    output reg         id_flush,     // ID阶段刷新
    output reg         ex_flush      // EX阶段刷新
);

    /**************** 前递控制逻辑 ****************/
    
    // 前递控制信号定义
    localparam FWD_NONE = 2'b00;    // 不需要前递
    localparam FWD_EX   = 2'b01;    // 从EX阶段前递
    localparam FWD_MEM  = 2'b10;    // 从MEM阶段前递
    
    // rs1的前递逻辑
    always @(*) begin
        if (ex_reg_write && (ex_rd != 5'b0) && (ex_rd == id_rs1)) begin
            forward_a = FWD_EX;      // EX阶段前递
        end else if (mem_reg_write && (mem_rd != 5'b0) && (mem_rd == id_rs1)) begin
            forward_a = FWD_MEM;     // MEM阶段前递
        end else begin
            forward_a = FWD_NONE;    // 不需要前递
        end
    end
    
    // rs2的前递逻辑
    always @(*) begin
        if (ex_reg_write && (ex_rd != 5'b0) && (ex_rd == id_rs2)) begin
            forward_b = FWD_EX;      // EX阶段前递
        end else if (mem_reg_write && (mem_rd != 5'b0) && (mem_rd == id_rs2)) begin
            forward_b = FWD_MEM;     // MEM阶段前递
        end else begin
            forward_b = FWD_NONE;    // 不需要前递
        end
    end
    
    /**************** 流水线控制逻辑 ****************/
    
    // 数据冒险导致的暂停
    wire load_use_hazard = (ex_reg_write && (ex_rd != 5'b0) && 
                          ((ex_rd == id_rs1) || (ex_rd == id_rs2)));
    
    // 控制冒险导致的刷新
    wire control_hazard = branch_taken || jump;
    
    // 流水线暂停控制
    always @(*) begin
        if (load_use_hazard) begin
            // 加载使用冒险：暂停IF和ID阶段
            if_stall = 1'b1;
            id_stall = 1'b1;
            ex_stall = 1'b0;
        end else begin
            if_stall = 1'b0;
            id_stall = 1'b0;
            ex_stall = 1'b0;
        end
    end
    
    // 流水线刷新控制
    always @(*) begin
        if (control_hazard) begin
            // 控制冒险：刷新IF和ID阶段
            if_flush = 1'b1;
            id_flush = 1'b1;
            ex_flush = 1'b0;
        end else begin
            if_flush = 1'b0;
            id_flush = 1'b0;
            ex_flush = 1'b0;
        end
    end

endmodule 