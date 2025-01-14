/****************************************
* 存储器测试模块
* 
* 测试场景：
* 1. 指令存储器读取
* 2. 数据存储器读写
* 3. 字节访问
* 4. 半字访问
* 5. 字访问
****************************************/

module memory_tb;
    // 时钟和复位信号
    reg         clk;
    reg         rst_n;
    
    // 指令存储器接口
    reg  [31:0] inst_addr;
    wire [31:0] inst;
    
    // 数据存储器接口
    reg  [31:0] data_addr;
    reg  [31:0] data_wdata;
    reg  [ 3:0] data_wmask;
    reg         data_wen;
    wire [31:0] data_rdata;
    
    // 例化指令存储器
    inst_mem u_inst_mem (
        .addr     (inst_addr),
        .inst     (inst)
    );
    
    // 例化数据存储器
    data_mem u_data_mem (
        .clk      (clk),
        .rst_n    (rst_n),
        .addr     (data_addr),
        .wdata    (data_wdata),
        .wmask    (data_wmask),
        .wen      (data_wen),
        .rdata    (data_rdata)
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
        inst_addr = 0;
        data_addr = 0;
        data_wdata = 0;
        data_wmask = 0;
        data_wen = 0;
        
        // 等待100ns后释放复位
        #100 rst_n = 1;
        
        // 测试指令读取
        @(posedge clk);
        inst_addr = 32'h0;
        #1;
        check_inst("Instruction Read 1");
        if (inst !== 32'h00100093)
            $display("ERROR: Unexpected instruction at addr 0!");
        
        @(posedge clk);
        inst_addr = 32'h4;
        #1;
        check_inst("Instruction Read 2");
        if (inst !== 32'h00200113)
            $display("ERROR: Unexpected instruction at addr 4!");
        
        // 测试数据写入（字访问）
        @(posedge clk);
        data_addr = 32'h0;
        data_wdata = 32'h12345678;
        data_wmask = 4'b1111;
        data_wen = 1'b1;
        #1;
        check_data("Word Write");
        
        // 测试数据读取
        @(posedge clk);
        data_wen = 1'b0;
        #1;
        check_data("Word Read");
        
        // 测试半字写入
        @(posedge clk);
        data_addr = 32'h4;
        data_wdata = 32'h0000ABCD;
        data_wmask = 4'b0011;
        data_wen = 1'b1;
        #1;
        check_data("Halfword Write");
        
        // 测试字节写入
        @(posedge clk);
        data_addr = 32'h8;
        data_wdata = 32'h000000FF;
        data_wmask = 4'b0001;
        data_wen = 1'b1;
        #1;
        check_data("Byte Write");
        
        // 等待一段时间后结束仿真
        #100 $finish;
    end
    
    // 波形输出
    initial begin
        $dumpfile("memory.vcd");
        $dumpvars(0, memory_tb);
    end
    
    // 检查指令读取
    task check_inst;
        input [63:0] test_name;
        begin
            $display("\nTime=%0t Testing %0s", $time, test_name);
            $display("inst_addr=%08x inst=%08x", inst_addr, inst);
        end
    endtask
    
    // 检查数据访问
    task check_data;
        input [63:0] test_name;
        begin
            $display("\nTime=%0t Testing %0s", $time, test_name);
            $display("data_addr=%08x data_wdata=%08x wmask=%b wen=%b",
                     data_addr, data_wdata, data_wmask, data_wen);
            $display("data_rdata=%08x", data_rdata);
        end
    endtask

endmodule 