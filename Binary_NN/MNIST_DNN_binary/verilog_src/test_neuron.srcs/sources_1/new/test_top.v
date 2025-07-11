`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/04 14:56:06
// Design Name: 
// Module Name: test_top
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


module test_top(
    input wire pin,
    input wire clk,
    input wire rst_n,
    output reg [3:0] result,
    output wire tx
    );

    reg next;
    reg en;
    reg [783:0] kernel_tmp;
    reg [9:0]   bias_tmp;
    wire flag;
    wire midneuron1_tmp;
    wire [7:0] out2;

    reg [191:0] kernel_tmp2;
    reg [191:0] inp_neuron;
    
    reg [7:0] count = 0;

    reg [783:0] ker1 [191:0];
    reg [9:0] bias1 [191:0];
    reg [191:0] ker2 [9:0];

    reg [191:0] mid_neuron;
    reg [7:0] out_neuron [9:0];
    reg [9:0] end_neuron;
    reg en2;
    wire flag2;

    reg [2:0] level;
    reg [3:0] i;
    reg [7:0] max_value;

    reg gap;

    ////////////// index in rx and tx part //////////////////
    wire [783:0] image;
    // reg clk_rx;
    // reg [13:0] counter_clk;

    reg en_tx;
    wire tx_data_valid;




initial
    begin
    $readmemb("D://Xilinx/Vivado/file/ker1.txt",ker1);
    $readmemb("D://Xilinx/Vivado/file/ker2.txt",ker2);
    $readmemb("D://Xilinx/Vivado/file/bias.txt",bias1);
    end 

rx image_inp(
    .clk    (clk),
    .rst_n  (rst_n),
    .rx_pin (pin),
    .next   (next),
    .rx_data    (image),
    .rx_data_valid   (rx_data_valid)
);

tx image_oup(
    .clk    (clk),
    .rst_n  (rst_n),
    .en_tx     (en_tx),
    .result (result),
    .tx_data_valid   (tx_data_valid),
    .tx     (tx)
);

simple_neuron_plus midneuron1(     //here we can switch calculating mode of the neuron  (majority gate or improved sum strategy)
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (en),
    .in_neuron  (image),
    .kernel (kernel_tmp),
    .bias   (bias_tmp),
    .out_neuron (midneuron1_tmp),
    .flag   (flag)
);

mac191  mac2(
    .clk            (clk),
    .rst_n          (rst_n),
    .en             (en2),
    .inp            (inp_neuron),
    .weight         (kernel_tmp2),
    .out            (out2),
    .flag           (flag2)
);

// always @(posedge clk or negedge rst_n) 
// begin                                               // ����ʱ�� for rx part
//     if (!rst_n)
//     begin
//         counter_clk = 0;
//         clk_rx <= 0;
//     end
//     else if (counter_clk == (10417 - 1)/2) 
//     begin
//         counter_clk <= 0;
//         clk_rx <= ~clk_rx;
//     end 
//     else 
//     begin
//         counter_clk <= counter_clk + 1;
//     end
// end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        en <= 0;
        count <= 0;
        level <= 0;
        result <= 0;
        en2 <= 0;
        i <= 0;
        en_tx <= 0;
        next <= 0;
    end

    else if (level == 0)    //this level(0) is for loading the image
    begin
        if (rx_data_valid == 0) ;
        else
        begin
            level <= 1;
        end
    end

    else if (level == 1)    //this level(1) is for calculating the first layer
    begin
        if (count < 192 && flag == 0)
        begin
        // gap = 0;
        en = 1;
        kernel_tmp = ker1[count];
        bias_tmp = bias1[count];
        end

        else if(count < 192 && en == 1)
        begin
        mid_neuron[191-count] <= midneuron1_tmp;
        count <= count + 1;
        en <= 0;     //en=0����ģ�鿲flag��±���??0���¸����ڼ�����ʼ��??��neuron��majority gate�жϸ�???
        // gap <= 0;
        end

        else if (count == 192)
        begin
            level <= 2;
            count <= 0;
        end
    end

    else if (count < 10 && level == 2)
    begin
        if (count < 10 && flag2 == 0)
        begin
            gap = 0;
            en2 = 1;
            inp_neuron = mid_neuron;
            kernel_tmp2 = ker2[count];
        end

        else if (count < 10 && flag2 == 1 && gap == 0)
        begin
            out_neuron[count] <= out2; 
            count <= count +1;
            en2 <= 0;
            gap <= 1;
            i <= 0;
        end
    end

    else if (count == 10 && level == 2)
    begin
        //�õ�result��ǰ���ٲ�result��ֵ
        if (i == 0)  max_value <= out_neuron[0];
        if (i<10)
        begin
            if (out_neuron[i] > max_value) begin
                max_value <= out_neuron[i];
                result <= i;
            end
            i = i+1;
        end
        if (i == 10)
        begin
            level = 3;
        end
    end

    else if (level == 3)      //this level(3) is for uart_tx
    begin
        next <= 1;
        if (tx_data_valid == 0)
        begin
            en_tx <= 1;
        end
        else
        begin
            next <= 0;
            en_tx <= 0;
            level <= 0;
        end
    end
end

endmodule
