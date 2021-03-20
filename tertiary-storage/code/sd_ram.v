module sd_ram(
    input clk,
    input we,
    input [8:0]waddr,
    input [15:0]wdata,
    
    input [8:0]raddr,
    output [7:0]rdata
    );

    reg[7:0]reg_ram[0:511];
    
    assign rdata = reg_ram[raddr];
                    
    always @(posedge clk)
    begin
        if(we)
        begin
            reg_ram[waddr] <= wdata[15:8];
            reg_ram[waddr+1] <= wdata[7:0];
        end
    end

endmodule