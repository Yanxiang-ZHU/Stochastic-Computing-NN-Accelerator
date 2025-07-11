`timescale 1ns / 1ps

module comparison #(  
    parameter DATA_WIDTH = 32,  
    parameter NUM_VALUES = 10  
)(  
    input wire clk,  
    input wire rst_n,  
    input wire en_cmp,  
    input wire [DATA_WIDTH*NUM_VALUES-1:0] input_cmp,  
    output reg [3:0] output_cmp,  // 4 bits to represent 0-9  
    output reg flag_cmp  
);  
  
reg [3:0] max_index;    // Internal registers to hold the maximum index  
wire [DATA_WIDTH-1:0] inputs [NUM_VALUES-1:0];  

localparam precision = 32;
reg [31:0] cmp_a;
reg [31:0] cmp_b;
wire [31:0] bigger;

integer j;

float_max #(
    .precision(precision)
)(
    .a(cmp_a),
    .b(cmp_b),
    .c(bigger)
);

// Generate block to assign inputs  
genvar i;  
generate  
    for (i = 0; i < NUM_VALUES; i = i + 1) 
    begin  
        assign inputs[i] = input_cmp[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];  
    end  
endgenerate  
  
always @(posedge clk or negedge rst_n) begin  
    if (!rst_n || !en_cmp) 
    begin  
        max_index <= 4'd0;  
        flag_cmp <= 1'b0;  
        j <= 0;
    end 

    else 
    begin  
        if (j == 0)
        begin
            max_index <= 4'd0;  
        end

        else if (j < NUM_VALUES)
        begin
            cmp_a <= inputs[j];
            cmp_b <= inputs[max_index];
            if (bigger == cmp_a)
            begin
                max_index <= j;
            end
            j <= j + 1;
        end

        else if (j == 10)
        begin
            output_cmp <= max_index;
            flag_cmp <= 1'b1;  
        end
    end  
end  
  
endmodule
