module top_tb;
    reg clk;
    reg rst_n;

    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 复位生成
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    // DUT例化
    riscv_top u_riscv_top (
        .clk       (clk),
        .rst_n     (rst_n),
        .inst         (inst),
        .inst_addr    (inst_addr),
        .data_addr    (data_addr),
        .data_wdata   (data_wdata),
        .data_wen     (data_wen),
        .data_wmask   (data_wmask),
        .data_rdata   (data_rdata)
    );

    // 测试过程
    initial begin
        // 等待复位完成
        @(posedge rst_n);
        
        // 添加测试激励
        
        // 结束仿真
        #1000;
        $finish;
    end

    // 波形输出
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, top_tb);
    end
endmodule 