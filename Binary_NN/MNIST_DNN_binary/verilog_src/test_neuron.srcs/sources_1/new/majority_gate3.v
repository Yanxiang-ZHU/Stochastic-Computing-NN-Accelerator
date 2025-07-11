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
    input wire a,    // ��һ������
    input wire b,    // �ڶ�������
    input wire c,    // ����������
    output wire y    // ���
);

// �����߼��ŵ��߼�
assign y = (a & b) | (a & c) | (b & c);

endmodule
