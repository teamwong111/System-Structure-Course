`timescale 1ns / 1ps
module Writeback(
    input [1:0]wb_rfaddr_inchoice,
    input [4:0]wb_rfaddr1, 
    input [4:0]wb_rfaddr2, 
    input [4:0]wb_rfaddr3,
    
    input [2:0]wb_rfinchoice,
    input [31:0]wb_rf1, 
    input [31:0]wb_rf2, 
    input [31:0]wb_rf3, 
    input [31:0]wb_rf4, 
    input [31:0]wb_rf5, 
    input [31:0]wb_rf6,
    
    input wb_rf_inallow,
    
    input wb_hi_inchoice,
    input [31:0]wb_rs1, 
    input [31:0]wb_alu_hiout,
    
    input wb_lo_inchoice,
    input [31:0]wb_rs2, 
    input [31:0]wb_alu_loout,
    
    output [4:0]wb_rfaddr_out,
    output [31:0]wb_rf_out,
    output wb_rf_allow,
    output [31:0]wb_hi_out,
    output [31:0]wb_lo_out
    );
    assign wb_rfaddr_out = wb_rfaddr_inchoice==2'b00 ? wb_rfaddr1 : 
                          (wb_rfaddr_inchoice==2'b01 ? wb_rfaddr2 : wb_rfaddr3);
    assign wb_rf_out =  wb_rfinchoice==3'b000 ? wb_rf1 : 
                       (wb_rfinchoice==3'b010 ? wb_rf2 : 
                       (wb_rfinchoice==3'b011 ? wb_rf3 : 
                       (wb_rfinchoice==3'b100 ? wb_rf4 : 
                       (wb_rfinchoice==3'b101 ? wb_rf5 : wb_rf6))));
                       
    assign wb_rf_allow = wb_rf_inallow;
    assign wb_hi_out = wb_hi_inchoice ? wb_rs1 : wb_alu_hiout;
    assign wb_lo_out = wb_lo_inchoice ? wb_rs2 : wb_alu_loout;
endmodule