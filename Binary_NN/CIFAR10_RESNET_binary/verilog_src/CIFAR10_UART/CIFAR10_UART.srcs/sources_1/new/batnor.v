`timescale 1ns / 1ps

module batnor#(
    parameter IM_LENTH = 32,    // example for batnor1
    parameter IM_DEPTH = 16,
    parameter GAMMA_NAME = "C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_128.txt",
    parameter BETA_NAME = "C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_129.txt",
    parameter MEAN_NAME = "C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_130.txt",
    parameter VARIANCE_NAME = "C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_131.txt"
)(
    input clk,
    input rst_n,
    input en,
    input [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] input_data,           // size: [IM_LENTH*IM_LENTH*IM_DEPTH-1:0] * 32bit

    output reg [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] output_data,     // size: [IM_LENTH*IM_LENTH*IM_DEPTH-1:0] * 32bit
    output reg flag
    );

    localparam epsilon = 32'b00110111001001111100010110101100;  // represent 0.00001

    reg level;          // level should cover 0 to IM_DEPTH-1

    reg [31:0] gamma [IM_DEPTH- 1:0];
    reg [31:0] beta [IM_DEPTH- 1:0];
    reg [31:0] mean [IM_DEPTH- 1:0];
    reg [31:0] variance [IM_DEPTH- 1:0];

    reg [31:0] a1_data;
    reg [31:0] a2_data;
    reg add_valid;
    wire add_flag;
    wire [31:0] add_result;

    reg [31:0] m1_data;
    reg [31:0] m2_data;
    reg m1_valid;
    reg m2_valid;
    wire mul_flag;
    wire [31:0] mul_result;

    reg [31:0] square_valid;
    reg square_data;
    reg square_result_ready;
    wire square_ready;
    wire square_flag;
    wire square_result;

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

    reg [31:0] slope;
    reg [31:0] intercept;
    reg [2:0] state;
    reg pre;
    reg [10:0] element;     // the size should be enough for it
    reg element_state;

    addfloat batnor_add(
        .clk    (clk),
        .a_tdata    (a1_data),
        .b_tdata    (a2_data),
        .operation_tvalid   (add_valid),
        .result_tvalid      (add_flag),
        .result_tdata       (add_result)
    );

    mulfloat batnor_mul(
        .clk        (clk),
        .a_tvalid   (m1_valid),
        .a_tdata    (m1_data),
        .b_tvalid   (m2_valid),
        .b_tdata    (m2_data),
        .mul_result_tvalid  (mul_flag),
        .mul_result_tdata   (mul_result)
    );

    squarefloat batnor_square(
        .clk        (clk),
        .a_tvalid   (square_valid),
        .a_tdata    (square_data),
        .result_ready   (square_result_ready),
        .a_tready   (square_ready),
        .result_tvalid  (square_flag),
        .result_data    (square_result)
    );

    subfloat batnor_sub(
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

    divfloat batnor_div(
        .clk    (clk),
        .a_tvalid   (div1_valid),
        .a_tdata    (div1_data),
        .b_tvalid   (div2_valid),
        .b_tdata    (div2_data),
        .div_result_tvalid  (div_flag),
        .div_result_tdata   (div_result)
    );

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n || !en)      // initialization
        begin
            level <= 0;
            flag <= 0;
            state <= 0;
            pre <= 1;
            element_state <= 0;
            output_data <= 0;
        end

        else if (level < IM_DEPTH)      // serial processing each (32*32) layer
        begin
            // get the slope(k) and intercept(b)
            if (pre && state == 0)     // add
            begin
                a1_data <= variance[((IM_DEPTH-level)-1)];
                a2_data <= epsilon;
                add_valid <= 1;

                if (add_flag)
                begin
                    state <= 1;
                    square_data <= add_result;
                    add_valid <= 0;
                end
            end

            else if (pre && state == 1)        // square
            begin
                square_valid <= 1;
                square_result_ready <= 1;

                if (square_flag)
                begin
                    state <= 2;
                    div2_data <= square_result;
                    div2_valid <= 1;
                    square_valid <= 0;
                    square_result_ready <= 0;
                end
            end

            else if (pre && state == 2)        // div
            begin
                div1_data <= gamma[((IM_DEPTH-level)-1)];
                div1_valid <= 1;
                
                if (div_flag)
                begin
                    state <= 3;
                    slope <= div_result;
                    div1_valid <= 0;
                    div2_valid <= 0;
                end
            end

            else if (pre && state == 3)
            begin
                m1_data <= slope;
                m1_valid <= 1;
                m2_data <= mean[((IM_DEPTH-level)-1)];
                m2_data <= 1;
                
                if (mul_flag)
                begin
                    state <= 4;
                    s2_data <= mul_result;
                    s2_valid <= 1;
                    m1_valid <= 0;
                    m2_valid <= 0;
                end                
            end

            else if (pre && state == 4)    // sub
            begin
                s1_data <= beta[((IM_DEPTH-level)-1)];
                s1_valid <= 1;
                sub_result_ready <= 1;

                if (sub_flag)
                begin
                    state <= 0;
                    intercept <= sub_result;
                    s1_valid <= 0;
                    s2_valid <= 0;
                    sub_result_ready <= 0;
                    pre <= 0;
                end
            end
            // a full layer loop to calculate each element(32*32 mul and add) ---- we can seek for parallel processing here
            else if (!pre && element < IM_LENTH*IM_LENTH)
            begin
                if (!element_state)
                begin
                    a1_data <= intercept;

                    m1_data <= slope;
                    m1_valid <= 1;
                    m2_data <= input_data[(((IM_DEPTH-level)*IM_LENTH*IM_LENTH-element)*32-1)-:32];
                    m2_valid <= 1;

                    if (mul_flag)
                    begin
                        a2_data <= mul_result;
                        add_valid <= 1;
                        m1_valid <= 0;
                        m2_valid <= 0;
                        element_state <= 1;
                    end
                end

                else if (element_state)
                begin
                    if (add_flag)
                    begin
                        output_data[(((IM_DEPTH-level)*IM_LENTH*IM_LENTH-element)*32-1)-:32] <= add_result;
                        element_state <= 0;
                        add_valid <= 0;
                        element <= element + 1;
                    end
                end
            end

            else if (!pre && element == IM_LENTH*IM_LENTH)
            begin
                element <= 0;
                pre <= 1;
                element_state <= 0;
                state <= 0;
                level <= level + 1;
            end
        end

        else if (level == IM_DEPTH)
        begin
            flag <= 1;
            level <= 0;
        end
    end

endmodule
