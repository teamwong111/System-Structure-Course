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

parameter CMD0  = {8'h40,8'h00,8'h00,8'h00,8'h00,8'h95};//SD�������λ����

parameter CMD8  = {8'h48,8'h00,8'h00,8'h01,8'haa,8'h87};//�������豸�ĵ�ѹ��Χ

parameter CMD55 = {8'h77,8'h00,8'h00,8'h00,8'h00,8'hff};//����SD����������������Ӧ���������

parameter ACMD41 = {8'h69,8'h40,8'h00,8'h00,8'h00,8'hff};//���Ͳ����Ĵ���(OCR)����

parameter div_num = 400;//ʱ�ӷ�Ƶϵ��,��ʼ��SD��ʱ����SD����ʱ��Ƶ��,50M/250K = 200 

parameter wait_num = 200;//�ϵ����ٵȴ�74��ͬ��ʱ������,�ڵȴ��ϵ��ȶ��ڼ�,sd_cs = 1,sd_mosi = 1

parameter over_num = 25000;//���������λ����ʱ�ȴ�SD�����ص����ʱ��,T = 100ms; 100_000us/4us = 25000
                        
parameter to_wait = 7'b000_0001;        //Ĭ��״̬,�ϵ�ȴ�SD���ȶ�
parameter send_cmd0 = 7'b000_0010;   //���������λ����
parameter wait_cmd0 = 7'b000_0100;   //�ȴ�SD����Ӧ
parameter send_cmd8 = 7'b000_1000;   //�������豸�ĵ�ѹ��Χ�����SD���Ƿ�����
parameter send_cmd55 = 7'b001_0000;  //����SD����������������Ӧ���������
parameter send_acmd41 = 7'b010_0000; //���Ͳ����Ĵ���(OCR)����
parameter _init_done = 7'b100_0000;   //SD����ʼ�����

reg [7:0]now_state;
reg [7:0]next_state;                            
reg [7:0]div_cnt;           //��Ƶ������
reg div_clk;                //��Ƶ���ʱ��         
reg [12:0]wait_cnt;      //�ϵ�ȴ��ȶ�������

reg res_enable;                 //����SD������������Ч�ź�
reg [47:0]res_data;         //����SD����������
reg res_flag;               //��ʼ���շ������ݵı�־
reg [5:0]res_bit_cnt;       //����λ���ݼ�����
                                   
reg [5:0]cmd_bit_cnt;       //����ָ��λ������
reg [15:0]over_time_cnt;    //��ʱ������  
reg  over_time_enable;          //��ʱʹ���ź� 

assign sd_clk = ~div_clk;  //SD_CLK,��λ��DIV_CLK���180�ȵ�ʱ��

//ʱ�ӷ�Ƶ,div_clk = 250KHz
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

//�ϵ�ȴ��ȶ�������
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

//����sd�����ص���Ӧ����,��sd_clk����������������
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
        if(sd_miso == 1'b0 && res_flag == 1'b0) //sd_miso = 0 ��ʼ������Ӧ����
        begin 
            res_flag <= 1'b1;
            res_data <= {res_data[46:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            res_enable <= 1'b0;
        end    
        else if(res_flag) 
        begin
            res_data <= {res_data[46:0],sd_miso}; //R1����1���ֽ�,R3 R7����5���ֽ�,������ͳһ����6���ֽ�������,�����1���ֽ�ΪNOP(8��ʱ�����ڵ���ʱ)    
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

//״̬ת��
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
            if(res_enable) //SD��������Ӧ�ź�
            begin                         
                if(res_data[47:40] == 8'h01) //SD�����ظ�λ�ɹ�        
                    next_state = send_cmd8;
                else
                    next_state = to_wait;
            end
            else if(over_time_enable) //SD����Ӧ��ʱ                   
                next_state = to_wait;
            else
                next_state = wait_cmd0;                                    
        end    
        send_cmd8 :
        begin 
            if(res_enable) //SD��������Ӧ�ź�  
            begin                          
                if(res_data[19:16] == 4'b0001) //����SD���Ĳ�����ѹ,[19:16] = 4'b0001(2.7V~3.6V)      
                    next_state = send_cmd55;
                else
                    next_state = to_wait;
            end
            else
                next_state = send_cmd8;            
        end
       
        send_cmd55 :
        begin     
            if(res_enable) //SD��������Ӧ�ź� 
            begin                          
                if(res_data[47:40] == 8'h01) //SD�����ؿ���״̬        
                    next_state = send_acmd41;
                else
                    next_state = send_cmd55;    
            end        
            else
                next_state = send_cmd55;     
        end  
        send_acmd41 :
        begin                       
            if(res_enable) //SD��������Ӧ�ź�
            begin                           
                if(res_data[47:40] == 8'h00) //��ʼ������ź�        
                    next_state = _init_done;
                else
                    next_state = send_cmd55; //��ʼ��δ���,���·���      
            end
            else
                next_state = send_acmd41;     
        end                
        _init_done : next_state = _init_done; //��ʼ����� 
        default : next_state = to_wait;
    endcase
end

//SD����sd_clk���½����������,Ϊ��ͳһ��alway����ʹ�������ش���,�˴�ʹ�ú�sd_clk��λ���180�ȵ�ʱ��
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
            send_cmd0 : //����CMD0�����λ���� 
            begin                          
                cmd_bit_cnt <= cmd_bit_cnt + 6'd1;        
                sd_cs <= 1'b0;                            
                sd_mosi <= CMD0[6'd47 - cmd_bit_cnt];//�ȷ���CMD0�����λ
                if(cmd_bit_cnt == 6'd47)                  
                    cmd_bit_cnt <= 6'd0;                  
            end                                         
            wait_cmd0 : //�ڽ���CMD0��Ӧ�����ڼ�,ƬѡCS����,����SPIģʽ
            begin                          
                sd_mosi <= 1'b1; //SD��������Ӧ�ź�            
                if(res_enable) //�������֮��������,����SPIģʽ                               
                    sd_cs <= 1'b1;                                      
                over_time_cnt <= over_time_cnt + 1'b1; //��ʱ��������ʼ����
                if(over_time_cnt == over_num - 1'b1) //SD����Ӧ��ʱ,���·��������λ����
                    over_time_enable <= 1'b1; 
                if(over_time_enable)
                    over_time_cnt <= 16'd0;                                        
            end                                           
            send_cmd8 : //����CMD8
            begin                          
                if(cmd_bit_cnt<=6'd47) 
                begin
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= CMD8[6'd47 - cmd_bit_cnt]; //�ȷ���CMD8�����λ       
                end
                else 
                begin
                    sd_mosi <= 1'b1;
                    if(res_enable) //SD��������Ӧ�ź�
                    begin                      
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0; 
                    end   
                end                                                                   
            end 
            send_cmd55 : //����CMD55
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
                    if(res_enable) //SD��������Ӧ�ź�
                    begin                      
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0;     
                    end        
                end                                                                                    
            end
            send_acmd41 : //����ACMD41
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
                    if(res_enable) //SD��������Ӧ�ź�
                    begin                      
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0;  
                    end        
                end     
            end
            _init_done : //��ʼ�����
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