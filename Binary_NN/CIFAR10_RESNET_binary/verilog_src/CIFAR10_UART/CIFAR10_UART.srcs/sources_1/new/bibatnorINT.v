`timescale 1ns / 1ps

module bibatnorINT#(
    parameter IM_LENTH = 32,
    parameter IM_DEPTH = 16
)(
    input clk,
    input rst_n,
    input en,
    input [IM_LENTH*IM_LENTH*IM_DEPTH*8-1:0] input_data,
    input [IM_DEPTH*8-1:0] thr,    // if the input_data in one layer is smaller than corresponding thr value, output will be 0, otherwise 1
    output reg [IM_LENTH*IM_LENTH*IM_DEPTH-1:0] output_data,
    output reg flag
    );

    integer index;
    integer layer;

    reg signed [7:0] input_data_slice;
    reg signed [7:0] thr_slice;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        flag <= 0;
        index <= 0;     // be the index of input_data
        layer <= 0;     // be the index of thr
    end

    else
    begin
        if (index < IM_LENTH * IM_LENTH * IM_DEPTH)
        begin
            input_data_slice <= input_data[index * 8 + 7 -: 8];
            thr_slice <= thr[layer*8 + 7 -: 8];
            output_data[index] =  (input_data_slice > thr_slice) ? 1 : 0;      // realize the comparison function
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
