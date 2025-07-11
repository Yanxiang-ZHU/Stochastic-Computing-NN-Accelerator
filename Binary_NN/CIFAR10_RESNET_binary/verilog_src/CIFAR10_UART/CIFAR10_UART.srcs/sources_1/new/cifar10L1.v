/*
    This part corresponds the Tensorflow part:
    x=self.batnor01(self.conv01(inputs),training=training)
*/

`timescale 1ns / 1ps

module cifar10L1(
    input clk,
    input rst_n,
    input en,
    input input_data,
    output reg flag,
    output reg output_data
    );

reg en_conv;
wire [524287:0] output_conv;
wire flag_conv;

reg [31:0] A_gamma [0:15];
reg [31:0] A_beta [0:15];
reg [31:0] A_mean [0:15];
reg [31:0] A_variance [0:15];

reg [16*32-1:0] gamma;
reg [16*32-1:0] beta;
reg [16*32-1:0] mean;
reg [16*32-1:0] variance;
reg en_batnor;
reg  [32*32*16*32-1:0] input_batnor;
wire [32*32*16*32-1:0] output_batnor;
wire flag_batnor;

reg level;
integer i;

parameter IM_LENTH = 32;
parameter IM_DEPTH = 16;

conv2d_3_16 arr0(
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en_conv),
    .input_data (input_data),
    .output_data   (output_conv),
    .flag   (flag_conv)
);

batnor #(
    .IM_LENTH (IM_LENTH),
    .IM_DEPTH (IM_DEPTH)
)batnor01(
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en_batnor),
    .input_data  (input_batnor),

    .gamma  (gamma),
    .beta   (beta),
    .mean   (mean),
    .variance   (variance),

    .output_data (output_batnor),
    .flag   (flag_batnor)
);

initial
begin
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_120.txt", A_gamma);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_121.txt", A_beta);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_122.txt", A_mean);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_123.txt", A_variance);

    for (i = 0; i < 16; i = i + 1) begin
        gamma[i*32+ 31 -: 32] = A_gamma[i];
        beta[i*32+ 31 -: 32] = A_beta[i];
        mean[i*32+ 31 -: 32] = A_mean[i];
        variance[i*32+ 31 -: 32] = A_variance[i];
    end
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        level <= 0;
        en_batnor <= 0;
        en_conv <= 0;
        flag <= 0;
    end

    else if (level == 0)        // conv01
    begin
        en_conv <= 1;

        if (flag_conv == 1)
        begin
            input_batnor <= output_conv;
            en_conv <= 0;
            level <= 1;
        end
    end

    else if (level == 1)        // batnor01
    begin
        en_batnor <= 1;

        if (flag_batnor == 1)
        begin
            output_data <= output_batnor;
            en_batnor <= 0;
            level <= 0;
            flag <= 1;
        end
    end
end

endmodule
