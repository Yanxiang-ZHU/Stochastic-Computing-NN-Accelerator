`timescale 1ns / 1ps

module globalavgpool #(
    parameter DATA_WIDTH = 32,
    parameter OUTPUT_NODES_GAP = 64
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [8*8*64*32-1:0] input_gap,  // shape of input_gap is [8*8*64*32-1:0]
    output reg [8*8*64*32-1:0] output_gap,
    output reg flag
);

// reg [31:0] add1;
// reg [31:0] add2;
// reg en_add;
// wire [31:0] output_add;
// wire flag_add;

reg en_acc;
reg [31:0] acc;
wire acc_ready;
reg acc_last;
wire flag_acc;
wire ready_acc;
wire [31:0] output_acc;
wire last_acc;

reg en_div1;
reg en_div2;
reg [31:0] div1;
reg [31:0] div2;
wire flag_div;
wire [31:0] output_div;

reg [6:0] layer_num;    // range from 0-63
reg [6:0] acc_num;

// addfloat add_gap(
//     .clk(clk),
//     .a_tdata(add1),
//     .b_tdata(add2),
//     .operation_tvalid(en_add),
//     .result_tvalid(flag_add),
//     .result_tdata(output_add)
// );

accfloat acc_gap(
    .clk(clk),
    .a_tvalid(en_acc),
    .a_tdata(acc),
    .a_tready(acc_ready),   // out
    .a_tlast(acc_last),
    .acc_result_tvalid(flag_acc),
    .acc_result_tready(1),   // in
    .acc_result_tdata(output_acc),
    .acc_result_tlast(last_acc)
);

// need to add a division module here, naming divfloat
divfloat div_gap(
    .clk(clk),
    .a_tvalid(en_div1),
    .a_tdata(div1),
    .b_tvalid(en_div2),
    .b_tdata(div2),
    .div_result_tvalid(flag_div),
    .div_rsult_tdata(output_div)
);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || !en)
    begin
        flag <= 0;
        output_gap <= 0;
        acc_num <= 0;
        layer_num <= 0;
        en_acc <= 0;
        en_div1 <= 0;
        en_div2 <= 0;
        acc_last <= 0;
    end

    else 
    begin
        if (layer_num < 64)
        begin
            // acc: input_gap[((64-layer_num)*64*32-1)-:64*32]
            if (acc_num < 63)
            begin
                if (acc_ready == 1)
                begin
                    en_acc <= 1;
                    acc = input_gap[((64-layer_num)*64*32-1-acc_num*32)-:32];
                    acc_last <= 0;
                    acc_num <= acc_num + 1;
                end
            end

            else if (acc_num == 63)
            begin
                acc = input_gap[((64-layer_num)*64*32-1-acc_num*32)-:32];
                acc_last <= 1;

                if (last_acc)
                begin
                    en_acc <= 0;
                    div1 <= output_acc;
                    acc_num <= acc_num + 1;
                end
            end

            else
            begin
                div2 <= 32'b01000010100000000000000000000000;   // representing 64
                en_div1 <= 1;
                en_div2 <= 2;
                
                if (flag_div)
                begin
                    output_gap[((64-layer_num)*32-1)-:32] = output_div;
                    en_div1 <= 0;
                    en_div2 <= 0;
                    acc_num <= 0;
                    layer_num <= layer_num + 1;
                end
            end
        end

        else if (layer_num == 64)
        begin
            flag <= 1;
        end
    end
end

endmodule