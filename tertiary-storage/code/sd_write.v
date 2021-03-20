`timescale 1ns / 1ps
module sd_write(
    input clk,
    input reset,
    //SD���ӿ�
    input sd_miso,
    output reg sd_cs,
    output reg sd_mosi,
    //д�ӿ�    
    input write_start,      
    input [31:0]write_addr,
    input [15:0]write_data,                      
    output reg write_busy, 
    output reg write_request
    );

parameter HEAD_BYTE = 8'hfe;//����ͷ
                 
reg write_enable_beat1;//write_start�ź���ʱ����
reg write_enable_beat2;   

reg res_enable;             //����SD������������Ч�ź�      
reg [7:0]res_data;      //����SD����������                 
reg res_flag;           //��ʼ���շ������ݵı�־
reg [5:0]res_bit_cnt;   //����λ���ݼ�����                   
                                
reg [3:0]write_state_cnt;   //д���Ƽ�����
reg [47:0]cmd_write;       //д����
reg [5:0]cmd_bit_cnt;   //д����λ������
reg [3:0]data_bit_cnt;       //д����λ������,16
reg [8:0]data_cnt;      //д����������,256
reg [15:0]reg_write_data;    //�Ĵ�д������ݣ���ֹ�����ı�
reg detect_done_flag;   //���д�����źŵı�־
reg [7:0]detect_data;   //��⵽������

wire pos_write_enable;//��ʼдSD�������źŵ�������

assign pos_write_enable = (~write_enable_beat2) & write_enable_beat1;

//�ź���ʱ����
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

//����sd�����ص���Ӧ����,��clk���½�����������
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
        if(sd_miso == 1'b0 && res_flag == 1'b0) //sd_miso = 0 ��ʼ������Ӧ����
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

//д�����ݺ���SD���Ƿ����
always @(posedge clk or negedge reset) 
begin
    if(!reset)
        detect_data <= 8'd0;   
    else if(detect_done_flag)
        detect_data <= {detect_data[6:0],sd_miso};
    else
        detect_data <= 8'd0;    
end        

//SD��д������
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
            4'd0 : //д����
            begin
                write_busy <= 1'b0;                          
                sd_cs <= 1'b1;                                 
                sd_mosi <= 1'b1;                               
                if(pos_write_enable) 
                begin                            
                    cmd_write <= {8'h58,write_addr,8'hff}; //д�뵥�������CMD24
                    write_state_cnt <= write_state_cnt + 4'd1; //���Ƽ�������1
                    write_busy <= 1'b1;//��ʼִ��д������,����дæ�ź�                      
                end                                            
            end   
            4'd1 : 
            begin
                if(cmd_bit_cnt <= 6'd47) //��ʼ��λ����д����
                begin              
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= cmd_write[6'd47 - cmd_bit_cnt]; //�ȷ��͸��ֽ�                 
                end    
                else 
                begin
                    sd_mosi <= 1'b1;
                    if(res_enable) //SD����Ӧ 
                    begin                        
                        write_state_cnt <= write_state_cnt + 4'd1; //���Ƽ�������1 
                        cmd_bit_cnt <= 6'd0;
                        data_bit_cnt <= 4'd1;
                    end    
                end     
            end                                                                                                     
            4'd2 : 
            begin                                       
                data_bit_cnt <= data_bit_cnt + 4'd1;     
                //data_bit_cnt = 0~7 �ȴ�8��ʱ������
                //data_bit_cnt = 8~15,д������ͷ8'hfe        
                if(data_bit_cnt>=4'd8 && data_bit_cnt <= 4'd15) 
                begin
                    sd_mosi <= HEAD_BYTE[4'd15-data_bit_cnt]; //�ȷ��͸��ֽ�
                    if(data_bit_cnt == 4'd14)                       
                        write_request <= 1'b1; //��ǰ����д���������ź�
                    else if(data_bit_cnt == 4'd15)                  
                        write_state_cnt <= write_state_cnt + 4'd1; //���Ƽ�������1   
                end                                            
            end                                                
            4'd3 : //д������
            begin                                    
                data_bit_cnt <= data_bit_cnt + 4'd1; //bit_cnt����                    
                if(data_bit_cnt == 4'd0) 
                begin                      
                    sd_mosi <= write_data[4'd15-data_bit_cnt]; //�ȷ������ݸ�λ     
                    reg_write_data <= write_data; //�Ĵ�����   
                end                                            
                else                                           
                    sd_mosi <= reg_write_data[4'd15-data_bit_cnt]; //�ȷ������ݸ�λ
                if((data_bit_cnt == 4'd14) && (data_cnt <= 9'd255)) 
                    write_request <= 1'b1;                          
                if(data_bit_cnt == 4'd15) 
                begin                     
                    data_cnt <= data_cnt + 9'd1;                        
                    if(data_cnt == 9'd255) //д�뵥��BLOCK��512���ֽ� = 256 * 16bit
                    begin
                        data_cnt <= 9'd0;                                            
                        write_state_cnt <= write_state_cnt + 4'd1;      
                    end                                        
                end                                            
            end                                             
            4'd4 : //д�������ֽڵ�8'hff����CRCУ�� 
            begin                                       
                data_bit_cnt <= data_bit_cnt + 4'd1;                  
                sd_mosi <= 1'b1;                            
                if(data_bit_cnt == 4'd15)                            
                    write_state_cnt <= write_state_cnt + 4'd1;            
            end                                                
            4'd5 : 
            begin                                    
                if(res_enable) //SD����Ӧ                                    
                    write_state_cnt <= write_state_cnt + 4'd1;         
            end                                                
            4'd6 : //�ȴ�д���
            begin                                               
                detect_done_flag <= 1'b1;                               
                if(detect_data == 8'hff) //detect_data = 8'hffʱ,SD��д�����,�������״̬
                begin              
                    write_state_cnt <= write_state_cnt + 4'd1;         
                    detect_done_flag <= 1'b0;                  
                end         
            end    
            default : 
            begin
                sd_cs <= 1'b1; //�������״̬��,����Ƭѡ�ź�,�ȴ�8��ʱ������  
                write_state_cnt <= write_state_cnt + 4'd1;
            end     
        endcase
    end
end            

endmodule