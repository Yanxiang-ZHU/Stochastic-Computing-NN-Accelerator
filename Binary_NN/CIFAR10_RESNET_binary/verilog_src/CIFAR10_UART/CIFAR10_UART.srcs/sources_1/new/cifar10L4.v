/*
    This part corresponds the Tensorflow part:
    x=self.convd2(x)+self.batnor15(self.conv15(self.actv14(self.batnor14(self.conv14(self.actv13(self.batnoh13(x,training=training))),training=training))),training=training)
    x=x+self.batnor17(self.conv17(self.actv16(self.batnor16(self.conv16(self.actv15(self.batnoh15(x,training=training))),training=training))),training=training)
    x=x+self.batnor19(self.conv19(self.actv18(self.batnor18(self.conv18(self.actv17(self.batnoh17(x,training=training))),training=training))),training=training)
*/

`timescale 1ns / 1ps

module cifar10L4(
    input clk,
    input rst_n,
    input en,
    input [16*16*32*32-1:0] input_data,
    output reg flag,
    output reg [8*8*64*32-1:0] output_data
    );

    parameter IM_LENTH_IN = 16;
    parameter IM_DEPTH_IN = 32;
    parameter IM_LENTH_OUT = 8;
    parameter IM_DEPTH_OUT = 64;

    parameter KN_LENTH = 3; // size of the kernel
    parameter KN_OC = 64;   // output channel

    reg flag_thrH13;
    reg flag_thrH15;
    reg flag_thrH17;
    reg flag_thrR14;
    reg flag_thrR16;
    reg flag_thrR18;

    reg [1:0] level;
    reg [2:0] state;

    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_L1;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_L2;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_L3;

////////// reg for thr calculation ////////////////
    reg [31:0] gamma_batnor14    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnor16    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnor18    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnoh13    [IM_DEPTH_IN -1:0];
    reg [31:0] gamma_batnoh15    [IM_DEPTH_OUT-1:0];
    reg [31:0] gamma_batnoh17    [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnor14     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnor16     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnor18     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnoh13     [IM_DEPTH_IN -1:0];
    reg [31:0] beta_batnoh15     [IM_DEPTH_OUT-1:0];
    reg [31:0] beta_batnoh17     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnor14     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnor16     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnor18     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnoh13     [IM_DEPTH_IN -1:0];
    reg [31:0] mean_batnoh15     [IM_DEPTH_OUT-1:0];
    reg [31:0] mean_batnoh17     [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnor14 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnor16 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnor18 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnoh13 [IM_DEPTH_IN -1:0];
    reg [31:0] variance_batnoh15 [IM_DEPTH_OUT-1:0];
    reg [31:0] variance_batnoh17 [IM_DEPTH_OUT-1:0];

    reg [IM_DEPTH_IN*32-1:0] thr_batnoh13;
    reg [IM_DEPTH_OUT*32-1:0] thr_batnoh15;
    reg [IM_DEPTH_OUT*32-1:0] thr_batnoh17;
    reg [IM_DEPTH_OUT*8-1:0] thr_batnor14;
    reg [IM_DEPTH_OUT*8-1:0] thr_batnor16;
    reg [IM_DEPTH_OUT*8-1:0] thr_batnor18;

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
    reg en_batnor14;
    reg en_batnor15;
    reg en_batnor16;
    reg en_batnor17;
    reg en_batnor18;
    reg en_batnor19;
    reg en_batnoh13;
    reg en_batnoh15; 
    reg en_batnoh17;

    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnor15;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnor17;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnor19;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] input_batnor14;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] input_batnor16;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] input_batnor18;
    reg [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN*32-1:0] input_batnoh13;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnoh15;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] input_batnoh17;

    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_batnor15;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_batnor17;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_batnor19;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnor14;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnor16;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnor18;
    wire [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN-1:0] output_batnoh13;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnoh15;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] output_batnoh17;

    wire flag_batnor15;
    wire flag_batnor17;
    wire flag_batnor19;
    wire flag_batnor14;
    wire flag_batnor16;
    wire flag_batnor18;
    wire flag_batnoh13;
    wire flag_batnoh15;
    wire flag_batnoh17;

////////// reg and wire for biconv //////////////
    reg en_conv14;
    reg en_conv15;
    reg en_conv16;
    reg en_conv17;
    reg en_conv18;
    reg en_conv19;

    reg [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN-1:0] input_conv14;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv15;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv16;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv17;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv18;
    reg [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT-1:0] input_conv19;

    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv14;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv15;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv16;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv17;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv18;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*8-1:0] output_conv19;

    wire flag_conv14;
    wire flag_conv15;
    wire flag_conv16;
    wire flag_conv17;
    wire flag_conv18;
    wire flag_conv19;

////////// batch normalization, 9 in total (3 in fully precision, and 6 in binary style) /////////////
    batnor #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_176.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_177.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_178.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_179.txt")
    )batnor15(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor15),
        .input_data  (input_batnor15),
        .output_data (output_batnor15),
        .flag   (flag_batnor15)
    );

    batnor #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_184.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_185.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_186.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_187.txt")
    )batnor17(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor17),
        .input_data  (input_batnor17),
        .output_data (output_batnor17),
        .flag   (flag_batnor17)
    );

    batnor #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_192.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_193.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_194.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_195.txt")
    )batnor19(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor19),
        .input_data  (input_batnor19),
        .output_data (output_batnor19),
        .flag   (flag_batnor19)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH_IN),
        .IM_DEPTH (IM_DEPTH_IN)
    )batnoh13(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh13),
        .input_data    (input_batnoh13),

        .thr  (thr_batnoh13),

        .output_data    (output_batnoh13),
        .flag           (flag_batnoh13)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnor14(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor14),
        .input_data    (input_batnor14),

        .thr  (thr_batnor14),

        .output_data    (output_batnor14),
        .flag           (flag_batnor14)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnoh15(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh15),
        .input_data    (input_batnoh15),

        .thr  (thr_batnoh15),

        .output_data    (output_batnoh15),
        .flag           (flag_batnoh15)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnor16(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor16),
        .input_data    (input_batnor16),

        .thr  (thr_batnor16),

        .output_data    (output_batnor16),
        .flag           (flag_batnor16)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnoh17(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh17),
        .input_data    (input_batnoh17),

        .thr  (thr_batnoh17),

        .output_data    (output_batnoh17),
        .flag           (flag_batnoh17)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH_OUT),
        .IM_DEPTH (IM_DEPTH_OUT)
    )batnor18(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor18),
        .input_data    (input_batnor18),

        .thr  (thr_batnor18),

        .output_data    (output_batnor18),
        .flag           (flag_batnor18)
    );

////////// convolution, 6 in total (all in binary style), size = 3*3*16*16 /////////////
    biconv #(
        .IM_LENTH(IM_LENTH_IN),
        .IM_DEPTH(IM_DEPTH_IN),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(2),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_50.txt")
    )conv14(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv14),
        .input_data     (input_conv14),
        .output_data    (output_conv14),
        .flag           (flag_conv14)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_54.txt")
    )conv15(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv15),
        .input_data     (input_conv15),
        .output_data    (output_conv15),
        .flag           (flag_conv15)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_58.txt")
    )conv16(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv16),
        .input_data     (input_conv16),
        .output_data    (output_conv16),
        .flag           (flag_conv16)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_62.txt")
    )conv17(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv17),
        .input_data     (input_conv17),
        .output_data    (output_conv17),
        .flag           (flag_conv17)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_66.txt")
    )conv18(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv18),
        .input_data     (input_conv18),
        .output_data    (output_conv18),
        .flag           (flag_conv18)
    );

    biconv #(
        .IM_LENTH(IM_LENTH_OUT),
        .IM_DEPTH(IM_DEPTH_OUT),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_70.txt")
    )conv19(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv19),
        .input_data     (input_conv19),
        .output_data    (output_conv19),
        .flag           (flag_conv19)
    );

    reg en_convd2;
    reg [IM_LENTH_IN*IM_LENTH_IN*IM_DEPTH_IN*32-1:0] input_convd2;
    wire [IM_LENTH_OUT*IM_LENTH_OUT*IM_DEPTH_OUT*32-1:0] output_convd2;
    wire flag_convd2;

    convd #(
        .IM_LENTH(IM_LENTH_IN),
        .IM_DEPTH(IM_DEPTH_IN),
        .KN_LENTH(1),
        .KN_OC(KN_OC),
        .STRIDE(2),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_78.txt"),
        .NMK_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_79.txt")
    )convd2(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_convd2),
        .input_data     (input_convd2),
        .output_data    (output_convd2),
        .flag           (flag_convd2)
    );

////////// floating calculation ////////////////
    subfloat L4_sub(
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

    divfloat L4_div(
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
    )L4_inttofloat(
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
    )L4_xadd(
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

    floor_floattoint L4_floor_floattoint(
        .float_in   (float_in),
        .int_out    (int_out)
    );

////////// architecture /////////////
initial
begin
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_172.txt", gamma_batnor14);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_180.txt", gamma_batnor16);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_188.txt", gamma_batnor18);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_220.txt", gamma_batnoh13);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_224.txt", gamma_batnoh15);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_228.txt", gamma_batnoh17);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_173.txt", beta_batnor14);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_181.txt", beta_batnor16);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_189.txt", beta_batnor18);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_221.txt", beta_batnoh13);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_225.txt", beta_batnoh15);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_229.txt", beta_batnoh17);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_174.txt", mean_batnor14);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_182.txt", mean_batnor16);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_190.txt", mean_batnor18);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_222.txt", mean_batnoh13);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_226.txt", mean_batnoh15);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_230.txt", mean_batnoh17);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_175.txt", variance_batnor14);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_183.txt", variance_batnor16);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_191.txt", variance_batnor18);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_223.txt", variance_batnoh13);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_227.txt", variance_batnoh15);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_231.txt", variance_batnoh17);
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        en_convd2 <= 0;
    end
    else
    begin
        input_convd2 <= input_data;
        en_convd2 <= 1;
        if (flag_convd2) 
        begin
            x_self <= output_convd2;
            en_convd2 <= 0;
        end
    end
end

// calculate thr value
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        flag_thrH13 <= 0;
        flag_thrH15 <= 0;
        flag_thrH17 <= 0;
        flag_thrR14 <= 0;
        flag_thrR16 <= 0;
        flag_thrR18 <= 0;
        thr_batnoh13 <= 0;
        thr_batnoh15 <= 0;
        thr_batnoh17 <= 0;
        thr_batnor14 <= 0;
        thr_batnor16 <= 0;
        thr_batnor18 <= 0;

        div1_valid <= 0;
        div2_valid <= 0;
        s1_valid <= 0;
        s2_valid <= 0;
        sub_result_ready <= 0;
    end

    else
    begin
        if (!flag_thrH13)
        begin
            if (thr_loop < IM_DEPTH_IN)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh13[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh13[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh13[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh13[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH13 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrH15)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh15[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh15[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh15[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh15[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH15 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrH17)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh17[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh17[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh17[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh17[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH17 <= 1;
                thr_loop <= 0;
            end
        end
        
        else if (!flag_thrR14)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor14[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor14[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor14[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor14[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR14 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrR16)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor16[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor16[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor16[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor16[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR16 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrR18)
        begin
            if (thr_loop < IM_DEPTH_OUT)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor18[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor18[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor18[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor18[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR18 <= 1;
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
        en_batnoh13 <= 0;
        en_batnoh15 <= 0;
        en_batnoh17 <= 0;
        en_batnor14 <= 0;
        en_batnor15 <= 0;
        en_batnor16 <= 0;
        en_batnor17 <= 0;
        en_batnor18 <= 0;
        en_batnor19 <= 0;
        en_conv14 <= 0;
        en_conv15 <= 0;
        en_conv16 <= 0;
        en_conv17 <= 0;
        en_conv18 <= 0;
        en_conv19 <= 0;
        en_convd2 <= 0;
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
                if (flag_thrH13)
                begin
                    input_batnoh13 <= input_data;
                    en_batnoh13 <= 1;
                    if (flag_batnoh13)
                    begin
                        input_conv14 <= output_batnoh13;
                        state <= 1;
                        en_batnoh13 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv14 <= 1;
                if (flag_conv14)
                begin
                    input_batnor14 <= output_conv14;
                    state <= 2;
                    en_conv14 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR14)
                begin
                    en_batnor14 <= 1;
                    if (flag_batnor14)
                    begin
                        input_conv15 <= output_batnor14;
                        state <= 3;
                        en_batnor14 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv15 <= 1;
                if (flag_conv15)
                begin
                    input_int <= output_conv15;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv15 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor15 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor15 <= 1;
                if (flag_batnor15)
                begin
                    x_add <= output_batnor15;
                    state <= 5;
                    en_batnor15 <= 0;
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
                if (flag_thrH15)
                begin
                    input_batnoh15 <= output_L1;
                    en_batnoh15 <= 1;
                    if (flag_batnoh15)
                    begin
                        input_conv16 <= output_batnoh15;
                        state <= 1;
                        en_batnoh15 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv16 <= 1;
                if (flag_conv16)
                begin
                    input_batnor16 <= output_conv16;
                    state <= 2;
                    en_conv16 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR16)
                begin
                    en_batnor16 <= 1;
                    if (flag_batnor16)
                    begin
                        input_conv17 <= output_batnor16;
                        state <= 3;
                        en_batnor16 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv17 <= 1;
                if (flag_conv17)
                begin
                    input_int <= output_conv17;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv17 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor17 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor17 <= 1;
                if (flag_batnor17)
                begin
                    x_add <= output_batnor17;
                    state <= 5;
                    en_batnor17 <= 0;
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
                if (flag_thrH17)
                begin
                    input_batnoh17 <= output_L2;
                    en_batnoh17 <= 1;
                    if (flag_batnoh17)
                    begin
                        input_conv18 <= output_batnoh17;
                        state <= 1;
                        en_batnoh17 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv18 <= 1;
                if (flag_conv18)
                begin
                    input_batnor18 <= output_conv18;
                    state <= 2;
                    en_conv18 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR18)
                begin
                    en_batnor18 <= 1;
                    if (flag_batnor18)
                    begin
                        input_conv19 <= output_batnor18;
                        state <= 3;
                        en_batnor18 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv19 <= 1;
                if (flag_conv19)
                begin
                    input_int <= output_conv19;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv19 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor19 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor19 <= 1;
                if (flag_batnor19)
                begin
                    x_add <= output_batnor19;
                    state <= 5;
                    en_batnor19 <= 0;
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