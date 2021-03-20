`timescale 1ns / 1ps
module clk_wiz(
    input clk_in,
    input reset,
    output the_clk_out
    );
//    parameter period= 20;  
    parameter period = 400000;
    reg [31:0]cnt;
    reg clk_out;
    always @(negedge clk_in)//·ÖÆµ
    begin 
        if(reset)
        begin
            cnt <= 0;
            clk_out <= 0;
        end
        else  
        begin  
            if(cnt== (period >> 1) - 1)
            begin               
                clk_out <= 1'b1;
                cnt<= cnt+1;
            end
            else if(cnt == period - 1)                    
            begin 
                clk_out <= 1'b0;
                cnt <= 1'b0;      
            end
            else
            begin
                cnt<= cnt+1;
            end         
        end
    end
    
    assign the_clk_out = clk_out;
endmodule
