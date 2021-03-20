`timescale 1ns / 1ps
module InstDecode(
    input clk, 
    input reset,
    input [31:0]id_pc_in, 
    input [31:0]id_inst_in,
    input [4:0]id_rfaddr_in, 
    input [31:0]id_rf_in, 
    input id_rf_inallow_rf,
    input [31:0]id_hi_in, 
    input [31:0]id_lo_in,
    
    input [31:0]stage_id_inst, 
    input [1:0]stage_id_rfaddrinchoice,
    input [31:0]stage_exe_inst, 
    input [1:0]stage_exe_rfaddrinchoice,
    
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
    output [31:0]id_lo_out, //要用到rf_in里，在writeback 
    
    output [1:0]id_dmem_inchoice,
    output [2:0]id_dmem_outchoice,
    output [31:0]ans
    );
    
    wire [1:0]alu_achoice;
    wire [1:0]alu_bchoice;
    
    
    wire mfc0src;
    wire mtc0src;
    wire exception;
    wire _eret;
    wire [4:0]cause;
    wire [31:0]exc_addr;
    
    controlunit cpu_controlunit(
        clk,
        id_inst_in,
        id_rs, 
        id_rt,
        id_aluchoice, 
        alu_achoice, 
        alu_bchoice,
        id_rf_addrinchoice, id_rf_inchoice, id_rf_inallow,
        id_hi_inchoice, id_lo_inchoice,
        id_dmem_inchoice, id_dmem_outchoice,
        mfc0src, mtc0src, exception, _eret, cause
    );

    regfile cpu_ref (
        clk, reset, 
        id_inst_in[25:21], id_inst_in[20:16], 
        id_rfaddr_in, id_rf_in, id_rf_inallow_rf, 
        id_rs, id_rt,
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
        exc_addr);
    
    hi_lo cpu_hi_lo(clk, reset, id_hi_in, id_lo_in, id_hi_out, id_lo_out);
    
    
    assign id_alu_a = alu_achoice==2'b00 ? id_rs : 
                     (alu_achoice==2'b01 ? {{27{1'b0}},id_rs} :
                     (alu_achoice==2'b10 ? {{27{1'b0}},id_inst_in[10:6]} : id_pc_in));
    assign id_alu_b = alu_bchoice==2'b00 ? id_rt : 
                     (alu_bchoice==2'b01 ? {{16{id_inst_in[15]}},id_inst_in[15:0]} :
                     (alu_bchoice==2'b10 ? {{16{1'b0}},id_inst_in[15:0]} : 32'b100));
    
    
    //stall
    reg [1:0]stall_count;
    always @(posedge clk)
    begin
        if(!id_stall_out && stage_id_inst)
        begin
            if(({stage_id_inst[31:26],stage_id_inst[5:0]}==12'b000000_011011 || 
                {stage_id_inst[31:26],stage_id_inst[5:0]}==12'b000000_011010 ||
                {stage_id_inst[31:26],stage_id_inst[5:0]}==12'b011100_000010 ||
                {stage_id_inst[31:26],stage_id_inst[5:0]}==12'b000000_011001) &&
                ({id_inst_in[31:26],id_inst_in[5:0]}==12'b000000_010000 ||
                 {id_inst_in[31:26],id_inst_in[5:0]}==12'b000000_010010))
            begin
                stall_count <= 2'b11;
            end
            else if(({stage_exe_inst[31:26],stage_exe_inst[5:0]}==12'b000000_011011 || 
                {stage_exe_inst[31:26],stage_exe_inst[5:0]}==12'b000000_011010 ||
                {stage_exe_inst[31:26],stage_exe_inst[5:0]}==12'b011100_000010 ||
                {stage_exe_inst[31:26],stage_exe_inst[5:0]}==12'b000000_011001) &&
                ({id_inst_in[31:26],id_inst_in[5:0]}==12'b000000_010000 ||
                 {id_inst_in[31:26],id_inst_in[5:0]}==12'b000000_010010))
            begin
                stall_count <= 2'b10;
            end            
            if(alu_achoice==2'b00 || alu_achoice==2'b01)
            begin                
                if(stage_id_rfaddrinchoice==2'b00 && id_inst_in[25:21]==stage_id_inst[15:11] && stage_id_inst[15:11]!=0)
                begin
                    stall_count <= 2'b11;
                end
                else if(stage_exe_rfaddrinchoice==2'b00 && id_inst_in[25:21]==stage_exe_inst[15:11] && stage_exe_inst[15:11]!=0)
                begin
                    stall_count <= 2'b10;
                end
                else if(stage_id_rfaddrinchoice==2'b01 && id_inst_in[25:21]==stage_id_inst[20:16] && stage_id_inst[20:16]!=0)
                begin
                    stall_count <= 2'b11;
                end
                else if(stage_exe_rfaddrinchoice==2'b01 && id_inst_in[25:21]==stage_exe_inst[20:16] && stage_exe_inst[20:16]!=0)
                begin
                    stall_count <= 2'b10;
                end
            end
            if(alu_bchoice==2'b00 && stall_count!=2'b11)
            begin
                if(stage_id_rfaddrinchoice==2'b00 && id_inst_in[20:16]==stage_id_inst[15:11] && stage_id_inst[15:11]!=0)
                begin
                    stall_count <= 2'b11;
                end
                else if(stage_exe_rfaddrinchoice==2'b00 && id_inst_in[20:16]==stage_exe_inst[15:11] && stage_exe_inst[15:11]!=0)
                begin
                    stall_count <= 2'b10;
                end
                else if(stage_id_rfaddrinchoice==2'b01 && id_inst_in[20:16]==stage_id_inst[20:16] && stage_id_inst[20:16]!=0)
                begin
                    stall_count <= 2'b11;
                end
                else if(stage_exe_rfaddrinchoice==2'b01 && id_inst_in[20:16]==stage_exe_inst[20:16] && stage_exe_inst[20:16]!=0)
                begin
                    stall_count <= 2'b10;
                end           
            end
        end    
        if(reset)
        begin
            stall_count <= 2'b00;
        end
        else
        begin
            if(stall_count!=2'b00)
            begin
                stall_count <= stall_count-1;
            end   
        end
    end
    
    assign id_stall_out = stall_count ? 1 : 0;                 
    
    //isbranch
    branchpredict cpu_branchpredict(
        clk,
        id_pc_in, id_inst_in,
        id_stall_out,
        id_rs, id_alu_a, id_alu_b,
        isbranch, branch_pc
    );
    
endmodule
