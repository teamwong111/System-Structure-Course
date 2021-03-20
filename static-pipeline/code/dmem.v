`timescale 1ns / 1ps
module dmem(
    input clk,//时钟
    input [1:0]dmem_inchoice,
    input [31:0] addr,//地址
    input [31:0] data_in,//输入
    input [2:0]dmem_outchoice,
    output reg [31:0] data_out//输出
    );
    wire [7:0]Addr;
    assign Addr = addr[7:0];
    wire [7:0]lh_lb;
    reg [7:0] num [0:1023];//寄存器  
    assign lh_lb = num[Addr];
    always@(posedge clk) 
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
        case(dmem_outchoice)
        3'b000:
        begin
            data_out <= {num[Addr],num[Addr+1],num[Addr+2],num[Addr+3]};
        end
        3'b001:
        begin
            data_out <= {{16{lh_lb[7]}},num[Addr],num[Addr+1]};
        end
        3'b010:
        begin
            data_out <= {{16{1'b0}},num[Addr],num[Addr+1]};
        end
        3'b011:
        begin
            data_out <= {{24{lh_lb[7]}},num[Addr]};
        end
        3'b100:
        begin
            data_out <= {{24{1'b0}},num[Addr]};
        end
        endcase
    end
endmodule
