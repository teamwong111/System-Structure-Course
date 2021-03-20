    `timescale 1ns / 1ps
    module sccomp_dataflow(
        input clk_in, //ʱ��
        input reset, //��λ
        output [7:0] o_seg,
        output [7:0] o_sel
        );
        wire [31:0]ans;
        //wire clk_in;
        //clk_wiz Myclk(clk, clk_in);
        
        reg [31:0] stage_if_inst;
        reg [31:0] stage_if_pc;
        reg [31:0] stage_if_nextpc;
        
        wire isbranch;
        wire [31:0]branch_pc;
        
        wire [31:0] if_pc_in = isbranch ? branch_pc : stage_if_nextpc;
        
        wire [31:0] if_inst_out;
        wire [31:0] if_nextpc_out;
        
        wire id_stall_out;
        
        
        InstFetch instfetch(
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
                stage_if_inst <= if_inst_out;//��ǰָ��inst
                stage_if_pc <= if_pc_in;//��ǰָ��pc������ID
                stage_if_nextpc <= if_nextpc_out;//��һָ��pc�����û����ת���򸳸�if_pc_in
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
        
        reg [31:0] stage_id_inst;
        reg [31:0] stage_id_rs;
        reg [31:0] stage_id_rt;
        
        reg [1:0] stage_id_dmem_inchoice;
        reg [2:0] stage_id_dmem_outchoice;
        
        //�����ж�stall
        reg [31:0]stage_exe_inst;
        reg [1:0] stage_exe_rfaddrinchoice;
        
        //writeback�����������id������
        wire [4:0]wb_rfaddr_out;
        wire [31:0]wb_rf_out;
        wire wb_rf_allow;
        wire [31:0]wb_hi_out;
        wire [31:0]wb_lo_out;
        
        InstDecode instdecode(
            clk_in, reset,
            stage_if_pc, stage_if_inst,
            wb_rfaddr_out, wb_rf_out, wb_rf_allow, //дregfile
            wb_hi_out, wb_lo_out, //дhi_lo
            stage_id_inst, stage_id_rfaddrinchoice,//�ж�stall
            stage_exe_inst, stage_exe_rfaddrinchoice,
            
            id_alu_a, id_alu_b, id_rs, id_rt, id_alu_choice, //��alu��writeback
            id_rf_addrinchoice, id_rf_inchoice, id_rf_inallow,//��writeback
            id_hi_inchoice, id_lo_inchoice,//��writeback
            
            isbranch, branch_pc,
            id_stall_out,
            id_cp0out, id_hiout, id_loout,
            id_dmem_inchoice, id_dmem_outchoice,
            ans
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
            end
            else 
            begin
                if (!id_stall_out) 
                begin
                    stage_id_alu_a <= id_alu_a;
                    stage_id_alu_b <= id_alu_b;
                    stage_id_aluchoice <= id_alu_choice;
                    
                    //writeback��
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
                end
            end
        end
        
        reg [31:0] stage_exe_alu_out;
        reg [31:0] stage_exe_alu_hiout;
        reg [31:0] stage_exe_alu_loout;
        
        wire [31:0] exe_alu_out;
        wire [31:0] exe_alu_hiout;
        wire [31:0] exe_alu_loout;
        
        reg [31:0]stage_exe_rs;
        reg [31:0]stage_exe_rt;
        
        reg [1:0]stage_exe_dmem_inchoice;
        reg [2:0]stage_exe_dmem_outchoice;
        
        reg [2:0] stage_exe_rfinchoice;
        reg [31:0] stage_exe_cp0out;
        reg [31:0] stage_exe_hiout;
        reg [31:0] stage_exe_loout;    
        reg stage_exe_rf_inallow;
        reg stage_exe_hi_inchoice;
        reg stage_exe_lo_inchoice;
    
        
        Execute execute(
            clk_in,
            stage_id_alu_a,
            stage_id_alu_b,
            stage_id_aluchoice,
            exe_alu_out,
            exe_alu_hiout,
            exe_alu_loout
        );
        
        // --- CLOCK ---
        always @ (negedge clk_in) 
        begin
            if(reset)
            begin
                stage_exe_alu_out <= 0;
                stage_exe_alu_hiout <= 0;
                stage_exe_alu_loout <= 0;
                stage_exe_inst <= 0;
                stage_exe_rs <= 0;
                stage_exe_rfaddrinchoice <= 0;
                stage_exe_cp0out <= 0;
                stage_exe_hiout <= 0;
                stage_exe_loout <= 0;
                stage_exe_rfinchoice <= 0;
                stage_exe_rf_inallow <= 0;
                stage_exe_hi_inchoice <= 0;
                stage_exe_lo_inchoice <= 0;
                
                stage_exe_rt <= 0;
                stage_exe_dmem_inchoice <= 0;
                stage_exe_dmem_outchoice <= 0;
            end
            else
            begin
                stage_exe_alu_out <= exe_alu_out;//
                stage_exe_alu_hiout <= exe_alu_hiout;//
                stage_exe_alu_loout <= exe_alu_loout;//
                
                
                stage_exe_inst <= stage_id_inst;
                stage_exe_rs <= stage_id_rs;
                stage_exe_rfaddrinchoice <= stage_id_rfaddrinchoice;
                stage_exe_cp0out <= stage_id_cp0out;
                stage_exe_hiout <= stage_id_hiout;
                stage_exe_loout <= stage_id_loout;
                stage_exe_rfinchoice <= stage_id_rfinchoice;
                stage_exe_rf_inallow <= stage_id_rf_inallow;
                stage_exe_hi_inchoice <= stage_id_hi_inchoice;
                stage_exe_lo_inchoice <= stage_id_lo_inchoice;
                
                stage_exe_rt <= stage_id_rt;
                stage_exe_dmem_inchoice <= stage_id_dmem_inchoice;
                stage_exe_dmem_outchoice <= stage_id_dmem_outchoice;
            end
        end
        
        
        reg [31:0]stage_mem_dmem_out;
        
        wire [31:0]mem_dmem_out;
        
        reg [31:0] stage_mem_alu_out;
        reg [31:0] stage_mem_alu_hiout;
        reg [31:0] stage_mem_alu_loout;
        reg [31:0]stage_mem_inst;
        reg [31:0]stage_mem_rs;
        reg [1:0] stage_mem_rfaddrinchoice;
        reg [31:0] stage_mem_cp0out;
        reg [31:0] stage_mem_hiout;
        reg [31:0] stage_mem_loout;   
        reg [2:0] stage_mem_rfinchoice;
        reg stage_mem_rf_inallow;
        reg stage_mem_hi_inchoice;
        reg stage_mem_lo_inchoice;
        
        Memory memory(
            clk_in,
            stage_exe_dmem_inchoice,
            stage_exe_alu_out,
            stage_exe_rt,
            stage_exe_dmem_outchoice,
            mem_dmem_out
        );
        
        // --- CLOCK ---
        always @ (negedge clk_in) 
        begin
            if(reset)
            begin
                stage_mem_dmem_out <= 0;              
                stage_mem_alu_out <= 0;
                stage_mem_alu_hiout <= 0;
                stage_mem_alu_loout <= 0;
                stage_mem_inst <= 0;
                stage_mem_rs <= 0;
                stage_mem_rfaddrinchoice <= 0;
                stage_mem_rfinchoice <= 0;
                stage_mem_rf_inallow <= 0;
                stage_mem_hi_inchoice <= 0;
                stage_mem_lo_inchoice <= 0;
            end
            else
            begin
                stage_mem_dmem_out <= mem_dmem_out;
                
                
                stage_mem_alu_out <= stage_exe_alu_out;
                stage_mem_alu_hiout <= stage_exe_alu_hiout;
                stage_mem_alu_loout <= stage_exe_alu_loout;
                stage_mem_inst <= stage_exe_inst;
                stage_mem_rs <= stage_exe_rs;
                stage_mem_rfaddrinchoice <= stage_exe_rfaddrinchoice;
                stage_mem_cp0out <= stage_exe_cp0out;
                stage_mem_hiout <= stage_exe_hiout;
                stage_mem_loout <= stage_exe_loout;  
                stage_mem_rfinchoice <= stage_exe_rfinchoice;
                stage_mem_rf_inallow <= stage_exe_rf_inallow;
                stage_mem_hi_inchoice <= stage_exe_hi_inchoice;
                stage_mem_lo_inchoice <= stage_exe_lo_inchoice;
            end
        end
        
    
        Writeback writeback(
            stage_mem_rfaddrinchoice,
            stage_mem_inst[15:11],
            stage_mem_inst[20:16],
            5'b11111,
            
            stage_mem_rfinchoice,
            stage_mem_alu_out,
            stage_mem_dmem_out,
            stage_mem_alu_loout,
            stage_mem_cp0out,
            stage_mem_hiout,
            stage_mem_loout,
            
            stage_mem_rf_inallow,
            
            stage_mem_hi_inchoice,
            stage_mem_rs,
            stage_mem_alu_hiout,
            
            stage_mem_lo_inchoice,
            stage_mem_rs,
            stage_mem_alu_loout,
            
            wb_rfaddr_out,
            wb_rf_out,
            wb_rf_allow,
            wb_hi_out,
            wb_lo_out
        );
        
        seg7x16 Seg(
            clk_in, 
            reset,
            ans,
            o_seg,
            o_sel
        );
            
    endmodule