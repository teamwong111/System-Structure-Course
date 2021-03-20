`timescale 1ns / 1ps
module sccomp_dataflow(
    input clk, //时钟
    input reset, //复位
    output [7:0] o_seg,
    output [7:0] o_sel
    );
    wire clk_in;
    clk_wiz myclk(
        clk,
        reset,
        clk_in
    );
        
    wire [31:0]ans;
    
    reg [31:0] stage_if_inst;
    reg [31:0] stage_if_pc;
    reg [31:0] stage_if_nextpc;
    
    wire isbranch;
    wire [31:0] branch_pc;
    
    wire [31:0] if_pc_in;
    assign if_pc_in = isbranch ? branch_pc : stage_if_nextpc;
    
    wire [31:0] if_inst_out;
    wire [31:0] if_nextpc_out;
    
    wire id_stall_out;
    
    Instfetch instfetch(
        if_pc_in,
        if_inst_out,
        if_nextpc_out
    );
    // --- CLOCK ---
    always @ (negedge clk_in) 
    begin
        if(reset)
        begin
            stage_if_inst <= 0;
            stage_if_pc <= 0;
            stage_if_nextpc <= 0;
        end
        else if (!id_stall_out) 
        begin
            stage_if_inst <= if_inst_out;//当前指令inst
            stage_if_pc <= if_pc_in;//当前指令pc，用于ID
            stage_if_nextpc <= if_nextpc_out;//下一指令pc，如果没有跳转，则赋给if_pc_in
        end
    end
    
    
    reg [31:0] stage_id_alu_a;
    reg [31:0] stage_id_alu_b;
    reg [4:0] stage_id_aluchoice;
    reg [1:0] stage_id_rfaddrinchoice;
    reg [31:0] stage_id_cp0out;
    reg [31:0] stage_id_hiout;
    reg [31:0] stage_id_loout;
    reg [2:0] stage_id_rfinchoice;
    reg stage_id_rf_inallow;
    reg stage_id_hi_inchoice;
    reg stage_id_lo_inchoice;
    
    reg [31:0] stage_id_inst;
    reg [31:0] stage_id_rs;
    reg [31:0] stage_id_rt;
    
    reg [1:0] stage_id_dmem_inchoice;
    reg [2:0] stage_id_dmem_outchoice;
    
    //用于判断stall
    reg [31:0] stage_exe_inst;
    reg [1:0] stage_exe_rfaddrinchoice;

    //writeback输入
    reg [4:0]stage_id_wb_rfaddr;

    wire [31:0] id_alu_a;
    wire [31:0] id_alu_b;
    wire [31:0] id_rs;
    wire [31:0] id_rt;
    wire [4:0] id_alu_choice;
    wire [1:0] id_rf_addrinchoice;
    wire [31:0] id_cp0out;
    wire [31:0] id_hiout;
    wire [31:0] id_loout;
    wire [2:0] id_rf_inchoice;
    wire id_rf_inallow;
    wire id_hi_inchoice;
    wire id_lo_inchoice;
    wire [1:0]id_dmem_inchoice;
    wire [2:0]id_dmem_outchoice;
    
    //writeback的输出，用于id的输入
    wire [4:0]wb_rfaddr_out;
    wire [31:0]wb_rf_out;
    wire wb_rf_allow_out;
    wire [31:0]wb_hi_out;
    wire [31:0]wb_lo_out;

    //writeback输入
    wire [4:0]id_wb_rfaddr;
    
    //把exe_out和mem_out回接
    wire [31:0] exe_alu_out;
    wire [31:0]mem_wb_rf;
    
    Instdecode instdecode(
        clk_in, 
        reset,
        stage_if_pc, 
        stage_if_inst,
        wb_rfaddr_out, //写regfile
        wb_rf_out, 
        wb_rf_allow_out, 
        wb_hi_out, //写hi_lo
        wb_lo_out, 
        stage_id_inst, //判断stall
        stage_id_rfaddrinchoice,
        stage_exe_inst, 
        stage_exe_rfaddrinchoice,

        //把exe_out和mem_out回接
        exe_alu_out,
        mem_wb_rf,
        
        id_alu_a, 
        id_alu_b, 
        id_rs, 
        id_rt, 
        id_alu_choice, //入alu和writeback
        id_rf_addrinchoice, 
        id_rf_inchoice, 
        id_rf_inallow,//入writeback
        id_hi_inchoice, 
        id_lo_inchoice,//入writeback
        
        isbranch, 
        branch_pc,
        id_stall_out,
        id_cp0out, 
        id_hiout, 
        id_loout,
        id_dmem_inchoice, 
        id_dmem_outchoice,
        ans,

        id_wb_rfaddr

    );
    
    // --- CLOCK ---
    always @ (negedge clk_in) 
    begin
        if(reset)
        begin
            stage_id_alu_a <= 0;
            stage_id_alu_b <= 0;
            stage_id_aluchoice <= 0;
            stage_id_inst <= 0;
            stage_id_rs <= 0;
            stage_id_rt <= 0;
            stage_id_rfaddrinchoice <= 0;
            stage_id_cp0out <= 0;
            stage_id_hiout <= 0;
            stage_id_loout <= 0;
            stage_id_rfinchoice <= 0;
            stage_id_rf_inallow <= 0;
            stage_id_hi_inchoice <= 0;
            stage_id_lo_inchoice <= 0;
            stage_id_dmem_inchoice <= 0;
            stage_id_dmem_outchoice <= 0;

            //writeback用
            stage_id_wb_rfaddr <= 0;
        end
        else 
        begin
            if (!id_stall_out) 
            begin
                stage_id_alu_a <= id_alu_a;
                stage_id_alu_b <= id_alu_b;
                stage_id_aluchoice <= id_alu_choice;
                
                //writeback用
                stage_id_inst <= stage_if_inst;
                stage_id_rs <= id_rs;
                stage_id_rt <= id_rt;
                stage_id_rfaddrinchoice <= id_rf_addrinchoice;
                stage_id_cp0out <= id_cp0out;
                stage_id_hiout <= id_hiout;
                stage_id_loout <= id_loout;
                stage_id_rfinchoice <= id_rf_inchoice;
                stage_id_rf_inallow <= id_rf_inallow;
                stage_id_hi_inchoice <= id_hi_inchoice;
                stage_id_lo_inchoice <= id_lo_inchoice;
                stage_id_dmem_inchoice <= id_dmem_inchoice;
                stage_id_dmem_outchoice <= id_dmem_inchoice;

                //writeback用
                stage_id_wb_rfaddr <= id_wb_rfaddr;
            end
        end
    end
    
    reg [31:0] stage_exe_alu_out;
    
    wire [31:0] exe_alu_loout;
    
    reg [31:0]stage_exe_rt;
    
    reg [1:0]stage_exe_dmem_inchoice;
    reg [2:0]stage_exe_dmem_outchoice;
    
    reg [2:0] stage_exe_rfinchoice;
    reg [31:0] stage_exe_cp0out;
    reg [31:0] stage_exe_hiout;
    reg [31:0] stage_exe_loout;    
    reg stage_exe_rf_inallow;

    //writeback输入
    reg [4:0]stage_exe_wb_rfaddr;
    reg [31:0]stage_exe_wb_hiin;
    reg [31:0]stage_exe_wb_loin;
    wire [31:0]exe_wb_hiin;
    wire [31:0]exe_wb_loin;

    Execute execute(
        stage_id_alu_a,
        stage_id_alu_b,
        stage_id_aluchoice,

        //writeback
        stage_id_hi_inchoice,
        stage_id_lo_inchoice,
        stage_id_rs,

        exe_alu_out,

        //wb
        exe_wb_hiin,
        exe_wb_loin
    );
    
    // --- CLOCK ---
    always @ (negedge clk_in) 
    begin
        if(reset)
        begin
            stage_exe_alu_out <= 0;
            stage_exe_inst <= 0;
            stage_exe_rfaddrinchoice <= 0;
            stage_exe_cp0out <= 0;
            stage_exe_hiout <= 0;
            stage_exe_loout <= 0;
            stage_exe_rfinchoice <= 0;
            stage_exe_rf_inallow <= 0;
            
            stage_exe_rt <= 0;
            stage_exe_dmem_inchoice <= 0;
            stage_exe_dmem_outchoice <= 0;

            //writaback用
            stage_exe_wb_rfaddr <= 0;
            stage_exe_wb_hiin <= 0;
            stage_exe_wb_loin <= 0;
        end
        else
        begin
            stage_exe_alu_out <= exe_alu_out;
            
            stage_exe_inst <= stage_id_inst;
            stage_exe_rfaddrinchoice <= stage_id_rfaddrinchoice;
            stage_exe_cp0out <= stage_id_cp0out;
            stage_exe_hiout <= stage_id_hiout;
            stage_exe_loout <= stage_id_loout;
            stage_exe_rfinchoice <= stage_id_rfinchoice;
            stage_exe_rf_inallow <= stage_id_rf_inallow;
            
            stage_exe_rt <= stage_id_rt;
            stage_exe_dmem_inchoice <= stage_id_dmem_inchoice;
            stage_exe_dmem_outchoice <= stage_id_dmem_outchoice;

            //writaback用
            stage_exe_wb_rfaddr <= stage_id_wb_rfaddr;
            stage_exe_wb_hiin <= exe_wb_hiin;
            stage_exe_wb_loin <= exe_wb_loin;
        end
    end
    
    //writaback用
    reg [4:0]stage_mem_wb_rfaddr;
    reg [31:0]stage_mem_wb_rfin;
    reg stage_mem_rf_inallow;
    reg [31:0]stage_mem_wb_hiin;
    reg [31:0]stage_mem_wb_loin;


    Memory memory(
        clk_in,
        stage_exe_dmem_inchoice,
        stage_exe_alu_out,//也是writeback用
        stage_exe_rt,
        stage_exe_dmem_outchoice,

        stage_exe_rfinchoice,//writeback用
        stage_exe_wb_loin,
        stage_exe_cp0out,
        stage_exe_hiout,
        stage_exe_loout,

        mem_wb_rf
    );
    
    // --- CLOCK ---
    always @ (negedge clk_in) 
    begin
        if(reset)
        begin             
            stage_mem_wb_rfaddr <= 0;
            stage_mem_wb_rfin <= 0;
            stage_mem_rf_inallow <= 0;
            stage_mem_wb_hiin <= 0;
            stage_mem_wb_loin <= 0;
        end
        else
        begin
            stage_mem_wb_rfaddr <= stage_exe_wb_rfaddr;
            stage_mem_wb_rfin <= mem_wb_rf;
            stage_mem_rf_inallow <= stage_exe_rf_inallow;
            stage_mem_wb_hiin <= stage_exe_wb_hiin;
            stage_mem_wb_loin <= stage_exe_wb_loin;
        end
    end
    
    Writeback writeback(
        stage_mem_wb_rfaddr,
        stage_mem_wb_rfin,
        stage_mem_rf_inallow,
        stage_mem_wb_hiin,
        stage_mem_wb_loin,
        
        wb_rfaddr_out,
        wb_rf_out,
        wb_rf_allow_out,
        wb_hi_out,
        wb_lo_out
    );
    
    seg7x16 seg(
        clk_in, 
        reset,
        ans,

        o_seg,
        o_sel
    );
        
endmodule