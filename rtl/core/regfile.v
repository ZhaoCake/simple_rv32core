module regfile (
    input  wire        clk,
    input  wire        rst_n,
    // 读端口1
    input  wire [ 4:0] rs1_addr,
    output reg  [31:0] rs1_data,
    // 读端口2
    input  wire [ 4:0] rs2_addr,
    output reg  [31:0] rs2_data,
    // 写端口
    input  wire        reg_write,   // 写使能
    input  wire [ 4:0] rd_addr,     // rd地址
    input  wire [31:0] rd_data      // 写入数据
);

    // 32个32位寄存器
    reg [31:0] regs [31:0];
    integer i;

    // 异步读取
    always @(*) begin
        rs1_data = (rs1_addr == 5'b0) ? 32'b0 : regs[rs1_addr];
        rs2_data = (rs2_addr == 5'b0) ? 32'b0 : regs[rs2_addr];
    end

    // 同步写入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时清零所有寄存器
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else if (reg_write && rd_addr != 5'b0) begin
            // x0寄存器不可写
            regs[rd_addr] <= rd_data;
        end
    end

endmodule 