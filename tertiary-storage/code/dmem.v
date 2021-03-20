`timescale 1ns / 1ps
module dmem(
    input clk,//ʱ��
    input [1:0]dmem_inchoice,
    input [31:0] addr,//��ַ
    input [31:0] data_in,//����
    input [2:0]dmem_outchoice,
    output [31:0] data_out//���
    );

    wire [7:0]Addr;
    assign Addr = addr[7:0];
    wire [7:0]lh_lb;
    reg [7:0] num [0:1023];//�Ĵ���  
    assign lh_lb = num[Addr];

    assign data_out =   (dmem_outchoice==3'b000) ? {num[Addr],num[Addr+1],num[Addr+2],num[Addr+3]}:
                        (dmem_outchoice==3'b001) ? {{16{lh_lb[7]}},num[Addr],num[Addr+1]}: 
                        (dmem_outchoice==3'b010) ? {{16{1'b0}},num[Addr],num[Addr+1]}:
                        (dmem_outchoice==3'b011) ? {{24{lh_lb[7]}},num[Addr]}:
                        (dmem_outchoice==3'b100) ? {{24{1'b0}},num[Addr]}: 0;                  

    always@(negedge clk) 
    begin
        case (dmem_inchoice)
        2'b00:num[Addr]<=num[Addr];
        2'b01:
        begin
            num[Addr]<=data_in[31:24];
            num[Addr+1]<=data_in[23:16];
            num[Addr+2]<=data_in[15:8];
            num[Addr+3]<=data_in[7:0];
        end
        2'b10:
        begin
            num[Addr]<=data_in[15:8];
            num[Addr+1]<=data_in[7:0];
        end
        2'b11:num[Addr]<=data_in[7:0];
        endcase
    end
endmodule
