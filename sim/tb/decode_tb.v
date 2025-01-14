/****************************************
* 译码级测试模块
* 
* 测试场景：
* 1. R型指令解码
* 2. I型指令解码
* 3. S型指令解码
* 4. B型指令解码
* 5. U型指令解码
* 6. J型指令解码
* 
* 每种类型测试：
* - 指令字段提取
* - 立即数生成
* - 控制信号生成
****************************************/

module decode_tb;
    // 时钟和复位信号
    reg         clk;
    reg         rst_n;
    
    // 指令接口
    reg  [31:0] inst;
    reg  [31:0] pc;
    
    // 寄存器堆接口
    wire [ 4:0] rs1_addr;
    wire [ 4:0] rs2_addr;
    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    wire [ 4:0] rd_addr;
    
    // 控制信号
    wire [ 3:0] alu_op;
    wire [ 1:0] alu_src1_sel;
    wire [ 1:0] alu_src2_sel;
    wire        mem_read;
    wire        mem_write;
    wire        reg_write;
    wire [ 1:0] reg_src_sel;
    
    // 立即数和跳转地址
    wire [31:0] imm;
    wire        branch;
    wire        jump;
    wire [31:0] branch_target;

    // 例化译码模块
    decode u_decode (
        .clk          (clk),
        .rst_n        (rst_n),
        .inst         (inst),
        .pc           (pc),
        .rs1_addr     (rs1_addr),
        .rs2_addr     (rs2_addr),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .rd_addr      (rd_addr),
        .alu_op       (alu_op),
        .alu_src1_sel (alu_src1_sel),
        .alu_src2_sel (alu_src2_sel),
        .mem_read     (mem_read),
        .mem_write    (mem_write),
        .reg_write    (reg_write),
        .reg_src_sel  (reg_src_sel),
        .imm          (imm),
        .branch       (branch),
        .jump         (jump),
        .branch_target(branch_target)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 测试用例定义
    localparam ADD  = 32'b0000000_00010_00001_000_00011_0110011;  // add  x3, x1, x2
    localparam SUB  = 32'b0100000_00010_00001_000_00011_0110011;  // sub  x3, x1, x2
    localparam ADDI = 32'b000000000100_00001_000_00011_0010011;   // addi x3, x1, 4
    localparam LW   = 32'b000000000100_00001_010_00011_0000011;   // lw   x3, 4(x1)
    localparam SW   = 32'b0000000_00010_00001_010_01100_0100011;  // sw   x2, 12(x1)
    localparam BEQ  = 32'b0000000_00010_00001_000_11000_1100011;  // beq  x1, x2, 24
    localparam LUI  = 32'b00000000000000000001_00011_0110111;     // lui  x3, 1
    localparam JAL  = 32'b00000000001000000000_00011_1101111;     // jal  x3, 8
    localparam JALR = 32'b000000000100_00001_000_00011_1100111;   // jalr x3, x1, 4
    
    // 测试激励
    initial begin
        // 初始化信号
        rst_n = 0;
        inst = 0;
        pc = 32'h1000;
        rs1_data = 32'h12345678;
        rs2_data = 32'h87654321;
        
        // 等待100ns后释放复位
        #100 rst_n = 1;
        
        // 测试R型指令
        @(posedge clk);
        inst = ADD;
        #1; // 等待组合逻辑稳定
        check_decode("ADD", 1'b0, 1'b0, 1'b1);
        
        @(posedge clk);
        inst = SUB;
        #1;
        check_decode("SUB", 1'b0, 1'b0, 1'b1);
        
        // 测试I型指令
        @(posedge clk);
        inst = ADDI;
        #1;
        check_decode("ADDI", 1'b0, 1'b0, 1'b1);
        
        @(posedge clk);
        inst = LW;
        #1;
        check_decode("LW", 1'b0, 1'b0, 1'b1);
        
        // 测试S型指令
        @(posedge clk);
        inst = SW;
        #1;
        check_decode("SW", 1'b0, 1'b1, 1'b0);
        
        // 测试B型指令
        @(posedge clk);
        inst = BEQ;
        pc = 32'h1000;
        #1;
        check_decode("BEQ", 1'b1, 1'b0, 1'b0);
        
        // 测试U型指令
        @(posedge clk);
        inst = LUI;
        #1;
        check_decode("LUI", 1'b0, 1'b0, 1'b1);
        
        // 测试J型指令
        @(posedge clk);
        inst = JAL;
        pc = 32'h1000;
        #1;
        check_decode("JAL", 1'b0, 1'b0, 1'b1);
        
        @(posedge clk);
        inst = JALR;
        #1;
        check_decode("JALR", 1'b0, 1'b0, 1'b1);
        
        // 等待一段时间后结束仿真
        #100 $finish;
    end
    
    // 波形输出
    initial begin
        $dumpfile("decode.vcd");
        $dumpvars(0, decode_tb);
    end
    
    // 检查译码结果
    task check_decode;
        input [63:0] inst_name;
        input        exp_branch;
        input        exp_mem_write;
        input        exp_reg_write;
        begin
            $display("\nTime=%0t Testing %0s", $time, inst_name);
            $display("inst=%08x pc=%08x", inst, pc);
            $display("rs1_addr=%d rs2_addr=%d rd_addr=%d", rs1_addr, rs2_addr, rd_addr);
            $display("alu_op=%d alu_src1_sel=%d alu_src2_sel=%d", alu_op, alu_src1_sel, alu_src2_sel);
            $display("mem_read=%b mem_write=%b reg_write=%b reg_src_sel=%d", 
                     mem_read, mem_write, reg_write, reg_src_sel);
            $display("imm=%08x branch=%b jump=%b branch_target=%08x",
                     imm, branch, jump, branch_target);
            
            if (branch !== exp_branch)
                $display("ERROR: branch signal mismatch: expected %b, got %b", exp_branch, branch);
            if (mem_write !== exp_mem_write)
                $display("ERROR: mem_write signal mismatch: expected %b, got %b", exp_mem_write, mem_write);
            if (reg_write !== exp_reg_write)
                $display("ERROR: reg_write signal mismatch: expected %b, got %b", exp_reg_write, reg_write);
        end
    endtask

endmodule 