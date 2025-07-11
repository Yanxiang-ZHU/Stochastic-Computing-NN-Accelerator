`timescale 1ns / 1ps

module DNN_tb;
    
    parameter LENTH = 256;  // the sequence length is adjustable 
    reg clk;
    reg rst_n;
    reg [LENTH-1:0] input_val [0:49];
    wire [3:0] output_val;
    wire flag;

    integer input_file, result_file, i, j;
    reg [LENTH-1:0] temp_data;
    
    // Instantiate the DNN_FPGA module
    DNN  #(
        .LENTH(LENTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .input_val(input_val),
        .output_val(output_val),
        .flag(flag)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        #10 rst_n = 1;
        
        // Open input and output files
        input_file = $fopen("input_val_s.txt", "r");
        result_file = $fopen("result.txt", "w");
        
        if (input_file == 0 || result_file == 0) begin
            $display("Error: Failed to open file.");
            $finish;
        end
        
        // Read input values and process
        for (j = 0; j < 2000; j = j + 1) begin
            for (i = 0; i < 50; i = i + 1) begin
                if (!$feof(input_file)) begin
                    $fscanf(input_file, "%b\n", temp_data);
                    input_val[i] = temp_data;
                end
            end
            
            // Wait for processing
            #20;
            wait(flag == 1);
            
            // Write output to file when flag is high
            $fwrite(result_file, "%d\n", output_val);
        end
        
        // Close files
        $fclose(input_file);
        $fclose(result_file);
        
        $finish;
    end

endmodule
