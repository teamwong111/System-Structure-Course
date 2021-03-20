`timescale 1ns / 1ps
module Memory(
    input clk,
    input [1:0] mem_dmem_inchoice,
    input [31:0] mem_dmem_addr,//输入输出用一个地址
    input [31:0] mem_dmem_in,
    input [2:0] mem_dmem_outchoice,
    output [31:0] mem_dmem_out
    );
    
    dmem cpu_dmem(
        clk,
        mem_dmem_inchoice,
        mem_dmem_addr,
        mem_dmem_in,
        mem_dmem_outchoice,
        mem_dmem_out
    );
endmodule
