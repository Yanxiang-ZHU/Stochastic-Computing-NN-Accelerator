`timescale 1ns / 1ps

module CountOnes (
    input logic [127:0] bitVector,
    input logic clk,
    input logic rst_n,
    output reg [6:0] numOnes
);

    // Counting the number of ones
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            numOnes <= 0;
        end else begin
            numOnes <= $countones(bitVector);
        end
    end

endmodule
