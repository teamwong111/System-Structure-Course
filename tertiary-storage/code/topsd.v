`timescale 1ns / 1ps
module topsd(
    input clk,
    input reset,
    input sd_miso,
    output sd_cs,
    output sd_mosi,
    output sd_clk,
//    output led,
//    output [7:0]o_seg,
//    output [7:0]o_sel,
    output init_done,
    output write_finish,
    output read_finish,
    
    input [8:0]raddr,
    output [7:0]rdata
    );
    assign write_finish = 1'b1;
    
//wire init_done;
wire write_start;
wire [31:0]write_addr;  
wire [15:0]write_data;
wire write_busy;         
wire write_request;                     
wire read_start;       
wire read_enable; 
wire [31:0]read_addr;
wire [15:0]read_data;   
wire read_error;                

wire [8:0]ram_addr;

//����SD����������  
data_gen u_data_gen(
    clk,
    reset,
    init_done,
    
    write_busy,
    write_request,
    write_start,
    write_addr,
    write_data,
    
    read_enable,
    read_data,
    read_start,
    read_addr,
    read_error,
    
    ram_addr
    );     

//SD���������ģ��
sd_ctrl_top u_sd_ctrl_top(
    clk,
    reset,
    //SD���ӿ�
    sd_miso,
    sd_clk,
    sd_cs,
    sd_mosi,
    //дSD���ӿ�
    write_start,
    write_addr,
    write_data,
    write_busy,
    write_request,
    //��SD���ӿ�
    read_start,
    read_addr,
    read_enable,
    read_data,    
    //��ʼ�����
    init_done,
    
    read_finish
    );

////led��ʾ 
//led_alarm u_led_alarm(
//    clk,
//    reset,
//    read_error,
//    led
//    );    

//wire [31:0]rdata;

////7�������
//seg7x16 seg(
//    clk, 
//    reset,
//    rdata,
//    o_seg,
//    o_sel
//);

//ram
sd_ram ram(
    clk,
    read_enable,
    ram_addr,
    read_data,
    
    raddr,
    rdata
); 

endmodule