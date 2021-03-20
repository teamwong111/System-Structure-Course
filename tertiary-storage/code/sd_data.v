`timescale 1ns / 1ps
module data_gen(
    input clk,
    input reset,
    input init_done,//SD卡初始化完成信号
    //写SD卡接口
    input write_busy,//写数据忙信号
    input write_request,//写数据请求信号
    output reg write_start,//开始写SD卡数据信号
    output reg [31:0]write_addr,//写数据扇区地址
    output [15:0]write_data,//写数据
    //读SD卡接口
    input read_enable,//读数据有效信号
    input [15:0]read_data,//读数据
    output reg read_start,//开始读SD卡数据信号
    output reg [31:0]read_addr,//读数据扇区地址
    output read_error,//SD卡读写错误的标志
    
    output reg [8:0]ram_addr
    );

reg init_done_beat1;//init_done信号延时打拍
reg init_done_beat2;       
reg write_busy_beat1;//write_busy信号延时打拍
reg write_busy_beat2;
reg [15:0]reg_write_data;    
reg [15:0]comp_read_data;//用于对读出数据作比较的正确数据
reg [8:0]right_read_cnt;//读出正确数据的个数

wire pos_init_done;//init_done信号的上升沿,用于启动写入信号
wire neg_write_busy;//write_busy信号的下降沿,用于判断数据写入完成

assign pos_init_done = (~init_done_beat2) & init_done_beat1;

assign neg_write_busy = write_busy_beat2 & (~write_busy_beat1);

assign write_data = reg_write_data;

assign read_error = (right_read_cnt == (9'd256)) ? 1'b0 : 1'b1;//读128次正确的数据,说明读写测试成功,read_error = 0

reg [15:0] ins[0:1023];//指令寄存器模块
reg [15:0]ins_cnt;
initial 
begin
    $readmemh("F:/Download/2.hex.txt", ins);
end

//信号延时打拍
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        init_done_beat1 <= 1'b0;
        init_done_beat2 <= 1'b0;
        write_busy_beat1 <= 1'b0;
        write_busy_beat2 <= 1'b0;
    end
    else 
    begin
        init_done_beat1 <= init_done;
        init_done_beat2 <= init_done_beat1;
        write_busy_beat1 <= write_busy;
        write_busy_beat2 <= write_busy_beat1;
    end        
end

//SD卡写入信号控制
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        write_start <= 1'b0;
        write_addr <= 32'd0;
    end    
    else 
    begin
        if(pos_init_done) 
        begin
            write_start <= 1'b1;
            write_addr <= 32'd20;//指定扇区地址 2000
        end    
        else
            write_start <= 1'b0;
    end    
end 

//SD卡写数据
always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        reg_write_data <= 16'b0;
        ins_cnt <= 16'b0;        
    end
    else 
    begin
        if(write_request) 
        begin
            ins_cnt <= ins_cnt + 16'b1;
            if (ins_cnt < 106) 
            begin
                reg_write_data <= ins[ins_cnt];  
            end
            else
            begin
                reg_write_data <= 16'b0;
            end
        end
    end
end

//SD卡读出信号控制
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        read_start <= 1'b0;
        read_addr <= 32'd0;    
    end
    else 
    begin
        if(neg_write_busy) 
        begin
            read_start <= 1'b1;
            read_addr <= 32'd20;
        end   
        else
            read_start <= 1'b0;          
    end    
end    

//读数据错误时给出标志
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        comp_read_data <= 16'd0;
        right_read_cnt <= 9'd0;
        
        ram_addr <= 9'b0;
    end     
    else 
    begin
        if(read_enable) 
        begin
            comp_read_data <= comp_read_data + 16'b1;
            if(ram_addr < 9'd212)
                ram_addr <= ram_addr + 9'd2;
            else
                ram_addr <= ram_addr;
            
            if(comp_read_data < 106)
            begin
                if(read_data == ins[comp_read_data])
                    right_read_cnt <= right_read_cnt + 9'd1; 
            end
            else
            begin
                if(read_data == 16'b0)
                    right_read_cnt <= right_read_cnt + 9'd1; 
            end 
        end    
    end        
end

endmodule