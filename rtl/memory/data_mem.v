/****************************************
* RISC-V 数据存储器模块
* 
* 特点：
* - 32位数据宽度
* - 字节寻址
* - 支持字节/半字/字访问
* - 同步写入
* - 异步读取
****************************************/

module data_mem (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 复位信号（低电平有效）
    
    input  wire [31:0] addr,     // 访问地址（字节寻址）
    input  wire [31:0] wdata,    // 写数据
    input  wire [ 3:0] wmask,    // 写掩码（按字节使能）
    input  wire        wen,      // 写使能
    output reg  [31:0] rdata     // 读数据
);

    // 数据存储器（使用寄存器数组实现）
    reg [7:0] mem [0:4095];      // 4KB数据存储器
    
    // 字节地址
    wire [31:0] byte_addr;
    assign byte_addr = {addr[31:2], 2'b00};
    
    // 异步读取数据
    always @(*) begin
        rdata = {mem[byte_addr+3], mem[byte_addr+2], 
                mem[byte_addr+1], mem[byte_addr]};
    end
    
    // 同步写入数据
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时清零所有存储器
            for (i = 0; i < 4096; i = i + 1) begin
                mem[i] <= 8'h0;
            end
        end else if (wen) begin
            // 按字节写入
            if (wmask[0]) mem[byte_addr]   <= wdata[ 7: 0];
            if (wmask[1]) mem[byte_addr+1] <= wdata[15: 8];
            if (wmask[2]) mem[byte_addr+2] <= wdata[23:16];
            if (wmask[3]) mem[byte_addr+3] <= wdata[31:24];
        end
    end

endmodule 