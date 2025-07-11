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
    input wire a,    // ��һ������
    input wire b,    // �ڶ�������
    input wire c,    // ����������
    input wire d,    // ���ĸ�����
    input wire e,    // ���������
    output wire y    // ���
);

// �����߼��ŵ��߼�
assign y = (a & b & c) | (a & b & d) | (a & b & e) | 
           (a & c & d) | (a & c & e) | (a & d & e) | 
           (b & c & d) | (b & c & e) | (b & d & e) | 
           (c & d & e);

endmodule
