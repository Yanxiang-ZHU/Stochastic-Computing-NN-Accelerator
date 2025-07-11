`timescale 1ns / 1ps

module fc_tb;
    parameter LENTH = 128;
    parameter NUM = 49;
    reg clk;
    reg rst_n;
    reg en;
    reg [LENTH-1:0] weight [NUM-1:0];
    reg [LENTH-1:0] input_val [NUM-1:0];
    wire [LENTH-1:0] output_val;
    wire flag;
    
    integer i;

    fc #(
        .LENTH(LENTH),
        .NUM(NUM)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .weight(weight),
        .input_val(input_val),
        .output_val(output_val),
        .flag(flag)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end


    // Testbench logic
    initial begin
        // Initialize signals
        rst_n = 0;
        en = 0;
        
        // Generate random weights and inputs
        for (i = 0; i < NUM; i = i + 1) begin
            weight[i] = $random;
            input_val[i] = $random;
        end

        // Apply reset
        #10;
        rst_n = 1;
        
        // Enable the kernel module
        #10;
        en = 1;

        // Wait for computation to complete
        wait(flag);

        // Check results
        #10;
        $display("Output Value: %h", output_val);

        // Finish simulation
        #20;
        $finish;
    end

endmodule
