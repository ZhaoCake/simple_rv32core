/****************************************
* RISC-V 处理器顶层模块
* 
* 特点：
* - 五级流水线架构
* - 支持RV32I基本指令集
* - 实现数据相关和控制相关处理
* - 支持字节/半字/字访问
****************************************/

module riscv_top (
    input  wire        clk,          // 时钟信号
    input  wire        rst_n,        // 复位信号（低电平有效）
    
    // 指令存储器接口
    output wire [31:0] inst_addr,    // 指令地址
    input  wire [31:0] inst,         // 读取的指令
    
    // 数据存储器接口
    output wire [31:0] data_addr,    // 数据地址
    output wire [31:0] data_wdata,   // 写数据
    output wire [ 3:0] data_wmask,   // 写掩码
    output wire        data_wen,     // 写使能
    input  wire [31:0] data_rdata,   // 读数据
    output wire [ 1:0] data_size     // 访问大小：00=byte, 01=half, 10=word
);

    /**************** IF阶段信号 ****************/
    wire [31:0] if_pc;              // IF阶段PC值
    wire [31:0] if_next_pc;         // 下一条指令地址
    
    /**************** ID阶段信号 ****************/
    wire [31:0] id_pc;              // ID阶段PC值
    wire [31:0] id_inst;            // ID阶段指令
    wire [31:0] id_rs1_data;        // rs1数据
    wire [31:0] id_rs2_data;        // rs2数据
    wire [ 4:0] id_rs1;             // rs1地址
    wire [ 4:0] id_rs2;             // rs2地址
    wire [ 4:0] id_rd;              // rd地址
    wire [31:0] id_imm;             // 立即数
    wire [ 3:0] id_alu_op;          // ALU操作码
    wire [ 1:0] id_alu_src1_sel;    // ALU操作数1来源
    wire [ 1:0] id_alu_src2_sel;    // ALU操作数2来源
    wire        id_mem_read;         // 内存读使能
    wire        id_mem_write;        // 内存写使能
    wire        id_reg_write;        // 寄存器写使能
    wire [ 1:0] id_reg_src_sel;     // 寄存器写数据来源
    wire        id_branch;           // 分支指令标志
    wire        id_jump;             // 跳转指令标志
    
    /**************** EX阶段信号 ****************/
    wire [31:0] ex_pc;              // EX阶段PC值
    wire [31:0] ex_rs1_data;        // rs1数据
    wire [31:0] ex_rs2_data;        // rs2数据
    wire [31:0] ex_imm;             // 立即数
    wire [ 4:0] ex_rd;              // rd地址
    wire [31:0] ex_alu_result;      // ALU计算结果
    wire        ex_branch_taken;     // 分支成立标志
    wire [31:0] ex_branch_target;   // 分支目标地址
    
    /**************** MEM阶段信号 ****************/
    wire [31:0] mem_alu_result;     // MEM阶段ALU结果
    wire [31:0] mem_read_data;      // 内存读取数据
    wire [ 4:0] mem_rd;             // MEM阶段rd地址
    
    /**************** WB阶段信号 ****************/
    wire [31:0] wb_write_data;      // 写回数据
    wire [ 4:0] wb_rd;              // WB阶段rd地址
    wire        wb_reg_write;       // WB阶段寄存器写使能
    reg  [31:0] mem_wb_pc;         // MEM/WB阶段PC值
    
    /**************** 流水线控制信号 ****************/
    wire [ 1:0] forward_a;          // rs1数据前递控制
    wire [ 1:0] forward_b;          // rs2数据前递控制
    wire        if_stall;           // IF阶段暂停
    wire        id_stall;           // ID阶段暂停
    wire        ex_stall;           // EX阶段暂停
    wire        if_flush;           // IF阶段刷新
    wire        id_flush;           // ID阶段刷新
    wire        ex_flush;           // EX阶段刷新
    
    /**************** IF级 ****************/
    fetch u_fetch (
        .clk          (clk),
        .rst_n        (rst_n),
        .stall        (if_stall),
        .branch_taken (ex_branch_taken),
        .branch_addr  (ex_branch_target),
        .pc           (if_pc),
        .inst_addr    (inst_addr),
        .next_pc      (if_next_pc)
    );
    
    /**************** IF/ID流水线寄存器 ****************/
    reg [31:0] if_id_pc;
    reg [31:0] if_id_inst;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_pc   <= 32'h0;
            if_id_inst <= 32'h0;
        end else if (if_flush) begin
            if_id_pc   <= 32'h0;
            if_id_inst <= 32'h0;
        end else if (!if_stall) begin
            if_id_pc   <= if_pc;
            if_id_inst <= inst;
        end
    end
    
    /**************** ID级 ****************/
    decode u_decode (
        .clk          (clk),
        .rst_n        (rst_n),
        .pc           (if_id_pc),
        .inst         (if_id_inst),
        .rs1_data     (id_rs1_data),
        .rs2_data     (id_rs2_data),
        .rs1_addr     (id_rs1),
        .rs2_addr     (id_rs2),
        .rd_addr      (id_rd),
        .imm          (id_imm),
        .alu_op       (id_alu_op),
        .alu_src1_sel (id_alu_src1_sel),
        .alu_src2_sel (id_alu_src2_sel),
        .mem_read     (id_mem_read),
        .mem_write    (id_mem_write),
        .reg_write    (id_reg_write),
        .reg_src_sel  (id_reg_src_sel),
        .branch       (id_branch),
        .jump         (id_jump)
    );
    
    /**************** 寄存器堆 ****************/
    regfile u_regfile (
        .clk          (clk),
        .rst_n        (rst_n),
        .rs1_addr     (id_rs1),
        .rs2_addr     (id_rs2),
        .rd_addr      (wb_rd),
        .rd_data      (wb_write_data),
        .reg_write    (wb_reg_write),
        .rs1_data     (id_rs1_data),
        .rs2_data     (id_rs2_data)
    );
    
    /**************** ID/EX流水线寄存器 ****************/
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_inst;          // ID/EX阶段指令
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;
    reg [31:0] id_ex_imm;
    reg [ 4:0] id_ex_rd;
    reg [ 3:0] id_ex_alu_op;
    reg [ 1:0] id_ex_alu_src1_sel;
    reg [ 1:0] id_ex_alu_src2_sel;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_reg_write;
    reg [ 1:0] id_ex_reg_src_sel;
    reg        id_ex_branch;
    reg        id_ex_jump;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || id_flush) begin
            id_ex_pc           <= 32'h0;
            id_ex_inst        <= 32'h0;
            id_ex_rs1_data    <= 32'h0;
            id_ex_rs2_data    <= 32'h0;
            id_ex_imm         <= 32'h0;
            id_ex_rd          <= 5'h0;
            id_ex_alu_op      <= 4'h0;
            id_ex_alu_src1_sel<= 2'h0;
            id_ex_alu_src2_sel<= 2'h0;
            id_ex_mem_read    <= 1'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_reg_write   <= 1'b0;
            id_ex_reg_src_sel <= 2'h0;
            id_ex_branch      <= 1'b0;
            id_ex_jump        <= 1'b0;
        end else if (!id_stall) begin
            id_ex_pc           <= if_id_pc;
            id_ex_inst        <= if_id_inst;
            id_ex_rs1_data    <= id_rs1_data;
            id_ex_rs2_data    <= id_rs2_data;
            id_ex_imm         <= id_imm;
            id_ex_rd          <= id_rd;
            id_ex_alu_op      <= id_alu_op;
            id_ex_alu_src1_sel<= id_alu_src1_sel;
            id_ex_alu_src2_sel<= id_alu_src2_sel;
            id_ex_mem_read    <= id_mem_read;
            id_ex_mem_write   <= id_mem_write;
            id_ex_reg_write   <= id_reg_write;
            id_ex_reg_src_sel <= id_reg_src_sel;
            id_ex_branch      <= id_branch;
            id_ex_jump        <= id_jump;
        end
    end
    
    /**************** EX级 ****************/
    assign ex_branch_target = id_ex_pc + id_ex_imm;  // 分支目标地址计算
    
    execute u_execute (
        .clk          (clk),
        .rst_n        (rst_n),
        .alu_op       (id_ex_alu_op),
        .alu_src1_sel (id_ex_alu_src1_sel),
        .alu_src2_sel (id_ex_alu_src2_sel),
        .rs1_data     (id_ex_rs1_data),
        .rs2_data     (id_ex_rs2_data),
        .imm          (id_ex_imm),
        .pc           (id_ex_pc),
        .alu_result   (ex_alu_result),
        .branch       (id_ex_branch),
        .jump         (id_ex_jump),
        .funct3       (id_ex_inst[14:12]),
        .branch_taken (ex_branch_taken),
        .mem_read     (id_ex_mem_read),
        .mem_write    (id_ex_mem_write),
        .mem_addr     (data_addr),
        .mem_wdata    (data_wdata)
    );
    
    /**************** EX/MEM流水线寄存器 ****************/
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_pc;          // EX/MEM阶段PC值
    reg [ 4:0] ex_mem_rd;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg [ 1:0] ex_mem_reg_src_sel;
    reg        ex_mem_reg_write;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_result  <= 32'h0;
            ex_mem_pc         <= 32'h0;
            ex_mem_rd         <= 5'h0;
            ex_mem_mem_read   <= 1'b0;
            ex_mem_mem_write  <= 1'b0;
            ex_mem_reg_src_sel<= 2'h0;
            ex_mem_reg_write  <= 1'b0;
        end else if (!ex_stall) begin
            ex_mem_alu_result  <= ex_alu_result;
            ex_mem_pc         <= id_ex_pc;
            ex_mem_rd         <= id_ex_rd;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_reg_src_sel<= id_ex_reg_src_sel;
            ex_mem_reg_write  <= id_ex_reg_write;
        end
    end
    
    /**************** MEM级 ****************/
    assign data_wmask = ex_mem_mem_write ? 4'b1111 : 4'b0000;
    assign data_wen   = ex_mem_mem_write;
    
    /**************** MEM/WB流水线寄存器 ****************/
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_read_data;
    reg [ 4:0] mem_wb_rd;
    reg [ 1:0] mem_wb_reg_src_sel;
    reg        mem_wb_reg_write;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_alu_result  <= 32'h0;
            mem_wb_read_data  <= 32'h0;
            mem_wb_rd         <= 5'h0;
            mem_wb_reg_src_sel<= 2'h0;
            mem_wb_reg_write  <= 1'b0;
            mem_wb_pc         <= 32'h0;
        end else begin
            mem_wb_alu_result  <= ex_mem_alu_result;
            mem_wb_read_data  <= data_rdata;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_src_sel<= ex_mem_reg_src_sel;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_pc         <= ex_mem_pc;
        end
    end
    
    /**************** WB级 ****************/
    assign wb_write_data = (mem_wb_reg_src_sel == 2'b00) ? mem_wb_alu_result :
                          (mem_wb_reg_src_sel == 2'b01) ? mem_wb_read_data :
                          (mem_wb_reg_src_sel == 2'b10) ? mem_wb_pc + 4 :
                          32'h0;
    
    assign wb_rd = mem_wb_rd;
    assign wb_reg_write = mem_wb_reg_write;
    
    /**************** 流水线控制 ****************/
    pipeline_ctrl u_pipeline_ctrl (
        .clk           (clk),
        .rst_n         (rst_n),
        .id_rs1        (id_rs1),
        .id_rs2        (id_rs2),
        .ex_rd         (id_ex_rd),
        .mem_rd        (ex_mem_rd),
        .ex_reg_write  (id_ex_reg_write),
        .mem_reg_write (ex_mem_reg_write),
        .branch_taken  (ex_branch_taken),
        .jump          (id_ex_jump),
        .forward_a     (forward_a),
        .forward_b     (forward_b),
        .if_stall      (if_stall),
        .id_stall      (id_stall),
        .ex_stall      (ex_stall),
        .if_flush      (if_flush),
        .id_flush      (id_flush),
        .ex_flush      (ex_flush)
    );

    /**************** 内存访问控制 ****************/
    // 生成写掩码
    reg [3:0] wmask;
    always @(*) begin
        case (ex_mem_size)
            2'b00: wmask = 4'b0001 << data_addr[1:0];  // SB
            2'b01: wmask = 4'b0011 << {data_addr[1], 1'b0};  // SH
            2'b10: wmask = 4'b1111;  // SW
            default: wmask = 4'b0000;
        endcase
    end
    assign data_wmask = ex_mem_mem_write ? wmask : 4'b0000;

    // 处理非对齐访问的读数据
    reg [31:0] aligned_rdata;
    always @(*) begin
        case (mem_wb_size)
            2'b00: begin  // LB/LBU
                case (mem_wb_addr[1:0])
                    2'b00: aligned_rdata = {{24{mem_wb_signed & data_rdata[7]}}, data_rdata[7:0]};
                    2'b01: aligned_rdata = {{24{mem_wb_signed & data_rdata[15]}}, data_rdata[15:8]};
                    2'b10: aligned_rdata = {{24{mem_wb_signed & data_rdata[23]}}, data_rdata[23:16]};
                    2'b11: aligned_rdata = {{24{mem_wb_signed & data_rdata[31]}}, data_rdata[31:24]};
                endcase
            end
            2'b01: begin  // LH/LHU
                case (mem_wb_addr[1])
                    1'b0: aligned_rdata = {{16{mem_wb_signed & data_rdata[15]}}, data_rdata[15:0]};
                    1'b1: aligned_rdata = {{16{mem_wb_signed & data_rdata[31]}}, data_rdata[31:16]};
                endcase
            end
            2'b10: aligned_rdata = data_rdata;  // LW
            default: aligned_rdata = data_rdata;
        endcase
    end

endmodule 