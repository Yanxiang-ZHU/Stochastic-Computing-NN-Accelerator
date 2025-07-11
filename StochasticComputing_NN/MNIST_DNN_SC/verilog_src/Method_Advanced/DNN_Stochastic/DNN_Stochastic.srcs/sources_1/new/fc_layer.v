`timescale 1ns / 1ps

module fc_layer #(
    parameter LAYER = 1,
    parameter SEQ_LENGTH = 128,
    parameter BATCH_SIZE = 2,
    parameter MAX_MID_NEURONS = 81,
    parameter INPUT_WIDTH = 27,
    parameter INPUT_HEIGHT = 27
)(
    input wire clk,
    input wire rst_n,
    input wire [SEQ_LENGTH-1:0] input_data [0:BATCH_SIZE-1][0:INPUT_WIDTH*INPUT_HEIGHT-1],
    input wire valid_in,
    output reg [SEQ_LENGTH-1:0] output_data [0: BATCH_SIZE-1][0: MAX_MID_NEURONS-1][0:INPUT_WIDTH*INPUT_HEIGHT-1],
    output reg valid_out
    );

    typedef enum logic [1:0] {
        IDLE,
        PROCESS,
        DONE
    } state_t;
    state_t state_reg, state_next;

    reg [15:0] address_fc [0:2];

    reg [SEQ_LENGTH-1:0] weight_fc [0:2];

    reg [15:0] address_all;
    reg [9:0] size_1;
    reg [9:0] size_2;
    reg [9:0] row;
    reg [9:0] col;
    integer b_cnt;

    generate
        if (LAYER == 1) begin
            weight_fc1 weight_fc1_u (
            .a(address_fc[0][15:0]),
            .spo(weight_fc[0])
        );
        end else if (LAYER == 2) begin
            weight_fc2 weight_fc2_u (
                .a(address_fc[1][12:0]),
                .spo(weight_fc[1])
            );
        end else if (LAYER == 3) begin
            weight_fc3 weight_fc3_u (
                .a(address_fc[2][8:0]),
                .spo(weight_fc[2])
            );
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_fc[0] <= 0;
            address_fc[1] <= 0;
            address_fc[2] <= 0;
            valid_out <= 0;
            b_cnt <= 0;
            row <= 0;
            col <= 0;
            state_reg <= IDLE;
            state_next <= IDLE;
        end else  begin
            state_reg <= state_next;

            case (state_reg)
                IDLE: begin
                    if (valid_in) begin
                        valid_out <= 0;
                        case (LAYER)
                            1: begin
                                address_all <= 59049; // 81*729
                                size_1 <= 81;
                                size_2 <= 729;
                            end
                            2: begin
                                address_all <= 6561; // 27*243
                                size_1 <= 27;
                                size_2 <= 243;
                            end
                            3: begin
                                address_all <= 270; // 10*27
                                size_1 <= 10;
                                size_2 <= 27;
                            end
                        endcase
                        state_next <= PROCESS;
                    end
                end

                PROCESS: begin
                    if (b_cnt < BATCH_SIZE) begin
                        if (address_fc[LAYER-1] < address_all) begin
                            // row = address_fc[LAYER-1] / size_2;
                            // col = address_fc[LAYER-1] % size_2;
                            if (col < size_2 - 1) begin
                                col <= col + 1;
                            end else begin
                                col <= 0;
                                row <= row + 1;
                            end
                            output_data[b_cnt][row][col] <= (input_data[b_cnt][col] ~^ weight_fc[LAYER-1]);

                            address_fc[LAYER-1] <= address_fc[LAYER-1] + 1;
                        end else begin
                            address_fc[LAYER-1] <= 0;
                            b_cnt <= b_cnt + 1;
                            row <= 0;
                            col <= 0;
                        end
                    end else begin
                        state_next <= DONE;
                    end 
                end

                DONE: begin
                    valid_out <= 1;
                    b_cnt <= 0; 
                    if (~valid_in)
                        state_next <= IDLE;
                end
            endcase
        end
    end

endmodule
