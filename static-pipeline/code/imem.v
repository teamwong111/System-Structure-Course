module imem(
    input [31:0] imem_pc_in,//pcÐÅºÅ
    output [31:0] imem_inst_out//Ö¸Áî
    );
    reg [31:0] ins[0:1023];//Ö¸Áî¼Ä´æÆ÷Ä£¿é
    
    initial 
    begin
        $readmemh("D:/cputest/1.hex.txt", ins);
    end
    assign imem_inst_out = ins[imem_pc_in >>> 2];
    
endmodule
