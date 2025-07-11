module maj #(
    parameter LAYER = 1,
    parameter BATCH_SIZE = 2,
    parameter SEQ_LENGTH = 128,
    parameter MAX_MID_NEURONS = 81,
    parameter INPUT_WIDTH = 27,
    parameter INPUT_HEIGHT = 27 
)(
    input wire [SEQ_LENGTH-1:0] input_data [0: BATCH_SIZE-1][0: MAX_MID_NEURONS-1][0:INPUT_WIDTH*INPUT_HEIGHT-1],
    output reg [SEQ_LENGTH-1:0] output_data [0: BATCH_SIZE-1][0:INPUT_WIDTH*INPUT_HEIGHT-1],
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output reg valid_out
);

integer i, b;

integer input_size1, input_size2;
integer output_size1, output_size2;

// Maximum Size
reg [SEQ_LENGTH-1:0] reshape_input [0: BATCH_SIZE-1][0: MAX_MID_NEURONS-1][0:INPUT_WIDTH*INPUT_HEIGHT-1];
reg [SEQ_LENGTH-1:0] reshape_output [0: BATCH_SIZE-1][0: MAX_MID_NEURONS*3-1][0:INPUT_WIDTH*INPUT_HEIGHT/3-1];
reg [SEQ_LENGTH-1:0] maj_buffer [0: BATCH_SIZE-1][0: MAX_MID_NEURONS*3-1][0:INPUT_WIDTH*INPUT_HEIGHT/3-1];
reg [SEQ_LENGTH-1:0] maj_buffer_out [0: BATCH_SIZE-1][0: MAX_MID_NEURONS*3-1][0:INPUT_WIDTH*INPUT_HEIGHT/3-1];

reshape_3d #(
    .BATCH(BATCH_SIZE),
    .SEQ_LENGTH(SEQ_LENGTH),
    .MAX_MID_NEURONS(MAX_MID_NEURONS),
    .INPUT_WIDTH(INPUT_WIDTH),
    .INPUT_HEIGHT(INPUT_HEIGHT)
) reshape_inst (
    .clk(clk),
    .rst(rst_n),
    .input1(input_size1),
    .input2(input_size2),
    .output1(output_size1),
    .output2(output_size2),
    .input_data(reshape_input),
    .output_data(reshape_output)
);

function [SEQ_LENGTH-1:0] majority3;
    input [SEQ_LENGTH-1:0] a, b, c;
    begin
        majority3 = (a & b) | (a & c) | (b & c);
    end
endfunction

typedef enum logic [1:0] {
    IDLE,
    RESHAPE,
    MAJ_PROCESS,
    DONE
} state_t;
state_t state_reg, state_next;

reg [15:0] b_cnt;
reg [15:0] group_cnt;
reg [3:0] layer_cnt;
reg [9:0] loop_size;
reg [3:0] layers;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg <= IDLE;
        state_next <= IDLE;
        valid_out <= 0;
        b_cnt <= 0;
        group_cnt <= 0;
        layer_cnt <= 0;
    end else begin
        state_reg <= state_next;
        
        case (state_reg)
            IDLE: begin
                if (valid_in) begin
                    valid_out <= 0;
                    state_next <= RESHAPE;
                    b_cnt <= 0;
                    group_cnt <= 0;
                    layer_cnt <= 0;
                end
            end
            
            RESHAPE: begin
                case (LAYER)
                    1: begin // LAYER1: 81x729 -> 243x243
                        input_size1 <= 81;
                        input_size2 <= 729;
                        output_size1 <= 243;
                        output_size2 <= 243;
                        reshape_input <= input_data;
                    end
                    2: ;
                    3: ;
                endcase
                state_next <= MAJ_PROCESS;
            end
            
            MAJ_PROCESS: begin
                maj_buffer <= reshape_output;
                case (LAYER)
                    1: begin loop_size <= 243; layers <= 5; end
                    2: begin loop_size <= 27;  layers <= 5; end
                    3: begin loop_size <= 10;  layers <= 3; end
                endcase
                for (b_cnt = 0; b_cnt < BATCH_SIZE; b_cnt = b_cnt + 1) begin
                    for (group_cnt = 0; group_cnt < loop_size; group_cnt = group_cnt + 1) begin
                        for (layer_cnt = 0; layer_cnt < layers; layer_cnt = layer_cnt + 1) begin
                            for (i = 0; i < 3**layers; i = i + 3) begin
                                maj_buffer_out[b_cnt][group_cnt][i/3] <= majority3(
                                    maj_buffer[b_cnt][group_cnt][i * 3],
                                    maj_buffer[b_cnt][group_cnt][i * 3 + 1],
                                    maj_buffer[b_cnt][group_cnt][i * 3 + 2]
                                );
                            end
                            maj_buffer <= maj_buffer_out;
                        end
                    end
                end
            end
            
            DONE: begin
                valid_out <= 1;
                state_next <= IDLE;
            end
        endcase
    end
end

endmodule


module reshape_3d #(
    parameter BATCH    = 1,
    parameter SEQ_LENGTH   = 128,
    parameter MAX_MID_NEURONS = 81,
    parameter INPUT_WIDTH = 27,
    parameter INPUT_HEIGHT = 27
)(
    input  wire clk,
    input  wire rst,
    input  wire [9:0] input1,
    input  wire [9:0] input2,
    input  wire [9:0] output1,
    input  wire [9:0] output2,
    input  wire [SEQ_LENGTH-1:0] input_data [0:BATCH-1][0:MAX_MID_NEURONS-1][0:INPUT_WIDTH*INPUT_HEIGHT-1],
    output reg  [SEQ_LENGTH-1:0] output_data[0:BATCH-1][0:MAX_MID_NEURONS*3-1][0:INPUT_WIDTH*INPUT_HEIGHT/3-1]
);

    integer b, i1, i2;
    integer flat_index, o1, o2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // optional: reset output data
            for (b = 0; b < BATCH; b = b + 1)
                for (o1 = 0; o1 < output1; o1 = o1 + 1)
                    for (o2 = 0; o2 < output2; o2 = o2 + 1)
                        output_data[b][o1][o2] <= 0;
        end else begin
            for (b = 0; b < BATCH; b = b + 1) begin
                for (i1 = 0; i1 < input1; i1 = i1 + 1) begin
                    for (i2 = 0; i2 < input2; i2 = i2 + 1) begin
                        flat_index = i1 * input2 + i2;
                        o1 = flat_index / output2;
                        o2 = flat_index % output2;
                        output_data[b][o1][o2] <= input_data[b][i1][i2];
                    end
                end
            end
        end
    end

endmodule
