`timescale 1ns / 1ps

module sobol_random_tb;
    // Parameters
    parameter SAMPLES = 128;
    parameter SET_INDEX = 1000;

    // Inputs
    reg clk;
    reg rst_n;
    reg valid;
    reg [31:0] comp;

    // Outputs
    wire [SAMPLES-1:0] result;

    // Instantiate the Unit Under Test (UUT)
    sobol_random #(
        .SAMPLES(SAMPLES),
        .SET_INDEX(SET_INDEX)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .comp(comp),
        .result(result)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end

    // Testbench logic
    initial begin
        // Initialize Inputs
        rst_n = 0;
        valid = 0;
        comp = 32'b10000000000000000000000000000000; 

        // Wait for global reset to finish
        #100;
        rst_n = 1;
        valid = 1;

        // Wait and then disable valid
        #20000;
        valid = 0;

        // Finish simulation
        #2000;
        $stop;
    end

    // Monitor the result
    initial begin
        $monitor("At time %t, result = %b", $time, result);
    end

endmodule
