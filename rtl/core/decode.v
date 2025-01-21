/****************************************
* RISC-V 译码级模块
* 
* 功能：
* 1. 指令解码
* 2. 生成控制信号
* 3. 读取寄存器值
* 4. 生成立即数
* 
* 支持指令类型：
* - R型：add/sub/and/or/xor/sll/srl/sra/slt/sltu
* - I型：addi/andi/ori/xori/slli/srli/srai/slti/sltiu/lw
* - S型：sw
* - B型：beq/bne/blt/bge/bltu/bgeu
* - U型：lui/auipc
* - J型：jal/jalr
****************************************/

module decode (
    input  wire        clk,          // 时钟信号
    input  wire        rst_n,        // 复位信号（低电平有效）
    
    // 指令接口
    input  wire [31:0] inst,         // 指令
    input  wire [31:0] pc,           // 指令对应的PC值
    
    // 寄存器堆接口
    output wire [ 4:0] rs1_addr,     // 源寄存器1地址
    output wire [ 4:0] rs2_addr,     // 源寄存器2地址
    input  wire [31:0] rs1_data,     // 源寄存器1数据
    input  wire [31:0] rs2_data,     // 源寄存器2数据
    output wire [ 4:0] rd_addr,      // 目标寄存器地址
    
    // 控制信号
    output reg  [ 3:0] alu_op,       // ALU操作码
    output reg  [ 1:0] alu_src1_sel, // ALU操作数1选择
    output reg  [ 1:0] alu_src2_sel, // ALU操作数2选择
    output reg         mem_read,      // 内存读使能
    output reg         mem_write,     // 内存写使能
    output reg         reg_write,     // 寄存器写使能
    output reg  [ 1:0] reg_src_sel,  // 寄存器写数据选择
    
    // 立即数和跳转地址
    output reg  [31:0] imm,          // 立即数
    output reg         branch,        // 分支指令标志
    output reg         jump,          // 跳转指令标志
    output wire [31:0] branch_target, // 分支/跳转目标地址
    output reg         ecall,         // ECALL指令标志
    output reg         ebreak         // EBREAK指令标志
);

    /**************** 指令解码 ****************/
    
    // 指令字段
    wire [ 6:0] opcode = inst[ 6: 0];
    wire [ 2:0] funct3 = inst[14:12];
    wire [ 6:0] funct7 = inst[31:25];
    
    // 寄存器地址
    assign rs1_addr = inst[19:15];
    assign rs2_addr = inst[24:20];
    assign rd_addr  = inst[11: 7];
    
    // 指令类型判断
    wire is_r_type = (opcode == 7'b0110011);  // R型指令
    wire is_i_type = (opcode == 7'b0010011) || // I型算术指令
                     (opcode == 7'b0000011);    // I型加载指令
    wire is_s_type = (opcode == 7'b0100011);   // S型存储指令
    wire is_b_type = (opcode == 7'b1100011);   // B型分支指令
    wire is_u_type = (opcode == 7'b0110111) || // U型lui指令
                     (opcode == 7'b0010111);    // U型auipc指令
    wire is_j_type = (opcode == 7'b1101111) || // J型jal指令
                     (opcode == 7'b1100111);    // J型jalr指令
    
    /**************** 立即数生成 ****************/
    
    // 根据指令类型生成立即数
    always @(*) begin
        case (1'b1)
            is_i_type: imm = {{20{inst[31]}}, inst[31:20]};
            is_s_type: imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            is_b_type: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            is_u_type: imm = {inst[31:12], 12'b0};
            is_j_type: imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            default:   imm = 32'b0;
        endcase
    end
    
    /**************** 控制信号生成 ****************/
    
    // ALU操作码
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
    
    // ALU操作数选择
    localparam ALU_SRC_REG  = 2'b00;  // 寄存器值
    localparam ALU_SRC_IMM  = 2'b01;  // 立即数
    localparam ALU_SRC_PC   = 2'b10;  // PC值
    localparam ALU_SRC_ZERO = 2'b11;  // 零
    
    // 寄存器写数据选择
    localparam REG_SRC_ALU  = 2'b00;  // ALU结果
    localparam REG_SRC_MEM  = 2'b01;  // 内存读数据
    localparam REG_SRC_PC4  = 2'b10;  // PC+4
    localparam REG_SRC_IMM  = 2'b11;  // 立即数
    
    // 控制信号生成逻辑
    always @(*) begin
        // 默认值
        alu_op       = ALU_ADD;
        alu_src1_sel = ALU_SRC_REG;
        alu_src2_sel = ALU_SRC_REG;
        mem_read     = 1'b0;
        mem_write    = 1'b0;
        reg_write    = 1'b0;
        reg_src_sel  = REG_SRC_ALU;
        branch       = 1'b0;
        jump         = 1'b0;
        ecall        = 1'b0;
        ebreak       = 1'b0;
        
        case (1'b1)
            is_r_type: begin
                reg_write = 1'b1;
                case (funct3)
                    3'b000:  alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    3'b001:  alu_op = ALU_SLL;
                    3'b010:  alu_op = ALU_SLT;
                    3'b011:  alu_op = ALU_SLTU;
                    3'b100:  alu_op = ALU_XOR;
                    3'b101:  alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    3'b110:  alu_op = ALU_OR;
                    3'b111:  alu_op = ALU_AND;
                endcase
            end
            
            is_i_type: begin
                reg_write    = 1'b1;
                alu_src2_sel = ALU_SRC_IMM;
                if (opcode == 7'b0000011) begin  // 加载指令
                    mem_read     = 1'b1;
                    reg_src_sel  = REG_SRC_MEM;
                    case (funct3)
                        3'b000: mem_size = 2'b00;  // LB
                        3'b001: mem_size = 2'b01;  // LH
                        3'b010: mem_size = 2'b10;  // LW
                        3'b100: mem_size = 2'b00;  // LBU
                        3'b101: mem_size = 2'b01;  // LHU
                        default: mem_size = 2'b10;
                    endcase
                end else begin                   // 算术指令
                    case (funct3)
                        3'b000:  alu_op = ALU_ADD;
                        3'b001:  alu_op = ALU_SLL;
                        3'b010:  alu_op = ALU_SLT;
                        3'b011:  alu_op = ALU_SLTU;
                        3'b100:  alu_op = ALU_XOR;
                        3'b101:  alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                        3'b110:  alu_op = ALU_OR;
                        3'b111:  alu_op = ALU_AND;
                    endcase
                end
            end
            
            is_s_type: begin
                mem_write    = 1'b1;
                alu_src2_sel = ALU_SRC_IMM;
                case (funct3)
                    3'b000: mem_size = 2'b00;  // SB
                    3'b001: mem_size = 2'b01;  // SH
                    3'b010: mem_size = 2'b10;  // SW
                    default: mem_size = 2'b10;
                endcase
            end
            
            is_b_type: begin
                branch       = 1'b1;
                alu_op      = ALU_SUB;
            end
            
            is_u_type: begin
                reg_write    = 1'b1;
                if (opcode == 7'b0110111) begin  // lui
                    alu_src1_sel = ALU_SRC_ZERO;
                    alu_src2_sel = ALU_SRC_IMM;
                end else begin                    // auipc
                    alu_src1_sel = ALU_SRC_PC;
                    alu_src2_sel = ALU_SRC_IMM;
                end
            end
            
            is_j_type: begin
                jump         = 1'b1;
                reg_write    = 1'b1;
                reg_src_sel  = REG_SRC_PC4;
                if (opcode == 7'b1100111) begin  // jalr
                    alu_src1_sel = ALU_SRC_REG;
                    alu_src2_sel = ALU_SRC_IMM;
                end else begin                    // jal
                    alu_src1_sel = ALU_SRC_PC;
                    alu_src2_sel = ALU_SRC_IMM;
                end
            end
            
            7'b1110011: begin  // System
                case (funct3)
                    3'b000: begin
                        case (inst)
                            32'h00000073: ecall = 1'b1;   // ECALL
                            32'h00100073: ebreak = 1'b1;  // EBREAK
                        endcase
                    end
                endcase
            end
        endcase
    end
    
    /**************** 分支/跳转目标地址计算 ****************/
    
    assign branch_target = (opcode == 7'b1100111) ? // jalr
                          (rs1_data + imm) & ~32'b1 : // 计算后最低位清零
                          pc + imm;                   // 其他跳转指令

endmodule 