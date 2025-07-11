`timescale 1ns / 1ps

module Top(
    input wire pin,
    input wire clk,
    input wire rst_n,
    output reg [3:0] result,    // will be transfered to different object in the uart_tx part 
    output wire tx
    );

// define the other things here
// for rx
reg next;
// wire [31:0] image [0:3071];
wire [98303:0] image;             // in the following steps, rx_data will be tranformed to image: 1D - 2D
wire rx_data_valid;
// for tx
reg en_tx;
wire tx_data_valid;
// for main structure
reg [2:0] level;
reg en_L1;
reg en_L2;
reg en_L3;
reg en_L4;
reg en_L5;

wire flag_L1;
wire flag_L2;
wire flag_L3;
wire flag_L4;
wire flag_L5;


// need to add the size here
wire [32*32*16*32-1:0] out_L1;
wire [32*32*16*32-1:0] out_L2;
wire [16*16*32*32-1:0] out_L3;
wire [8*8*64*32-1:0] out_L4;
wire [3:0] out_L5;  // out_L5 is the final result between 0 and 9



rx uart_rx(
    .clk    (clk),
    .rst_n  (rst_n),
    .rx_pin (pin),
    .next   (next),
    .rx_data    (image),
    .rx_data_valid   (rx_data_valid)
);


tx uart_tx(
    // define the tx structure
    // need to transfer from number to specific items
    .clk    (clk),
    .rst_n  (rst_n),
    .en_tx     (en_tx),
    .result (result),
    .tx_data_valid   (tx_data_valid),
    .tx     (tx)
);

// net-structures defined here

//Initialization -- the first fully convolution and batnor
cifar10L1 L1(
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en_L1),
    .flag   (flag_L1),
    .input_data (image),
    .output_data    (out_L1)
);

// main body part, Resnet: L2 L3 L4
cifar10L2 L2(
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en_L2),
    .flag   (flag_L2),
    .input_data (out_L1),
    .output_data    (out_L2)
);

cifar10L3 L3(
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en_L3),
    .flag   (flag_L3),
    .input_data (out_L2),
    .output_data    (out_L3)
);

cifar10L4 L4(
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en_L4),
    .flag   (flag_L4),
    .input_data (out_L3),
    .output_data    (out_L4)
);

// ending part with fully activation, globalavgpool and dense layer
cifar10L5 L5(
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en_L5),
    .flag   (flag_L5),
    .input_data (out_L4),
    .output_data    (out_L5) // after the dense layer, the size would be 10*1 (finding the biggest number)
);

// the main clk structure
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        level <= 0;
        result <= 0;
        en_tx <= 0;
        next <= 0;
        en_L1 <= 0;
        en_L2 <= 0;
        en_L3 <= 0;
        en_L4 <= 0;
        en_L5 <= 0;
    end

    else if (level == 0)
    // level == 0 is for loading the image
    begin
        if (rx_data_valid == 0) ;
        else 
        begin
            level <= 1;
        end
    end

    else if (level == 1)
    // the first layer
    begin
        en_L1 <= 1;
        if (flag_L1)
        begin
            level <= 2;
            en_L1 <= 0;
        end
    end
    
    else if (level == 2)
    begin
        en_L2 <= 1;
        if (flag_L2)
        begin
            level <=3;
            en_L2 <= 0;
        end
    end

    else if (level == 3)
    begin
        en_L3 <= 1;
        if (flag_L3)
        begin
            level <= 4;
            en_L3 <= 0;
        end
    end

    else if (level == 4)
    begin
        en_L4 <= 1;
        if (flag_L4)
        begin
            level <= 5;
            en_L4 <= 0;
        end
    end

    else if (level == 5)
    begin
        en_L5 <= 1;
        if (flag_L5)
        begin
            level <= 6;
            en_L5 <= 0;
        end
    end

    else if (level == 6)
    // for tx
    begin
        next <= 1;
        result <= out_L5;
        if (tx_data_valid == 0)
        begin
            en_tx <= 1;
        end
        else
        begin
            next <= 0;
            en_tx <= 0;
            level <= 0;
        end
    end
end

endmodule
