/*
    This part corresponds the Tensorflow part:
    x=x+self.batnor03(self.conv03(self.actv02(self.batnor02(self.conv02(self.actv01(self.batnoh01(x,training=training))),training=training))),training=training)
    x=x+self.batnor05(self.conv05(self.actv04(self.batnor04(self.conv04(self.actv03(self.batnoh03(x,training=training))),training=training))),training=training)
    x=x+self.batnor07(self.conv07(self.actv06(self.batnor06(self.conv06(self.actv05(self.batnoh05(x,training=training))),training=training))),training=training)
*/


`timescale 1ns / 1ps

module cifar10L2(
    input clk,
    input rst_n,
    input en,
    input [32*32*16*32-1:0] input_data,     // floating data
    output reg flag,
    output reg [32*32*16*32-1:0] output_data    // actually the same size
    );

    parameter IM_LENTH = 32;
    parameter IM_DEPTH = 16;    // stick on this size
    parameter KN_LENTH = 3; // size of the kernel
    parameter KN_OC = 16;   // output channel

    reg flag_thrH01;
    reg flag_thrH02;
    reg flag_thrH03;
    reg flag_thrR02;
    reg flag_thrR04;
    reg flag_thrR06;

    reg [1:0] level;
    reg [2:0] state;

    reg [32*32*16*32-1:0] output_L1;
    reg [32*32*16*32-1:0] output_L2;
    reg [32*32*16*32-1:0] output_L3;

////////// reg for thr calculation ////////////////
    reg [31:0] gamma_batnor02    [15:0];
    reg [31:0] gamma_batnor04    [15:0];
    reg [31:0] gamma_batnor06    [15:0];
    reg [31:0] gamma_batnoh01    [15:0];
    reg [31:0] gamma_batnoh03    [15:0];
    reg [31:0] gamma_batnoh05    [15:0];
    reg [31:0] beta_batnor02     [15:0];
    reg [31:0] beta_batnor04     [15:0];
    reg [31:0] beta_batnor06     [15:0];
    reg [31:0] beta_batnoh01     [15:0];
    reg [31:0] beta_batnoh03     [15:0];
    reg [31:0] beta_batnoh05     [15:0];
    reg [31:0] mean_batnor02     [15:0];
    reg [31:0] mean_batnor04     [15:0];
    reg [31:0] mean_batnor06     [15:0];
    reg [31:0] mean_batnoh01     [15:0];
    reg [31:0] mean_batnoh03     [15:0];
    reg [31:0] mean_batnoh05     [15:0];
    reg [31:0] variance_batnor02 [15:0];
    reg [31:0] variance_batnor04 [15:0];
    reg [31:0] variance_batnor06 [15:0];
    reg [31:0] variance_batnoh01 [15:0];
    reg [31:0] variance_batnoh03 [15:0];
    reg [31:0] variance_batnoh05 [15:0];

    reg [16*32-1:0] thr_batnoh01;
    reg [16*32-1:0] thr_batnoh03;
    reg [16*32-1:0] thr_batnoh05;
    reg [16*8-1:0] thr_batnor02;
    reg [16*8-1:0] thr_batnor04;
    reg [16*8-1:0] thr_batnor06;

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
    reg en_batnor02;
    reg en_batnor03;
    reg en_batnor04;
    reg en_batnor05;
    reg en_batnor06;
    reg en_batnor07;
    reg en_batnoh01;
    reg en_batnoh03;
    reg en_batnoh05;

    reg [32*32*16*32-1:0] input_batnor03;
    reg [32*32*16*32-1:0] input_batnor05;
    reg [32*32*16*32-1:0] input_batnor07;
    reg [32*32*16*8-1:0] input_batnor02;
    reg [32*32*16*8-1:0] input_batnor04;
    reg [32*32*16*8-1:0] input_batnor06;
    reg [32*32*16*32-1:0] input_batnoh01;
    reg [32*32*16*32-1:0] input_batnoh03;
    reg [32*32*16*32-1:0] input_batnoh05;

    wire [32*32*16*32-1:0] output_batnor03;
    wire [32*32*16*32-1:0] output_batnor05;
    wire [32*32*16*32-1:0] output_batnor07;
    wire [32*32*16-1:0] output_batnor02;
    wire [32*32*16-1:0] output_batnor04;
    wire [32*32*16-1:0] output_batnor06;
    wire [32*32*16-1:0] output_batnoh01;
    wire [32*32*16-1:0] output_batnoh03;
    wire [32*32*16-1:0] output_batnoh05;

    wire flag_batnor03;
    wire flag_batnor05;
    wire flag_batnor07;
    wire flag_batnor02;
    wire flag_batnor04;
    wire flag_batnor06;
    wire flag_batnoh01;
    wire flag_batnoh03;
    wire flag_batnoh05;

////////// reg and wire for biconv //////////////
    reg en_conv02;
    reg en_conv03;
    reg en_conv04;
    reg en_conv05;
    reg en_conv06;
    reg en_conv07;

    reg [32*32*16-1:0] input_conv02;
    reg [32*32*16-1:0] input_conv03;
    reg [32*32*16-1:0] input_conv04;
    reg [32*32*16-1:0] input_conv05;
    reg [32*32*16-1:0] input_conv06;
    reg [32*32*16-1:0] input_conv07;

    wire [32*32*16*8-1:0] output_conv02;
    wire [32*32*16*8-1:0] output_conv03;
    wire [32*32*16*8-1:0] output_conv04;
    wire [32*32*16*8-1:0] output_conv05;
    wire [32*32*16*8-1:0] output_conv06;
    wire [32*32*16*8-1:0] output_conv07;

    wire flag_conv02;
    wire flag_conv03;
    wire flag_conv04;
    wire flag_conv05;
    wire flag_conv06;
    wire flag_conv07;

////////// batch normalization, 9 in total (3 in fully precision, and 6 in binary style) /////////////
    batnor #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_128.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_129.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_130.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_131.txt")
    )batnor03(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor03),
        .input_data  (input_batnor03),
        .output_data (output_batnor03),
        .flag   (flag_batnor03)
    );

    batnor #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_136.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_137.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_138.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_139.txt")
    )batnor05(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor05),
        .input_data  (input_batnor05),
        .output_data (output_batnor05),
        .flag   (flag_batnor05)
    );

    batnor #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .GAMMA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_144.txt"),
        .BETA_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_145.txt"),
        .MEAN_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_146.txt"),
        .VARIANCE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_147.txt")
    )batnor07(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor07),
        .input_data  (input_batnor07),
        .output_data (output_batnor07),
        .flag   (flag_batnor07)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH),
        .IM_DEPTH (IM_DEPTH)
    )batnoh01(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh01),
        .input_data    (input_batnoh01),

        .thr  (thr_batnoh01),

        .output_data    (output_batnoh01),
        .flag           (flag_batnoh01)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH),
        .IM_DEPTH (IM_DEPTH)
    )batnor02(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor02),
        .input_data    (input_batnor02),

        .thr  (thr_batnor02),

        .output_data    (output_batnor02),
        .flag           (flag_batnor02)
    );

    bibatnorFLOAT #(
        .IM_LENTH (IM_LENTH),
        .IM_DEPTH (IM_DEPTH)
    )batnoh03(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh03),
        .input_data    (input_batnoh03),

        .thr  (thr_batnoh03),

        .output_data    (output_batnoh03),
        .flag           (flag_batnoh03)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH),
        .IM_DEPTH (IM_DEPTH)
    )batnor04(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor04),
        .input_data    (input_batnor04),

        .thr  (thr_batnor04),

        .output_data    (output_batnor04),
        .flag           (flag_batnor04)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH),
        .IM_DEPTH (IM_DEPTH)
    )batnoh05(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnoh05),
        .input_data    (input_batnoh05),

        .thr  (thr_batnoh05),

        .output_data    (output_batnoh05),
        .flag           (flag_batnoh05)
    );

    bibatnorINT #(
        .IM_LENTH (IM_LENTH),
        .IM_DEPTH (IM_DEPTH)
    )batnor06(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_batnor06),
        .input_data    (input_batnor06),

        .thr  (thr_batnor06),

        .output_data    (output_batnor06),
        .flag           (flag_batnor06)
    );

////////// convolution, 6 in total (all in binary style), size = 3*3*16*16 /////////////
    biconv #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_2.txt")
    )conv02(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv02),
        .input_data     (input_conv02),
        .output_data    (output_conv02),
        .flag           (flag_conv02)
    );

    biconv #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_6.txt")
    )conv03(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv03),
        .input_data     (input_conv03),
        .output_data    (output_conv03),
        .flag           (flag_conv03)
    );

    biconv #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_10.txt")
    )conv04(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv04),
        .input_data     (input_conv04),
        .output_data    (output_conv04),
        .flag           (flag_conv04)
    );

    biconv #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_14.txt")
    )conv05(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv05),
        .input_data     (input_conv05),
        .output_data    (output_conv05),
        .flag           (flag_conv05)
    );

    biconv #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_18.txt")
    )conv06(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv06),
        .input_data     (input_conv06),
        .output_data    (output_conv06),
        .flag           (flag_conv06)
    );

    biconv #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH),
        .KN_LENTH(KN_LENTH),
        .KN_OC(KN_OC),
        .STRIDE(1),
        .FILE_NAME("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_22.txt")
    )conv07(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_conv07),
        .input_data     (input_conv07),
        .output_data    (output_conv07),
        .flag           (flag_conv07)
    );

////////// floating calculation ////////////////
    subfloat L2_sub(
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

    divfloat L2_div(
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
    reg [32*32*16*8-1:0] input_int;
    wire [32*32*16*32-1:0] output_float;
    wire flag_tsf;

    inttofloat #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH)
    )L2_inttofloat(
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en_tsf),
        .input_data     (input_int),
        .output_data    (output_float),
        .flag   (flag_tsf)
    );

    reg en_xadd;
    reg [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] x_self;
    reg [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] x_add;
    wire [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] output_xadd;
    wire flag_xadd;

    xadd #(
        .IM_LENTH(IM_LENTH),
        .IM_DEPTH(IM_DEPTH)
    )L2_xadd(
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
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_124.txt", gamma_batnor02);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_132.txt", gamma_batnor04);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_140.txt", gamma_batnor06);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_196.txt", gamma_batnoh01);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_200.txt", gamma_batnoh03);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_204.txt", gamma_batnoh05);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_125.txt", beta_batnor02);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_133.txt", beta_batnor04);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_141.txt", beta_batnor06);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_197.txt", beta_batnoh01);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_201.txt", beta_batnoh03);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_205.txt", beta_batnoh05);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_126.txt", mean_batnor02);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_134.txt", mean_batnor04);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_142.txt", mean_batnor06);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_198.txt", mean_batnoh01);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_202.txt", mean_batnoh03);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_206.txt", mean_batnoh05);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_127.txt", variance_batnor02);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_135.txt", variance_batnor04);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_143.txt", variance_batnor06);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_199.txt", variance_batnoh01);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_203.txt", variance_batnoh03);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_207.txt", variance_batnoh05);
end

// calculate thr value
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        flag_thrH01 <= 0;
        flag_thrH02 <= 0;
        flag_thrH03 <= 0;
        flag_thrR02 <= 0;
        flag_thrR04 <= 0;
        flag_thrR06 <= 0;
        thr_batnoh01 <= 0;
        thr_batnoh03 <= 0;
        thr_batnoh05 <= 0;
        thr_batnor02 <= 0;
        thr_batnor04 <= 0;
        thr_batnor06 <= 0;

        div1_valid <= 0;
        div2_valid <= 0;
        s1_valid <= 0;
        s2_valid <= 0;
        sub_result_ready <= 0;
        thr_loop <= 0;
    end

    else
    begin
        if (!flag_thrH01)
        begin
            if (thr_loop < IM_DEPTH)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh01[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh01[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh01[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh01[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH01 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrH02)
        begin
            if (thr_loop < IM_DEPTH)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh03[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh03[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh03[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh03[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH02 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrH03)
        begin
            if (thr_loop < IM_DEPTH)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnoh05[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnoh05[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnoh05[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    thr_batnoh05[thr_loop*32+31-:32] <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrH03 <= 1;
                thr_loop <= 0;
            end
        end
        
        else if (!flag_thrR02)
        begin
            if (thr_loop < IM_DEPTH)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor02[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor02[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor02[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor02[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR02 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrR04)
        begin
            if (thr_loop < IM_DEPTH)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor04[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor04[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor04[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor04[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR04 <= 1;
                thr_loop <= 0;
            end
        end

        else if (!flag_thrR06)
        begin
            if (thr_loop < IM_DEPTH)
            begin
                if (!sub_flag)
                begin
                    if (!div_flag)
                    begin
                        div1_data <= gamma_batnor06[thr_loop];
                        div1_valid <= 1;
                        div2_data <= beta_batnor06[thr_loop];
                        div2_valid <= 1;
                    end
                    else if (div_flag)
                    begin
                        s2_data <= div_result;
                        div1_valid <= 0;
                        div2_valid <= 0;
                        s2_valid <= 1;
                        s1_data <= mean_batnor06[thr_loop];
                        s1_valid <= 1;
                        sub_result_ready <= 1;
                    end
                end
                else if (sub_flag)
                begin
                    float_in <= sub_result;
                    thr_batnor06[thr_loop*8+7-:8] <= int_out;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    thr_loop <= thr_loop + 1;
                end
            end
            else
            begin
                flag_thrR06 <= 1;
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
        en_batnoh01 <= 0;
        en_batnoh03 <= 0;
        en_batnoh05 <= 0;
        en_batnor02 <= 0;
        en_batnor03 <= 0;
        en_batnor04 <= 0;
        en_batnor05 <= 0;
        en_batnor06 <= 0;
        en_batnor07 <= 0;
        en_conv02 <= 0;
        en_conv03 <= 0;
        en_conv04 <= 0;
        en_conv05 <= 0;
        en_conv06 <= 0;
        en_conv07 <= 0;
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
                if (flag_thrH01)
                begin
                    input_batnoh01 <= input_data;
                    en_batnoh01 <= 1;
                    if (flag_batnoh01)
                    begin
                        input_conv02 <= output_batnoh01;
                        state <= 1;
                        en_batnoh01 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv02 <= 1;
                if (flag_conv02)
                begin
                    input_batnor02 <= output_conv02;
                    state <= 2;
                    en_conv02 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR02)
                begin
                    en_batnor02 <= 1;
                    if (flag_batnor02)
                    begin
                        input_conv03 <= output_batnor02;
                        state <= 3;
                        en_batnor02 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv03 <= 1;
                if (flag_conv03)
                begin
                    input_int <= output_conv03;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv03 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor03 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor03 <= 1;
                if (flag_batnor03)
                begin
                    x_add <= output_batnor03;
                    state <= 5;
                    en_batnor03 <= 0;
                end
            end

            else if (state == 5)     // x add
            begin
                en_xadd <= 1;
                x_self <= input_data;
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
                if (flag_thrH02)
                begin
                    input_batnoh03 <= output_L1;
                    en_batnoh03 <= 1;
                    if (flag_batnoh03)
                    begin
                        input_conv04 <= output_batnoh03;
                        state <= 1;
                        en_batnoh03 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv04 <= 1;
                if (flag_conv04)
                begin
                    input_batnor04 <= output_conv04;
                    state <= 2;
                    en_conv04 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR04)
                begin
                    en_batnor04 <= 1;
                    if (flag_batnor04)
                    begin
                        input_conv05 <= output_batnor04;
                        state <= 3;
                        en_batnor04 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv05 <= 1;
                if (flag_conv05)
                begin
                    input_int <= output_conv05;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv05 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor05 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor05 <= 1;
                if (flag_batnor05)
                begin
                    x_add <= output_batnor05;
                    state <= 5;
                    en_batnor05 <= 0;
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
                if (flag_thrH03)
                begin
                    input_batnoh05 <= output_L2;
                    en_batnoh05 <= 1;
                    if (flag_batnoh05)
                    begin
                        input_conv06 <= output_batnoh05;
                        state <= 1;
                        en_batnoh05 <= 0;
                    end
                end
            end

            else if (state == 1)    // conv
            begin
                en_conv06 <= 1;
                if (flag_conv06)
                begin
                    input_batnor06 <= output_conv06;
                    state <= 2;
                    en_conv06 <= 0;
                end
            end

            else if (state == 2)    // batnor (bibatnorINT) + actv
            begin
                if (flag_thrR06)
                begin
                    en_batnor06 <= 1;
                    if (flag_batnor06)
                    begin
                        input_conv07 <= output_batnor06;
                        state <= 3;
                        en_batnor06 <= 0;
                    end
                end
            end

            else if (state == 3)    // conv
            begin
                en_conv07 <= 1;
                if (flag_conv07)
                begin
                    input_int <= output_conv07;    // need to change the type from int to float
                    en_tsf <= 1;
                    en_conv07 <= 0;
                end

                if (flag_tsf)
                begin
                    input_batnor07 <= output_float;
                    state <= 4;
                    en_tsf <= 0;
                end
            end

            else if (state == 4)    // batnor (fully)
            begin
                en_batnor07 <= 1;
                if (flag_batnor07)
                begin
                    x_add <= output_batnor07;
                    state <= 5;
                    en_batnor07 <= 0;
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