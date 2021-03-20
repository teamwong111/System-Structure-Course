`timescale 1ns / 1ps
module Instfetch(
    input [31:0] if_pc_in,
    output [31:0] if_nextpc_out
    );
    assign if_nextpc_out = if_pc_in + 4;
endmodule
