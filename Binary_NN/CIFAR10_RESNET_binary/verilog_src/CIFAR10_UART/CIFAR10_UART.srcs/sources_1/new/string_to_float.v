`timescale 1ns / 1ps
module string_to_float(
    input rx_valid,
    input [7:0] part_fn,
    output reg [31:0] one_fn,
    output reg num_done
);

// 中间信号定义
reg sign;
reg [7:0] exponent;
reg [22:0] mantissa;
reg is_zero_input;
reg [7:0] input_value;
integer highest_bit_pos = -1;
integer i;

always @(*) begin
    sign = 1'b0;
    exponent = 8'd0;
    mantissa = 23'd0;
    is_zero_input = 1'b1;
    num_done = 1'b0;
    one_fn = 32'd0;

    if (rx_valid) begin
        if (part_fn == 8'd0) begin
            is_zero_input = 1'b1;
        end else begin
            is_zero_input = 1'b0;
            input_value <= part_fn;
            for (i = 7; i >= 0; i = i - 1) begin
                if ((input_value >> i) & 1'b1) begin
                    highest_bit_pos = i;
                end
            end
            if (highest_bit_pos >= 0) begin
                exponent = highest_bit_pos + 8'd127;
                mantissa = input_value << (23 - highest_bit_pos);
            end
        end
    end
end

always @(*) begin
    if (is_zero_input) begin
        one_fn = 32'd0;
    end
    else begin
        one_fn = {sign, exponent, mantissa};
    end
    num_done = ~is_zero_input & rx_valid;
end

endmodule