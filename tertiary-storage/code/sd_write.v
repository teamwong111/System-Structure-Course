`timescale 1ns / 1ps
module sd_write(
    input clk,
    input reset,
    //SD卡接口
    input sd_miso,
    output reg sd_cs,
    output reg sd_mosi,
    //写接口    
    input write_start,      
    input [31:0]write_addr,
    input [15:0]write_data,                      
    output reg write_busy, 
    output reg write_request
    );

parameter HEAD_BYTE = 8'hfe;//数据头
                 
reg write_enable_beat1;//write_start信号延时打拍
reg write_enable_beat2;   

reg res_enable;             //接收SD卡返回数据有效信号      
reg [7:0]res_data;      //接收SD卡返回数据                 
reg res_flag;           //开始接收返回数据的标志
reg [5:0]res_bit_cnt;   //接收位数据计数器                   
                                
reg [3:0]write_state_cnt;   //写控制计数器
reg [47:0]cmd_write;       //写命令
reg [5:0]cmd_bit_cnt;   //写命令位计数器
reg [3:0]data_bit_cnt;       //写数据位计数器,16
reg [8:0]data_cnt;      //写入数据数量,256
reg [15:0]reg_write_data;    //寄存写入的数据，防止发生改变
reg detect_done_flag;   //检测写空闲信号的标志
reg [7:0]detect_data;   //检测到的数据

wire pos_write_enable;//开始写SD卡数据信号的上升沿

assign pos_write_enable = (~write_enable_beat2) & write_enable_beat1;

//信号延时打拍
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        write_enable_beat1 <= 1'b0;
        write_enable_beat2 <= 1'b0;
    end    
    else 
    begin
        write_enable_beat1 <= write_start;
        write_enable_beat2 <= write_enable_beat1;
    end        
end 

//接收sd卡返回的响应数据,在clk的下降沿锁存数据
always @(negedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        res_enable <= 1'b0;
        res_data <= 8'd0;
        res_flag <= 1'b0;
        res_bit_cnt <= 6'd0;
    end    
    else 
    begin
        if(sd_miso == 1'b0 && res_flag == 1'b0) //sd_miso = 0 开始接收响应数据
        begin
            res_flag <= 1'b1;
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            res_enable <= 1'b0;
        end    
        else if(res_flag) 
        begin
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            if(res_bit_cnt == 6'd7) 
            begin
                res_flag <= 1'b0;
                res_bit_cnt <= 6'd0;
                res_enable <= 1'b1; 
            end                
        end  
        else
            res_enable <= 1'b0;       
    end
end 

//写完数据后检测SD卡是否空闲
always @(posedge clk or negedge reset) 
begin
    if(!reset)
        detect_data <= 8'd0;   
    else if(detect_done_flag)
        detect_data <= {detect_data[6:0],sd_miso};
    else
        detect_data <= 8'd0;    
end        

//SD卡写入数据
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1; 
        write_state_cnt <= 4'd0;
        write_busy <= 1'b0;
        cmd_write <= 48'd0;
        cmd_bit_cnt <= 6'd0;
        data_bit_cnt <= 4'd0;
        reg_write_data <= 16'd0;
        data_cnt <= 9'd0;
        write_request <= 1'b0;
        detect_done_flag <= 1'b0;
    end
    else 
    begin
        write_request <= 1'b0;
        case(write_state_cnt)
            4'd0 : //写空闲
            begin
                write_busy <= 1'b0;                          
                sd_cs <= 1'b1;                                 
                sd_mosi <= 1'b1;                               
                if(pos_write_enable) 
                begin                            
                    cmd_write <= {8'h58,write_addr,8'hff}; //写入单个命令块CMD24
                    write_state_cnt <= write_state_cnt + 4'd1; //控制计数器加1
                    write_busy <= 1'b1;//开始执行写入数据,拉高写忙信号                      
                end                                            
            end   
            4'd1 : 
            begin
                if(cmd_bit_cnt <= 6'd47) //开始按位发送写命令
                begin              
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= cmd_write[6'd47 - cmd_bit_cnt]; //先发送高字节                 
                end    
                else 
                begin
                    sd_mosi <= 1'b1;
                    if(res_enable) //SD卡响应 
                    begin                        
                        write_state_cnt <= write_state_cnt + 4'd1; //控制计数器加1 
                        cmd_bit_cnt <= 6'd0;
                        data_bit_cnt <= 4'd1;
                    end    
                end     
            end                                                                                                     
            4'd2 : 
            begin                                       
                data_bit_cnt <= data_bit_cnt + 4'd1;     
                //data_bit_cnt = 0~7 等待8个时钟周期
                //data_bit_cnt = 8~15,写入命令头8'hfe        
                if(data_bit_cnt>=4'd8 && data_bit_cnt <= 4'd15) 
                begin
                    sd_mosi <= HEAD_BYTE[4'd15-data_bit_cnt]; //先发送高字节
                    if(data_bit_cnt == 4'd14)                       
                        write_request <= 1'b1; //提前拉高写数据请求信号
                    else if(data_bit_cnt == 4'd15)                  
                        write_state_cnt <= write_state_cnt + 4'd1; //控制计数器加1   
                end                                            
            end                                                
            4'd3 : //写入数据
            begin                                    
                data_bit_cnt <= data_bit_cnt + 4'd1; //bit_cnt归零                    
                if(data_bit_cnt == 4'd0) 
                begin                      
                    sd_mosi <= write_data[4'd15-data_bit_cnt]; //先发送数据高位     
                    reg_write_data <= write_data; //寄存数据   
                end                                            
                else                                           
                    sd_mosi <= reg_write_data[4'd15-data_bit_cnt]; //先发送数据高位
                if((data_bit_cnt == 4'd14) && (data_cnt <= 9'd255)) 
                    write_request <= 1'b1;                          
                if(data_bit_cnt == 4'd15) 
                begin                     
                    data_cnt <= data_cnt + 9'd1;                        
                    if(data_cnt == 9'd255) //写入单个BLOCK共512个字节 = 256 * 16bit
                    begin
                        data_cnt <= 9'd0;                                            
                        write_state_cnt <= write_state_cnt + 4'd1;      
                    end                                        
                end                                            
            end                                             
            4'd4 : //写入两个字节的8'hff进行CRC校验 
            begin                                       
                data_bit_cnt <= data_bit_cnt + 4'd1;                  
                sd_mosi <= 1'b1;                            
                if(data_bit_cnt == 4'd15)                            
                    write_state_cnt <= write_state_cnt + 4'd1;            
            end                                                
            4'd5 : 
            begin                                    
                if(res_enable) //SD卡响应                                    
                    write_state_cnt <= write_state_cnt + 4'd1;         
            end                                                
            4'd6 : //等待写完成
            begin                                               
                detect_done_flag <= 1'b1;                               
                if(detect_data == 8'hff) //detect_data = 8'hff时,SD卡写入完成,进入空闲状态
                begin              
                    write_state_cnt <= write_state_cnt + 4'd1;         
                    detect_done_flag <= 1'b0;                  
                end         
            end    
            default : 
            begin
                sd_cs <= 1'b1; //进入空闲状态后,拉高片选信号,等待8个时钟周期  
                write_state_cnt <= write_state_cnt + 4'd1;
            end     
        endcase
    end
end            

endmodule