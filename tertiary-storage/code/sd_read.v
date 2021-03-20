`timescale 1ns / 1ps
module sd_read(
    input clk,
    input reset, 

    input sd_miso,
    output reg sd_cs,
    output reg sd_mosi,
    
    input read_start,
    input [31:0]read_addr,                      
    output reg read_busy,
    output reg read_enable, 
    output reg [15:0]read_data, 
    
    output reg read_finish
    );

reg read_beat1;    
reg read_beat2;

reg res_enable;        
reg [7:0]res_data;                  
reg res_flag;                 
reg [5:0]res_bit_cnt;                 
                             
reg get_en_t;          
reg [15:0]get_data_t;          
reg get_flag;            
reg [3:0]get_bit_cnt;          
reg [8:0]get_data_cnt;            
reg get_finish_en;           
                             
reg [3:0]rd_ctrl_cnt;    
reg [47:0]read_cmd;   
reg [5:0]cmd_bit_cnt;     
reg rd_data_flag;  

wire pos_rd_en;    

assign  pos_rd_en = (~read_beat2) & read_beat1;

//信号延时打拍
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        read_beat1 <= 1'b0;
        read_beat2 <= 1'b0;
    end    
    else 
    begin
        read_beat1 <= read_start;
        read_beat2 <= read_beat1;
    end        
end  

//接收sd卡返回的响应数据,在sd_clk的上升沿锁存数据
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
        //sd_miso = 0 开始接收响应数据
        if(sd_miso == 1'b0 && res_flag == 1'b0) 
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

//接收SD卡有效数据在sd_clk的上升沿锁存数据
always @(negedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        get_en_t <= 1'b0;
        get_data_t <= 16'd0;
        get_flag <= 1'b0;
        get_bit_cnt <= 4'd0;
        get_data_cnt <= 9'd0;
        get_finish_en <= 1'b0;
    end    
    else 
    begin
        get_en_t <= 1'b0; 
        get_finish_en <= 1'b0;
        if(rd_data_flag && sd_miso == 1'b0 && get_flag == 1'b0)//数据头0xfe 8'b1111_1110，所以检测0为起始位    
            get_flag <= 1'b1;   
        else if(get_flag) 
        begin
            get_bit_cnt <= get_bit_cnt + 4'd1;
            get_data_t <= {get_data_t[14:0],sd_miso};
            if(get_bit_cnt == 4'd15) 
            begin 
                get_data_cnt <= get_data_cnt + 9'd1;
                
                if(get_data_cnt <= 9'd255) //接收单个BLOCK共512个字节 = 256 * 16bit                        
                    get_en_t <= 1'b1;  
                else if(get_data_cnt == 9'd257) 
                begin   //接收两个字节的CRC校验值
                    get_flag <= 1'b0;
                    get_finish_en <= 1'b1;//数据接收完成              
                    get_data_cnt <= 9'd0;               
                    get_bit_cnt <= 4'd0;
                end    
            end                
        end       
        else
            get_data_t <= 16'd0;
    end    
end    

//寄存输出数据有效信号和数据
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        read_enable <= 1'b0;
        read_data <= 16'd0;
    end
    else 
    begin
        if(get_en_t) 
        begin
            read_enable <= 1'b1;
            read_data <= get_data_t;
        end    
        else
            read_enable <= 1'b0;
    end
end              

//读命令
always @(posedge clk or negedge reset) 
begin
    if(!reset) 
    begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1;        
        rd_ctrl_cnt <= 4'd0;
        read_cmd <= 48'd0;
        cmd_bit_cnt <= 6'd0;
        read_busy <= 1'b0;
        rd_data_flag <= 1'b0;
        
        read_finish <= 1'b0;
    end   
    else 
    begin
        case(rd_ctrl_cnt)
            4'd0 : 
            begin
                read_busy <= 1'b0;
                sd_cs <= 1'b1;
                sd_mosi <= 1'b1;
                if(pos_rd_en) 
                begin
                    read_cmd <= {8'h51,read_addr,8'hff}; 
                    rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;      
                    read_busy <= 1'b1;                      
                end    
            end
            4'd1 : 
            begin
                if(cmd_bit_cnt <= 6'd47) 
                begin             
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= read_cmd[6'd47 - cmd_bit_cnt]; 
                end    
                else 
                begin                                  
                    sd_mosi <= 1'b1;
                    if(res_enable) 
                    begin                        
                        rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1; 
                        cmd_bit_cnt <= 6'd0;
                    end    
                end    
            end    
            4'd2 : 
            begin         
                rd_data_flag <= 1'b1;                       
                if(get_finish_en) 
                begin                     
                    rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1; 
                    rd_data_flag <= 1'b0;
                    sd_cs <= 1'b1;
                    
                    read_finish <= 1'b1;
                end
            end        
            default : 
            begin      
                sd_cs <= 1'b1;
                rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;
            end    
        endcase
    end         
end

endmodule