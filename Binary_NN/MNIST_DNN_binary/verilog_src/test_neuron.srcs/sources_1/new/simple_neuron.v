`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/29 10:16:26
// Design Name: 
// Module Name: simple_neuron
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module simple_neuron(
input wire clk,
input wire rst_n,
input wire en,
input wire [783:0] in_neuron,
input wire [783:0] kernel,
input wire [9:0] bias,
output reg out_neuron,
output reg flag
    );
    integer i;
    integer j;
    reg [9:0] zero_count;
    reg [9:0] one_count;

    // integer step;
    // integer zero_count;
    // integer zero_count;
    // reg [31:0] rand_pos;
    // reg [31:0] lcg_seed;
    // reg [31:0] lcg_rand;
    // integer a = 1664525;
    // integer c = 1013904223;
    // integer m = 4294967296;
    
    integer count_zeros;
    integer count_ones;
    
    integer state;  //?????????
    reg [3:0] level;  //????????????
    
    //???????????��??

    // reg [780:0] addnum;
    reg [745:0] addnum;

    reg [783:0] in_neuron_t;

    reg flag3;
    reg flag5;

    //????Majority Gate??????
    //temp?????��?????????num?????��???????????

    // reg [1564:0] temp0;
    // wire [312:0] temp0_out;
    // reg [312:0] temp1;
    // reg [80:0] temp2;
    // reg [26:0] temp3;
    // reg [8:0] temp4;
    // reg [2:0] temp5;
    // reg temp6;
    reg [1529:0] temp0;
    wire [305:0] temp0_out;
    reg [305:0] temp1;
    reg [101:0] temp2;
    reg [33:0] temp3;
    
    // reg [10:0] num0;
    // reg [8:0] num1;
    // reg [6:0] num2;
    // reg [4:0] num3;
    // reg [3:0] num4;
    // reg [1:0] num5;
    // reg num6;  //?????out_neuron????

    //????????
    reg in3_a;
    reg in3_b;
    reg in3_c;
    wire in3_y;
    reg in5_a;
    reg in5_b;
    reg in5_c;
    reg in5_d;
    reg in5_e;
    wire in5_y;
    
    majority_gate3 three(
    .a  (in3_a),
    .b  (in3_b),
    .c  (in3_c),
    .y  (in3_y)
    );
    
    majority_gate5 five(
    .a  (in5_a),
    .b  (in5_b),
    .c  (in5_c),
    .d  (in5_d),
    .e  (in5_e),
    .y  (in5_y)
    );


    // generate
    //     genvar j;
    //     for (j = 0; j < 313; j = j + 1) begin: gen_state0
    //         majority_gate5 level0(
    //             .a  (temp0[j*5]),
    //             .b  (temp0[j*5+1]),
    //             .c  (temp0[j*5+2]),
    //             .d  (temp0[j*5+3]),
    //             .e  (temp0[j*5+4]),
    //             .y  (temp0_out[j])
    //         );
    //     end
    // endgenerate

    // generate
    //     genvar i;
    //     for (i = 0; i < 27; i = i + 1) begin: gen_state1
    //         majority_gate5 level0(
    //             .a  (temp2[j*5]),
    //             .b  (temp2[j*5+1]),
    //             .c  (temp2[j*5+2]),
    //             .d  (temp0[j*5+3]),
    //             .e  (temp0[j*5+4]),
    //             .y  (temp0_out[j])
    //         );
    //     end
    // endgenerate


    always @(posedge clk or negedge rst_n)
    if (!rst_n || !en)
    begin 
    //?????
        state <= 0;
        level <= 6;
        out_neuron <= 0;
        //????????��
        temp0 <= 0;
        addnum <= 0;
        in_neuron_t <=0;
        flag <= 0;
        // i = 0;
    end

    else
    begin 
        if (level == 6)
        begin
        //?????? ???? 784bit???????781bit?????????????1??0??784-2*bias??????
        //??????????1&2??bit?????????????????????????��??????????????????????temp0??
        //????????????????????bias-1???0???�?????�I??????781bit???1?????��????bit��??   ?????????????????��???????????????????????????????????
        // if (i == 0)
        // begin
        in_neuron_t = in_neuron ^ kernel;
        // zero_count = bias - 1; // Ҫ����� 0 ������
        // one_count = 781 - zero_count; // Ҫ����� 1 ������
        zero_count = bias - 19;
        one_count = 746 - zero_count;
        // addnum = 781'b0;
        addnum = 745'b0;

        // i = 1;
        // end
        // else if (i < 781) begin
        //     addnum[i] <= 1'b0;
        //     i = i + 1;
        // end
        // else
        // begin
            level = 7;
            j = 0;
        // end
        end

        else if (level == 7)
        begin
        // ���ȷ��� 0 �� 1
        // if( j < 781) begin
        if( j < 746) begin
            if ((j % 2 == 0 && zero_count > 0) || one_count == 0) begin
                addnum[j] <= 1'b0;
                zero_count <= zero_count - 1;
            end else begin
                addnum[j] <= 1'b1;
                one_count <= one_count - 1;
            end
            j = j + 1;
        end
        else
        begin
            level = 8;
        end
        end

        else if (level == 8)
        begin
        // temp0[0] <= in_neuron_t[0];
        // temp0[1] <= in_neuron_t[1];

        // for (state = 0; state < 781; state = state + 1) begin
        //     temp0[state*2+2] <= in_neuron_t[state + 2];
        //     temp0[state*2+3] <= addnum[state];
        // end
        // temp0[1564] <= in_neuron_t[783];

        for (state = 0; state < 1530; state = state + 1) begin
            if (state < 1492)
            begin
                if (state % 2 == 0)     temp0[state] <= in_neuron_t[state/2];
                else                    temp0[state] <= addnum[state/2];
            end
            else 
            begin
                temp0[state] <= in_neuron_t[state-746];
            end
        end

        level = 0;
        state = 0;
        end

        else if (level == 0)
        begin
        //1565-->313
        // if (state<313)
        if (state < 306)
            begin
                in5_a = temp0[state*5];
                in5_b = temp0[state*5+1];
                in5_c = temp0[state*5+2];
                in5_d = temp0[state*5+3];
                in5_e = temp0[state*5+4];
                temp1[state] = in5_y;
                state = state + 1;
            end
        else
        // for (state = 0; state < 313; state = state + 1)
        // begin
        //     temp1[state] = temp0_out[state];
        // end
        begin
            level = 1;
            state = 0;
            flag3 = 0;
            flag5 = 1;
        end
        end

        else if (level == 1)
        begin
        //313-->81
            // if (state < 35 && flag5 == 1)   //5bit Majority Gate * 35
            // begin
            //     in5_a = temp1[state*5];
            //     in5_b = temp1[state*5+1];
            //     in5_c = temp1[state*5+2];
            //     in5_d = temp1[state*5+3];
            //     in5_e = temp1[state*5+4];
            //     temp2[state] = in5_y;
            //     state = state + 1;
            // end
            // else if (state == 35 && flag5 == 1)
            // begin
            //     state = 0;
            //     flag5 = 0;
            //     flag3 = 1;
            // end
            // else if (state < 46 && flag3 == 1)   //3bit Majority Gate * 46
            // begin
            //     in3_a = temp1[state*3+175];
            //     in3_b = temp1[state*3+176];
            //     in3_c = temp1[state*3+177];
            //     temp2[state+35] = in3_y;
            //     state = state + 1;
            // end
            if (state < 102)
            begin
                in3_a = temp1[state*3];
                in3_b = temp1[state*3+1];
                in3_c = temp1[state*3+2];
                temp2[state] = in3_y;
                state = state + 1;
            end
            else
            begin
            level = 2;
            state = 0;
            end
        end

        else if (level == 2)
        begin
        //81-->27
            // if (state < 27)   //3bit Majority Gate * 27
            if (state < 34)
            begin
                in3_a = temp2[state*3];
                in3_b = temp2[state*3+1];
                in3_c = temp2[state*3+2];
                temp3[state] = in3_y;
                state = state + 1;
            end
            else
            begin
            level = 3;
            state = 0;
            count_zeros = 0;
            count_ones = 0;
            end
        end

        else if (level == 3)
        begin
        // if (state < 27) begin
        if (state < 34) begin
            if (temp3[state] == 1'b0)
                count_zeros = count_zeros + 1;
            else
                count_ones = count_ones + 1;
            state = state + 1;
        end
        else begin
        if (count_zeros > count_ones)
            out_neuron = 1'b0;
        else
            out_neuron = 1'b1;
        flag = 1;
        end
        end
        // else if (level == 3)
        // begin
        // //27-->9
        //     if(state<9)   //3bit Majority Gate * 9
        //     begin
        //         in3_a = temp3[state*3];
        //         in3_b = temp3[state*3+1];
        //         in3_c = temp3[state*3+2];
        //         temp4[state] = in3_y;
        //         state = state + 1;
        //     end
        //     else
        //     begin
        //     level = 4;
        //     state = 0;
        //     end
        // end

        // else if (level == 4)
        // begin
        // //9-->3
        //     if (state < 3)  //3bit Majority Gate * 3
        //     begin
        //         in3_a = temp4[state*3];
        //         in3_b = temp4[state*3+1];
        //         in3_c = temp4[state*3+2];
        //         temp5[state] = in3_y;
        //         state = state + 1;
        //     end
        //     else
        //     begin
        //         level = 5;
        //     end
        // end 

        // else if (level == 5)
        // begin
        // //3-->1
        //     in3_a = temp5[0];
        //     in3_b = temp5[1];
        //     in3_c = temp5[2];
        //     temp6 = in3_y;
        //     out_neuron = temp6;
        //     flag = 1;
        // end
    end  
    
endmodule
