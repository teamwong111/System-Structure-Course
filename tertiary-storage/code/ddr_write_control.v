`timescale 1ns / 1ps
module ddr2_write_control(
    input clk,
    input reset, 
    input [26:0] write_addr,
    input [127:0] write_data,
    input write_stb,
    output reg write_ack,
    output reg read_enable,
    //ddr2 signals
    input app_rdy, 
    input app_wdf_rdy,
    output reg app_en, 
    output reg app_wdf_wren, 
    output reg app_wdf_end,
    output reg [2:0] app_cmd,
    output reg [26:0] app_addr,
    output reg [127:0] app_wdf_data
    );

    parameter idle = 2'b01;
    parameter write = 2'b10;

    reg [1:0] state;
    reg [3:0] write_count;

    always @(posedge clk)
    begin
        if(reset) 
        begin
            write_ack <= 0;
            read_enable <= 0;
            
            app_en <= 1'b0;
            app_wdf_wren <= 1'b0;
            app_wdf_end <= 1'b0;
            app_cmd <= 3'b1;
            app_addr <= 27'h0;
            app_wdf_data <= 128'h0;
            
            write_count <= 0;
            state <= idle;
        end
        else if(write_stb) 
        begin
            if(state==idle)
            begin
                if(app_rdy & app_wdf_rdy) 
                begin
                    write_ack <= 0;

                    app_en <= 1'b1;
                    app_wdf_wren <= 1'b1; 
                    app_wdf_end <= 1'b1;
                    app_cmd <= 3'b0;
                    app_addr <= write_addr;
                    app_wdf_data <= write_data;
                                            
                    write_count <= write_count + 1;
                    state <= write;
                end
                else 
                begin
                    state <= idle; 
                end
            end
            else if(state==write)
            begin
                write_ack <= 1;
                if(write_count == 3)
                begin
                    read_enable <= 1;
                end
                app_en <= 1'b0;                    
                app_wdf_wren <= 1'b0;
                app_wdf_end <= 0;
                app_cmd <= 3'b1;
                
                state <= idle;
            end
            else
            begin
                state <= idle;
            end
        end
        else 
        begin
            write_ack <= 0;
            app_en <= 0;
            app_wdf_wren <= 0;
            app_wdf_end <= 0;

            state <= idle;
        end
    end
endmodule