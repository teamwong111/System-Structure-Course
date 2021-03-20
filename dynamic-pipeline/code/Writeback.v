`timescale 1ns / 1ps
module Writeback(
    input [4:0]wb_rfaddr_in,
    input [31:0]wb_rfin,
    input wb_rf_inallow,
    input [31:0]wb_hiin,
    input [31:0]wb_loin,
    output [4:0]wb_rfaddr_out,
    output [31:0]wb_rf_out,
    output wb_rf_allow,
    output [31:0]wb_hi_out,
    output [31:0]wb_lo_out
    );
    assign wb_rfaddr_out = wb_rfaddr_in;                    
    assign wb_rf_out = wb_rfin;          
    assign wb_rf_allow = wb_rf_inallow;
    assign wb_hi_out = wb_hiin;
    assign wb_lo_out = wb_loin;
endmodule