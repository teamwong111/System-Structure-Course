`timescale 1ns / 1ps
module ddrandsd(
	input clk,
	input reset,
	input sd_miso,
	output sd_cs,
	output sd_mosi,
	output sd_clk,
	output sd_init_done,
	output sd_write_done,
	output sd_read_done,
/************************/
    inout [15:0]ddr2_dq,
	inout [1:0]ddr2_dqs_n,
	inout [1:0]ddr2_dqs_p,
	output [12:0]ddr2_addr,
	output [2:0]ddr2_ba,
	output ddr2_ras_n,
	output ddr2_cas_n,
	output ddr2_we_n,
	output ddr2_ck_p,
	output ddr2_ck_n,
	output ddr2_cke,
	output ddr2_cs_n,
	output [1:0]ddr2_dm,
	output ddr2_odt,
/************tempLook********/
	output ishit,
	input[7:0]pc_in,
	output[31:0]inst
    );

    wire[31:0]pc;
    assign pc={22'b0,pc_in,2'b0};

    reg write_cache;
    reg[511:0]cache_data_in;
    reg cache_need_data;
    reg[31:0]ddr_out_addr;
    reg[5:0]cache_cnt;

    cache icache(
        clk,
        reset,
        write_cache,
        pc,
        cache_data_in,
        ishit,
        inst
    );
        
    reg can_cache_read;
    reg[4:0]ddr_cache_state;
    reg[127:0]reg_ddr_data_out;
    wire[127:0]ddr_data_out;
    reg ddr_read_ready;

    always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            ddr_cache_state <= 0;
            cache_need_data <= 0;
            write_cache <= 0;
            cache_cnt <= 0;
            cache_data_in <= 0;
        end
        else
        begin
            if(ddr_cache_state==0&&can_cache_read)
            begin
                write_cache <= 0;
                if(~ishit)
                begin
                    ddr_cache_state <= 1;
                    cache_need_data <= 0;
                    ddr_out_addr <= {4'b0,pc[31:6],2'b0};
                    cache_cnt <= 4;
                end
            end
            if(ddr_cache_state==1)
            begin
                if(cache_cnt==0)
                begin
                    ddr_cache_state <= 0;
                    write_cache <= 1;
                end
                else
                begin
                    cache_need_data <= 1;
                    ddr_cache_state <= 2;
                end
            end
            if(ddr_cache_state==2)
            begin
                cache_need_data <= 0;
                if(ddr_read_ready)
                begin
                    ddr_cache_state <= 1;
                    cache_cnt <= cache_cnt-1;
                    ddr_out_addr <= ddr_out_addr+1;
                    cache_data_in <= {cache_data_in[383:0],reg_ddr_data_out};
                end
            end
        end
    end
    
    wire[8:0]sd_addr;
    wire[7:0]sd_data_out;

    topsd sdtop(
        clk,
        ~reset,
        sd_miso,
        sd_cs,
        sd_mosi,
        sd_clk,
        sd_init_done,
        sd_write_done,
        sd_read_done,
        sd_addr,
        sd_data_out
    );

    wire ddr_busy;
    wire ddr_done;
    wire ddr_start_ready;

    reg[5:0]ddr_state;
    reg[31:0]result;
    reg ddr_read_write;
    reg[31:0]ddr_addr;
    reg[127:0]ddr_data_in;

    reg can_write_ddr;
    reg[4:0]sd_ddr_state;
    reg[127:0]reg_ddr_data_in;
    reg sd_data_ready;
    reg[3:0]ddr_cnt;

    assign sd_addr={ddr_addr[4:0],ddr_cnt};

    //把sd_output传递到reg
    always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            reg_ddr_data_in <= 0;
            sd_data_ready <= 0;
            ddr_cnt <= 0;
            sd_ddr_state <= 0;
        end
        else
        begin
            if(sd_ddr_state==5)
            begin
                if(sd_read_done)
                    sd_ddr_state <= 0;
            end
            else if(sd_ddr_state==0)
            begin
                if(can_write_ddr)
                begin
                    ddr_cnt <= 0;
                    sd_data_ready <= 0;
                    reg_ddr_data_in <= 0;
                    sd_ddr_state <= 1;
                end
            end
            else if(sd_ddr_state==1)
            begin
                if(ddr_cnt==15)
                begin
                    reg_ddr_data_in <= {reg_ddr_data_in[119:0],sd_data_out};
                    sd_data_ready <= 1;
                    sd_ddr_state <= 0;
                end
                else
                begin
                    reg_ddr_data_in <= {reg_ddr_data_in[119:0],sd_data_out};
                    ddr_cnt <= ddr_cnt+1;
                end
            end
        end
    end
    //sd_output到reg结束


    reg ddr_write_done;
    always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            ddr_state <= 0;
            ddr_read_write <= 1'b0;
            result <= 32'h10000000;
            ddr_addr <= 0;
            ddr_write_done <= 0;
            can_cache_read <= 0;
        end
        else if(ddr_state==0&&ddr_start_ready==1&&sd_read_done)
        begin
            if(ddr_write_done==0)
            begin
                ddr_state <= 11;
                ddr_read_write <= 1'b0;
                can_write_ddr <= 1'b1;
            end
            else
            begin
                ddr_state <= 1;
                ddr_read_write <= 1'b0;
                ddr_addr <= 0;
            end
        end
        else if(ddr_state==11)
        begin
            can_write_ddr <= 1'b0;
            if(~ddr_busy&&ddr_done&&sd_data_ready)
            begin
                ddr_state <= 12;
                ddr_read_write <= 1'b1;
                ddr_addr <= ddr_addr;
                ddr_data_in <= reg_ddr_data_in;
            end	
        end
        else if(ddr_state==12)
        begin
            can_write_ddr <= 1'b0;
            if(~ddr_busy&&ddr_done)
            begin
                ddr_state <= 0;
                ddr_read_write <= 1'b0;
                if(ddr_addr==31)ddr_write_done <= 1;
                    ddr_addr <= ddr_addr+1;
            end
        end
        else if(ddr_state==1)
        begin
            can_cache_read <= 1;
            ddr_read_ready <= 0;
            reg_ddr_data_out <= 0;
            if(cache_need_data)
            begin
                ddr_state <= 2;
                ddr_read_write <= 1'b0;
            end
            else
            begin
                ddr_state <= 1;
                ddr_read_write <= 1'b0;
            end
        end
        else if(ddr_state==2)
        begin
            if(~ddr_busy&&ddr_done)
            begin
                ddr_read_write <= 1'b0;
                ddr_addr <= ddr_out_addr;
                ddr_state <= 3;
            end
            else
            begin
                ddr_state <= 2;
            end
        end
        else if(ddr_state==3)
        begin
            if(~ddr_busy&&ddr_done)
            begin
                ddr_read_write <= 1'b0;
                reg_ddr_data_out <= ddr_data_out;
                ddr_read_ready <= 1'b1;
                ddr_state <= 1;
            end
            else
            begin
                ddr_state <= 3;
            end
        end
    end

    sealedDDR top_ddr(
        clk,
        reset,
        ddr_addr,
        ddr_data_in,
        ddr_read_write,
        ddr_data_out,
        ddr_busy,
        ddr_done,
        ddr_start_ready,
        //ddr signal
        ddr2_dq,
        ddr2_dqs_n,
        ddr2_dqs_p,
        ddr2_addr,
        ddr2_ba,
        ddr2_ras_n,
        ddr2_cas_n,
        ddr2_we_n,
        ddr2_ck_p,
        ddr2_ck_n,
        ddr2_cke,
        ddr2_cs_n,
        ddr2_dm,
        ddr2_odt
    );

endmodule
