/****************************************
* 执行级测试模块
* 
* 测试场景：
* 1. ALU运算
* 2. 分支判断
* 3. 内存访问
****************************************/

module execute_tb;
    // 时钟和复位信号
    reg         clk;
    reg         rst_n;
    
    // ALU接口
    reg  [ 3:0] alu_op;
    reg  [ 1:0] alu_src1_sel;
    reg  [ 1:0] alu_src2_sel;
    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    reg  [31:0] imm;
    reg  [31:0] pc;
    wire [31:0] alu_result;
    
    // 分支控制接口
    reg         branch;
    reg         jump;
    reg  [ 2:0] funct3;
    wire        branch_taken;
    
    // 内存访问接口
    reg         mem_read;
    reg         mem_write;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    
    // 例化执行模块
    execute u_execute (
        .clk          (clk),
        .rst_n        (rst_n),
        .alu_op       (alu_op),
        .alu_src1_sel (alu_src1_sel),
        .alu_src2_sel (alu_src2_sel),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .imm          (imm),
        .pc           (pc),
        .alu_result   (alu_result),
        .branch       (branch),
        .jump         (jump),
        .funct3       (funct3),
        .branch_taken (branch_taken),
        .mem_read     (mem_read),
        .mem_write    (mem_write),
        .mem_addr     (mem_addr),
        .mem_wdata    (mem_wdata)
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
        alu_op = 0;
        alu_src1_sel = 0;
        alu_src2_sel = 0;
        rs1_data = 0;
        rs2_data = 0;
        imm = 0;
        pc = 0;
        branch = 0;
        jump = 0;
        funct3 = 0;
        mem_read = 0;
        mem_write = 0;
        
        // 等待100ns后释放复位
        #100 rst_n = 1;
        
        // 测试ALU运算
        // ADD
        @(posedge clk);
        alu_op = 4'b0000;
        rs1_data = 32'h1234_5678;
        rs2_data = 32'h8765_4321;
        #1;
        check_alu("ADD", 32'h9999_9999);
        
        // SUB
        @(posedge clk);
        alu_op = 4'b0001;
        #1;
        check_alu("SUB", 32'h8ACF_1357);
        
        // AND
        @(posedge clk);
        alu_op = 4'b0010;
        #1;
        check_alu("AND", 32'h0224_4220);
        
        // 测试分支指令
        // BEQ (equal)
        @(posedge clk);
        branch = 1;
        funct3 = 3'b000;
        rs1_data = 32'h1234_5678;
        rs2_data = 32'h1234_5678;
        #1;
        check_branch("BEQ (equal)", 1'b1);
        
        // BEQ (not equal)
        @(posedge clk);
        rs2_data = 32'h8765_4321;
        #1;
        check_branch("BEQ (not equal)", 1'b0);
        
        // BLT (less)
        @(posedge clk);
        funct3 = 3'b100;
        rs1_data = 32'h8000_0000;
        rs2_data = 32'h0000_0000;
        #1;
        check_branch("BLT (less)", 1'b1);
        
        // 测试跳转指令
        @(posedge clk);
        branch = 0;
        jump = 1;
        #1;
        check_branch("JAL", 1'b1);
        
        // 测试内存访问地址计算
        @(posedge clk);
        jump = 0;
        alu_op = 4'b0000;
        rs1_data = 32'h1000_0000;
        imm = 32'h0000_0100;
        alu_src2_sel = 2'b01;
        mem_write = 1;
        #1;
        check_mem("SW", 32'h1000_0100);
        
        // 等待一段时间后结束仿真
        #100 $finish;
    end
    
    // 波形输出
    initial begin
        $dumpfile("execute.vcd");
        $dumpvars(0, execute_tb);
    end
    
    // 检查ALU结果
    task check_alu;
        input [63:0] op_name;
        input [31:0] expected;
        begin
            $display("\nTime=%0t Testing ALU %0s", $time, op_name);
            $display("rs1_data=%08x rs2_data=%08x", rs1_data, rs2_data);
            $display("alu_result=%08x (expected=%08x)", alu_result, expected);
            if (alu_result !== expected)
                $display("ERROR: ALU result mismatch!");
        end
    endtask
    
    // 检查分支结果
    task check_branch;
        input [63:0] br_name;
        input        expected;
        begin
            $display("\nTime=%0t Testing Branch %0s", $time, br_name);
            $display("rs1_data=%08x rs2_data=%08x", rs1_data, rs2_data);
            $display("branch_taken=%b (expected=%b)", branch_taken, expected);
            if (branch_taken !== expected)
                $display("ERROR: Branch result mismatch!");
        end
    endtask
    
    // 检查内存访问
    task check_mem;
        input [63:0] op_name;
        input [31:0] expected;
        begin
            $display("\nTime=%0t Testing Memory %0s", $time, op_name);
            $display("rs1_data=%08x imm=%08x", rs1_data, imm);
            $display("mem_addr=%08x (expected=%08x)", mem_addr, expected);
            if (mem_addr !== expected)
                $display("ERROR: Memory address mismatch!");
        end
    endtask

endmodule 