`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/04 15:28:52
// Design Name: 
// Module Name: test_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_sim;
    reg pin;
    reg clk;
    reg rst_n;
    wire [3:0] result;

    reg [9:0] counter = 0; // 计数器
    reg [13:0] delay_counter;  //循环体中的参数
    reg [4:0] cnt_n;

    test_top top(
        .pin  (pin),
        .clk    (clk),
        .rst_n  (rst_n),
        .result (result)
    );

    parameter  send_data = 784'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111000000000000000000000111111110000000000000000000111111111000000000000000000011100001110000000000000000001100000110000000000000000000000000111000000000000000000000000011100000000000000000000000011100000000000000000000000011110000000000000000000000011110000000000000000000000001110000000000000000000000001111000000000000000000000000111000000000000000000000000111100000000000000000000000111100000000000000000000000011100000000000000000000000001110000000000011110000000000111111111111111111000000000011111111111111110000000000000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    always #(20/2) clk <= ~clk; 

    initial
    begin
        clk = 0;
        rst_n = 0;
        #100
        rst_n = 1;
    end

    always @ (posedge clk) 
    begin
        if (!rst_n) 
        begin
            counter = 0;
            delay_counter = 0;
            pin = 1;
            cnt_n = 0;
        end 

        else if (delay_counter < 5208 -1)
        begin
            delay_counter <= delay_counter + 1;
        end 

        else if (delay_counter == 5208 -1)
        begin
            if (cnt_n == 0)
            begin 
                pin = 0;    //初始位的一个时钟周期的低电平
                delay_counter = 0;
                cnt_n = 1;
            end
            else if ((cnt_n !=0)&&(cnt_n!=9))
            begin
                pin = send_data[counter];     //实际的运行逻辑是每个字符顺序传入，而每个字符内部是LSB-->MSB的形式填充数据位（与sim代码中的形式不同）
                if (counter < 783)
                    counter = counter + 1;
                delay_counter = 0;
                cnt_n = cnt_n + 1;
            end
            else if(cnt_n == 9)
            begin
                pin = 1;    //终止位一个时钟周期的高电平
                delay_counter = 0;
                cnt_n = 0;
            end
        end
    end

endmodule
