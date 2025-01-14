module top_tb;
    reg clk;
    reg rst_n;

    // 指令存储器接口
    wire [31:0] inst_addr;
    wire [31:0] inst;

    // 数据存储器接口
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [ 3:0] data_wmask;
    wire        data_wen;
    wire [31:0] data_rdata;

    // 指令存储器
    inst_mem u_inst_mem (
        .addr         (inst_addr),
        .inst         (inst)
    );

    // 数据存储器
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

    // 复位生成
    initial begin
        rst_n = 0;
        #100 rst_n = 1;

        // 等待指令执行完成
        repeat(20) @(posedge clk);

        // 检查结果
        check_result;

        // 等待一段时间后结束仿真
        #100 $finish;
    end

    // DUT例化
    riscv_top u_riscv_top (
        .clk          (clk),
        .rst_n        (rst_n),
        .inst         (inst),
        .inst_addr    (inst_addr),
        .data_addr    (data_addr),
        .data_wdata   (data_wdata),
        .data_wen     (data_wen),
        .data_wmask   (data_wmask),
        .data_rdata   (data_rdata)
    );

    // 波形输出
    initial begin
        $dumpfile("riscv_core.vcd");
        $dumpvars(0, top_tb);
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
            if ({u_data_mem.mem[7], u_data_mem.mem[6],
                 u_data_mem.mem[5], u_data_mem.mem[4]} !== 32'h2)
                $display("ERROR: mem[4] should be 2, got %0d",
                         {u_data_mem.mem[7],
                          u_data_mem.mem[6],
                          u_data_mem.mem[5],
                          u_data_mem.mem[4]});

            $display("Test completed");
        end
    endtask
endmodule 