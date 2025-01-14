module regfile_tb;
    reg         clk;
    reg         rst_n;
    reg  [ 4:0] rs1_addr;
    wire [31:0] rs1_data;
    reg  [ 4:0] rs2_addr;
    wire [31:0] rs2_data;
    reg         we;
    reg  [ 4:0] rd_addr;
    reg  [31:0] rd_data;

    // 例化寄存器堆
    regfile u_regfile (
        .clk       (clk),
        .rst_n     (rst_n),
        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),
        .rd_data   (rd_data),
        .reg_write (we),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
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
        rs1_addr = 0;
        rs2_addr = 0;
        we = 0;
        rd_addr = 0;
        rd_data = 0;

        // 等待100ns后释放复位
        #100 rst_n = 1;
        
        // 测试写入x1寄存器
        @(posedge clk);
        we = 1;
        rd_addr = 5'd1;
        rd_data = 32'h12345678;
        
        // 测试写入x2寄存器
        @(posedge clk);
        rd_addr = 5'd2;
        rd_data = 32'h87654321;
        
        // 测试读取x1和x2
        @(posedge clk);
        we = 0;
        rs1_addr = 5'd1;
        rs2_addr = 5'd2;
        
        // 测试写入x0（应该无效）
        @(posedge clk);
        we = 1;
        rd_addr = 5'd0;
        rd_data = 32'hFFFFFFFF;
        
        // 测试读取x0（应该为0）
        @(posedge clk);
        we = 0;
        rs1_addr = 5'd0;
        
        // 等待一段时间后结束仿真
        #100 $finish;
    end

    // 波形输出
    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, regfile_tb);
    end

    // 监控测试结果
    always @(posedge clk) begin
        if (rst_n) begin
            $display("Time=%0t rs1_addr=%0d rs1_data=%8h rs2_addr=%0d rs2_data=%8h",
                     $time, rs1_addr, rs1_data, rs2_addr, rs2_data);
        end
    end

endmodule 