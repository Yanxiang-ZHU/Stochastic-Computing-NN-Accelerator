`timescale 1ns / 1ps

module subfloat(
    input clk,
    input a_tvalid,
    input a_tdata,
    input b_tvalid,
    input b_tdata,
    input result_ready,

    output reg a_tready,
    output reg b_tready,
    output reg result_valid,
    output reg result_data
    );

sub_float u1_sub_float(
    .aclk(clk),
    .s_axis_a_tvalid(a_tvalid),
    .s_axis_a_tready(a_tready),
    .s_axis_a_tdata(a_tdata),
    .s_axis_b_tvalid(b_tvalid),
    .s_axis_b_tready(b_tready),
    .s_axis_b_tdata(b_tdata),
    .m_axis_result_tvalid(result_valid),
    .m_axis_result_tready(result_ready),
    .m_axis_result_tdata(result_data)
);

endmodule
