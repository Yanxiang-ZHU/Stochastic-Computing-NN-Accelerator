`timescale 1ns / 1ps

module biconv#(
    parameter IM_LENTH = 32,
    parameter IM_DEPTH = 16,
    parameter KN_LENTH = 3,
    parameter KN_OC = 16,
    parameter STRIDE = 1,
    parameter FILE_NAME = "arr_2.txt"
)(
    input clk,
    input rst_n,
    input en,
    input [IM_LENTH*IM_LENTH*IM_DEPTH-1:0] input_data,
    // input [KN_LENTH*KN_LENTH*IM_DEPTH*KN_OC-1:0] kernel,
    output reg [IM_LENTH / STRIDE *IM_LENTH / STRIDE*KN_OC*8-1:0] output_data,
    output reg flag
    );

integer i,j,k,l,m,n,o,p;
integer state;
localparam PADDING = (KN_LENTH-1)/2;
localparam PADDED_LENTH = IM_LENTH + PADDING;

reg kernel [KN_LENTH*KN_LENTH*IM_DEPTH*KN_OC-1:0];
reg input_matrix [0:PADDED_LENTH-1][0:PADDED_LENTH-1][0:IM_DEPTH-1];
reg kernel_matrix [0:KN_LENTH-1][0:KN_LENTH-1][0:IM_DEPTH-1][0:KN_OC-1];
reg signed [7:0] conv_result [0:IM_LENTH/STRIDE-1][0:IM_LENTH/STRIDE-1][0:KN_OC-1];

initial 
begin
    $readmemh(FILE_NAME, kernel);
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
    end

    else        
    begin       
        if (state == 0)     // load the input data into padded input matrix
        begin
            if (i < IM_LENTH) begin
                if  (j < IM_LENTH) begin
                    if (k < IM_DEPTH) begin
                        input_matrix[i+PADDING][j+PADDING][k] <= input_data[(i*IM_LENTH*IM_DEPTH + j*IM_DEPTH + k)*8];
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
                                for (o = 0; o < IM_DEPTH; o = o + 1) begin
                                    conv_result[i][j][l] <= conv_result[i][j][l] + (~(input_matrix[i*STRIDE+m][j*STRIDE+n][o] ^ kernel_matrix[m][n][o][l]));
                                end
                                n <= n + 1;
                            end
                            else
                            begin
                                n <= 0;
                                m <= m + 1;
                            end
                        end
                        else
                        begin
                            conv_result[i][j][l] <= 2 * conv_result[i][j][l] - KN_LENTH*KN_LENTH*IM_DEPTH;
                            m <= 0;
                            l <= l + 1;
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
                        output_data[(i*IM_LENTH/STRIDE*KN_OC + j*KN_OC + l)*8+7 -: 8] <= conv_result[i][j][l][7:0];
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