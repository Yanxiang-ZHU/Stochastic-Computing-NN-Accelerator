`timescale 1ns / 1ps

module Countones_MG(
    input wire clk,
    input wire rst_n,
    input wire [783:0] vector,
    output reg out
    );

    reg [261:0] MG_1;   // 261个MG3结果及1个轮空 = 262
    // reg [87:0] MG_2;    // 87个MG3结果及1个轮空
    // reg [29:0] MG_3;    // 29个MG3结果及1个轮空
    // reg [9:0] MG_4;     // 10个MG3结果
    // reg [4:0] MG_5;     // 3个MG3结果及1个轮空
    // reg []
    integer i;
    integer count;
    reg a;
    reg b;
    reg c;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // MG_1 = 0;
            count = 0;
            i = 0;

        end else begin
            for (i = 0; i < 261; i = i + 1) begin
                a = vector[3*i];
                b = vector[3*i+1];
                c = vector[3*i+2];
                MG_1[i] = (a & b) | (a & c) | (b & c);
            end
            MG_1[261] = vector[783];

            for (i = 0; i < 87; i = i + 1) begin
                a = MG_1[3*i];
                b = MG_1[3*i+1];
                c = MG_1[3*i+2];
                count = count + (a & b) | (a & c) | (b & c);
            end
            count = count + MG_1[261];
            out = count > 88/2;
        end
    end

endmodule
