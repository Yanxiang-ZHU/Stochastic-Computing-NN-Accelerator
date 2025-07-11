/*
    This part corresponds the Tensorflow part:
    x=self.convd1(x)+   self.batnor09(self.conv09(self.actv08(self.batnor08(self.conv08(self.actv07(self.batnoh07(x,training=training))),training=training))),training=training)
    x=x+                self.batnor11(self.conv11(self.actv10(self.batnor10(self.conv10(self.actv09(self.batnoh09(x,training=training))),training=training))),training=training)
    x=x+                self.batnor13(self.conv13(self.actv12(self.batnor12(self.conv12(self.actv11(self.batnoh11(x,training=training))),training=training))),training=training)
*/

`timescale 1ns / 1ps

module cifar10L3(
    input clk,
    input rst_n,
    input en,
    input [32*32*16*32-1:0] input_data,
    output reg flag,
    output reg [16*16*32*32-1:0] output_data
    );


    parameter IM_LENTH_IN = 32;
    parameter IM_DEPTH_IN = 16;
    parameter IM_LENTH_OUT = 16;
    parameter IM_DEPTH_OUT = 32;

    parameter KN_LENTH = 3; // size of the kernel
    parameter KN_OC = 32;   // output channel

    reg flag_thrH07;
    reg flag_thrH09;
    reg flag_thrH11;
    reg flag_thrR08;
    reg flag_thrR10;
    reg flag_thrR12;

    reg [1:0] level;
    reg [2:0] state;

    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_L1;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_L2;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_L3;

////////// reg for thr calculation ////////////////
    reg [31:0] gamma_batnor08    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnor10    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnor12    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnoh07    [IM_DEPTH_IN -1:0];
    reg [31:0] gamma_batnoh09    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnoh11    [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnor08     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnor10     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnor12     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnoh07     [IM_DEPTH_IN -1:0];
    reg [31:0] beta_batnoh09     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnoh11     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnor08     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnor10     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnor12     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnoh07     [IM_DEPTH_IN -1:0];
    reg [31:0] mean_batnoh09     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnoh11     [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnor08 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnor10 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnor12 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnoh07 [IM_DEPTH_IN -1:0];
    reg [31:0] variance_batnoh09 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnoh11 [IM_DEPTH_OUT-1:0];

    reg [IM_DEPTH_IN*32-1:0] thr_batnoh07;
    reg [IM_DEPTH_OUT*32-1:0] thr_batnoh09;
    reg [IM_DEPTH_OUT*32-1:0] thr_batnoh11;
    reg [IM_DEPTH_OUT*8-1:0] thr_batnor08;
    reg [IM_DEPTH_OUT*8-1:0] thr_batnor10;
    reg [IM_DEPTH_OUT*8-1:0] thr_batnor12;

    reg s1_valid;
    reg s2_valid;
    reg [31:0] s1_data;
    reg [31:0] s2_data;
    reg sub_result_ready;
    wire s1_ready;
    wire s2_ready;
    wire sub_flag;
    wire [31:0] sub_result;

    reg div1_valid;
    reg div2_valid;
    reg [31:0] div1_data;
    reg [31:0] div2_data;
    wire div_flag;
    wire [31:0] div_result;

////////// reg and wire for batch normalization //////////////
    reg en_batnor08;
    reg en_batnor09;
    reg en_batnor10;
    reg en_batnor11;
    reg en_batnor12;
    reg en_batnor13;
    reg en_batnoh07;
    reg en_batnoh09; 
    reg en_batnoh11;

    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnor09;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnor11;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnor13;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] input_batnor08;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] input_batnor10;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] input_batnor12;
    reg [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN*32-1:0] input_batnoh07;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnoh09;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnoh11;

    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_batnor09;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_batnor11;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_batnor13;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnor08;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnor10;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnor12;
    wire [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN-1:0] output_batnoh07;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnoh09;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnoh11;

    wire flag_batnor09;
    wire flag_batnor11;
    wire flag_batnor13;
    wire flag_batnor08;
    wire flag_batnor10;
    wire flag_batnor12;
    wire flag_batnoh07;
    wire flag_batnoh09;
    wire flag_batnoh11;

////////// reg and wire for biconv //////////////
    reg en_conv08;
    reg en_conv09;
    reg en_conv10;
    reg en_conv11;
    reg en_conv12;
    reg en_conv13;

    reg [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN-1:0] input_conv08;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv09;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv10;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv11;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv12;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv13;

    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv08;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv09;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv10;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv11;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv12;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv13;

    wire flag_conv08;
    wire flag_conv09;
    wire flag_conv10;
    wire flag_conv11;
    wire flag_conv12;
    wire flag_conv13;

////////// batch normalization, 9 in total (3 in fully precision, and 6 in binary style) /////////////
    batnor #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_152.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_153.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_154.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_155.txt")
    )batnor09(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor09),
        .input_data  (input_batnor09),
        .output_data (output_batnor09),
        .flag   (flag_batnor09)
    );

    batnor #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_160.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_161.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_162.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_163.txt")
    )batnor11(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor11),
        .input_data  (input_batnor11),
        .output_data (output_batnor11),
        .flag   (flag_batnor11)
    );

    batnor #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_168.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_169.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_170.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_171.txt")
    )batnor13(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor13),
        .input_data  (input_batnor13),
        .output_data (output_batnor13),
        .flag   (flag_batnor13)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH_IN),
        .IM_DEPTH (IM_DEPTH_IN)
    )batnoh07(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh07),
        .input_data    (input_batnoh07),

        .thr  (thr_batnoh07),

        .output_data    (output_batnoh07),
        .flag           (flag_batnoh07)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnor08(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor08),
        .input_data    (input_batnor08),

        .thr  (thr_batnor08),

        .output_data    (output_batnor08),
        .flag           (flag_batnor08)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnoh09(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh09),
        .input_data    (input_batnoh09),

        .thr  (thr_batnoh09),

        .output_data    (output_batnoh09),
        .flag           (flag_batnoh09)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnor10(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor10),
        .input_data    (input_batnor10),

        .thr  (thr_batnor10),

        .output_data    (output_batnor10),
        .flag           (flag_batnor10)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnoh11(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh11),
        .input_data    (input_batnoh11),

        .thr  (thr_batnoh11),

        .output_data    (output_batnoh11),
        .flag           (flag_batnoh11)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnor12(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor12),
        .input_data    (input_batnor12),

        .thr  (thr_batnor12),

        .output_data    (output_batnor12),
        .flag           (flag_batnor12)
    );

////////// convolution, 6 in total (all in binary style), size = 3*3*16*16 /////////////
    biconv #(
        .IM_LENTH(IM_LENTH_IN),
        .IM_DEPTH(IM_DEPTH_IN),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(2),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_26.txt")
    )conv08(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv08),
        .input_data     (input_conv08),
        .output_data    (output_conv08),
        .flag           (flag_conv08)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_30.txt")
    )conv09(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv09),
        .input_data     (input_conv09),
        .output_data    (output_conv09),
        .flag           (flag_conv09)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_34.txt")
    )conv10(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv10),
        .input_data     (input_conv10),
        .output_data    (output_conv10),
        .flag           (flag_conv10)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_38.txt")
    )conv11(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv11),
        .input_data     (input_conv11),
        .output_data    (output_conv11),
        .flag           (flag_conv11)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_42.txt")
    )conv12(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv12),
        .input_data     (input_conv12),
        .output_data    (output_conv12),
        .flag           (flag_conv12)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_46.txt")
    )conv13(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv13),
        .input_data     (input_conv13),
        .output_data    (output_conv13),
        .flag           (flag_conv13)
    );

    reg en_convd1;
    reg [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN*32-1:0] input_convd1;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_convd1;
    wire flag_convd1;

    convd #(
        .IM_LENTH(IM_LENTH_IN),
        .IM_DEPTH(IM_DEPTH_IN),
        .KN_LENTH(1),
        .KN_OC(KN_OC),
        .STRIDE(2),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_74.txt"),
        .NMK_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_75.txt")
    )convd1(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_convd1),
        .input_data     (input_convd1),
        .output_data    (output_convd1),
        .flag           (flag_convd1)
    );

////////// floating calculation ////////////////
    subfloat L3_sub(
        .clk    (clk),
        .a_tvalid   (s1_valid),
        .a_tdata    (s1_data),
        .b_tvalid   (s2_valid),
        .b_tdata    (s2_data),
        .result_ready   (sub_result_ready),
        .a_tready   (s1_ready),
        .b_tready   (s2_ready),
        .result_valid   (sub_flag),
        .result_data    (sub_result)
    );

    divfloat L3_div(
        .clk    (clk),
        .a_tvalid   (div1_valid),
        .a_tdata    (div1_data),
        .b_tvalid   (div2_valid),
        .b_tdata    (div2_data),
        .div_result_tvalid  (div_flag),
        .div_result_tdata   (div_result)
    );

////////// data type transfer && xadd//////////////////
    reg en_tsf;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] input_int;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_float;
    wire flag_tsf;

    inttofloat #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT)
    )L3_inttofloat(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_tsf),
        .input_data     (input_int),
        .output_data    (output_float),
        .flag   (flag_tsf)
    );

    reg en_xadd;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] x_self;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] x_add;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_xadd;
    wire flag_xadd;

    xadd #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT)
    )L3_xadd(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_xadd),
        .x_self (x_self),
        .x_add  (x_add),
        .output_data    (output_xadd),
        .flag   (flag_xadd)
    );

    integer thr_loop;
    reg [31:0] float_in;
    wire signed [7:0] int_out;

    floor_floattoint L2_floor_floattoint(
        .float_in   (float_in),
        .int_out    (int_out)
    );

////////// architecture /////////////
initial
begin
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_148.txt", gamma_batnor08);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_156.txt", gamma_batnor10);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_164.txt", gamma_batnor12);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_208.txt", gamma_batnoh07);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_212.txt", gamma_batnoh09);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_216.txt", gamma_batnoh11);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_149.txt", beta_batnor08);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_157.txt", beta_batnor10);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_165.txt", beta_batnor12);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_209.txt", beta_batnoh07);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_213.txt", beta_batnoh09);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_217.txt", beta_batnoh11);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_150.txt", mean_batnor08);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_158.txt", mean_batnor10);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_166.txt", mean_batnor12);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_210.txt", mean_batnoh07);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_214.txt", mean_batnoh09);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_218.txt", mean_batnoh11);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_151.txt", variance_batnor08);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_159.txt", variance_batnor10);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_167.txt", variance_batnor12);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_211.txt", variance_batnoh07);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_215.txt", variance_batnoh09);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_219.txt", variance_batnoh11);
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        en_convd1 <= 0;
    end
    else
    begin
        input_convd1 <= input_data;
        en_convd1 <= 1;
        if (flag_convd1) 
        begin
            x_self <= output_convd1;
            en_convd1 <= 0;
        end
    end
end

// calculate thr value
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        flag_thrH07 <= 0;
        flag_thrH09 <= 0;
        flag_thrH11 <= 0;
        flag_thrR08 <= 0;
        flag_thrR10 <= 0;
        flag_thrR12 <= 0;
        thr_batnoh07 <= 0;
        thr_batnoh09 <= 0;
        thr_batnoh11 <= 0;
        thr_batnor08 <= 0;
        thr_batnor10 <= 0;
        thr_batnor12 <= 0;

        div1_valid <= 0;
        div2_valid <= 0;
        s1_valid <= 0;
        s2_valid <= 0;
        sub_result_ready <= 0;
    end

    else
    begin
        if (!flag_thrH07)
        begin
            if (thr_loop < IM_DEPTH_IN)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh07[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh07[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh07[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh07[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH07 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrH09)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh09[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh09[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh09[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh09[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH09 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrH11)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh11[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh11[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh11[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh11[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH11 <= 1;
                thr_loop <= 0;
            end
        end
        
        else if (!flag_thrR08)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor08[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor08[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor08[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor08[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR08 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrR10)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor10[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor10[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor10[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor10[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR10 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrR12)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor12[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor12[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor12[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor12[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR12 <= 1;
                thr_loop <= 0;
            end
        end
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        level <= 0;
        state <= 0;
        flag <= 0;
        output_data <= 0;

        // make all en signal into 0
        en_batnoh07 <= 0;
        en_batnoh09 <= 0;
        en_batnoh11 <= 0;
        en_batnor08 <= 0;
        en_batnor09 <= 0;
        en_batnor10 <= 0;
        en_batnor11 <= 0;
        en_batnor12 <= 0;
        en_batnor13 <= 0;
        en_conv08 <= 0;
        en_conv09 <= 0;
        en_conv10 <= 0;
        en_conv11 <= 0;
        en_conv12 <= 0;
        en_conv13 <= 0;
        en_convd1 <= 0;
        en_tsf <= 0;
        en_xadd <= 0;
    end
    
    else
    begin
        // 3 level and each level we suppose it will work serially (use state as label)
        if (level == 0)
        begin
            if (state == 0)     // batnoh (bibatnorFLOAT) + actv
            begin
                if (flag_thrH07)
                begin
                    input_batnoh07 <= input_data;
                    en_batnoh07 <= 1;
                    if (flag_batnoh07)
                    begin
                        input_conv08 <= output_batnoh07;
                        state <= 1;
                        en_batnoh07 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv08 <= 1;
                if (flag_conv08)
                begin
                    input_batnor08 <= output_conv08;
                    state <= 2;
                    en_conv08 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR08)
                begin
                    en_batnor08 <= 1;
                    if (flag_batnor08)
                    begin
                        input_conv09 <= output_batnor08;
                        state <= 3;
                        en_batnor08 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv09 <= 1;
                if (flag_conv09)
                begin
                    input_int <= output_conv09;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv09 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor09 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor09 <= 1;
                if (flag_batnor09)
                begin
                    x_add <= output_batnor09;
                    state <= 5;
                    en_batnor09 <= 0;
                end
            end

            else if (state == 5)     // convd1 add  (not x add, be careful!!)
            begin
                en_xadd <= 1;
                if (flag_xadd)
                begin
                    output_L1 <= output_xadd;
                    state <= 0;
                    level <= 1;
                    en_xadd <= 0;
                end
            end
        end

        else if (level == 1)
        begin
            if (state == 0)     // batnoh (bibatnorFLOAT) + actv
            begin
                if (flag_thrH09)
                begin
                    input_batnoh09 <= output_L1;
                    en_batnoh09 <= 1;
                    if (flag_batnoh09)
                    begin
                        input_conv10 <= output_batnoh09;
                        state <= 1;
                        en_batnoh09 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv10 <= 1;
                if (flag_conv10)
                begin
                    input_batnor10 <= output_conv10;
                    state <= 2;
                    en_conv10 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR10)
                begin
                    en_batnor10 <= 1;
                    if (flag_batnor10)
                    begin
                        input_conv11 <= output_batnor10;
                        state <= 3;
                        en_batnor10 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv11 <= 1;
                if (flag_conv11)
                begin
                    input_int <= output_conv11;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv11 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor11 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor11 <= 1;
                if (flag_batnor11)
                begin
                    x_add <= output_batnor11;
                    state <= 5;
                    en_batnor11 <= 0;
                end
            end

            else if (state == 5)     // x add
            begin
                en_xadd <= 1;
                x_self <= output_L1;
                if (flag_xadd)
                begin
                    output_L2 <= output_xadd;
                    state <= 0;
                    level <= 2;
                    en_xadd <= 0;
                end
            end
        end

        else if (level == 2)
        begin
            if (state == 0)     // batnoh (bibatnorFLOAT) + actv
            begin
                if (flag_thrH11)
                begin
                    input_batnoh11 <= output_L2;
                    en_batnoh11 <= 1;
                    if (flag_batnoh11)
                    begin
                        input_conv12 <= output_batnoh11;
                        state <= 1;
                        en_batnoh11 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv12 <= 1;
                if (flag_conv12)
                begin
                    input_batnor12 <= output_conv12;
                    state <= 2;
                    en_conv12 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR12)
                begin
                    en_batnor12 <= 1;
                    if (flag_batnor12)
                    begin
                        input_conv13 <= output_batnor12;
                        state <= 3;
                        en_batnor12 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv13 <= 1;
                if (flag_conv13)
                begin
                    input_int <= output_conv13;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv13 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor13 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor13 <= 1;
                if (flag_batnor13)
                begin
                    x_add <= output_batnor13;
                    state <= 5;
                    en_batnor13 <= 0;
                end
            end

            else if (state == 5)     // x add
            begin
                en_xadd <= 1;
                x_self <= output_L2;
                if (flag_xadd)
                begin
                    output_data <= output_xadd;
                    state <= 0;
                    level <= 0;
                    en_xadd <= 0;
                    flag <= 1;
                end
            end
        end
    end
end


endmodule
