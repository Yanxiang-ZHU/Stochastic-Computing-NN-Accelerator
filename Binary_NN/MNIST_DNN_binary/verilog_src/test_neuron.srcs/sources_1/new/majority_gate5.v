`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/29 10:27:47
// Design Name: 
// Module Name: majority_gate5
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


module majority_gate5(
    input wire a,    // 第一个输入
    input wire b,    // 第二个输入
    input wire c,    // 第三个输入
    input wire d,    // 第四个输入
    input wire e,    // 第五个输入
    output wire y    // 输出
);

// 多数逻辑门的逻辑
assign y = (a & b & c) | (a & b & d) | (a & b & e) | 
           (a & c & d) | (a & c & e) | (a & d & e) | 
           (b & c & d) | (b & c & e) | (b & d & e) | 
           (c & d & e);

endmodule
