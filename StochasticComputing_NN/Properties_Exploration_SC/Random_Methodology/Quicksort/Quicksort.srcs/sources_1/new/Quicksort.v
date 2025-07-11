`timescale 1ns / 1ps

module Quicksort(
    input clk,
    input rst_n,
    input [783:0] Vector,
    output reg out
);

    reg tempVector;
    reg [783:0] bitVector;
    integer pivot, i, j;

    task quickSort;
        input integer left, right;
        integer i, j;
        reg pivot;
        begin
            i = left;
            j = right;
            pivot = bitVector[i]; 
            
            while (i < j) begin
                while (bitVector[i] <= pivot && i < j) i = i + 1;
                while (bitVector[j] >= pivot && i < j) j = j - 1;
                bitVector[j] = bitVector[i];
            end

            bitVector[i] = pivot;

            if (left < i - 1)
                quickSort(left, i - 1);

            if (i + 1 < right)
                quickSort(i + 1, right);
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bitVector = 0;
        end

        else begin
            bitVector = Vector;
            quickSort(0, 783);
            out = bitVector[391]; 
        end
    end

endmodule
