`timescale 1ns / 1ps

module dense #(
    parameter DATA_WIDTH = 32,
    parameter OUTPUT_NODES = 10
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [64*32-1:0] input_dense,  // the size of input_dense will be 64 * 32(size of floating number)
    output reg [10*32-1:0] output_dense, // the size of output_dense will be 10 *32(size of floating number)
    output reg flag
    );

reg [31:0] dense_wt   [0:639];         // the weight in the dense layer is stored in arr_82
reg [31:0] dense_bias [0:9];

reg en_mul1;
reg en_mul2;
reg [31:0] mul1;
reg [31:0] mul2;
wire flag_mul;
wire [31:0] output_mul;

reg en_add;
reg [31:0] add1;
reg [31:0] add2;
wire flag_add;
wire [31:0] output_add;

reg [3:0] oper_num;     
reg [7:0] in_num;      

integer i;

initial
begin
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_82.txt", dense_wt);
    $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_83.txt", dense_bias);
end

mulfloat mul_dense(
    .clk(clk),
    .a_tvalid(en_mul1),
    .a_tdata(mul1),
    .b_tvalid(en_mul2),
    .b_tdata(mul2),
    .mul_result_tvalid(flag_mul),
    .mul_result_tdata(output_mul)
);

addfloat add_dense(
    .clk(clk),
    // .a_tvalid(),
    .a_tdata(add1),
    // .b_tvalid(),
    .b_tdata(add2),
    .operation_tvalid(en_add),
    // .operation_tdata(),
    .result_tvalid(flag_add),
    .result_tdata(output_add)
);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        flag <= 0;
        output_dense <= 0;
        oper_num <= 0;
        in_num <= 64;

        en_mul1 <= 0;
        en_mul2 <= 0;
        en_add <= 0;
    end

    else
    begin
        // determine the value of each 10 output numbers one by one -- 64 multiplication and 64-1+1(bias) addition. So 640 muls and 640 adds in total
        if (oper_num < 10)
        begin
            // store in output_dense[((10-i)*32-1)-:32]
            if (in_num < 64)
            begin
                // maybe there is a question here!! need to check whether the mul/add are blocked or not blocked
                mul1 <= input_dense[((64-in_num)*32-1)-:32];
                mul2 <= dense_wt[oper_num*64+in_num];
                en_mul1 <= 1;
                en_mul2 <= 1;

                if(flag_mul)
                begin
                    add1 <= output_mul;
                    add2 <= output_dense[((10-oper_num)*32-1)-:32];
                    en_add <= 1;

                    if (flag_add)
                    begin
                        output_dense[((10-oper_num)*32-1)-:32] <= output_add;
                    end
                end

                en_mul1 <= 0;
                en_mul2 <= 0;
                en_add <= 0;
                in_num <= in_num + 1;
            end

            else if (in_num == 64)
            begin
                // plus bias
                add1 <= output_dense[((10-oper_num)*32-1)-:32];
                add2 <= dense_bias[oper_num];
                en_add <= 1;

                if (flag_add)
                begin
                    output_dense[((10-oper_num)*32-1)-:32] <= output_add;
                end
                en_add <= 0;

                oper_num <= oper_num + 1;
                in_num <= 0;
            end
        end

        else if (oper_num == 10)
        begin
            flag <= 1;
        end
    end
end



endmodule
