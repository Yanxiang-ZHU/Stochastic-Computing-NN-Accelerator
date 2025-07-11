`timescale 1ns / 1ps 

module CNN_TOP #(
    parameter LENTH  = 100,
    parameter IMG_SIZE  = 784  
)(
    input wire clk,
    input wire rst_n,
    input wire rx_pin,     
    output wire tx_pin
);

typedef enum logic [2:0] {
    IDLE        = 3'b000,   // waiting for data
    RECEIVING   = 3'b001,   // receiving fixed-point numbers and transforming to random sequences
    PROCESSING  = 3'b010,   // CNN neuron network processing
    TRANSMITTING= 3'b011,   // transmitting result: 0~9
    WAIT_TX     = 3'b100    // waiting for completion
} state_t;

reg [LENTH-1:0] img_buffer [0:IMG_SIZE-1];
reg [LENTH-1:0] rx_data [0:IMG_SIZE-1];
reg [3:0] result_reg;
reg [3:0] cnn_result;
reg tx_enable;
state_t current_state, next_state;

RX #(
    .LENTH(LENTH),
    .SIZE(IMG_SIZE),
    .BAUD(9600)
) u_RX (
    .clk(clk),
    .rst_n(rst_n),
    .rx_pin(rx_pin),
    .rx_data(rx_data),
    .flag(rx_done)
);

CNN #(
    .LENTH(LENTH)
) u_CNN (
    .clk(clk),
    .rst_n(rst_n),
    .input_val(img_buffer),
    .output_val(cnn_result),
    .flag(cnn_done)
);

TX u_TX (
    .clk(clk),
    .rst_n(rst_n),
    .result(result_reg),
    .en_tx(tx_enable),
    .tx_data_valid(tx_done),
    .tx(tx_pin)
);

always @(posedge clk) begin
    if (rx_done) img_buffer <= rx_data;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            next_state = RECEIVING;
        end
        RECEIVING: begin
            if (rx_done) next_state = PROCESSING;
        end
        PROCESSING: begin
            if (cnn_done) next_state = TRANSMITTING;
        end
        TRANSMITTING: begin
            next_state = WAIT_TX;
        end
        WAIT_TX: begin
            if (tx_done) next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_enable <= 0;
        result_reg <= 0;
    end else begin
        case (current_state)
            IDLE: begin
                tx_enable <= 0;
            end
            PROCESSING: begin
                result_reg <= cnn_result;
            end
            TRANSMITTING: begin
                tx_enable <= 1;
            end
            WAIT_TX: begin
                tx_enable <= 0;
            end
        endcase
    end
end
endmodule