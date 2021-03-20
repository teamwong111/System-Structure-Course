`timescale 1ns / 1ps
module alu(
    input clk, 
    input [31:0] A,
    input [31:0] B,
    input [4:0] aluchoice,
    output reg [31:0] result,
    output reg [31:0] hi_result,
    output reg [31:0] lo_result
    );
    integer i; // CLZ用
    integer j;
    integer max;
    reg [63:0]tomux;
    always @(*) 
    begin
        result <= 0;
        hi_result <= 0;
        lo_result <= 0;
        tomux <= 0;
        case(aluchoice)
            5'b00000: result <= A + B;                                    //ADDU
            5'b00001: result <= $signed(A) + $signed(B);                //ADD
            5'b00010: result <= A - B;                                    //SUBU
            5'b00011: result <= $signed(A) - $signed(B);               //SUB
            5'b00100: result <= A & B;                                    //AND
            5'b00101: result <= A | B;                                    //OR
            5'b00110: result <= A ^ B;                                    //XOR
            5'b00111: result <= ~(A|B);                                   //NOR
            5'b01000: result <= {B[15:0], 16'b0};                         //LUI
            5'b01001: result <= (A < B) ? 1 : 0;                          //SLTU
            5'b01010: result <= ($signed(A)<$signed(B)) ? 1 : 0;       //SLT
            5'b01011: result <= $signed(B) >>> A;                        //SRA 向右算术移位
            5'b01100: result <= B >> A;                                  //SRL 向右逻辑移位
            5'b01101: result <= B << A;                                  //SLL SLR
            
            5'b10001: 
            begin//DIV
                hi_result <= $signed(A) % $signed(B);
                lo_result <= $signed(A) / $signed(B);
            end
            5'b10010: 
            begin//DIVU
                hi_result <= A % B;
                lo_result <= A / B;
            end
            5'b10011: 
            begin// MUL
                tomux = $signed(A) * $signed(B);
                hi_result = tomux[63:32];
                lo_result = tomux[31:0];
            end
            5'b10100:
            begin//MULTU
                tomux = A * B;
                hi_result = tomux[63:32];
                lo_result = tomux[31:0]; 
            end
            5'b10101://CLZ
            begin
                j <= 0;
                max <= 0;
                for(i = 31; i >= 0;i = i-1) 
                begin
                    if(A[i]==1'b1) 
                        j <= 1;
                    if(!j) 
                        max <= max + 1;
                end
                result <= max;
            end 
        endcase
    end
endmodule
