`timescale 1ns / 1ps
module topcpu(
    input clk_in,
    input reset,
    output [7:0] o_seg,
    output [7:0] o_sel,
    input miso,
    output cs,
    output mosi,
    output spiclk,
    output initfinish,
    output writefinish,
    output readfinish,
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
	output ddr2_odt
/************tempLook********/
    );
    wire cpu_stall;
    wire[31:0]reg28;
    wire[31:0]inst;
    wire[31:0]realpc;
    reg div_clk=0;
    reg[40:0]clk_cnt=0;

    always @(posedge clk_in or posedge reset)
    begin
        if(reset)
        begin
            div_clk<=0;
        end
        else if(clk_cnt==0)
        begin
            div_clk<=~div_clk;
            clk_cnt<=200000;
        end
        else
        begin
            clk_cnt<=clk_cnt-1;
        end
    end

    sccomp_dataflow cpu(
        div_clk,
        reset,
        inst,        
        cpu_stall,
        realpc,//pc=realpc>>2
        reg28 
    );

    seg7x16 seg(
        clk_in,
        reset,
        1'b1,
        reg28,
        o_seg,
        o_sel
    ); 

    wire[31:0]pc;
    assign pc=realpc>>2;

    wire ishit;
    assign cpu_stall=~ishit;

    ddrandsd threemem(
        clk_in,
        reset,
        miso,
        cs,
        mosi,
        spiclk,
        initfinish,
        writefinish,
        readfinish,

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
        ddr2_odt,

        ishit,
        pc[7:0],
        inst
    );

endmodule
