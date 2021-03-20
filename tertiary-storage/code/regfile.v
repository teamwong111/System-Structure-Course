`timescale 1ns / 1ps
module regfile(
    input clk, 
    input rst,
    input [4:0] raddr1, 
    input [4:0] raddr2, //所需读取的寄存器的地址
    input [4:0] waddr, 
    input [31:0] wdata, 
    input  regfilesrc,//写寄存器的地址//写寄存器数据，数据在 clk 下降沿时被写入
    input [1:0]ischangea,
    input [1:0]ischangeb,
    input [31:0]exe_out,
    input [31:0]mem_out,
    output [31:0] rdata1,//raddr1 所对应寄存器的输出数据 
    output [31:0] rdata2,//raddr2 所对应寄存器的输出数据
    output [31:0] ans
    );
    reg [31:0] array_reg [31:0]; //寄存器
    
    assign rdata1 = (ischangea==2'b01) ? exe_out :
                    (ischangea==2'b10) ? mem_out :
                    (ischangea==2'b00 && raddr1==waddr && waddr!=0) ? wdata : array_reg[raddr1];

    assign rdata2 = (ischangeb==2'b01) ? exe_out :
                    (ischangeb==2'b10) ? mem_out :
                    (ischangeb==2'b00 && raddr2==waddr && waddr!=0) ? wdata : array_reg[raddr2];

    assign ans = array_reg[28];

    //写寄存器
    integer i;    
    always @(negedge clk) 
    begin
        if(rst) 
        begin
            for(i=0;i<32;i=i+1)
               array_reg[i] <= 0;
        end
        else 
        begin
            if((waddr!=0)&&regfilesrc==1)
            begin
                array_reg[waddr] <= wdata;
            end
            else
            begin
                array_reg[waddr] <= array_reg[waddr];
            end
        end
    end
endmodule