`timescale 1ns / 1ps

module hash(
    input wire clk,
    input wire rst_n,
    input wire [783:0] vector,
    output reg [9:0] count 
);

    reg [7:0] poptable [255:0];
    reg [9:0] temp_count;
    integer i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize poptable
            for (i = 0; i < 256; i = i + 1) begin
                poptable[i] = 0;
                for (j = 0; j < 8; j = j + 1) begin
                    poptable[i] = poptable[i] + ((i >> j) & 1);
                end
            end
            count <= 0;
        end else begin
            temp_count = 0;
            for (i = 0; i < 98; i = i + 1) begin
                temp_count = temp_count + poptable[vector[i*8 +: 8]];
            end
            count <= temp_count;
        end
    end

endmodule