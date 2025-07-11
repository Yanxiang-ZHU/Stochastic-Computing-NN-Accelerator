`timescale 1ns / 1ps

module adder_192(
    input   wire    clk,
    input   wire    en_adder,
    input   wire    [191:0] inp,
    output  reg     [7:0]   sum,
    output  reg     flag_adder
    );

    reg [7:0] i;
    reg [7:0] sum_tmp;

    always @(posedge clk) begin
        if (!en_adder)
        begin
            sum_tmp <= 0;
            i <= 0;
            flag_adder <= 0;
        end

        else
        begin
            if(i < 192) begin
                sum_tmp <= sum_tmp + inp[i];
                i = i+1;
            end
            else if (i == 192) begin
                sum <= sum_tmp;
                flag_adder <= 1;
            end
        end
    end

endmodule


