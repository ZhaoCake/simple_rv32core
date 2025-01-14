/****************************************
* RISC-V 指令存储器模块
* 
* 特点：
* - 32位指令宽度
* - 字节寻址
* - 4字节对齐访问
* - 只读存储器
* - 异步读取
****************************************/

module inst_mem (
    input  wire [31:0] addr,     // 指令地址（字节寻址）
    output reg  [31:0] inst      // 读出的指令
);

    // 指令存储器（使用寄存器数组实现）
    reg [31:0] mem [0:1023];     // 1KB指令存储器
    
    // 异步读取指令
    always @(*) begin
        inst = mem[addr[10:2]];  // 4字节对齐访问
    end
    
    // 初始化指令存储器
    initial begin
        $readmemh("../sim/hex/inst.hex", mem, 0, 1023);  // 显式指定范围
    end

endmodule 