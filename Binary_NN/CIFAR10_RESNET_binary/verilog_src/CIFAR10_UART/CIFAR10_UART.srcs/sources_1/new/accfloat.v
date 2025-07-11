`timescale 1ns / 1ps

module accfloat(
    input clk,
    input a_tvalid,
    input [31:0] a_tdata,
    output a_tready,
    input a_tlast,
    output acc_result_tvalid,
    input acc_result_tready,
    output [31:0] acc_result_tdata,
    output   acc_result_tlast
);

acc_float acc_float_1(
    .aclk(clk),
    .s_axis_a_tvalid(a_tvalid),
    .s_axis_a_tready(a_tready),  // ready to input, before valid pin go up
    .s_axis_a_tdata(a_tdata),
    .s_axis_a_tlast(a_tlast),
    .m_axis_result_tvalid(acc_result_tvalid),  // when tvalid and tready are both high, read the output data
    .m_axis_result_tready(acc_result_tready),
    .m_axis_result_tdata(acc_result_tdata),
    .m_axis_result_tlast(acc_result_tlast)
);

endmodule