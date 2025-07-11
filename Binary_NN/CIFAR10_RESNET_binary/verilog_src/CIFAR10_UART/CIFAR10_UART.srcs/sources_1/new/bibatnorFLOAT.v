`timescale 1ns / 1ps

module bibatnorFLOAT#(
    parameter IM_LENTH = 32,
    parameter IM_DEPTH = 16
)(
    input clk,
    input rst_n,
    input en,
    input [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] input_data,
    input [IM_DEPTH*32-1:0] thr,    // if the input_data in one layer is smaller than corresponding thr value, output will be 0, otherwise 1
    output reg [IM_LENTH*IM_LENTH*IM_DEPTH-1:0] output_data,
    output reg flag
    );

    localparam PRECISION = 32;

    reg [31:0] float_a;
    reg [31:0] float_b;
    wire [31:0] output_max;

    integer index;
    integer layer;

    float_max #(
        .precision  (PRECISION)
    )bibatnorFLOAT_floatmax(
        .a      (float_a),
        .b      (float_b),
        .c      (output_max)
    );

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        float_a <= 0;
        float_b <= 0;
        output_data <= 0;
        flag <= 0;
        index <= 0;     // be the index of input_data
        layer <= 0;     // be the index of thr
    end

    else
    begin
        if (index < IM_LENTH * IM_LENTH * IM_DEPTH)
        begin
            float_a <= input_data[index * 32 + 31 -: 32];
            float_b <= thr[layer*32 + 31 -: 32];
            output_data[index] =  (output_max == float_a) ? 1 : 0;      // realize the comparison function
            index <= index + 1;
            if (index % (IM_LENTH * IM_LENTH) == 0)
            begin
                layer <= layer + 1;
            end
        end

        else if (index == IM_LENTH * IM_LENTH * IM_DEPTH)
        begin
            index <= 0;
            layer <= 0;
            flag <= 1;
        end
    end
end


endmodule