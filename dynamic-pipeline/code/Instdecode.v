`timescale 1ns / 1ps
module Instdecode(
    input clk, 
    input reset,
    input [31:0]id_pc_in, 
    input [31:0]id_inst_in,
    input [4:0]id_rfaddr_in, 
    input [31:0]id_rf_in, 
    input id_rf_inallow_rf,
    input [31:0]id_hi_in, 
    input [31:0]id_lo_in,
    
    input [31:0]stage_id_inst,//
    input [1:0]stage_id_rfaddrinchoice,
    input [31:0]stage_exe_inst, 
    input [1:0]stage_exe_rfaddrinchoice,

    //传入exe_out、mem_out
    input [31:0]exe_out,
    input [31:0]mem_out,
    
    output [31:0]id_alu_a, 
    output [31:0]id_alu_b, 
    output [31:0]id_rs,
    output [31:0]id_rt, 
    output [4:0]id_aluchoice,
    output [1:0]id_rf_addrinchoice, 
    output [2:0]id_rf_inchoice, 
    output id_rf_inallow,
    output id_hi_inchoice, 
    output id_lo_inchoice,
    
    output isbranch, 
    output [31:0]branch_pc,
    output id_stall_out,
    output [31:0]cp0_out, 
    output [31:0]id_hi_out, 
    output [31:0]id_lo_out, //来自writeback
    
    output [1:0]id_dmem_inchoice,
    output [2:0]id_dmem_outchoice,
    output [31:0]ans,

    output [4:0]id_wb_rfaddr//wb
    );
    wire [1:0]alu_achoice;
    wire [1:0]alu_bchoice;
    wire mfc0src;
    wire mtc0src;
    wire exception;
    wire _eret;
    wire [4:0]cause;
    wire [31:0]exc_addr;
    
    wire [1:0] ischangea;
    wire [1:0] ischangeb;

    controlunit cpu_controlunit(
        id_inst_in,
        id_rs, 
        id_rt,
        id_aluchoice, 
        alu_achoice, 
        alu_bchoice,
        id_rf_addrinchoice, 
        id_rf_inchoice, 
        id_rf_inallow,
        id_hi_inchoice, 
        id_lo_inchoice,
        id_dmem_inchoice, 
        id_dmem_outchoice,
        mfc0src, 
        mtc0src, 
        exception, 
        _eret, 
        cause
    );

    regfile cpu_ref (
        clk, 
        reset, 
        id_inst_in[25:21], 
        id_inst_in[20:16], 
        id_rfaddr_in, 
        id_rf_in, 
        id_rf_inallow_rf, 
        ischangea,
        ischangeb,
        exe_out,
        mem_out,
        id_rs, 
        id_rt,
        ans
    );
    
    cp0 cpu_cp0(
        clk, 
        reset, 
        mfc0src, 
        mtc0src, 
        id_pc_in,
        id_inst_in[15:11], 
        id_rt, 
        exception, 
        _eret, 
        cause, 
        cp0_out, 
        exc_addr
    );
    
    hi_lo cpu_hi_lo(
        clk, 
        reset, 
        id_hi_in, 
        id_lo_in, 
        id_hi_out, 
        id_lo_out
    );
    
    branchpredict cpu_branchpredict(
        clk,
        id_pc_in, 
        id_inst_in,
        id_stall_out,
        id_rs, 
        id_alu_a, 
        id_alu_b,
        isbranch, 
        branch_pc
    );
    
    assign ischangea =  ((alu_achoice==2'b00 || alu_achoice==2'b01) && 
                        ((stage_id_rfaddrinchoice==2'b00 && id_inst_in[25:21]==stage_id_inst[15:11] && stage_id_inst[15:11]!=0 && stage_id_inst[31:26]!=6'b101011) || 
                        (stage_id_rfaddrinchoice==2'b01 && id_inst_in[25:21]==stage_id_inst[20:16] && stage_id_inst[20:16]!=0 && stage_id_inst[31:26]!=6'b101011))) ? 2'b01 : 
                        ((alu_achoice==2'b00 || alu_achoice==2'b01) &&
                        ((stage_exe_rfaddrinchoice==2'b00 && id_inst_in[25:21]==stage_exe_inst[15:11] && stage_exe_inst[15:11]!=0 && stage_exe_inst[31:26]!=6'b101011) ||
                        (stage_exe_rfaddrinchoice==2'b01 && id_inst_in[25:21]==stage_exe_inst[20:16] && stage_exe_inst[20:16]!=0 && stage_exe_inst[31:26]!=6'b101011))) ? 2'b10 : 2'b00;
    
    assign ischangeb =  ((alu_bchoice==2'b00 || alu_bchoice==2'b10) &&
                        ((stage_id_rfaddrinchoice==2'b00 && id_inst_in[20:16]==stage_id_inst[15:11] && stage_id_inst[15:11]!=0 && stage_id_inst[31:26]!=6'b101011) ||
                        (stage_id_rfaddrinchoice==2'b01 && id_inst_in[20:16]==stage_id_inst[20:16] && stage_id_inst[20:16]!=0 && stage_id_inst[31:26]!=6'b101011))) ? 2'b01 :
                        ((alu_bchoice==2'b00 || alu_bchoice==2'b10) &&
                        ((stage_exe_rfaddrinchoice==2'b00 && id_inst_in[20:16]==stage_exe_inst[15:11] && stage_exe_inst[15:11]!=0 && stage_exe_inst[31:26]!=6'b101011) ||
                        (stage_exe_rfaddrinchoice==2'b01 && id_inst_in[20:16]==stage_exe_inst[20:16] && stage_exe_inst[20:16]!=0 && stage_exe_inst[31:26]!=6'b101011))) ? 2'b10 : 2'b00;

    assign id_alu_a=(alu_achoice==2'b00) ? id_rs : 
                    (alu_achoice==2'b01) ? {{27{1'b0}},id_rs} :
                    (alu_achoice==2'b10) ? {{27{1'b0}},id_inst_in[10:6]} : 
                    (alu_achoice==2'b11) ? id_rt : id_pc_in;

    assign id_alu_b=(alu_bchoice==2'b00) ? id_rt : 
                    (alu_bchoice==2'b01) ? {{16{id_inst_in[15]}},id_inst_in[15:0]} :
                    (alu_bchoice==2'b10) ? {{16{1'b0}},id_inst_in[15:0]} : 32'b100;
                    
    assign id_stall_out = 0;
    
    assign id_wb_rfaddr =  id_rf_addrinchoice==2'b00 ? id_inst_in[15:11] : 
                            (id_rf_addrinchoice==2'b01 ? id_inst_in[20:16] : 5'b11111);
                    
endmodule
