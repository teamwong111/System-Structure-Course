`timescale 1ns / 1ps
module alu(
    input [31:0] A,
    input [31:0] B,
    input [4:0] aluchoice,
    output [31:0] result,
    output [31:0] hi_result,
    output [31:0] lo_result
    );
    wire [63:0] tomux;
    wire [31:0] clz;

    assign tomux =  (aluchoice==5'b10011) ? $signed(A) * $signed(B):
                    (aluchoice==5'b10100) ? A * B: 0;

    assign clz= A[31]?0:A[30]?1:A[29]?2:A[28]?3:
                A[27]?4:A[26]?5:A[25]?6:A[24]?7:
                A[23]?8:A[22]?9:A[21]?10:A[20]?11:
                A[19]?12:A[18]?13:A[17]?14:A[16]?15:
                A[15]?16:A[14]?17:A[13]?18:A[12]?19:
                A[11]?20:A[10]?21:A[9]?22:A[8]?23:
                A[7]?24:A[6]?25:A[5]?26:A[4]?27:
                A[3]?28:A[2]?29:A[1]?30:A[0]?31:32;

    assign result = (aluchoice==5'b00000) ? A + B://ADDU
                    (aluchoice==5'b00001) ? $signed(A) + $signed(B)://ADD
                    (aluchoice==5'b00010) ? A - B://SUBU
                    (aluchoice==5'b00011) ? $signed(A) - $signed(B)://SUB
                    (aluchoice==5'b00100) ? A & B://AND
                    (aluchoice==5'b00101) ? A | B://OR
                    (aluchoice==5'b00110) ? A ^ B://XOR
                    (aluchoice==5'b00111) ? ~(A|B)://NOR
                    (aluchoice==5'b01000) ? {B[15:0], 16'b0}://LUI
                    (aluchoice==5'b01001) ? ((A < B) ? 1 : 0)://SLTU
                    (aluchoice==5'b01010) ? (($signed(A)<$signed(B)) ? 1 : 0)://SLT
                    (aluchoice==5'b01011) ? $signed(B) >>> A://SRA向右算术移位
                    (aluchoice==5'b01100) ? B >> A://SRL向右逻辑移位
                    (aluchoice==5'b01101) ? B << A://SLL SLR
                    (aluchoice==5'b10101) ? clz:
                    (aluchoice==5'b10001) ? $signed(A) / $signed(B)://DIV
                    (aluchoice==5'b10010) ? A / B://DIVU
                    (aluchoice==5'b10011) ? tomux[31:0]://MUL
                    (aluchoice==5'b10100) ? tomux[31:0]: 0;//MULTU
    
    assign hi_result =  (aluchoice==5'b10001) ? $signed(A) % $signed(B)://DIV
                        (aluchoice==5'b10010) ? A % B://DIVU
                        (aluchoice==5'b10011) ? tomux[63:32]://MUL
                        (aluchoice==5'b10100) ? tomux[63:32]: 0;//MULTU
    
    assign lo_result =  (aluchoice==5'b10001) ? $signed(A) / $signed(B)://DIV
                        (aluchoice==5'b10010) ? A / B://DIVU
                        (aluchoice==5'b10011) ? tomux[31:0]://MUL
                        (aluchoice==5'b10100) ? tomux[31:0]: 0;//MULTU
endmodule
