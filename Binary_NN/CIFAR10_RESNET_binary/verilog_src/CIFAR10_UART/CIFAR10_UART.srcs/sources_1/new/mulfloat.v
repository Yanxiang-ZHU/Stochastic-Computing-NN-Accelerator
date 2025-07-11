`timescale 1ns / 1ps

module mulfloat(
    input clk,
    input a_tvalid,
    input [31:0] a_tdata,
    input b_tvalid,
    input [31:0] b_tdata,
    output mul_result_tvalid,
    output [31:0] mul_result_tdata
    );

mul_float u1_float_multiply(              
    .aclk(clk),
    .s_axis_a_tvalid(a_tvalid),
    .s_axis_a_tdata(a_tdata),
    .s_axis_b_tvalid(b_tvalid),
    .s_axis_b_tdata(b_tdata),
    .m_axis_result_tvalid(mul_result_tvalid),
    .m_axis_result_tdata(mul_result_tdata)
);

endmodule
