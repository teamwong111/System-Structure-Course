`timescale 1ns / 1ps
module Memory(
    input clk,
    input [1:0] mem_dmem_inchoice,
    input [31:0] mem_dmem_addr,//输入输出用一个地址
    input [31:0] mem_dmem_in,
    input [2:0] mem_dmem_outchoice,
    input [2:0]mem_rfinchoice,//writeback
    input [31:0]mem_alu_loout,
    input [31:0]mem_cp0out,
    input [31:0]mem_hiout,
    input [31:0]mem_loout,
    output [31:0] mem_wb_rf
    );
    wire [31:0]mem_dmem_out;

    dmem cpu_dmem(
        clk,
        mem_dmem_inchoice,
        mem_dmem_addr,
        mem_dmem_in,
        mem_dmem_outchoice,
        mem_dmem_out
    );

    assign mem_wb_rf =  mem_rfinchoice==3'b000 ? mem_dmem_addr : 
                        (mem_rfinchoice==3'b010 ? mem_dmem_out : 
                        (mem_rfinchoice==3'b011 ? mem_alu_loout : 
                        (mem_rfinchoice==3'b100 ? mem_cp0out : 
                        (mem_rfinchoice==3'b101 ? mem_hiout : mem_loout))));
endmodule
