`timescale 1ns / 1ps
module data_gen(
    input clk,
    input reset,
    input init_done,//SD����ʼ������ź�
    //дSD���ӿ�
    input write_busy,//д����æ�ź�
    input write_request,//д���������ź�
    output reg write_start,//��ʼдSD�������ź�
    output reg [31:0]write_addr,//д����������ַ
    output [15:0]write_data,//д����
    //��SD���ӿ�
    input read_enable,//��������Ч�ź�
    input [15:0]read_data,//������
    output reg read_start,//��ʼ��SD�������ź�
    output reg [31:0]read_addr,//������������ַ
    output read_error,//SD����д����ı�־
    
    output reg [8:0]ram_addr
    );

reg init_done_beat1;//init_done�ź���ʱ����
reg init_done_beat2;       
reg write_busy_beat1;//write_busy�ź���ʱ����
reg write_busy_beat2;
reg [15:0]reg_write_data;    
reg [15:0]comp_read_data;//���ڶԶ����������Ƚϵ���ȷ����
reg [8:0]right_read_cnt;//������ȷ���ݵĸ���

wire pos_init_done;//init_done�źŵ�������,��������д���ź�
wire neg_write_busy;//write_busy�źŵ��½���,�����ж�����д�����

assign pos_init_done = (~init_done_beat2) & init_done_beat1;

assign neg_write_busy = write_busy_beat2 & (~write_busy_beat1);

assign write_data = reg_write_data;

assign read_error = (right_read_cnt == (9'd256)) ? 1'b0 : 1'b1;//��128����ȷ������,˵����д���Գɹ�,read_error = 0

reg [15:0] ins[0:1023];//ָ��Ĵ���ģ��
reg [15:0]ins_cnt;
initial 
begin
    $readmemh("F:/Download/2.hex.txt", ins);
end

//�ź���ʱ����
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

//SD��д���źſ���
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
            write_addr <= 32'd20;//ָ��������ַ 2000
        end    
        else
            write_start <= 1'b0;
    end    
end 

//SD��д����
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

//SD�������źſ���
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

//�����ݴ���ʱ������־
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