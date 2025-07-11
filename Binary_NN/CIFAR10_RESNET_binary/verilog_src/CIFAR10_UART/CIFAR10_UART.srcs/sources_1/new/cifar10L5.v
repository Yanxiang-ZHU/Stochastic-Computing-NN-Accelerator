/*
    This part corresponds the Tensorflow part:
    x=self.actv19(x)
    return self.dense(self.globalavgpool(x))
*/

`timescale 1ns / 1ps

module cifar10L5(
    input clk,
    input rst_n,
    input en,
    input input_data,
    output reg flag,
    output reg output_data
    );

reg [1:0] level;

reg en_actv;
reg [64*64*32-1:0] input_fc;
wire [64*64*32-1:0] output_fc;
wire flag_actv;

reg en_gap;
reg [64*64*32-1:0] input_gap;
wire [1*64*32-1:0] output_gap;
wire flag_gap;

reg en_dense;
reg [1*64*32-1:0] input_dense;
wire [1*10*32-1:0] output_dense;
wire flag_dense;

reg en_cmp;
reg [1*10*32-1:0] input_cmp;
wire [3:0] output_cmp;
wire flag_cmp;

parameter DATA_WIDTH = 32;
parameter OUTPUT_NODES_ACTV = 64*64;
parameter OUTPUT_NODES_GAP = 1*64;
parameter OUTPUT_NODES_DENSE = 10;
parameter NUM_VALUES_CMP = 10;

activation_relu #(
    .DATA_WIDTH(DATA_WIDTH),
    .OUTPUT_NODES(OUTPUT_NODES_ACTV)
)uut(
    .clk(clk),
    .reset(rst_n),
    .en(en_actv),
    .input_fc(input_fc),
    .output_fc(output_fc),
    .flag(flag_actv)
);

globalavgpool #(
    .DATA_WIDTH(DATA_WIDTH),
    .OUTPUT_NODES(OUTPUT_NODES_GAP)
)gap(
    .clk(clk),
    .rst_n(rst_n),
    .en(en_gap),
    .input_gap(input_gap),
    .output_gap(output_gap),
    .flag(flag_gap)
);

dense #(
    .DATA_WIDTH(DATA_WIDTH),
    .OUTPUT_NODES(OUTPUT_NODES_DENSE)
)ds(
    .clk(clk),
    .rst_n(rst_n),
    .en(en_dense),
    .input_dense(input_dense),
    .output_dense(output_dense),
    .flag(flag_dense)
);

comparison #(
    .DATA_WIDTH(DATA_WIDTH),
    .NUM_VALUES(NUM_VALUES_CMP)
)cmp(
    .clk(clk),
    .rst_n(rst_n),
    .en(en_cmp),
    .input_cmp(input_cmp),
    .output_cmp(output_cmp),
    .flag(flag_cmp)
);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        level <= 0;
        flag <= 0;
        output_data <= 0;
    end

    else if (level == 0)       // relu layer
    begin
        input_fc <= input_data;
        en_actv <= 1;
        if (flag_actv)
        begin
            level <= 1;
            en_actv <= 0;
        end
    end

    else if (level == 1)        // globalavgpool
    begin
        // division in floating numbers, need the IP core
        input_gap <= output_fc;
        en_gap <= 1;
        if (flag_gap)
        begin
            level <= 2;
            en_gap <= 0;
        end
    end

    else if (level == 2)        // dense: arr_82, arr_83
    begin
        // multiplication and addition in floating numbers, need the IP core
        input_dense <= output_gap;
        en_dense <= 1;
        if (flag_dense)
        begin
            level <= 3;
            en_dense <= 0;
        end
    end

    else if (level == 3)
    begin
        input_cmp <= output_dense;
        en_cmp <= 1;
        if (flag_cmp)
        begin
            output_data <= output_cmp;
            flag <= 1;
            en_cmp <= 0;
        end
    end
end

endmodule
