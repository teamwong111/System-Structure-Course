module imem(
    input [31:0] imem_pc_in,//pc�ź�
    output [31:0] imem_inst_out//ָ��
    );
    reg [31:0] ins[0:1023];//ָ��Ĵ���ģ��
    
    initial 
    begin
        $readmemh("D:/cputest/1.hex.txt", ins);
    end
    assign imem_inst_out = ins[imem_pc_in >>> 2];
    
endmodule
