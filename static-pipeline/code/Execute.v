`timescale 1ns / 1ps
module Execute(
    input clk,
    input [31:0]exe_rs_in,
    input [31:0]exe_rt_in,
    input [4:0]exe_aluchoice,
    output [31:0]exe_alu_out,
    output [31:0]exe_hi_out,
    output [31:0]exe_lo_out
    );
    alu cpu_alu(clk, exe_rs_in, exe_rt_in, exe_aluchoice, exe_alu_out, exe_hi_out, exe_lo_out);

endmodule
