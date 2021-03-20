`timescale 1ns / 1ps
module regfile(
    input clk, 
    input rst,
    input [4:0] raddr1, 
    input [4:0] raddr2, //�����ȡ�ļĴ����ĵ�ַ
    input [4:0] waddr, 
    input [31:0] wdata, 
    input  regfilesrc,//д�Ĵ����ĵ�ַ//д�Ĵ������ݣ������� clk �½���ʱ��д��
    output [31:0] rdata1, 
    output [31:0] rdata2,//raddr1 ����Ӧ�Ĵ������������ //raddr2 ����Ӧ�Ĵ������������
    output [31:0] ans
    );
    reg [31:0] array_reg [31:0]; //�Ĵ���
    
    //д�Ĵ���
    integer i;    
    always @(posedge clk) 
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
    
    assign rdata1 = array_reg[raddr1];
    assign rdata2 = array_reg[raddr2];
    assign ans = array_reg[28];
endmodule