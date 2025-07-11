`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/29 10:26:28
// Design Name: 
// Module Name: majority_gate3
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


module majority_gate3(
    input wire a,    // 第一个输入
    input wire b,    // 第二个输入
    input wire c,    // 第三个输入
    output wire y    // 输出
);

// 多数逻辑门的逻辑
assign y = (a & b) | (a & c) | (b & c);

endmodule
