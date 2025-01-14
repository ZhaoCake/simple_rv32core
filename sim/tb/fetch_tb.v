/****************************************
* 取指级测试模块
* 
* 测试场景：
* 1. 复位功能
* 2. 顺序取指
* 3. 分支跳转
* 4. 流水线暂停
****************************************/

module fetch_tb;
    // 时钟和复位信号
    reg         clk;
    reg         rst_n;
    
    // 流水线控制信号
    reg         stall;
    
    // 分支控制信号
    reg         branch_taken;
    reg  [31:0] branch_addr;
    
    // 取指接口
    wire [31:0] pc;
    wire [31:0] inst_addr;
    wire [31:0] next_pc;
    
    // 例化取指模块
    fetch u_fetch (
        .clk         (clk),
        .rst_n       (rst_n),
        .stall       (stall),
        .branch_taken(branch_taken),
        .branch_addr (branch_addr),
        .pc          (pc),
        .inst_addr   (inst_addr),
        .next_pc     (next_pc)
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
        stall = 0;
        branch_taken = 0;
        branch_addr = 0;
        
        // 等待100ns后释放复位
        #100 rst_n = 1;
        
        // 测试场景1：顺序取指
        repeat(5) @(posedge clk);
        
        // 测试场景2：流水线暂停
        stall = 1;
        repeat(3) @(posedge clk);
        stall = 0;
        
        // 测试场景3：分支跳转
        @(posedge clk);
        branch_taken = 1;
        branch_addr = 32'h1000;
        @(posedge clk);
        branch_taken = 0;
        
        // 测试场景4：分支跳转 + 流水线暂停
        repeat(3) @(posedge clk);
        branch_taken = 1;
        branch_addr = 32'h2000;
        stall = 1;
        @(posedge clk);
        stall = 0;
        branch_taken = 0;
        
        // 等待一段时间后结束仿真
        #100 $finish;
    end
    
    // 波形输出
    initial begin
        $dumpfile("fetch.vcd");
        $dumpvars(0, fetch_tb);
    end
    
    // 监控测试结果
    always @(posedge clk) begin
        if (rst_n) begin
            $display("Time=%0t pc=%h next_pc=%h stall=%b branch_taken=%b branch_addr=%h",
                     $time, pc, next_pc, stall, branch_taken, branch_addr);
        end
    end

endmodule 