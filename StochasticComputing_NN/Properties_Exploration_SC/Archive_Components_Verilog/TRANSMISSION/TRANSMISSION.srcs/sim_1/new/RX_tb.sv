`timescale 1ns / 1ps

module RX_tb;
    reg clk;
    reg rst_n;
    reg rx_pin;
    wire [255:0] rx_data [0:783];
    wire flag;

    parameter CLOCK_PERIOD = 20;
    parameter BAUD = 9600;
    parameter BIT_PERIOD = 50000000 / BAUD; // in ns

    RX #(
        .LENTH(256),
        .SIZE(784),
        .BAUD(BAUD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_pin(rx_pin),
        .rx_data(rx_data),
        .flag(flag)
    );

    always #(CLOCK_PERIOD / 2) clk = ~clk;

    task send_byte(input [7:0] data);
        integer i;
        begin
            rx_pin = 0;
            #(CLOCK_PERIOD * BIT_PERIOD); // Start bit
            
            for (i = 0; i < 8; i = i + 1) begin
                rx_pin = data[i];
                #(CLOCK_PERIOD * BIT_PERIOD);
            end
            
            rx_pin = 1; // Stop bit
            #(CLOCK_PERIOD * BIT_PERIOD);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        rx_pin = 1;
        #(CLOCK_PERIOD * 10);
        rst_n = 1;
        
        #(CLOCK_PERIOD * 100);

        send_byte(8'h3C);
        send_byte(8'hA5);
        
        send_byte(8'h7F);
        send_byte(8'h3C);

        send_byte(8'h3C);
        send_byte(8'hA5);
        
        send_byte(8'h7F);
        send_byte(8'h3C);

        #(CLOCK_PERIOD * 1000);
        $stop;
    end
endmodule
