`timescale 1ns / 1ps

module convd #(
    parameter IM_LENTH = 32,
    parameter IM_DEPTH = 16,
    parameter KN_LENTH = 1,
    parameter KN_OC = 32,
    parameter STRIDE = 2,
    parameter FILE_NAME = "arr_74.txt",
    parameter NMK_NAME = "arr_75.txt"
)(
    input clk,
    input rst_n,
    input en,
    input [IM_LENTH * IM_LENTH * IM_DEPTH * 32 -1:0] input_data,
    output reg [IM_LENTH/STRIDE * IM_LENTH/STRIDE * KN_OC * 32 -1:0] output_data,
    output reg flag
    );

integer i,j,k,l,m,n,o,p;
integer state;
localparam PADDING = (KN_LENTH-1)/2;
localparam PADDED_LENTH = IM_LENTH + PADDING;

reg kernel [KN_LENTH*KN_LENTH*IM_DEPTH*KN_OC-1:0];
reg [31:0] nmk;

reg [31:0] input_matrix [0:PADDED_LENTH-1][0:PADDED_LENTH-1][0:IM_DEPTH-1];
reg kernel_matrix [0:KN_LENTH-1][0:KN_LENTH-1][0:IM_DEPTH-1][0:KN_OC-1];
reg [31:0] conv_result [0:IM_LENTH/STRIDE-1][0:IM_LENTH/STRIDE-1][0:KN_OC-1];

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
integer nmk_txt;

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

initial 
begin
    $readmemh(FILE_NAME, kernel);
    nmk_txt = $fopen(NMK_NAME, "r");
    if (nmk_txt!= 0) begin
        $fscanf(nmk_txt, "%d", nmk);
        $fclose(nmk_txt);
    end
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        flag <= 0;
        output_data <= 0;
        state <= 0;
        i<=0;j<=0;k<=0;l<=0;m<=0;n<=0;o<=0;p<=0;

        for (i = 0; i < PADDED_LENTH; i = i + 1) begin
            for (j = 0; j < PADDED_LENTH; j = j + 1) begin
                for (k = 0; k < IM_DEPTH; k = k + 1) begin
                    input_matrix[i][j][k] <= 0;
                end
            end
        end
        for (i = 0; i < KN_LENTH; i = i + 1) begin
            for (j = 0; j < KN_LENTH; j = j + 1) begin
                for (k = 0; k < IM_DEPTH; k = k + 1) begin
                    for (l = 0; l < KN_OC; l = l + 1) begin
                        kernel_matrix[i][j][k][l] <= 0;
                    end
                end
            end
        end
        for (i = 0; i < IM_LENTH/STRIDE; i = i + 1) begin
            for (j = 0; j < IM_LENTH/STRIDE; j = j + 1) begin
                for (k = 0; k < KN_OC; k = k + 1) begin
                    conv_result[i][j][k] <= 0;
                end
            end
        end

        m2_data <= nmk;
        m2_valid <= 1;
    end

    else        
    begin       
        if (state == 0)     // load the input data into padded input matrix
        begin
            if (i < IM_LENTH) begin
                if  (j < IM_LENTH) begin
                    if (k < IM_DEPTH) begin
                        input_matrix[i+PADDING][j+PADDING][k][31:0] <= input_data[(i*IM_LENTH*IM_DEPTH + j*IM_DEPTH + k)*32 + 31-:32];
                        k = k + 1;
                    end
                    else 
                    begin
                        k = 0;
                        j = j + 1;
                    end
                end
                else
                begin
                    j = 0;
                    i = i + 1;
                end
            end
            else
            begin
                i = 0;
                state = 1;
            end
        end

        else if (state == 1)    // load the kernel data into padded input matrix
        begin
            if(i < KN_LENTH) begin
                if (j < KN_LENTH) begin
                    if (k < IM_DEPTH) begin
                        if (l < KN_OC) begin
                            kernel_matrix[i][j][k][l] <= kernel[(i*KN_LENTH*IM_DEPTH*KN_OC + j*IM_DEPTH*KN_OC + k*KN_OC + l)];
                            l = l + 1;
                        end
                        else
                        begin
                            l = 0;
                            k = k + 1;
                        end
                    end
                    else
                    begin
                        k = 0;
                        j = j + 1;
                    end
                end
                else 
                begin
                    i = i + 1;
                    j = 0;
                end
            end
            else
            begin
                i = 0;
                state = 2;
            end
        end

        // calculate: this huge circulation should be seperated into serial circuit
        else if (state == 2)
        begin
            if (i < IM_LENTH/STRIDE) begin
                if (j < IM_LENTH/STRIDE) begin
                    if (l < KN_OC) begin
                        // if (m == 0 && n == 0 && o == 0)
                        //     conv_result[i][j][l] <= 0;
                        if (m < KN_LENTH) begin
                            if (n < KN_LENTH) begin
                                if (o < IM_DEPTH) begin     // input_matrix is floating here, 
                                    if (!kernel_matrix[m][n][o][l])  // 0: minus, 1: plus
                                    begin
                                        input_matrix[i*STRIDE+m][j*STRIDE+n][o][31] <= ~input_matrix[i*STRIDE+m][j*STRIDE+n][o][31];
                                    end
                                    a1_data <= conv_result[i][j][l];
                                    a2_data <= input_matrix[i*STRIDE+m][j*STRIDE+n][o];
                                    add_valid <= 1;
                                    if (add_flag)
                                    begin
                                        conv_result[i][j][l] <= add_result;
                                        o <= o + 1;
                                        add_valid <= 0;
                                    end
                                end
                                else
                                begin
                                    n <= n + 1;
                                    o <= 0;
                                end
                            end
                            else
                            begin
                                n <= 0;
                                m <= m + 1;
                            end
                        end
                        else
                        begin
                            // conv_result[i][j][l] <= 2 * conv_result[i][j][l] - KN_LENTH*KN_LENTH*IM_DEPTH;
                            m1_data <= conv_result[i][j][l];
                            m1_valid <= 1;
                            if (mul_flag) begin
                                conv_result[i][j][l] <= mul_result;
                                m1_valid <= 0;
                                m <= 0;
                                l <= l + 1;
                            end
                        end
                    end
                    else
                    begin
                        l <= 0;
                        j <= j + 1;
                    end
                end
                else
                begin
                    j <= 0;
                    i <= i + 1;
                end
            end
            else
            begin
                i <= 0;
                state <= 3;
            end
        end

        else if (state == 3)    // store into output data
        begin
            if (i < IM_LENTH/STRIDE) begin
                if (j < IM_LENTH/STRIDE) begin
                    if (l < KN_OC) begin
                        output_data[(i*IM_LENTH/STRIDE*KN_OC + j*KN_OC + l)*32+31 -: 32] <= conv_result[i][j][l][31:0];
                        l <= l + 1;
                    end
                    else
                    begin
                        l <= 0;
                        j <= j + 1;
                    end
                end
                else
                begin
                    j <= 0;
                    i <= i + 1;
                end
            end
            else
            begin
                i <= 0;
                state <= 0;
                flag <= 1;
            end
        end
    end
end



endmodule
