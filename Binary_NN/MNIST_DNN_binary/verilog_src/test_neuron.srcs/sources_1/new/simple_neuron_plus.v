`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/11 17:12:04
// Design Name: 
// Module Name: simple_neuron_plus
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


module simple_neuron_plus(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [783:0] in_neuron,
    input wire [783:0] kernel,
    input wire [9:0] bias,
    output reg out_neuron,
    output reg flag
    );

    integer state;
    reg [9:0] sum_one;
    reg [2:0] level;
    reg [783:0] in_neuron_t;

    always @(posedge clk or negedge rst_n)
    if (!rst_n || !en)
    begin
        state <= 0;
        out_neuron <= 0;
        flag <= 0;
        sum_one <= 0;
        level <= 0;
    end
    else
    begin
        if (level == 0)      //transform the input 
        begin
            in_neuron_t = in_neuron ^ kernel;
            level = 1;
        end
        else if (level == 1)    //counting numbers of 1
        begin
            if (state < 784)
            begin
                if (in_neuron_t[state] == 1)
                    sum_one <= sum_one + 1;
                state <= state + 1;
            end
            else 
            begin
                state <= 0;
                level <= 2;
            end
        end
        else if (level == 2 ) //comparing with bias
        begin
            if (sum_one > bias)
                out_neuron = 1;
            else out_neuron = 0;
            flag = 1;
        end
    end



endmodule
