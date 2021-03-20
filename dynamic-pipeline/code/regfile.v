`timescale 1ns / 1ps
module regfile(
    input clk, 
    input rst,
    input [4:0] raddr1, 
    input [4:0] raddr2, //�����ȡ�ļĴ����ĵ�ַ
    input [4:0] waddr, 
    input [31:0] wdata, 
    input  regfilesrc,//д�Ĵ����ĵ�ַ//д�Ĵ������ݣ������� clk �½���ʱ��д��
    input [1:0]ischangea,
    input [1:0]ischangeb,
    input [31:0]exe_out,
    input [31:0]mem_out,
    output [31:0] rdata1,//raddr1 ����Ӧ�Ĵ������������ 
    output [31:0] rdata2,//raddr2 ����Ӧ�Ĵ������������
    output [31:0] ans
    );
    reg [31:0] array_reg [31:0]; //�Ĵ���
    
    assign rdata1 = (ischangea==2'b01) ? exe_out :
                    (ischangea==2'b10) ? mem_out :
                    (ischangea==2'b00 && raddr1==waddr && waddr!=0) ? wdata : array_reg[raddr1];

    assign rdata2 = (ischangeb==2'b01) ? exe_out :
                    (ischangeb==2'b10) ? mem_out :
                    (ischangeb==2'b00 && raddr2==waddr && waddr!=0) ? wdata : array_reg[raddr2];

    assign ans = array_reg[28];

    //д�Ĵ���
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