`timescale 1ns / 1ps
module ddr2_read_control(
    input clk,
    input reset,
    input enable,
    //ddr2 signals    
    input app_rdy,
    output reg app_en,
    output reg [2:0] app_cmd
    );

    parameter idle = 2'b01;
    parameter read = 2'b10;

    reg [1:0] state;

    always @(posedge clk)
    begin
        if(reset) 
        begin
            app_en <= 0;
            app_cmd <= 0;
            state <= idle;
        end
        else if(enable) 
        begin
            if(state==idle)
            begin
                app_en <= 1;
                app_cmd <= 3'b001;
                state <= read;
            end
            else if(state==read)
            begin
                if(app_rdy) 
                begin
                    app_en <= 0;
                    state <= idle;
                end
            end
            else
            begin
                state <= idle;
            end
        end 
        else 
        begin
            app_en <= 0;
            app_cmd <= 0;
            state <= idle;
        end 
    end

endmodule