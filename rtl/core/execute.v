/****************************************
* RISC-V 执行级模块
* 
* 功能：
* 1. ALU运算
* 2. 分支条件判断
* 3. 内存访问地址计算
* 
* ALU操作：
* - 算术：ADD/SUB
* - 逻辑：AND/OR/XOR
* - 移位：SLL/SRL/SRA
* - 比较：SLT/SLTU
* 
* 分支类型：
* - BEQ/BNE：相等/不等
* - BLT/BGE：小于/大于等于
* - BLTU/BGEU：无符号比较
****************************************/

module execute (
    input  wire        clk,          // 时钟信号
    input  wire        rst_n,        // 复位信号（低电平有效）
    
    // ALU接口
    input  wire [ 3:0] alu_op,       // ALU操作码
    input  wire [ 1:0] alu_src1_sel, // 操作数1来源选择
    input  wire [ 1:0] alu_src2_sel, // 操作数2来源选择
    input  wire [31:0] rs1_data,     // 寄存器1数据
    input  wire [31:0] rs2_data,     // 寄存器2数据
    input  wire [31:0] imm,          // 立即数
    input  wire [31:0] pc,           // 程序计数器
    output reg  [31:0] alu_result,   // ALU计算结果
    
    // 分支控制接口
    input  wire        branch,       // 分支指令标志
    input  wire        jump,         // 跳转指令标志
    input  wire [ 2:0] funct3,       // 分支类型
    output reg         branch_taken, // 分支成立标志
    
    // 内存访问接口
    input  wire        mem_read,     // 内存读使能
    input  wire        mem_write,    // 内存写使能
    output wire [31:0] mem_addr,     // 内存访问地址
    output wire [31:0] mem_wdata     // 内存写数据
);

    /**************** ALU操作码定义 ****************/
    
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;
    
    /**************** 操作数选择 ****************/
    
    localparam ALU_SRC_REG  = 2'b00;  // 寄存器值
    localparam ALU_SRC_IMM  = 2'b01;  // 立即数
    localparam ALU_SRC_PC   = 2'b10;  // PC值
    localparam ALU_SRC_ZERO = 2'b11;  // 零
    
    // 选择ALU操作数
    reg [31:0] alu_src1;
    reg [31:0] alu_src2;
    
    always @(*) begin
        case (alu_src1_sel)
            ALU_SRC_REG:  alu_src1 = rs1_data;
            ALU_SRC_PC:   alu_src1 = pc;
            ALU_SRC_ZERO: alu_src1 = 32'b0;
            default:      alu_src1 = rs1_data;
        endcase
        
        case (alu_src2_sel)
            ALU_SRC_REG:  alu_src2 = rs2_data;
            ALU_SRC_IMM:  alu_src2 = imm;
            default:      alu_src2 = rs2_data;
        endcase
    end
    
    /**************** ALU运算 ****************/
    
    // 移位操作数（只使用低5位）
    wire [4:0] shamt = alu_src2[4:0];
    
    // ALU运算结果
    always @(*) begin
        case (alu_op)
            4'b0000: alu_result = alu_src1 + alu_src2;  // ADD
            4'b0001: alu_result = alu_src1 - alu_src2;  // SUB
            4'b0010: alu_result = alu_src1 & alu_src2;  // AND
            4'b0011: alu_result = alu_src1 | alu_src2;  // OR
            4'b0100: alu_result = alu_src1 ^ alu_src2;  // XOR
            4'b0101: alu_result = alu_src1 << shamt;  // SLL
            4'b0110: alu_result = alu_src1 >> shamt;  // SRL
            4'b0111: alu_result = $signed(alu_src1) >>> shamt;  // SRA
            ALU_SLT:  alu_result = {31'b0, $signed(alu_src1) < $signed(alu_src2)};
            ALU_SLTU: alu_result = {31'b0, alu_src1 < alu_src2};
            default:  alu_result = 32'h0;
        endcase
    end
    
    /**************** 分支条件判断 ****************/
    
    // 分支比较结果
    wire equal  = (rs1_data == rs2_data);
    wire less   = $signed(rs1_data) < $signed(rs2_data);
    wire lessu  = rs1_data < rs2_data;
    
    // 分支条件判断
    always @(*) begin
        if (jump) begin
            branch_taken = 1'b1;
        end else if (branch) begin
            case (funct3)
                3'b000:  branch_taken = equal;           // BEQ
                3'b001:  branch_taken = !equal;          // BNE
                3'b100:  branch_taken = less;            // BLT
                3'b101:  branch_taken = !less;           // BGE
                3'b110:  branch_taken = lessu;           // BLTU
                3'b111:  branch_taken = !lessu;          // BGEU
                default: branch_taken = 1'b0;
            endcase
        end else begin
            branch_taken = 1'b0;
        end
    end
    
    /**************** 内存访问接口 ****************/
    
    // 内存访问地址使用ALU计算结果
    assign mem_addr  = alu_result;
    assign mem_wdata = rs2_data;

endmodule 