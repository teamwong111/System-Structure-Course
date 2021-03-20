`timescale 1ns / 1ps
module cache (
    input clk,
    input reset,
    input write_cache,
    input [31:0]cache_addr,
    input [511:0]cache_data_in,
    output ishit,
    output [31:0]cache_data_out
    );

    wire [512:0]block_in;
    wire [512:0]block_out;
    
    reg [512:0]thecache[0:31];

    assign block_in = {1'b1,cache_data_in};

    assign block_out = thecache[cache_addr[10:6]];
    
    assign ishit =  (block_out[512]);

    assign cache_data_out = (cache_addr[5:2]==4'b0000)?block_out[511:480]:
                            (cache_addr[5:2]==4'b0001)?block_out[479:448]:
                            (cache_addr[5:2]==4'b0010)?block_out[447:416]:
                            (cache_addr[5:2]==4'b0011)?block_out[415:384]:
                            (cache_addr[5:2]==4'b0100)?block_out[383:352]:
                            (cache_addr[5:2]==4'b0101)?block_out[351:320]:
                            (cache_addr[5:2]==4'b0110)?block_out[319:288]:
                            (cache_addr[5:2]==4'b0111)?block_out[287:256]:
                            (cache_addr[5:2]==4'b1000)?block_out[255:224]:
                            (cache_addr[5:2]==4'b1001)?block_out[223:192]:
                            (cache_addr[5:2]==4'b1010)?block_out[191:160]:
                            (cache_addr[5:2]==4'b1011)?block_out[159:128]:
                            (cache_addr[5:2]==4'b1100)?block_out[127:96]:
                            (cache_addr[5:2]==4'b1101)?block_out[95:64]:
                            (cache_addr[5:2]==4'b1110)?block_out[63:32]:block_out[31:0];
    
    always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            thecache[0]<=0;
            thecache[1]<=0;
            thecache[2]<=0;
            thecache[3]<=0;
            thecache[4]<=0;
            thecache[5]<=0;
            thecache[6]<=0;
            thecache[7]<=0;
            thecache[8]<=0;
            thecache[9]<=0;
            thecache[10]<=0;
            thecache[11]<=0;
            thecache[12]<=0;
            thecache[13]<=0;
            thecache[14]<=0;
            thecache[15]<=0;
            thecache[16]<=0;
            thecache[17]<=0;
            thecache[18]<=0;
            thecache[19]<=0;
            thecache[20]<=0;
            thecache[21]<=0;
            thecache[22]<=0;
            thecache[23]<=0;
            thecache[24]<=0;
            thecache[25]<=0;
            thecache[26]<=0;
            thecache[27]<=0;
            thecache[28]<=0;
            thecache[29]<=0;
            thecache[30]<=0;
            thecache[31]<=0;
        end
        else
        begin
            if(write_cache)
                thecache[cache_addr[10:6]]<=block_in;
        end
    end
    
endmodule 