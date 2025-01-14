/****************************************
* RISC-V 取指级模块
* 
* 功能：
* 1. 维护程序计数器(PC)
* 2. 处理分支跳转
* 3. 生成指令访问地址
* 
* 特点：
* - 支持流水线暂停
* - 支持分支跳转
* - 4字节对齐的指令访问
****************************************/

module fetch (
    input  wire        clk,          // 时钟信号
    input  wire        rst_n,        // 复位信号（低电平有效）
    
    // 流水线控制接口
    input  wire        stall,        // 流水线暂停信号
    
    // 分支跳转接口
    input  wire        branch_taken, // 分支成立信号
    input  wire [31:0] branch_addr,  // 分支目标地址
    
    // 取指接口
    output reg  [31:0] pc,          // 程序计数器
    output wire [31:0] inst_addr,    // 指令访问地址
    
    // 调试接口
    output wire [31:0] next_pc      // 下一条指令地址
);

    /**************** PC计算逻辑 ****************/
    
    // 计算下一条指令地址
    // 优先级：分支跳转 > 顺序执行
    wire [31:0] seq_pc = pc + 4;    // 顺序执行的下一条指令地址
    
    assign next_pc = branch_taken ? branch_addr : seq_pc;
    
    // PC更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时PC清零
            pc <= 32'h0;
        end else if (!stall) begin
            // 非暂停时更新PC
            pc <= next_pc;
        end
        // 暂停时保持PC不变
    end
    
    /**************** 指令访问接口 ****************/
    
    // 指令地址直接使用当前PC
    // 注意：这里假设指令存储器是字对齐的，且访问不需要等待
    assign inst_addr = pc;
    
    /**************** 断言检查 ****************/
    
    // 复位后PC应该是4字节对齐的
    always @(posedge clk) begin
        if (rst_n && pc[1:0] !== 2'b00) begin
            $error("PC alignment error: pc = %h", pc);
        end
    end
    
    // 分支目标地址应该是4字节对齐的
    always @(posedge clk) begin
        if (branch_taken && branch_addr[1:0] !== 2'b00) begin
            $error("Branch target alignment error: branch_addr = %h", branch_addr);
        end
    end

endmodule 