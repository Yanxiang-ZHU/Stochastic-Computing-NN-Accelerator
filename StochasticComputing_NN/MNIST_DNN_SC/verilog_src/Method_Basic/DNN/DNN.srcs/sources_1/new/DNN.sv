`timescale 1ns / 1ps

module DNN #(
    parameter LENTH = 128
)(
    input wire clk,
    input wire rst_n,
    input wire [LENTH-1:0] input_val [0:49],
    output reg [3:0] output_val,
    output reg flag
);

localparam STATE_INIT = 2'b11, STATE_LAYER1 = 2'b00, STATE_LAYER2 = 2'b01, STATE_COMP = 2'b10;

reg [1:0] state;
reg [LENTH-1:0] weight1 [0:127][0:49];
reg [LENTH-1:0] weight2 [0:9][0:127];
reg [LENTH-1:0] layer1_out [0:127];
reg [LENTH-1:0] layer2_out [0:9];
reg [7:0] count1s [0:9];
reg [LENTH-1: 0] temp_data;
integer i, j, k;
integer bit_count;
integer max_index, max_value;
integer weight1_file, weight2_file;

initial begin
    weight1_file = $fopen("weight1.txt", "r");
    weight2_file = $fopen("weight2.txt", "r");
    for (j = 0; j < 128; j = j + 1) begin
        for (i = 0; i < 50; i = i + 1) begin
            if (!$feof(weight1_file)) begin
                $fscanf(weight1_file, "%b\n", temp_data);
                weight1[j][i] = temp_data;
            end
        end
    end
    for (j = 0; j < 10; j = j + 1) begin
        for (i = 0; i < 128; i = i + 1) begin
            if (!$feof(weight2_file)) begin
                $fscanf(weight2_file, "%b\n", temp_data);
                weight2[j][i] = temp_data;
            end
        end
    end
    state = STATE_INIT;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= STATE_INIT;
        flag <= 0;
        bit_count <= 0;
    end else begin
        case (state)
            STATE_INIT: begin
                state <= STATE_LAYER1;
            end
            
            STATE_LAYER1: begin
                flag <= 0;
                for (i = 0; i < 128; i = i + 1) begin
                    for (k = 0; k < LENTH; k = k + 1) begin
                        bit_count = 0;
                        for (j = 0; j < 50; j = j + 1) begin
                            bit_count = bit_count + ^(~(input_val[j][k] ^ weight1[i][j][k]));
                        end
                        layer1_out[i][k] = (bit_count > 25) ? {LENTH{1'b1}} : {LENTH{1'b0}};
                    end
                end
                state <= STATE_LAYER2;
            end
            
            STATE_LAYER2: begin
                for (i = 0; i < 10; i = i + 1) begin
                    for (k = 0; k < LENTH; k = k + 1) begin
                        bit_count = 0;
                        for (j = 0; j < 128; j = j + 1) begin
                            bit_count = bit_count + ^(~(layer1_out[j][k] ^ weight2[i][j][k]));
                        end
                        layer2_out[i][k] = (bit_count >= 64) ? {LENTH{1'b1}} : {LENTH{1'b0}};
                    end
                end
                state <= STATE_COMP;
            end
            
            STATE_COMP: begin
                max_value = 0;
                max_index = 0;
                for (i = 0; i < 10; i = i + 1) begin
                    bit_count = 0;
                    for (j = 0; j < LENTH; j = j + 1) begin
                        bit_count = bit_count + layer2_out[i][j];
                    end
                    count1s[i] = bit_count;
                    if (bit_count > max_value) begin
                        max_value = bit_count;
                        max_index = i;
                    end
                end
                output_val = max_index;
                flag = 1;
                state <= STATE_LAYER1;
            end
        endcase
    end
end

endmodule
