`timescale 1ns / 1ps
module Execute(
    input [31:0]exe_rs_in,
    input [31:0]exe_rt_in,
    input [4:0]exe_aluchoice,

    //writeback
    input exe_hi_inchoice,
    input exe_lo_inchoice,
    input [31:0]exe_rs,

    output [31:0]exe_alu_out,

    //writeback
    output [31:0]exe_wb_hiin,
    output [31:0]exe_wb_loin
    );
    wire [31:0]exe_hi_out;
    wire [31:0]exe_lo_out;
    alu cpu_alu(
        exe_rs_in, 
        exe_rt_in, 
        exe_aluchoice, 
        exe_alu_out, 
        exe_hi_out, 
        exe_lo_out
    );

    assign exe_wb_hiin = exe_hi_inchoice ? exe_rs : exe_hi_out;
    assign exe_wb_loin = exe_lo_inchoice ? exe_rs : exe_lo_out;

endmodule
