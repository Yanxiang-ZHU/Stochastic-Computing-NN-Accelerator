`timescale 1ns / 1ps

module activation_relu(clk, reset, en, input_fc, output_fc, flag);

    // parameter initialization
    parameter DATA_WIDTH = 32;   
    parameter OUTPUT_NODES = 64*64;

    // define the signals
    input clk, reset, en;                        
    input [DATA_WIDTH*OUTPUT_NODES-1:0] input_fc;
    output reg [DATA_WIDTH*OUTPUT_NODES-1:0] output_fc;
    output reg flag;

    integer i; 

    always @ (posedge clk or negedge reset) begin
        if (!reset || !en) 
        begin
            output_fc <= 0;
            flag <= 0;
        end 

        else 
        begin
            if (en == 1'b1) 
            begin
                for (i = 0; i < OUTPUT_NODES; i = i + 1)    // this for loop may take too many hardware sources
                begin   
                    if (input_fc[DATA_WIDTH*i + DATA_WIDTH - 1] == 1'b1) // negetive
                    begin
                        output_fc[DATA_WIDTH*i +: DATA_WIDTH] = 0;
                    end 

                    else      // positive
                    begin
                        output_fc[DATA_WIDTH*i +: DATA_WIDTH] = input_fc[DATA_WIDTH*i +: DATA_WIDTH];
                    end
                end
                flag <= 1;
            end
        end
    end

endmodule
