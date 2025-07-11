`timescale 1ns / 1ps

module rx(
    input wire next,  // defined to realize the same function as ret_n
    input wire clk,
    input wire rst_n,
    input wire rx_pin,
    // output reg [31:0] rx_data [0:3071],  // need to take floating number into consideration, is that [31:0]?
    output reg [98303:0] rx_data,
    // +/- with 8bit with '.'  Here the case is different from MNIST, which divides the 784bit(0 or 1) into 98Byte. In this case we need to use 7Byte as one floating number.
    // or 4Byte as one float number, two number in one bag - but this method is not portable
    output reg rx_data_valid
    );

wire [7:0] one_rx;      // one Byte
wire [31:0] one_fn;     // one floating number
wire rx_done;
wire num_done;
reg [11:0] image_cnt; // 3072 floating number
reg [7:0] part_fn;
reg rx_valid;
reg [1:0] num_state;

single_rx  single_rx(
    .clk    (clk),
    .rst_n  (rst_n),
    .pin    (rx_pin),
    .one_rx (one_rx),
    .rx_done (rx_done)
);

string_to_float string_to_float(
    // combine to floating number
    // .clk        (clk),
    // .rst_n      (rst_n),
    .rx_valid        (rx_valid),      // same function as rst_n
    .part_fn    (part_fn),   // input
    .one_fn     (one_fn),
    .num_done   (num_done)  //output
);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || next)
    begin
        rx_data = 0;
        rx_data_valid = 0;
        rx_valid = 0;
        image_cnt = 0;
        num_state = 0;
    end

    else if (num_done == 0)
    begin
        if (num_state == 0)
        begin
            part_fn <= 8'h02;   // the starting flag
            rx_valid <= 1;
            num_state <= 1;
        end

        else if (num_state == 1)    // working state
        begin
            rx_valid <= 0;
            if (rx_done == 0)
            begin
                rx_valid = 0;
            end
            else if (rx_done == 1)
            begin
                part_fn = one_rx;
                rx_valid = 1;
            end
        end

        else if (num_state == 2)
        begin
            part_fn <= 8'h03;   // the ending flag
            rx_valid <= 1;
        end
        // it should be num_done == 1 at this moment 
    end

    else if (num_done == 1)
    begin
        rx_valid <= 0;
        num_state <= 0; // for next number

        if (image_cnt < 3072)
        begin
            rx_data[(98303-8*image_cnt)-:32] <= one_rx;
            image_cnt <= image_cnt + 1;
        end
        
        else if (image_cnt == 3072)
        begin
            rx_data_valid = 1;
        end
    end
end

endmodule