`timescale 1ns / 1ps

module DNN #(
    parameter INPUT_WIDTH = 27,
    parameter INPUT_HEIGHT = 27,
    parameter SEQ_LENGTH = 128,
    parameter BATCH_SIZE = 2,
    parameter DNN_LAYER_NUM = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [SEQ_LENGTH-1:0] input_data [0:BATCH_SIZE-1][0:INPUT_WIDTH*INPUT_HEIGHT-1],
    output reg [3:0] output_data [0: BATCH_SIZE-1],
    output reg output_valid
    );

    localparam MAX_MID_NEURONS = 81;
    // Internal Signals
    reg [SEQ_LENGTH-1:0] output_fc [0: DNN_LAYER_NUM-1][0: BATCH_SIZE-1][0: MAX_MID_NEURONS-1][0:INPUT_WIDTH*INPUT_HEIGHT-1];
    reg [SEQ_LENGTH-1:0] output_maj [0: DNN_LAYER_NUM-1][0: BATCH_SIZE-1][0:INPUT_WIDTH*INPUT_HEIGHT-1];
    wire output_valid_fc [0: DNN_LAYER_NUM-1];
    wire output_valid_maj [0: DNN_LAYER_NUM-1];
    reg [6:0] decimal_output [0: BATCH_SIZE-1][0: 9]; // should be adjusted based on the SEQ_LENGTH: log2(SEQ_LENGTH) bits per output

    // State Machine
    typedef enum logic [2:0] {
        IDLE,
        LAYER1,
        LAYER2,
        LAYER3,
        OUTPUT
    } state_t;
    state_t current_state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state; // Default to stay in the current state
        case (current_state)
            IDLE: next_state = LAYER1;
            LAYER1: if (output_valid_maj[0]) next_state = LAYER2;
            LAYER2: if (output_valid_maj[1]) next_state = LAYER3;
            LAYER3: if (output_valid_maj[2]) next_state = OUTPUT;
            OUTPUT: if (output_valid) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    // end of State Machine

    // Instantiation
    genvar i;
    generate for(i=0; i<DNN_LAYER_NUM; i++) begin:inst
        fc_layer #(
            .LAYER(i+1),
            .SEQ_LENGTH(SEQ_LENGTH),
            .BATCH_SIZE(BATCH_SIZE),
            .MAX_MID_NEURONS(MAX_MID_NEURONS),
            .INPUT_WIDTH(INPUT_WIDTH),
            .INPUT_HEIGHT(INPUT_HEIGHT)
        ) fc_layer_u (
            .input_data(if (i == 0) input_data else output_maj[i-1]),
            .output_data(output_fc[i]),
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(current_state == (i + 1)),
            .valid_out(output_valid_fc[i])
        );

        maj #(
            .LAYER(i+1),
            .BATCH_SIZE(BATCH_SIZE),
            .SEQ_LENGTH(SEQ_LENGTH),
            .MAX_MID_NEURONS(MAX_MID_NEURONS),
            .INPUT_WIDTH(INPUT_WIDTH),
            .INPUT_HEIGHT(INPUT_HEIGHT)
        ) maj_u (
            .input_data(output_fc[i]),
            .output_data(output_maj[i]),
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(current_state == (i + 1) && output_valid_fc[i]),
            .valid_out(output_valid_maj[i])
        );
    end
    endgenerate
    // end of Instantiation

    // DNN Analysis Logic
    integer count_batch;
    integer count_seq;
    integer count_channel;
    integer max_decimal_output;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
//            output_data <= 4'b1111; // unvalid output
            output_valid <= 0;
//            output_layer <= '0;     // reset three output layers
//            output_maj <= '0;       // reset majority gate outputs
//            output_fc <= '0;        // reset fully connected layer outputs
//            output_valid_fc <= '0;  // reset valid signals for fully connected layers
//            output_valid_maj <= '0; // reset valid signals for majority gates
        end else begin
            case (current_state)
                IDLE: begin
//                    output_data <= 4'b1111;
                    output_valid <= 0;
                end
                LAYER1: begin
                    // layer1: fully_connected_layer+majority_gate(27*27->27*3)
                end
                LAYER2: begin
                    // layer2: fully_connected_layer+majority_gate(27*3->27)
                end
                LAYER3: begin
                    // layer3: fully_connected_layer+majority_gate(27->10)
                end
                OUTPUT: begin
                    // comparsion
                    for (count_batch = 0; count_batch < BATCH_SIZE; count_batch = count_batch + 1) begin
                        output_data[count_batch] = 4'b0000; // reset output data
                        for (count_channel = 0; count_channel < 10; count_channel = count_channel + 1) begin
                            decimal_output[count_batch][count_channel] = '0; // reset digital output
                            for (count_seq = 0; count_seq < SEQ_LENGTH; count_seq = count_seq + 1) begin
                                decimal_output[count_batch][count_channel] = decimal_output[count_batch][count_channel] + output_maj[DNN_LAYER_NUM-1][count_batch][count_channel][count_seq];
                            end
                        end
                        // find the max value
                        output_data[count_batch] = 4'b0000; // reset output data
                        max_decimal_output = 0; // reset max value
                        for (count_channel = 0; count_channel < 10; count_channel = count_channel + 1) begin
                            if (decimal_output[count_batch][count_channel] > max_decimal_output) begin
                                output_data[count_batch] = count_channel; // update output data with the channel index
                                max_decimal_output = decimal_output[count_batch][count_channel]; // update max value
                            end
                        end
                        output_valid <= 1; // set output valid signal
                    end
                end
            endcase
        end
    end
    // end of DNN Analysis Logic
endmodule
