`timescale 1ns / 1ps

module addfloat(
    input clk,
    // input a_tvalid,
    input [31:0] a_tdata,
    // input b_tvalid,
    input [31:0] b_tdata,
    input operation_tvalid,
    // input [7:0] operation_tdata,
    output result_tvalid,
    output [31:0] result_tdata
    );

add_float add_float_u(
    .aclk(clk),
    .s_axis_a_tvalid(1),
    .s_axis_a_tdata(a_tdata),
    .s_axis_b_tvalid(1),
    .s_axis_b_tdata(b_tdata),
    .s_axis_operation_tvalid(operation_tvalid),
    .s_axis_operation_tdata(8'b00000000),
    .m_axis_result_tvalid(result_tvalid),
    .m_axis_result_tdata(result_tdata)
);

endmodule