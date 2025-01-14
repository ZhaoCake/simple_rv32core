/****************************************
* RISC-V 处理器顶层测试模块
* 
* 测试场景：
* 1. 基本指令执行
* 2. 数据相关处理
* 3. 控制相关处理
* 4. 存储器访问
* 5. 流水线控制
****************************************/

module riscv_core_tb;
    // 时钟和复位信号
    reg         clk;
    reg         rst_n;
    
    // 指令存储器接口
    wire [31:0] inst_addr;
    wire [31:0] inst;
    
    // 数据存储器接口
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [ 3:0] data_wmask;
    wire        data_wen;
    wire [31:0] data_rdata;
    
    // 例化处理器核心
    riscv_top u_riscv_top (
        .clk          (clk),
        .rst_n        (rst_n),
        .inst_addr    (inst_addr),
        .inst         (inst),
        .data_addr    (data_addr),
        .data_wdata   (data_wdata),
        .data_wmask   (data_wmask),
        .data_wen     (data_wen),
        .data_rdata   (data_rdata)
    );
    
    // 例化指令存储器
    inst_mem u_inst_mem (
        .addr         (inst_addr),
        .inst         (inst)
    );
    
    // 例化数据存储器
    data_mem u_data_mem (
        .clk          (clk),
        .rst_n        (rst_n),
        .addr         (data_addr),
        .wdata        (data_wdata),
        .wmask        (data_wmask),
        .wen          (data_wen),
        .rdata        (data_rdata)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 测试激励
    initial begin
        // 初始化信号
        rst_n = 0;
        
        // 等待100ns后释放复位
        #100 rst_n = 1;
        
        // 等待指令执行完成
        // 测试程序：
// addi x1, x0, 5    // x1 = 5
// addi x2, x0, 3    // x2 = 3
// sub  x3, x1, x2   // x3 = x1 - x2 = 2
// sw   x3, 4(x0)    // mem[4] = x3
// lw   x4, 4(x0)    // x4 = mem[4]
        repeat(20) @(posedge clk);
        
        // 检查结果
        check_result;
        
        // 等待一段时间后结束仿真
        #100 $finish;
    end
    
    // 波形输出
    initial begin
        $dumpfile("riscv_core.vcd");
        $dumpvars(0, riscv_core_tb);
    end
    
    // 检查处理器状态
    task check_result;
        begin
            $display("\nTime=%0t Checking processor state", $time);
            
            // 检查寄存器值
            if (u_riscv_top.u_regfile.regs[1] !== 32'h5)
                $display("ERROR: x1 should be 5, got %0d", 
                         u_riscv_top.u_regfile.regs[1]);
                         
            if (u_riscv_top.u_regfile.regs[2] !== 32'h3)
                $display("ERROR: x2 should be 3, got %0d",
                         u_riscv_top.u_regfile.regs[2]);
                         
            if (u_riscv_top.u_regfile.regs[3] !== 32'h2)
                $display("ERROR: x3 should be 2, got %0d",
                         u_riscv_top.u_regfile.regs[3]);
                         
            if (u_riscv_top.u_regfile.regs[4] !== 32'h2)
                $display("ERROR: x4 should be 2, got %0d",
                         u_riscv_top.u_regfile.regs[4]);
                         
            // 检查内存值
            if ({u_data_mem.mem[3], u_data_mem.mem[2],
                 u_data_mem.mem[1], u_data_mem.mem[0]} !== 32'h3)
                $display("ERROR: mem[0] should be 3, got %0d",
                         {u_data_mem.mem[3],
                          u_data_mem.mem[2],
                          u_data_mem.mem[1],
                          u_data_mem.mem[0]});
                          
            $display("Test completed");
        end
    endtask

endmodule 