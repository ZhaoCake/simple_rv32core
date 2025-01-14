.section .text
.global _start

_start:
    # 初始化栈指针
    li sp, 0x1000
    
    # 跳转到主程序
    call main
    
    # 程序结束循环
1:  j 1b 