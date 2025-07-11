`timescale 1ns / 1ps

module squarefloat(
    input clk,
    input a_tvalid,
    input [31:0] a_tdata,
    input result_ready,

    output reg a_tready,
    output reg result_tvalid,
    output reg [31:0] result_data
    );

square_float u1_square_float(
    .aclk(clk),
    .s_axis_a_tvalid(a_tvalid),
    .s_axis_a_tready(a_tready),
    .s_axis_a_tdata(a_tdata),
    .m_axis_result_tvalid(result_tvalid),
    .m_axis_result_tready(result_tready),
    .m_axis_result_tdata(result_tdata)
);
endmodule
