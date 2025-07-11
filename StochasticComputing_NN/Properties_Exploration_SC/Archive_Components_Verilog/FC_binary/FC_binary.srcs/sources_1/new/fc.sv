`timescale 1ns / 1ps

module fc #(
    parameter LENTH = 128,
    parameter NUM = 49   // suppose we downsample a 28*28 figure for 16 times
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [LENTH-1:0] weight [NUM-1:0],   
    input wire [LENTH-1:0] input_val [NUM-1:0], 
    output reg [LENTH-1:0] output_val, 
    output reg flag
);

    // Internal signals for xnor operation and majority gate (3 bit)
    reg [LENTH-1:0] products [NUM-1:0];
    reg [LENTH-1:0] line1;
    reg [LENTH-1:0] line2;
    reg [LENTH-1:0] line3;
    reg en_majority;
    wire [LENTH-1:0] output_majority;
    wire flag_majority;

    // establish the majority gate for two layers (9x reduction), followed by precise counting
    reg [LENTH-1:0] products_majority1 [(NUM/3-1):0];
    reg [LENTH-1:0] products_majority2 [(NUM/9-1):0];
    
    majority_3bit #(
        .LENTH(LENTH)
    ) majority_3bit_u (
        .clk(clk),
        .rst_n(rst_n),
        .line1(line1),
        .line2(line2),
        .line3(line3),
        .en(en_majority),
        .output_majority(output_majority),
        .flag(flag_majority)
    );

    typedef enum reg [1:0]  {
        IDLE,
        XNOR_OPERATION,
        MAJORITY
    } state_t;
    state_t state;

    typedef enum reg [1:0] {
        MAJORITY_FIRST,
        MAJORITY_SECOND,
        COUNTING
    } state_majority;
    state_majority state_m;

    integer j;
    integer k;
    integer count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            state_m <= MAJORITY_FIRST;
            output_val <= 0;
            
        end else begin
            // state machine
            case (state)
                IDLE: begin
                    flag <= 0;
                    if (en) begin
                        state <= XNOR_OPERATION;
                        en_majority <= 0;
                    end
                end

                XNOR_OPERATION: begin
                    // NOTICE: do not try NUM with an excessively large number
                    for (j = 0;  j < NUM; j = j + 1) begin
                        products[j] <= weight[j] ^~ input_val[j];
                    end
                    state <= MAJORITY;
                    state_m <= MAJORITY_FIRST;
                    j <= 0;
                    k <= 0;
                end

                MAJORITY: begin
                    case (state_m)
                        MAJORITY_FIRST: begin
                            if (k < NUM/3) begin
                                if (!en_majority) begin
                                    line1 <= products[3*k + 0];
                                    line2 <= products[3*k + 1];
                                    line3 <= products[3*k + 2];
                                    en_majority <= 1;
                                end else if (flag_majority) begin
                                    en_majority <= 0;
                                    products_majority1[k] <= output_majority;
                                    k <= k + 1;
                                end
                            end else begin
                                k <= 0;
                                state_m <= MAJORITY_SECOND;
                            end
                        end

                        MAJORITY_SECOND: begin
                            if (k < NUM/9) begin
                                if (!en_majority) begin
                                    line1 <= products_majority1[3*k + 0];
                                    line2 <= products_majority1[3*k + 1];
                                    line3 <= products_majority1[3*k + 2];
                                    en_majority <= 1;
                                end else if (flag_majority) begin
                                    en_majority <= 0;
                                    products_majority2[k] <= output_majority;
                                    k <= k + 1;
                                end
                            end else begin
                                k <= 0;
                                state_m <= COUNTING;
                            end
                        end

                        COUNTING: begin
                            if (k < LENTH) begin
                                count <= 0;
                                for (j = 0; j < NUM/9; j++) begin
                                    if (products_majority2[j][k])  begin 
                                        count <= count + 1;
                                    end
                                end
                                if (count > NUM/18) begin 
                                    output_val[k] <= 1;
                                end
                                k <= k + 1;
                            end else begin
                                k <= 0;
                                j <= 0;
                                flag <= 1;
                                state <= IDLE;
                                state_m <= MAJORITY_FIRST;
                            end
                        end
                    endcase
                end
            endcase
        end
    end
endmodule

module majority_3bit #(
    parameter LENTH = 128
)(
    input wire clk,
    input wire rst_n,
    input wire [LENTH-1:0] line1,
    input wire [LENTH-1:0] line2,
    input wire [LENTH-1:0] line3,
    input wire en,
    output reg [LENTH-1:0] output_majority,
    output reg flag
);
    integer j;
    reg [3:0] i;

    localparam SLICE = LENTH / 8;


    // try to complete in single clk cycle
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flag <= 0;
            output_majority <= 0;
            i <= 0;
        end else if (en) begin
            if (i < 8) begin
                for (j = i * 16; j < (i+1) * 16; j = j + 1) begin
                    output_majority[j] <= (line1[j] & line2[j]) | (line1[j] & line3[j]) | (line2[j] & line3[j]);
                end
                i = i + 1;
            end else begin
                flag <= 1;
                i <= 0;
            end
        end else begin
            flag <= 0;
            output_majority <= 0;
        end
    end
endmodule 

