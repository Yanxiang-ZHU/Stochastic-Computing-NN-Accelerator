//`timescale 1ns / 1ps

//module kernel_tb;
//    parameter LENTH = 128;
//    reg clk;
//    reg rst_n;
//    reg en;
//    reg [LENTH-1:0] weight [8:0];
//    reg [LENTH-1:0] input_val [8:0];
//    wire [LENTH-1:0] output_val;
//    wire flag;
    
//    integer i;

//    kernel #(
//        .LENTH(LENTH)
//    ) uut (
//        .clk(clk),
//        .rst_n(rst_n),
//        .en(en),
//        .weight(weight),
//        .input_val(input_val),
//        .output_val(output_val),
//        .flag(flag)
//    );

//    // Clock generation
//    initial begin
//        clk = 0;
//        forever #5 clk = ~clk; // 10ns clock period
//    end


//    // Testbench logic
//    initial begin
//        // Initialize signals
//        rst_n = 0;
//        en = 0;
        
//        // Generate random weights and inputs
//        for (i = 0; i < 9; i = i + 1) begin
//            weight[i] =  {$urandom, $urandom, $urandom, $urandom};
//            input_val[i] =  {$urandom, $urandom, $urandom, $urandom};
//        end

//        // Apply reset
//        #10;
//        rst_n = 1;
        
//        // Enable the kernel module
//        #10;
//        en = 1;

//        // Wait for computation to complete
//        wait(flag);

//        // Check results
//        #10;
//        $display("Output Value: %h", output_val);

//        // Finish simulation
//        #20;
//        $finish;
//    end

//endmodule

`timescale 1ns / 1ps

module kernel_tb;

    // Parameters
    parameter LENTH = 256;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg en;
    reg [LENTH-1:0] weight [8:0];
    reg [LENTH-1:0] input_val [8:0];
    wire [LENTH-1:0] output_val;
    wire flag;

    integer file_weight, file_input, file_output;
    integer i, j;
    reg [LENTH-1:0] temp_weight, temp_input;

    // Instantiate the DUT (Device Under Test)
    kernel #(
        .LENTH(LENTH)
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
    always #5 clk = ~clk;

    // Initial block for test
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        en = 0;
        for (i = 0; i < 9; i = i + 1) begin
            weight[i] = 0;
            input_val[i] = 0;
        end

        // Open files
        file_weight = $fopen("first_200_sequences.txt", "r");
        file_input = $fopen("last_200_sequences.txt", "r");
        file_output = $fopen("output_results.txt", "w");

        if (file_weight == 0 || file_input == 0 || file_output == 0) begin
            $display("Error opening input or output files.");
            $stop;
        end

        // Release reset
        #10;
        rst_n = 1;

        // Read and process data
        for (i = 0; i < 1000; i = i + 1) begin
            // Read 9 lines for weight and input_val
            for (j = 0; j < 9; j = j + 1) begin
                if (!$feof(file_weight)) begin
                    $fscanf(file_weight, "%b\n", temp_weight);
                    weight[j] = temp_weight;
                end
                if (!$feof(file_input)) begin
                    $fscanf(file_input, "%b\n", temp_input);
                    input_val[j] = temp_input;
                end
            end

            // Trigger the kernel
            en = 1;
            #20;
            en = 0;

            // Wait for output
            wait(flag == 1);

            // Write the output to the file
            $fwrite(file_output, "%b\n", output_val);
        end

        // Close files
        $fclose(file_weight);
        $fclose(file_input);
        $fclose(file_output);

        // End simulation
        $stop;
    end

endmodule

