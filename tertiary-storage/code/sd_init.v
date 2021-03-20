`timescale 1ns / 1ps
module sd_init(
    input clk,
    input reset,
    input sd_miso,
    output sd_clk,
    output reg sd_cs,
    output reg sd_mosi,
    output reg init_done
    );

parameter CMD0  = {8'h40,8'h00,8'h00,8'h00,8'h00,8'h95};//SD卡软件复位命令

parameter CMD8  = {8'h48,8'h00,8'h00,8'h01,8'haa,8'h87};//发送主设备的电压范围

parameter CMD55 = {8'h77,8'h00,8'h00,8'h00,8'h00,8'hff};//告诉SD卡接下来的命令是应用相关命令

parameter ACMD41 = {8'h69,8'h40,8'h00,8'h00,8'h00,8'hff};//发送操作寄存器(OCR)内容

parameter div_num = 400;//时钟分频系数,初始化SD卡时降低SD卡的时钟频率,50M/250K = 200 

parameter wait_num = 200;//上电至少等待74个同步时钟周期,在等待上电稳定期间,sd_cs = 1,sd_mosi = 1

parameter over_num = 25000;//发送软件复位命令时等待SD卡返回的最大时间,T = 100ms; 100_000us/4us = 25000
                        
parameter to_wait = 7'b000_0001;        //默认状态,上电等待SD卡稳定
parameter send_cmd0 = 7'b000_0010;   //发送软件复位命令
parameter wait_cmd0 = 7'b000_0100;   //等待SD卡响应
parameter send_cmd8 = 7'b000_1000;   //发送主设备的电压范围，检测SD卡是否满足
parameter send_cmd55 = 7'b001_0000;  //告诉SD卡接下来的命令是应用相关命令
parameter send_acmd41 = 7'b010_0000; //发送操作寄存器(OCR)内容
parameter _init_done = 7'b100_0000;   //SD卡初始化完成

reg [7:0]now_state;
reg [7:0]next_state;                            
reg [7:0]div_cnt;           //分频计数器
reg div_clk;                //分频后的时钟         
reg [12:0]wait_cnt;      //上电等待稳定计数器

reg res_enable;                 //接收SD卡返回数据有效信号
reg [47:0]res_data;         //接收SD卡返回数据
reg res_flag;               //开始接收返回数据的标志
reg [5:0]res_bit_cnt;       //接收位数据计数器
                                   
reg [5:0]cmd_bit_cnt;       //发送指令位计数器
reg [15:0]over_time_cnt;    //超时计数器  
reg  over_time_enable;          //超时使能信号 

assign sd_clk = ~div_clk;  //SD_CLK,相位和DIV_CLK相差180度的时钟

//时钟分频,div_clk = 250KHz
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        div_clk <= 1'b0;
        div_cnt <= 8'd0;
    end
    else 
    begin
        if(div_cnt == div_num/2-1'b1) 
        begin
            div_clk <= ~div_clk;
            div_cnt <= 8'd0;
        end
        else    
            div_cnt <= div_cnt + 1'b1;
    end        
end

//上电等待稳定计数器
always @(posedge div_clk or negedge reset) 
begin
    if(!reset) 
        wait_cnt <= 13'd0;
    else if(now_state == to_wait) 
    begin
        if(wait_cnt < wait_num)
            wait_cnt <= wait_cnt + 1'b1;                   
    end
    else
        wait_cnt <= 13'd0;    
end    

//接收sd卡返回的响应数据,在sd_clk的上升沿锁存数据
always @(posedge sd_clk or negedge reset) 
begin
    if(!reset) 
    begin
        res_enable <= 1'b0;
        res_data <= 48'd0;
        res_flag <= 1'b0;
        res_bit_cnt <= 6'd0;
    end    
    else 
    begin
        if(sd_miso == 1'b0 && res_flag == 1'b0) //sd_miso = 0 开始接收响应数据
        begin 
            res_flag <= 1'b1;
            res_data <= {res_data[46:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            res_enable <= 1'b0;
        end    
        else if(res_flag) 
        begin
            res_data <= {res_data[46:0],sd_miso}; //R1返回1个字节,R3 R7返回5个字节,在这里统一按照6个字节来接收,多出的1个字节为NOP(8个时钟周期的延时)    
            res_bit_cnt <= res_bit_cnt + 6'd1;
            if(res_bit_cnt == 6'd47) 
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

//状态转移
always @(posedge div_clk or negedge reset) 
begin
    if(!reset)
        now_state <= to_wait;
    else
        now_state <= next_state;
end

//
always @(*) 
begin
    next_state = to_wait;
    case(now_state)
        to_wait :
        begin
            if(wait_cnt == wait_num)
                next_state = send_cmd0;
            else
                next_state = to_wait;
        end 
        send_cmd0 :
        begin                         
            if(cmd_bit_cnt == 6'd47)
                next_state = wait_cmd0;
            else
                next_state = send_cmd0;    
        end               
        wait_cmd0 :
        begin                         
            if(res_enable) //SD卡返回响应信号
            begin                         
                if(res_data[47:40] == 8'h01) //SD卡返回复位成功        
                    next_state = send_cmd8;
                else
                    next_state = to_wait;
            end
            else if(over_time_enable) //SD卡响应超时                   
                next_state = to_wait;
            else
                next_state = wait_cmd0;                                    
        end    
        send_cmd8 :
        begin 
            if(res_enable) //SD卡返回响应信号  
            begin                          
                if(res_data[19:16] == 4'b0001) //返回SD卡的操作电压,[19:16] = 4'b0001(2.7V~3.6V)      
                    next_state = send_cmd55;
                else
                    next_state = to_wait;
            end
            else
                next_state = send_cmd8;            
        end
       
        send_cmd55 :
        begin     
            if(res_enable) //SD卡返回响应信号 
            begin                          
                if(res_data[47:40] == 8'h01) //SD卡返回空闲状态        
                    next_state = send_acmd41;
                else
                    next_state = send_cmd55;    
            end        
            else
                next_state = send_cmd55;     
        end  
        send_acmd41 :
        begin                       
            if(res_enable) //SD卡返回响应信号
            begin                           
                if(res_data[47:40] == 8'h00) //初始化完成信号        
                    next_state = _init_done;
                else
                    next_state = send_cmd55; //初始化未完成,重新发起      
            end
            else
                next_state = send_acmd41;     
        end                
        _init_done : next_state = _init_done; //初始化完成 
        default : next_state = to_wait;
    endcase
end

//SD卡在sd_clk的下降沿输出数据,为了统一在alway块中使用上升沿触发,此处使用和sd_clk相位相差180度的时钟
always @(posedge div_clk or negedge reset) 
begin
    if(!reset) 
    begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1;
        init_done <= 1'b0;
        cmd_bit_cnt <= 6'd0;
        over_time_cnt <= 16'd0;
        over_time_enable <= 1'b0;
    end
    else 
    begin
        over_time_enable <= 1'b0;
        case(now_state)
            to_wait :
            begin                               
                sd_cs <= 1'b1;                    
                sd_mosi <= 1'b1;                    
            end     
            send_cmd0 : //发送CMD0软件复位命令 
            begin                          
                cmd_bit_cnt <= cmd_bit_cnt + 6'd1;        
                sd_cs <= 1'b0;                            
                sd_mosi <= CMD0[6'd47 - cmd_bit_cnt];//先发送CMD0命令高位
                if(cmd_bit_cnt == 6'd47)                  
                    cmd_bit_cnt <= 6'd0;                  
            end                                         
            wait_cmd0 : //在接收CMD0响应返回期间,片选CS拉低,进入SPI模式
            begin                          
                sd_mosi <= 1'b1; //SD卡返回响应信号            
                if(res_enable) //接收完成之后再拉高,进入SPI模式                               
                    sd_cs <= 1'b1;                                      
                over_time_cnt <= over_time_cnt + 1'b1; //超时计数器开始计数
                if(over_time_cnt == over_num - 1'b1) //SD卡响应超时,重新发送软件复位命令
                    over_time_enable <= 1'b1; 
                if(over_time_enable)
                    over_time_cnt <= 16'd0;                                        
            end                                           
            send_cmd8 : //发送CMD8
            begin                          
                if(cmd_bit_cnt<=6'd47) 
                begin
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= CMD8[6'd47 - cmd_bit_cnt]; //先发送CMD8命令高位       
                end
                else 
                begin
                    sd_mosi <= 1'b1;
                    if(res_enable) //SD卡返回响应信号
                    begin                      
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0; 
                    end   
                end                                                                   
            end 
            send_cmd55 : //发送CMD55
            begin                         
                if(cmd_bit_cnt<=6'd47) 
                begin
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= CMD55[6'd47 - cmd_bit_cnt];       
                end
                else 
                begin
                    sd_mosi <= 1'b1;
                    if(res_enable) //SD卡返回响应信号
                    begin                      
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0;     
                    end        
                end                                                                                    
            end
            send_acmd41 : //发送ACMD41
            begin                        
                if(cmd_bit_cnt <= 6'd47) 
                begin
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= ACMD41[6'd47 - cmd_bit_cnt];      
                end
                else 
                begin
                    sd_mosi <= 1'b1;
                    if(res_enable) //SD卡返回响应信号
                    begin                      
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0;  
                    end        
                end     
            end
            _init_done : //初始化完成
            begin                         
                init_done <= 1'b1;
                sd_cs <= 1'b1;
                sd_mosi <= 1'b1;
            end
            default : 
            begin
                sd_cs <= 1'b1;
                sd_mosi <= 1'b1;                
            end    
        endcase
    end
end

endmodule