`timescale 1ns / 1ps
module branchpredict(
    input clk,
    input [31:0] pc, 
    input [31:0] inst,
    input stall,
    input [31:0] rs, 
    input [31:0] alu_a, 
    input [31:0] alu_b,
    output reg isbranch, 
    output reg [31:0]branch_pc
    );
    wire [16:0]moreop;
    assign moreop = {inst[31:21],inst[5:0]};
    wire [11:0]opcode;
    assign opcode = {inst[31:26],inst[5:0]};
    wire [5:0]halfop;
    assign halfop = {inst[31:26]};
    
    parameter [5:0]
    beq = 12'b000100,
    bne = 6'b000101,
    bgez = 6'b000001,
    
    j = 6'b000010,
    jal = 6'b000011;
    
    parameter [11:0] 
    jr = 12'b000000_001000,
    jalr = 12'b000000_001001;
    
    always @(*) 
    begin;
        //isbracnh
//        if(stall)
//        begin
//            isbranch <= 0;
//            branch_pc <= 0;    
//        end   
        if(opcode==jr || opcode==jalr)
        begin
            isbranch <= 1;
            branch_pc <= rs-32'h00400000;
        end
        else if(halfop==j || halfop==jal)
        begin
            isbranch <= 1;
            branch_pc <= {pc[31:28],inst[25:0]<<2}-32'h00400000;
        end
        else if((halfop==beq && alu_a==alu_b) || (halfop==bne && alu_a!=alu_b) || (halfop==bgez && $signed(alu_a)>=0))
        begin
            isbranch <= 1;
            branch_pc <= pc+{{(32 - 18){inst[15]}},inst[15:0],2'b00}+32'b100;
        end         
        else
        begin
            isbranch <= 0;
            branch_pc <= 0;            
        end
    end
    
    
endmodule
