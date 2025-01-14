/****************************************
* 流水线控制测试模块
* 
* 测试场景：
* 1. 数据冒险检测
* 2. 控制冒险检测
* 3. 前递控制
* 4. 流水线暂停
* 5. 流水线刷新
****************************************/

module pipeline_ctrl_tb;
    // 时钟和复位信号
    reg         clk;
    reg         rst_n;
    
    // 数据冒险检测接口
    reg  [ 4:0] id_rs1;
    reg  [ 4:0] id_rs2;
    reg  [ 4:0] ex_rd;
    reg  [ 4:0] mem_rd;
    reg         ex_reg_write;
    reg         mem_reg_write;
    
    // 控制冒险检测接口
    reg         branch_taken;
    reg         jump;
    
    // 前递控制接口
    wire [ 1:0] forward_a;
    wire [ 1:0] forward_b;
    
    // 流水线控制接口
    wire        if_stall;
    wire        id_stall;
    wire        ex_stall;
    wire        if_flush;
    wire        id_flush;
    wire        ex_flush;
    
    // 例化流水线控制模块
    pipeline_ctrl u_pipeline_ctrl (
        .clk           (clk),
        .rst_n         (rst_n),
        .id_rs1        (id_rs1),
        .id_rs2        (id_rs2),
        .ex_rd         (ex_rd),
        .mem_rd        (mem_rd),
        .ex_reg_write  (ex_reg_write),
        .mem_reg_write (mem_reg_write),
        .branch_taken  (branch_taken),
        .jump          (jump),
        .forward_a     (forward_a),
        .forward_b     (forward_b),
        .if_stall      (if_stall),
        .id_stall      (id_stall),
        .ex_stall      (ex_stall),
        .if_flush      (if_flush),
        .id_flush      (id_flush),
        .ex_flush      (ex_flush)
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
        id_rs1 = 0;
        id_rs2 = 0;
        ex_rd = 0;
        mem_rd = 0;
        ex_reg_write = 0;
        mem_reg_write = 0;
        branch_taken = 0;
        jump = 0;
        
        // 等待100ns后释放复位
        #100 rst_n = 1;
        
        // 测试数据冒险 - EX阶段前递
        @(posedge clk);
        id_rs1 = 5'd1;
        id_rs2 = 5'd2;
        ex_rd = 5'd1;
        ex_reg_write = 1'b1;
        #1;
        check_hazard("EX Forwarding", 2'b01, 2'b00);
        
        // 测试数据冒险 - MEM阶段前递
        @(posedge clk);
        ex_rd = 5'd0;
        ex_reg_write = 1'b0;
        mem_rd = 5'd2;
        mem_reg_write = 1'b1;
        #1;
        check_hazard("MEM Forwarding", 2'b00, 2'b10);
        
        // 测试加载使用冒险
        @(posedge clk);
        id_rs1 = 5'd3;
        ex_rd = 5'd3;
        ex_reg_write = 1'b1;
        #1;
        check_stall("Load-Use Hazard");
        
        // 测试分支冒险
        @(posedge clk);
        branch_taken = 1'b1;
        #1;
        check_flush("Branch Hazard");
        
        // 测试跳转冒险
        @(posedge clk);
        branch_taken = 1'b0;
        jump = 1'b1;
        #1;
        check_flush("Jump Hazard");
        
        // 等待一段时间后结束仿真
        #100 $finish;
    end
    
    // 波形输出
    initial begin
        $dumpfile("pipeline_ctrl.vcd");
        $dumpvars(0, pipeline_ctrl_tb);
    end
    
    // 检查前递控制
    task check_hazard;
        input [63:0] hzd_name;
        input [ 1:0] exp_fwd_a;
        input [ 1:0] exp_fwd_b;
        begin
            $display("\nTime=%0t Testing %0s", $time, hzd_name);
            $display("id_rs1=%0d id_rs2=%0d ex_rd=%0d mem_rd=%0d",
                     id_rs1, id_rs2, ex_rd, mem_rd);
            $display("forward_a=%0d forward_b=%0d", forward_a, forward_b);
            if (forward_a !== exp_fwd_a)
                $display("ERROR: forward_a mismatch: expected %0d, got %0d",
                         exp_fwd_a, forward_a);
            if (forward_b !== exp_fwd_b)
                $display("ERROR: forward_b mismatch: expected %0d, got %0d",
                         exp_fwd_b, forward_b);
        end
    endtask
    
    // 检查流水线暂停
    task check_stall;
        input [63:0] stall_name;
        begin
            $display("\nTime=%0t Testing %0s", $time, stall_name);
            $display("if_stall=%0b id_stall=%0b ex_stall=%0b",
                     if_stall, id_stall, ex_stall);
            if (!if_stall || !id_stall || ex_stall)
                $display("ERROR: Pipeline stall signals mismatch!");
        end
    endtask
    
    // 检查流水线刷新
    task check_flush;
        input [63:0] flush_name;
        begin
            $display("\nTime=%0t Testing %0s", $time, flush_name);
            $display("if_flush=%0b id_flush=%0b ex_flush=%0b",
                     if_flush, id_flush, ex_flush);
            if (!if_flush || !id_flush || ex_flush)
                $display("ERROR: Pipeline flush signals mismatch!");
        end
    endtask

endmodule 