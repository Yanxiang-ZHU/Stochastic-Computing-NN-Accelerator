`timescale 1ns / 1ps

module conv2d_3_16(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [98303:0] input_data,  // flatten from [32,32,3] and [31:0]   -- should be unflattened later
    output reg [524287:0] output_data,     // flatten from [32,32,16] and [31:0]
    output reg flag
);

    reg [31:0] weight   [0:431];   // (3, 3, 3, 16) = 432
    reg [31:0] bias     [0:15];

    reg [31:0] R_tn [0:1023];
    reg [31:0] G_tn [0:1023];
    reg [31:0] B_tn [0:1023];

    reg [32*32*16*32-1:0] output_data_R;
    reg [32*32*16*32-1:0] output_data_G;
    reg [32*32*16*32-1:0] output_data_B;

    parameter FILTERS = 16;     
    parameter KERNEL_SIZE = 3;
    parameter INPUT_SIZE = 32 * 32;
    parameter OUTPUT_SIZE = 32 * 32; 
    parameter STRIDE = 1;
    parameter LENTH = 32;
    
    reg signed [31:0] input_matrix [0:INPUT_SIZE-1];  
    reg signed [63:0] weight_matrix [0:KERNEL_SIZE*KERNEL_SIZE-1];   // one single matrix
    reg signed [31:0] conv_result;

    reg [4:0] level;
    reg [1:0] tn;

    integer i, j, k, l;

    reg a_tvalid [0:8];
    reg [31:0] a_tdata [0:8];
    reg b_tvalid [0:8];
    reg [31:0] b_tdata [0:8];
    wire mul_result_tvalid [0:8];
    wire [31:0] mul_result_tdata [0:8];

    reg [31:0] c_tdata;
    reg [31:0] d_tdata;
    reg en_add;
    wire flag_add;
    wire [31:0] output_add;

    reg [31:0] acc;
    reg en_acc;
    wire acc_ready;
    reg acc_last;
    wire [31:0] output_acc;
    wire flag_acc;
    reg acc_result_ready;
    wire acc_result_last;

    reg [31:0] r_data, g_data, b_data, rg_sum, final_sum;
    reg [13:0] idx;
    reg state_b;

    reg state; // 0: mul operation, 1: add operation (float)
    
    // Initialization
    initial begin
        conv_result = 0;
        $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_0.txt", weight);
        $readmemh("C://Users/39551/Desktop/cifar10/CIFAR10_UART/weight/arr_1.txt", bias);
    end

    // floating number mul/add IP
    mulfloat mul1(
        .clk    (clk),
        .a_tvalid   (a_tvalid[0]),
        .a_tdata    (a_tdata[0]),
        .b_tvalid   (b_tvalid[0]),
        .b_tdata    (b_tdata[0]),
        .mul_result_tvalid  (mul_result_tvalid[0]),
        .mul_result_tdata   (mul_result_tdata[0])
    );

    mulfloat mul2(
        .clk    (clk),
        .a_tvalid   (a_tvalid[1]),
        .a_tdata    (a_tdata[1]),
        .b_tvalid   (b_tvalid[1]),
        .b_tdata    (b_tdata[1]),
        .mul_result_tvalid  (mul_result_tvalid[1]),
        .mul_result_tdata   (mul_result_tdata[1])
    );

    mulfloat mul3(
        .clk    (clk),
        .a_tvalid   (a_tvalid[2]),
        .a_tdata    (a_tdata[2]),
        .b_tvalid   (b_tvalid[2]),
        .b_tdata    (b_tdata[2]),
        .mul_result_tvalid  (mul_result_tvalid[2]),
        .mul_result_tdata   (mul_result_tdata[2])
    );

    mulfloat mul4(
        .clk    (clk),
        .a_tvalid   (a_tvalid[3]),
        .a_tdata    (a_tdata[3]),
        .b_tvalid   (b_tvalid[3]),
        .b_tdata    (b_tdata[3]),
        .mul_result_tvalid  (mul_result_tvalid[3]),
        .mul_result_tdata   (mul_result_tdata[3])
    );

    mulfloat mul5(
        .clk    (clk),
        .a_tvalid   (a_tvalid[4]),
        .a_tdata    (a_tdata[4]),
        .b_tvalid   (b_tvalid[4]),
        .b_tdata    (b_tdata[4]),
        .mul_result_tvalid  (mul_result_tvalid[4]),
        .mul_result_tdata   (mul_result_tdata[4])
    );

    mulfloat mul6(
        .clk    (clk),
        .a_tvalid   (a_tvalid[5]),
        .a_tdata    (a_tdata[5]),
        .b_tvalid   (b_tvalid[5]),
        .b_tdata    (b_tdata[5]),
        .mul_result_tvalid  (mul_result_tvalid[5]),
        .mul_result_tdata   (mul_result_tdata[5])
    );

    mulfloat mul7(
        .clk    (clk),
        .a_tvalid   (a_tvalid[6]),
        .a_tdata    (a_tdata[6]),
        .b_tvalid   (b_tvalid[6]),
        .b_tdata    (b_tdata[6]),
        .mul_result_tvalid  (mul_result_tvalid[6]),
        .mul_result_tdata   (mul_result_tdata[6])
    );

    mulfloat mul8(
        .clk    (clk),
        .a_tvalid   (a_tvalid[7]),
        .a_tdata    (a_tdata[7]),
        .b_tvalid   (b_tvalid[7]),
        .b_tdata    (b_tdata[7]),
        .mul_result_tvalid  (mul_result_tvalid[7]),
        .mul_result_tdata   (mul_result_tdata[7])
    );

    mulfloat mul9(
        .clk    (clk),
        .a_tvalid   (a_tvalid[8]),
        .a_tdata    (a_tdata[8]),
        .b_tvalid   (b_tvalid[8]),
        .b_tdata    (b_tdata[8]),
        .mul_result_tvalid  (mul_result_tvalid[8]),
        .mul_result_tdata   (mul_result_tdata[8])
    );

    addfloat add1(
        .clk        (clk),
        .a_tdata    (c_tdata),
        .b_tdata    (d_tdata),
        .operation_tvalid   (en_add),
        .result_tvalid      (flag_add),
        .result_tdata       (output_add)
    );

    accfloat acc_conv01(
        .clk(clk),
        .a_tvalid(en_acc),
        .a_tdata(acc),
        .a_tready(acc_ready),   // out
        .a_tlast(acc_last),
        .acc_result_tvalid(flag_acc),
        .acc_result_tready(1),   // in
        .acc_result_tdata(output_acc),
        .acc_result_tlast(acc_result_last)
    );

    // Convolution
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || !en) 
        begin
            output_data = 0;
            i = 0; j = 0; k = 0; l = 0;  // k is the index for pairing the kernel and input data
            level = 0;
            flag = 0;
            tn = 1;
            conv_result = 0;
            state = 0;
            a_tvalid[0] <= 0;           b_tvalid[0] <= 0;
            a_tvalid[1] <= 0;           b_tvalid[1] <= 0;
            a_tvalid[2] <= 0;           b_tvalid[2] <= 0;
            a_tvalid[3] <= 0;           b_tvalid[3] <= 0;
            a_tvalid[4] <= 0;           b_tvalid[4] <= 0;
            a_tvalid[5] <= 0;           b_tvalid[5] <= 0;
            a_tvalid[6] <= 0;           b_tvalid[6] <= 0;
            a_tvalid[7] <= 0;           b_tvalid[7] <= 0;
            a_tvalid[8] <= 0;           b_tvalid[8] <= 0;
            en_acc <= 0;
            acc_last <= 0;
            en_add <= 0;
            idx <= 0;
            state_b <= 0;
        end

        else if (level == 0)
        begin
            // separate the input data into three RGB tunnels
            if (i < 1024)
            begin
                R_tn[i] = input_data[(98303-32*3*i)-:32];
                G_tn[i] = input_data[(98303-32-32*3*i)-:32];
                B_tn[i] = input_data[(98303-32*2-32*3*i)-:32];
                i <= i + 1;
            end

            else
            begin
                i <= 0;
                level <= 1;
            end
        end

        else if (level < 17)        // 1~16
        begin
            // calculate the first filter. kernel size [3,3,3]  -- 16 filter (level) in total
            // in this level, input and weight are all in three tunnels
            if (tn == 1 && j < INPUT_SIZE)
            begin
                // consider the edge
                if (j == 0)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[0];                     a_tvalid[0] <= 1;     
                        a_tdata[1] <= R_tn[1];                     a_tvalid[1] <= 1;     
                        a_tdata[2] <= R_tn[LENTH];                 a_tvalid[2] <= 1;     
                        a_tdata[3] <= R_tn[LENTH+1];               a_tvalid[3] <= 1;         
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];       b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];       b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];     b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];     b_tvalid[3] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[LENTH-2];                    a_tvalid[0] <= 1;   
                        a_tdata[1] <= R_tn[LENTH-1];                    a_tvalid[1] <= 1;   
                        a_tdata[2] <= R_tn[LENTH*2-2];                  a_tvalid[2] <= 1;   
                        a_tdata[3] <= R_tn[LENTH*2-1];                  a_tvalid[3] <= 1;       
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];              b_tvalid[0] <= 1;   
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];            b_tvalid[1] <= 1;       
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];            b_tvalid[2] <= 1;   
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];          b_tvalid[3] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH*LENTH-LENTH)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[LENTH*(LENTH-2)];                a_tvalid[0] <= 1;  
                        a_tdata[1] <= R_tn[LENTH*(LENTH-2)+1];              a_tvalid[1] <= 1;  
                        a_tdata[2] <= R_tn[LENTH*(LENTH-1)];                a_tvalid[2] <= 1;  
                        a_tdata[3] <= R_tn[LENTH*(LENTH-1)+1];              a_tvalid[3] <= 1;      
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                            b_tvalid[0] <= 1;  
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];                            b_tvalid[1] <= 1;      
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];                b_tvalid[2] <= 1;  
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];                b_tvalid[3] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH*LENTH - 1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[LENTH*(LENTH-1)-2];          a_tvalid[0] <= 1;    
                        a_tdata[1] <= R_tn[LENTH*(LENTH-1)-1];          a_tvalid[1] <= 1;    
                        a_tdata[2] <= R_tn[LENTH*LENTH-2];              a_tvalid[2] <= 1;    
                        a_tdata[3] <= R_tn[LENTH*LENTH-1];              a_tvalid[3] <= 1;        
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];                        b_tvalid[0] <= 1;    
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                        b_tvalid[1] <= 1;        
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];              b_tvalid[2] <= 1;    
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];            b_tvalid[3] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j > 0 && j < LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[j-1];                   a_tvalid[0] <= 1;     
                        a_tdata[1] <= R_tn[j];                     a_tvalid[1] <= 1;     
                        a_tdata[2] <= R_tn[j+1];                   a_tvalid[2] <= 1;     
                        a_tdata[3] <= R_tn[LENTH+j-1];             a_tvalid[3] <= 1;
                        a_tdata[4] <= R_tn[LENTH+j];               a_tvalid[4] <= 1;     
                        a_tdata[5] <= R_tn[LENTH+j+1];             a_tvalid[5] <= 1;            
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];       b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];       b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];     b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];     b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];     b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];     b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j % LENTH == 0 && j > 0 && j < LENTH*LENTH -LENTH)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[j-LENTH];                a_tvalid[0] <= 1;     
                        a_tdata[1] <= R_tn[j+1-LENTH];              a_tvalid[1] <= 1;     
                        a_tdata[2] <= R_tn[j];                      a_tvalid[2] <= 1;     
                        a_tdata[3] <= R_tn[j+1];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= R_tn[LENTH+j];                a_tvalid[4] <= 1;     
                        a_tdata[5] <= R_tn[LENTH+j+1];              a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                    b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];                    b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];        b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];      b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end



                else if (j % LENTH == LENTH -1 && j > LENTH -1 && j < LENTH*LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[j-LENTH-1];            a_tvalid[0] <= 1;     
                        a_tdata[1] <= R_tn[j-LENTH];              a_tvalid[1] <= 1;     
                        a_tdata[2] <= R_tn[j-1];                  a_tvalid[2] <= 1;     
                        a_tdata[3] <= R_tn[j];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= R_tn[LENTH+j-1];            a_tvalid[4] <= 1;     
                        a_tdata[5] <= R_tn[LENTH+j];              a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];                  b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                  b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];      b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];    b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end


                else if (j>LENTH*LENTH-LENTH && j < LENTH*LENTH-1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= R_tn[j-LENTH-1];              a_tvalid[0] <= 1;     
                        a_tdata[1] <= R_tn[j-LENTH];                a_tvalid[1] <= 1;     
                        a_tdata[2] <= R_tn[j-LENTH+1];              a_tvalid[2] <= 1;     
                        a_tdata[3] <= R_tn[j-1];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= R_tn[j];                      a_tvalid[4] <= 1;     
                        a_tdata[5] <= R_tn[j+1];                    a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];          b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];        b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];        b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];      b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else
                begin     
                    if (state == 0)
                    begin                 
                        a_tdata[0] <= R_tn[j-LENTH-1];                                     a_tvalid[0] <= 1;
                        a_tdata[1] <= R_tn[j-LENTH];                                       a_tvalid[1] <= 1;
                        a_tdata[2] <= R_tn[j-LENTH+1];                                     a_tvalid[2] <= 1;
                        a_tdata[3] <= R_tn[j-1];                                           a_tvalid[3] <= 1;
                        a_tdata[4] <= R_tn[j];                                             a_tvalid[4] <= 1;
                        a_tdata[5] <= R_tn[j+1];                                           a_tvalid[5] <= 1;
                        a_tdata[6] <= R_tn[j+LENTH-1];                                     a_tvalid[6] <= 1;
                        a_tdata[7] <= R_tn[j+LENTH];                                       a_tvalid[7] <= 1;
                        a_tdata[8] <= R_tn[j+LENTH+1];                                     a_tvalid[8] <= 1;
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];            b_tvalid[0] <= 1;
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];            b_tvalid[1] <= 1;
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];            b_tvalid[2] <= 1;
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 3];            b_tvalid[3] <= 1;
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 4];            b_tvalid[4] <= 1;
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 5];            b_tvalid[5] <= 1;
                        b_tdata[6] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 6];            b_tvalid[6] <= 1;
                        b_tdata[7] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 7];            b_tvalid[7] <= 1;
                        b_tdata[8] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 8];            b_tvalid[8] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            a_tvalid[6] <= 0;
                            a_tvalid[7] <= 0;
                            a_tvalid[8] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                            b_tvalid[6] <= 0;
                            b_tvalid[7] <= 0;
                            b_tvalid[8] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_R[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end
            end

            else if (tn == 1 && j == INPUT_SIZE)
            begin
                j <= 0;
                k <= 0;
                tn <= 2;
            end

////////////////////////// tn == 2 ////////////////////////////////////////////////////////////////
            else if (tn == 2 && j < INPUT_SIZE)
            begin
                // consider the edge
                if (j == 0)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[0];                     a_tvalid[0] <= 1;     
                        a_tdata[1] <= G_tn[1];                     a_tvalid[1] <= 1;     
                        a_tdata[2] <= G_tn[LENTH];                 a_tvalid[2] <= 1;     
                        a_tdata[3] <= G_tn[LENTH+1];               a_tvalid[3] <= 1;         
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];       b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];       b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];     b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];     b_tvalid[3] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[LENTH-2];                    a_tvalid[0] <= 1;   
                        a_tdata[1] <= G_tn[LENTH-1];                    a_tvalid[1] <= 1;   
                        a_tdata[2] <= G_tn[LENTH*2-2];                  a_tvalid[2] <= 1;   
                        a_tdata[3] <= G_tn[LENTH*2-1];                  a_tvalid[3] <= 1;       
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];              b_tvalid[0] <= 1;   
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];            b_tvalid[1] <= 1;       
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];            b_tvalid[2] <= 1;   
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];          b_tvalid[3] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH*LENTH-LENTH)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[LENTH*(LENTH-2)];                a_tvalid[0] <= 1;  
                        a_tdata[1] <= G_tn[LENTH*(LENTH-2)+1];              a_tvalid[1] <= 1;  
                        a_tdata[2] <= G_tn[LENTH*(LENTH-1)];                a_tvalid[2] <= 1;  
                        a_tdata[3] <= G_tn[LENTH*(LENTH-1)+1];              a_tvalid[3] <= 1;      
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                            b_tvalid[0] <= 1;  
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];                            b_tvalid[1] <= 1;      
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];                b_tvalid[2] <= 1;  
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];                b_tvalid[3] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH*LENTH - 1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[LENTH*(LENTH-1)-2];          a_tvalid[0] <= 1;    
                        a_tdata[1] <= G_tn[LENTH*(LENTH-1)-1];          a_tvalid[1] <= 1;    
                        a_tdata[2] <= G_tn[LENTH*LENTH-2];              a_tvalid[2] <= 1;    
                        a_tdata[3] <= G_tn[LENTH*LENTH-1];              a_tvalid[3] <= 1;        
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];                        b_tvalid[0] <= 1;    
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                        b_tvalid[1] <= 1;        
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];              b_tvalid[2] <= 1;    
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];            b_tvalid[3] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j > 0 && j < LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[j-1];                   a_tvalid[0] <= 1;     
                        a_tdata[1] <= G_tn[j];                     a_tvalid[1] <= 1;     
                        a_tdata[2] <= G_tn[j+1];                   a_tvalid[2] <= 1;     
                        a_tdata[3] <= G_tn[LENTH+j-1];             a_tvalid[3] <= 1;
                        a_tdata[4] <= G_tn[LENTH+j];               a_tvalid[4] <= 1;     
                        a_tdata[5] <= G_tn[LENTH+j+1];             a_tvalid[5] <= 1;            
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];       b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];       b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];     b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];     b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];     b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];     b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j % LENTH == 0 && j > 0 && j < LENTH*LENTH -LENTH)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[j-LENTH];                a_tvalid[0] <= 1;     
                        a_tdata[1] <= G_tn[j+1-LENTH];              a_tvalid[1] <= 1;     
                        a_tdata[2] <= G_tn[j];                      a_tvalid[2] <= 1;     
                        a_tdata[3] <= G_tn[j+1];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= G_tn[LENTH+j];                a_tvalid[4] <= 1;     
                        a_tdata[5] <= G_tn[LENTH+j+1];              a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                    b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];                    b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];        b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];      b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end



                else if (j % LENTH == LENTH -1 && j > LENTH -1 && j < LENTH*LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[j-LENTH-1];            a_tvalid[0] <= 1;     
                        a_tdata[1] <= G_tn[j-LENTH];              a_tvalid[1] <= 1;     
                        a_tdata[2] <= G_tn[j-1];                  a_tvalid[2] <= 1;     
                        a_tdata[3] <= G_tn[j];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= G_tn[LENTH+j-1];            a_tvalid[4] <= 1;     
                        a_tdata[5] <= G_tn[LENTH+j];              a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];                  b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                  b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];      b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];    b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end


                else if (j>LENTH*LENTH-LENTH && j < LENTH*LENTH-1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= G_tn[j-LENTH-1];              a_tvalid[0] <= 1;     
                        a_tdata[1] <= G_tn[j-LENTH];                a_tvalid[1] <= 1;     
                        a_tdata[2] <= G_tn[j-LENTH+1];              a_tvalid[2] <= 1;     
                        a_tdata[3] <= G_tn[j-1];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= G_tn[j];                      a_tvalid[4] <= 1;     
                        a_tdata[5] <= G_tn[j+1];                    a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];          b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];        b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];        b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];      b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else
                begin     
                    if (state == 0)
                    begin                 
                        a_tdata[0] <= G_tn[j-LENTH-1];      a_tvalid[0] <= 1;
                        a_tdata[1] <= G_tn[j-LENTH];        a_tvalid[1] <= 1;
                        a_tdata[2] <= G_tn[j-LENTH+1];      a_tvalid[2] <= 1;
                        a_tdata[3] <= G_tn[j-1];            a_tvalid[3] <= 1;
                        a_tdata[4] <= G_tn[j];              a_tvalid[4] <= 1;
                        a_tdata[5] <= G_tn[j+1];            a_tvalid[5] <= 1;
                        a_tdata[6] <= G_tn[j+LENTH-1];      a_tvalid[6] <= 1;
                        a_tdata[7] <= G_tn[j+LENTH];        a_tvalid[7] <= 1;
                        a_tdata[8] <= G_tn[j+LENTH+1];      a_tvalid[8] <= 1;
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];            b_tvalid[0] <= 1;
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];            b_tvalid[1] <= 1;
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];            b_tvalid[2] <= 1;
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 3];            b_tvalid[3] <= 1;
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 4];            b_tvalid[4] <= 1;
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 5];            b_tvalid[5] <= 1;
                        b_tdata[6] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 6];            b_tvalid[6] <= 1;
                        b_tdata[7] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 7];            b_tvalid[7] <= 1;
                        b_tdata[8] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 8];            b_tvalid[8] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            a_tvalid[6] <= 0;
                            a_tvalid[7] <= 0;
                            a_tvalid[8] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                            b_tvalid[6] <= 0;
                            b_tvalid[7] <= 0;
                            b_tvalid[8] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_G[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end
            end
            
            else if (tn == 2 && j == INPUT_SIZE)
            begin
                j <= 0;
                tn <= 3;
            end

/////////////////////////// tn == 3////////////////////////////////////////////////////////////////            

            else if (tn == 3 && j < INPUT_SIZE)
            begin
                // consider the edge
                if (j == 0)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[0];                     a_tvalid[0] <= 1;     
                        a_tdata[1] <= B_tn[1];                     a_tvalid[1] <= 1;     
                        a_tdata[2] <= B_tn[LENTH];                 a_tvalid[2] <= 1;     
                        a_tdata[3] <= B_tn[LENTH+1];               a_tvalid[3] <= 1;         
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];       b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];       b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];     b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];     b_tvalid[3] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[LENTH-2];                    a_tvalid[0] <= 1;   
                        a_tdata[1] <= B_tn[LENTH-1];                    a_tvalid[1] <= 1;   
                        a_tdata[2] <= B_tn[LENTH*2-2];                  a_tvalid[2] <= 1;   
                        a_tdata[3] <= B_tn[LENTH*2-1];                  a_tvalid[3] <= 1;       
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];              b_tvalid[0] <= 1;   
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];            b_tvalid[1] <= 1;       
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];            b_tvalid[2] <= 1;   
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];          b_tvalid[3] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH*LENTH-LENTH)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[LENTH*(LENTH-2)];                a_tvalid[0] <= 1;  
                        a_tdata[1] <= B_tn[LENTH*(LENTH-2)+1];              a_tvalid[1] <= 1;  
                        a_tdata[2] <= B_tn[LENTH*(LENTH-1)];                a_tvalid[2] <= 1;  
                        a_tdata[3] <= B_tn[LENTH*(LENTH-1)+1];              a_tvalid[3] <= 1;      
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                            b_tvalid[0] <= 1;  
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];                            b_tvalid[1] <= 1;      
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];                b_tvalid[2] <= 1;  
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];                b_tvalid[3] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j == LENTH*LENTH - 1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[LENTH*(LENTH-1)-2];          a_tvalid[0] <= 1;    
                        a_tdata[1] <= B_tn[LENTH*(LENTH-1)-1];          a_tvalid[1] <= 1;    
                        a_tdata[2] <= B_tn[LENTH*LENTH-2];              a_tvalid[2] <= 1;    
                        a_tdata[3] <= B_tn[LENTH*LENTH-1];              a_tvalid[3] <= 1;        
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];                        b_tvalid[0] <= 1;    
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                        b_tvalid[1] <= 1;        
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];              b_tvalid[2] <= 1;    
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];            b_tvalid[3] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE-1)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j > 0 && j < LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[j-1];                   a_tvalid[0] <= 1;     
                        a_tdata[1] <= B_tn[j];                     a_tvalid[1] <= 1;     
                        a_tdata[2] <= B_tn[j+1];                   a_tvalid[2] <= 1;     
                        a_tdata[3] <= B_tn[LENTH+j-1];             a_tvalid[3] <= 1;
                        a_tdata[4] <= B_tn[LENTH+j];               a_tvalid[4] <= 1;     
                        a_tdata[5] <= B_tn[LENTH+j+1];             a_tvalid[5] <= 1;            
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];       b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];       b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];     b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];     b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];     b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];     b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else if (j % LENTH == 0 && j > 0 && j < LENTH*LENTH -LENTH)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[j-LENTH];                a_tvalid[0] <= 1;     
                        a_tdata[1] <= B_tn[j+1-LENTH];              a_tvalid[1] <= 1;     
                        a_tdata[2] <= B_tn[j];                      a_tvalid[2] <= 1;     
                        a_tdata[3] <= B_tn[j+1];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= B_tn[LENTH+j];                a_tvalid[4] <= 1;     
                        a_tdata[5] <= B_tn[LENTH+j+1];              a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                    b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];                    b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];        b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];      b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end



                else if (j % LENTH == LENTH -1 && j > LENTH -1 && j < LENTH*LENTH -1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[j-LENTH-1];            a_tvalid[0] <= 1;     
                        a_tdata[1] <= B_tn[j-LENTH];              a_tvalid[1] <= 1;     
                        a_tdata[2] <= B_tn[j-1];                  a_tvalid[2] <= 1;     
                        a_tdata[3] <= B_tn[j];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= B_tn[LENTH+j-1];            a_tvalid[4] <= 1;     
                        a_tdata[5] <= B_tn[LENTH+j];              a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];                  b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];                  b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];      b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];    b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end


                else if (j>LENTH*LENTH-LENTH && j < LENTH*LENTH-1)
                begin
                    if (state == 0)
                    begin
                        a_tdata[0] <= B_tn[j-LENTH-1];              a_tvalid[0] <= 1;     
                        a_tdata[1] <= B_tn[j-LENTH];                a_tvalid[1] <= 1;     
                        a_tdata[2] <= B_tn[j-LENTH+1];              a_tvalid[2] <= 1;     
                        a_tdata[3] <= B_tn[j-1];                    a_tvalid[3] <= 1;
                        a_tdata[4] <= B_tn[j];                      a_tvalid[4] <= 1;     
                        a_tdata[5] <= B_tn[j+1];                    a_tvalid[5] <= 1;  

                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE];          b_tvalid[0] <= 1;     
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+1];        b_tvalid[1] <= 1;         
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE+2];        b_tvalid[2] <= 1;     
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2];        b_tvalid[3] <= 1; 
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+1];      b_tvalid[4] <= 1;     
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + KERNEL_SIZE*2+2];      b_tvalid[5] <= 1; 
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end

                else
                begin     
                    if (state == 0)
                    begin                 
                        a_tdata[0] <= B_tn[j-LENTH-1];      a_tvalid[0] <= 1;
                        a_tdata[1] <= B_tn[j-LENTH];        a_tvalid[1] <= 1;
                        a_tdata[2] <= B_tn[j-LENTH+1];      a_tvalid[2] <= 1;
                        a_tdata[3] <= B_tn[j-1];            a_tvalid[3] <= 1;
                        a_tdata[4] <= B_tn[j];              a_tvalid[4] <= 1;
                        a_tdata[5] <= B_tn[j+1];            a_tvalid[5] <= 1;
                        a_tdata[6] <= B_tn[j+LENTH-1];      a_tvalid[6] <= 1;
                        a_tdata[7] <= B_tn[j+LENTH];        a_tvalid[7] <= 1;
                        a_tdata[8] <= B_tn[j+LENTH+1];      a_tvalid[8] <= 1;
                        b_tdata[0] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 0];            b_tvalid[0] <= 1;
                        b_tdata[1] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 1];            b_tvalid[1] <= 1;
                        b_tdata[2] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 2];            b_tvalid[2] <= 1;
                        b_tdata[3] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 3];            b_tvalid[3] <= 1;
                        b_tdata[4] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 4];            b_tvalid[4] <= 1;
                        b_tdata[5] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 5];            b_tvalid[5] <= 1;
                        b_tdata[6] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 6];            b_tvalid[6] <= 1;
                        b_tdata[7] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 7];            b_tvalid[7] <= 1;
                        b_tdata[8] <= weight[(level-1)*3*3*3 + (tn-1)*3*3 + 8];            b_tvalid[8] <= 1;
                    
                        if (mul_result_tvalid[0] && mul_result_tvalid[1] && mul_result_tvalid[2] && mul_result_tvalid[3] && mul_result_tvalid[4] && mul_result_tvalid[5])
                        begin
                            state <= 1;   // get the mul answers
                            a_tvalid[0] <= 0;
                            a_tvalid[1] <= 0;
                            a_tvalid[2] <= 0;
                            a_tvalid[3] <= 0;
                            a_tvalid[4] <= 0;
                            a_tvalid[5] <= 0;
                            a_tvalid[6] <= 0;
                            a_tvalid[7] <= 0;
                            a_tvalid[8] <= 0;
                            b_tvalid[0] <= 0;
                            b_tvalid[1] <= 0;
                            b_tvalid[2] <= 0;
                            b_tvalid[3] <= 0;
                            b_tvalid[4] <= 0;
                            b_tvalid[5] <= 0;
                            b_tvalid[6] <= 0;
                            b_tvalid[7] <= 0;
                            b_tvalid[8] <= 0;
                        end
                    end

                    else if (state == 1)
                    begin
                        if (k < (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            en_acc <= 1;
                            acc_last <= 0;
                            acc <= mul_result_tdata[k];
                            k <= k + 1;
                        end

                        else if (k == (KERNEL_SIZE)*(KERNEL_SIZE-1)-1)
                        begin
                            acc_last <= 1;
                            acc <= mul_result_tdata[k];
                            
                            if(acc_result_last)
                            begin
                                en_acc <= 0;
                                output_data_B[((1024-j)*16*32-(level-1)*32-1)-:32] <= output_acc;
                                j <= j + 1;
                                k <= 0;
                                state <= 0;
                            end
                        end
                    end
                end
            end

            else if (tn == 3 && j < INPUT_SIZE)
            begin
                j <= 0;
                tn <= 1;
                level  <= level + 1;
            end
        end


        // now we have got the output_data_R and G and B, we need add them together into output_data, and raise the flag
        else if (level == 17)
        begin
            if (idx < 32*32*16) 
            begin
                r_data <= output_data_R[idx*32 +: 32];
                g_data <= output_data_G[idx*32 +: 32];
                b_data <= output_data_B[idx*32 +: 32];

                if (!state_b)
                begin
                    c_tdata <= r_data;
                    d_tdata <= g_data;
                    en_add <= 1;
                    if (flag_add) 
                    begin
                        rg_sum <= output_add; // store the result of r add g
                        state_b <= 1;
                        en_add <= 0;
                    end
                end
                
                else if (state_b)
                begin
                    c_tdata <= rg_sum;
                    d_tdata <= b_data;
                    en_add <= 1;
                    if (flag_add) 
                    begin
                        en_add <= 0;
                        final_sum <= output_add;
                        output_data[idx*32 +: 32] <= final_sum;
                        idx <= idx + 1;
                        state_b <= 0;
                    end
                end
            end 

            else 
            begin
                level <= 0;
                idx <= 0;
                flag <= 1;
            end
        end
    end
endmodule
