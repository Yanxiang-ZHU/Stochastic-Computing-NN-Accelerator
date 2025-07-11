`timescale 1ns / 1ps

module inttofloat #(
    parameter IM_LENTH = 32,
    parameter IM_DEPTH = 16
)(
    input clk,
    input rst_n,
    input en,
    input [IM_LENTH*IM_LENTH*IM_DEPTH*8-1:0] input_data,
    output reg [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] output_data,
    output reg flag
);

localparam SIZE = IM_LENTH * IM_LENTH * IM_DEPTH;

// inner signals
reg [7:0] int_value;
reg [31:0] float_value;

integer i, j;

function [31:0] int_to_float;
    input [7:0] int_in;
    reg sign;
    reg [7:0] abs_value;
    reg [22:0] mantissa;
    reg [7:0] exponent;
    integer k;
begin
    sign = int_in[7];
    abs_value = sign ? -int_in : int_in;
    k = 7;
    while (k >= 0 && !abs_value[k]) k = k - 1;
    if (k == -1) begin
        exponent = 0;
        mantissa = 0;
    end else begin
        exponent = k + 127;
        mantissa = abs_value << (23 - k);
    end
    int_to_float = {sign, exponent, mantissa};
end
endfunction

// define the state machine here
reg [4:0] state;
localparam IDLE = 0, LOAD = 1, CONVERT = 2, STORE = 3, DONE = 4;

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        state <= IDLE;
        flag <= 0;
        i <= 0;
        j <= 0;
    end 
    
    else begin
        case (state)
            IDLE: 
            begin
                if (en) 
                begin
                    state <= LOAD;
                    i <= 0;
                    j <= 0;
                    flag <= 0;
                end
            end

            LOAD: 
            begin
                if (i < SIZE) 
                begin
                    int_value <= input_data[8*i+7 -: 8];
                    state <= CONVERT;
                end 
                else 
                begin
                    state <= DONE;
                end
            end

            CONVERT: 
            begin
                float_value <= int_to_float(int_value);
                state <= STORE;
            end

            STORE: 
            begin
                output_data[32*i+31 -: 32] <= float_value;
                i <= i + 1;
                state <= LOAD;
            end

            DONE: 
            begin
                flag <= 1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule