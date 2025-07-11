`timescale 1ns / 1ps

module float_max #(
    localparam precision = 32
) (
    input  [31 : 0] a,
    input  [31 : 0] b,
    output [31 : 0] c
);
    wire            a_flag  = a[31];
    wire   [7 : 0]  a_floor = a[30 : 23];
    wire   [22 : 0] a_tail  = a[22 : 0];
    wire            b_flag  = b[31];
    wire   [7 : 0]  b_floor = b[30 : 23];
    wire   [22 : 0] b_tail  = b[22 : 0];
    
    wire            a_e_b = ~(| (a[31 : 0] ^ b[31 : 0]));
    wire            a_flag_l_b_flag = (~a_flag) & b_flag;
    wire            a_flag_e_b_flag = ~(a_flag ^ b_flag);
    wire            a_floor_g_b_floor = a_floor > b_floor ? 1 : 0;
    wire            a_floor_l_b_floor = a_floor < b_floor ? 1 : 0;
    wire            a_floor_e_b_floor = ~(| (a_floor[7 : 0] ^ b_floor[7 : 0]));
    wire            a_tail_g_b_tail = a_tail > b_tail ? 1 : 0;
    wire            a_tail_l_b_tail = a_tail < b_tail ? 1 : 0;
    
    wire            condition1 = a_e_b;
    wire            condition3 = ~a_e_b & a_flag_l_b_flag;
    wire            condition4 = ~a_e_b & a_flag_e_b_flag & (~a_flag) & a_floor_g_b_floor;
    wire            condition6 = ~a_e_b & a_flag_e_b_flag & (~a_flag) & a_floor_e_b_floor & a_tail_g_b_tail;                         
    wire            condition9 = ~a_e_b & a_flag_e_b_flag & (a_flag) & a_floor_l_b_floor;                           
    wire            condition11= ~a_e_b & a_flag_e_b_flag & (a_flag) & a_floor_e_b_floor & a_tail_l_b_tail;         
    
    assign c = (condition1 | condition3 | condition4 | condition6 | condition9 | condition11) ? a : b;
endmodule

