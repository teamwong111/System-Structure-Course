`timescale 1ns / 1ps
module hi_lo(
    input clk,
    input rst,
    input [31:0] Write_hi,
    input [31:0] Write_lo,
    output [31:0] Rd_hi,
    output [31:0] Rd_lo
    );
    reg [31:0] hi;
    reg [31:0] lo;
    assign Rd_hi = hi;
    assign Rd_lo = lo;
    
    always @(negedge clk) 
    begin
        if(rst) 
        begin
            hi <= 32'b0;
            lo <= 32'b0; 
        end
        else
        begin 
            hi <= Write_hi;
            lo <= Write_lo;
        end
    end
endmodule