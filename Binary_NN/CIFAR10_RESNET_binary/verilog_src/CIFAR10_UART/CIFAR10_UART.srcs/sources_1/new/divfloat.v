`timescale 1ns / 1ps

module divfloat(
    input clk,
    input a_tvalid,
    input [31:0] a_tdata,
    input b_tvalid,
    input [31:0] b_tdata,       // seem that here we don't need b_tdata to be a floating number?
    output div_result_tvalid,
    output [31:0] div_result_tdata
    );

div_float div_float_1(
    .aclk(clk),
    .s_axis_a_tvalid(a_tvalid),
    .s_axis_a_tdata(a_tdata),
    .s_axis_b_tvalid(b_tvalid),
    .s_axis_b_tdata(b_tdata),
    .m_axis_result_tvalid(div_result_tvalid),
    .m_axis_result_tdata(div_result_tdata)
);


endmodule
