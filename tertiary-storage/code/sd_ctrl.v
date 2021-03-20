`timescale 1ns / 1ps
module sd_ctrl_top(
    input clk,           
    input reset,
    //SD���ӿ�
    input sd_miso,              
    output sd_clk,                
    output sd_cs,              
    output sd_mosi,             
    //�û�дSD���ӿ�
    input write_start,          
    input [31:0]write_addr,   
    input [15:0]write_data,                        
    output write_busy,             
    output write_request,         
    //�û���SD���ӿ�
    input read_start,    
    input [31:0]read_addr,   
    output read_enable,//��������Ч�ź�
    output [15:0]read_data,      
    output init_done,
    
    output read_finish
    );

wire read_busy;
wire init_sd_clk;
wire init_sd_cs;
wire init_sd_mosi;
wire write_sd_cs;     
wire write_sd_mosi; 
wire read_sd_cs;   
wire read_sd_mosi;
  
assign sd_clk = (init_done==1'b0) ? init_sd_clk : ~clk; //ʱ���ź�,��clk_ref��λ���180��

//SD���ӿ��ź�ѡ��
assign sd_cs =  (init_done == 1'b0) ? init_sd_cs :
                (write_busy) ? write_sd_cs :
                (read_busy) ? read_sd_cs : 1'b1;

assign sd_mosi= (init_done == 1'b0) ? init_sd_mosi :
                (write_busy) ? write_sd_mosi :
                (read_busy) ? read_sd_mosi : 1'b1;
 
//SD����ʼ��
sd_init u_sd_init(
    clk,
    reset,
    sd_miso,
    init_sd_clk,
    init_sd_cs,
    init_sd_mosi,
    init_done
    );

//SD��д����
sd_write u_sd_write(
    clk,
    reset,
    sd_miso,
    write_sd_cs,
    write_sd_mosi,
    //SD����ʼ�����֮����Ӧд����    
    write_start & init_done,  
    write_addr,
    write_data,
    write_busy,
    write_request
    );

//SD��������
sd_read u_sd_read(
    clk,
    reset,
    sd_miso,
    read_sd_cs,
    read_sd_mosi,    
    //SD����ʼ�����֮����Ӧ������
    read_start & init_done,  
    read_addr,
    read_busy,
    read_enable,
    read_data,
    
    read_finish
    );

endmodule