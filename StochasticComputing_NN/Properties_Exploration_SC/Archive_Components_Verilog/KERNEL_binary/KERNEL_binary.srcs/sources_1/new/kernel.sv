 `timescale 1ns / 1ps

 module kernel #(
     parameter LENTH = 128
 )(
     input wire clk,
     input wire rst_n,
     input wire en,
     input wire [LENTH-1:0] weight [8:0],    // notice that in binary mode, bias are not taken into consideration
     input wire [LENTH-1:0] input_val [8:0], // 9 binary string input values
     output reg [LENTH-1:0] output_val,      // binary string output
     output reg flag
 );

     // Internal signals for xnor operation and majority gate (3 bit)
     reg [LENTH-1:0] products [8:0];
     reg [LENTH-1:0] line1;
     reg [LENTH-1:0] line2;
     reg [LENTH-1:0] line3;
     // reg en_majority;
     reg [LENTH-1:0] output_majority;
     // wire flag_majority;

     reg [LENTH-1:0] products_majority [2:0];
     reg [3:0] sum;   // no use in MJ method
    
     typedef enum reg [1:0]  {
         IDLE,
         XNOR_OPERATION,
         MAJORITY_GATE
     } state_t;
     state_t state;

     typedef enum reg [1:0] {
         MAJORITY_1,
         MAJORITY_2,
         MAJORITY_3,
         MAJORITY_LAST
     } state_majority;
     state_majority state_m;

     integer i;
     integer j;
    
     always @(posedge clk or negedge rst_n) begin
         if (!rst_n) begin
             state <= IDLE;
             state_m <= MAJORITY_1;
             output_val <= 0;
             sum <= 0;
            
         end else begin
             // state machine
             case (state)
                 IDLE: begin
                     flag <= 0;
                     if (en) begin
                         state <= XNOR_OPERATION;
                         // en_majority <= 0;
                     end
                 end

                 XNOR_OPERATION: begin
                     for (j = 0;  j < 9; j = j + 1) begin
                         products[j] = weight[j] ^~ input_val[j];
                     end
                     state <= MAJORITY_GATE;
                     j <= 0;
                 end

                 MAJORITY_GATE: begin
//                     case (state_m)
//                         MAJORITY_1: begin
//                             line1 = products[0];
//                             line2 = products[1];
//                             line3 = products[2];
//                             output_majority = 0;
//                             for (j = 0; j < LENTH; j = j + 1) begin
//                                 output_majority[j] = (line1[j] & line2[j]) | (line1[j] & line3[j]) | (line2[j] & line3[j]);
//                             end
//                             products_majority[0] = output_majority;
//                             state_m = MAJORITY_2;
//                         end

//                         MAJORITY_2: begin
//                             line1 = products[3];
//                             line2 = products[4];
//                             line3 = products[5];
//                             output_majority = 0;
//                             for (j = 0; j < LENTH; j = j + 1) begin
//                                 output_majority[j] = (line1[j] & line2[j]) | (line1[j] & line3[j]) | (line2[j] & line3[j]);
//                             end                            
//                             products_majority[1] = output_majority;
//                             state_m = MAJORITY_3;
//                         end

//                         MAJORITY_3: begin
//                             line1 = products[6];
//                             line2 = products[7];
//                             line3 = products[8];
//                             output_majority = 0;
//                             for (j = 0; j < LENTH; j = j + 1) begin
//                                 output_majority[j] = (line1[j] & line2[j]) | (line1[j] & line3[j]) | (line2[j] & line3[j]);
//                             end
//                             products_majority[2] = output_majority;
//                             state_m = MAJORITY_LAST;
//                         end

//                         MAJORITY_LAST: begin
//                             line1 = products_majority[0];
//                             line2 = products_majority[1];
//                             line3 = products_majority[2];
//                             output_majority = 0;
//                             for (j = 0; j < LENTH; j = j + 1) begin
//                                 output_majority[j] = (line1[j] & line2[j]) | (line1[j] & line3[j]) | (line2[j] & line3[j]);
//                             end    
//                             output_val = output_majority;
//                             state = IDLE;
//                             state_m = MAJORITY_1;
//                             flag = 1;
//                         end
//                     endcase
                    // Majority Gate not used:
                    for (j = 0; j < LENTH; j = j + 1) begin
                        sum = 0;
                        for (i = 0; i < 9; i = i + 1) begin
                            sum = sum + products[i][j];
                        end
                        if (sum > 6) begin
                            output_val[j] = 1;
                        end else begin
                            output_val[j] = 0;
                        end
                    end
                    state = IDLE;
                    flag = 1;
                 end
             endcase
         end
     end

 endmodule



/* 
    in the above method, we have applied a (LENTH)-bit loop.
    if pursuing a smaller lut consumption, we can break the loop down into any clk cycles.
*/


//`timescale 1ns / 1ps

