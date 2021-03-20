`timescale 1ns / 1ps
module sd_ctrl_top(
    input clk,           
    input reset,
    //SD卡接口
    input sd_miso,              
    output sd_clk,                
    output sd_cs,              
    output sd_mosi,             
    //用户写SD卡接口
    input write_start,          
    input [31:0]write_addr,   
    input [15:0]write_data,                        
    output write_busy,             
    output write_request,         
    //用户读SD卡接口
    input read_start,    
    input [31:0]read_addr,   
    output read_enable,//读数据有效信号
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
  
assign sd_clk = (init_done==1'b0) ? init_sd_clk : ~clk; //时钟信号,与clk_ref相位相差180度

//SD卡接口信号选择
assign sd_cs =  (init_done == 1'b0) ? init_sd_cs :
                (write_busy) ? write_sd_cs :
                (read_busy) ? read_sd_cs : 1'b1;

assign sd_mosi= (init_done == 1'b0) ? init_sd_mosi :
                (write_busy) ? write_sd_mosi :
                (read_busy) ? read_sd_mosi : 1'b1;
 
//SD卡初始化
sd_init u_sd_init(
    clk,
    reset,
    sd_miso,
    init_sd_clk,
    init_sd_cs,
    init_sd_mosi,
    init_done
    );

//SD卡写数据
sd_write u_sd_write(
    clk,
    reset,
    sd_miso,
    write_sd_cs,
    write_sd_mosi,
    //SD卡初始化完成之后响应写操作    
    write_start & init_done,  
    write_addr,
    write_data,
    write_busy,
    write_request
    );

//SD卡读数据
sd_read u_sd_read(
    clk,
    reset,
    sd_miso,
    read_sd_cs,
    read_sd_mosi,    
    //SD卡初始化完成之后响应读操作
    read_start & init_done,  
    read_addr,
    read_busy,
    read_enable,
    read_data,
    
    read_finish
    );

endmodule