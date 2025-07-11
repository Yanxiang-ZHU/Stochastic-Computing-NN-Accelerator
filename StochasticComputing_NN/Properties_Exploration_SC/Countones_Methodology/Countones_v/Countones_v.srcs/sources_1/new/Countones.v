`timescale 1ns / 1ps

module CountOnes #(
    parameter BIT_WIDTH = 128,
    parameter NUM = 192
)(
    input [BIT_WIDTH-1:0] bitVector [0:NUM-1],
    input clk,
    input rst_n,
    output reg [BIT_WIDTH-1:0] numOnes
);

    integer i;
    reg [7:0] count;
    integer bit_count;
    reg [BIT_WIDTH-1:0] numOnes_reg;
    reg [NUM-1:0] rotated_Vector [0:BIT_WIDTH-1];
    integer ii, jj;

    initial
    begin
        for (ii = 0; ii < NUM; ii = ii + 1) begin 
            for (jj = 0; jj < BIT_WIDTH; jj = jj + 1) begin 
                rotated_Vector[jj][ii] = bitVector[ii][jj]; 
            end 
        end
    end

    // Counting the number of ones
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            numOnes <= 0;
            numOnes_reg <= 0;
            bit_count <= 0;
        end 
        
        else begin
            if (bit_count < BIT_WIDTH) begin
                count = 0;
                for (i = 0; i < NUM; i = i + 1) begin
                    if (rotated_Vector[bit_count][i]) begin
                        count = count + 1;
                    end
                end
                numOnes_reg[bit_count] <= (count >= NUM/2);
                bit_count <= bit_count + 1;
            end
            else begin
                numOnes = numOnes_reg;
                numOnes_reg <= 0;
                bit_count <= 0;
            end
        end
    end

endmodule