//module kernel #(
//    parameter LENTH = 128
//)(
//    input wire clk,
//    input wire rst_n,
//    input wire en,
//    input wire [LENTH-1:0] weight [8:0],    // notice that in binary mode, bias are not taken into consideration
//    input wire [LENTH-1:0] input_val [8:0], // 9 binary string input values
//    output reg [LENTH-1:0] output_val,      // binary string output
//    output reg flag
//);

//    // Internal signals for xnor operation and majority gate (3 bit)
//    reg [LENTH-1:0] products [8:0];
//    reg [LENTH-1:0] line1;
//    reg [LENTH-1:0] line2;
//    reg [LENTH-1:0] line3;
//    reg en_majority;
//    wire [LENTH-1:0] output_majority;
//    wire flag_majority;

//    reg [LENTH-1:0] products_majority [2:0];
    
//    majority_3bit #(
//        .LENTH(LENTH)
//    ) majority_3bit_u (
//        .clk(clk),
//        .rst_n(rst_n),
//        .line1(line1),
//        .line2(line2),
//        .line3(line3),
//        .en(en_majority),
//        .output_majority(output_majority),
//        .flag(flag_majority)
//    );

//    typedef enum reg [1:0]  {
//        IDLE,
//        XNOR_OPERATION,
//        MAJORITY_GATE
//    } state_t;
//    state_t state;

//    typedef enum reg [1:0] {
//        MAJORITY_1,
//        MAJORITY_2,
//        MAJORITY_3,
//        MAJORITY_LAST
//    } state_majority;
//    state_majority state_m;

//    integer j;
    
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            state <= IDLE;
//            state_m <= MAJORITY_1;
//            output_val <= 0;
            
//        end else begin
//            // state machine
//            case (state)
//                IDLE: begin
//                    flag <= 0;
//                    if (en) begin
//                        state <= XNOR_OPERATION;
//                        en_majority <= 0;
//                    end
//                end

//                XNOR_OPERATION: begin
//                    for (j = 0;  j < 9; j = j + 1) begin
//                        products[j] <= weight[j] ^~ input_val[j];
//                    end
//                    state <= MAJORITY_GATE;
//                    j <= 0;
//                end

//                MAJORITY_GATE: begin
//                    case (state_m)
//                        MAJORITY_1: begin
//                            if (!en_majority) begin
//                                line1 <= products[0];
//                                line2 <= products[1];
//                                line3 <= products[2];
//                                en_majority <= 1;
//                            end else if (flag_majority) begin
//                                    en_majority = 0;
//                                    state_m = MAJORITY_2;
//                                    products_majority[0] = output_majority;
//                            end
//                        end

//                        MAJORITY_2: begin
//                            if (!en_majority) begin
//                                line1 <= products[3];
//                                line2 <= products[4];
//                                line3 <= products[5];
//                                en_majority <= 1;
//                            end else if (flag_majority) begin
//                                    en_majority = 0;
//                                    state_m = MAJORITY_3;
//                                    products_majority[1] = output_majority;
//                            end
//                        end

//                        MAJORITY_3: begin
//                            if (!en_majority) begin
//                                line1 <= products[6];
//                                line2 <= products[7];
//                                line3 <= products[8];
//                                en_majority <= 1;
//                            end else if (flag_majority) begin
//                                    en_majority = 0;
//                                    state_m = MAJORITY_LAST;
//                                    products_majority[2] = output_majority;
//                            end
//                        end

//                        MAJORITY_LAST: begin
//                            if (!en_majority) begin
//                                line1 <= products_majority[0];
//                                line2 <= products_majority[1];
//                                line3 <= products_majority[2];
//                                en_majority <= 1;
//                            end else if (flag_majority) begin
//                                    en_majority = 0;
//                                    state = IDLE;
//                                    state_m = MAJORITY_1;
//                                    output_val <= output_majority;
//                                    flag <= 1;
//                            end
//                        end
//                    endcase
//                end
//            endcase
//        end
//    end

//endmodule

//module majority_3bit #(
//    parameter LENTH = 128
//)(
//    input wire clk,
//    input wire rst_n,
//    input wire [LENTH-1:0] line1,
//    input wire [LENTH-1:0] line2,
//    input wire [LENTH-1:0] line3,
//    input wire en,
//    output reg [LENTH-1:0] output_majority,
//    output reg flag
//);
//    integer j;
//    reg [3:0] i;

//    localparam SLICE = LENTH / 8;


//    // try to complete in single clk cycle
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            flag <= 0;
//            output_majority <= 0;
//            i <= 0;
//        end else if (en) begin
//            if (i < 8) begin
//                for (j = 0; j < 16; j = j + 1) begin
//                    output_majority[j + 16 * i] <= (line1[j + 16 * i] & line2[j + 16 * i]) | (line1[j + 16 * i] & line3[j + 16 * i]) | (line2[j + 16 * i] & line3[j + 16 * i]);
//                end
//                i = i + 1;
//            end else begin
//                flag <= 1;
//                i <= 0;
//            end
//        end else begin
//            flag <= 0;
//            output_majority <= 0;
//        end
//    end
//endmodule 
