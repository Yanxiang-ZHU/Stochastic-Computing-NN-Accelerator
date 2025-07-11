`timescale 1ns / 1ps

module hash_tb;

    // Inputs
    reg clk;
    reg rst_n;
    reg [783:0] vector;

    // Outputs
    wire [9:0] count;

    // Instantiate the Unit Under Test (UUT)
    hash uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .vector(vector), 
        .count(count)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Stimulus
    initial begin
        // Initialize Inputs
        rst_n = 0;
        vector = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Deassert reset
        rst_n = 1;

        // Apply test vector
        vector = 784'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        
        // Wait for a few clock cycles
        #50;
        
        // Apply another test vector
        vector = 784'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        
        // Wait for a few clock cycles
        #50;

        // Apply a mixed test vector
        vector = 784'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
        
        // Wait for a few clock cycles
        #50;

        // Finish the simulation
        $stop;
    end

endmodule