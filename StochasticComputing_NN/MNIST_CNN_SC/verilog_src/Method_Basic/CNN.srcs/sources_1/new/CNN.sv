`timescale 1ns / 1ps

module CNN #(
    parameter LENTH = 256
)(
    input wire clk,
    input wire rst_n,
    input wire [LENTH-1:0] input_val [0:783],
    output reg [3:0] output_val,
    output reg flag
);

    typedef enum logic [2:0] {STATE_INIT, STATE_CONV, STATE_FC, STATE_FC_WAIT, STATE_COMP} state_t;
    state_t state;
    reg [LENTH-1:0] conv_weight [0:15][0:8];
    (* ram_style = "block" *) reg [LENTH-1:0] conv_out [0:10815];
    reg [31:0] fc_out [0:9][0:LENTH-1];
    reg [31:0] count1s [0:9];
    integer i, j;
    integer row, bit_idx, ones_count;
    integer max_idx, max_count;
    integer count;
    integer conv_idx;
    
    // Kernel instantiation
    reg [LENTH-1:0] kernel_input [0:8];
    reg en_kernel;
    wire [15:0] kernel_flag;
    wire [LENTH-1:0] kernel_out [0:15];

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : conv_layer
            kernel #(.LENTH(LENTH)) conv_kernel (
                .clk(clk),
                .rst_n(rst_n),
                .en(en_kernel),
                .weight(conv_weight[k]),
                .input_val(kernel_input),
                .output_val(kernel_out[k]),
                .flag(kernel_flag[k])
            );
        end
    endgenerate
    
    reg [13:0] fc_addr;
    wire [LENTH-1:0] fc_weight_out;

    bram_fcweight u_fc_weight (
        .clka(clk),
        .addra(fc_addr),
        .douta(fc_weight_out)
    );

    initial begin
        $readmemb("conv_weight.mem", conv_weight);
        state = STATE_INIT;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_INIT;
            flag <= 0;
            en_kernel <= 0;
        end else begin
            case (state)
                STATE_INIT: begin
                    flag <= 0;
                    state <= STATE_CONV;
                    conv_idx <= 0;
                    en_kernel <= 0;
                end
                
                STATE_CONV: begin
                    if (conv_idx < 26*26) begin
                        if (kernel_flag == 0) begin
                            en_kernel = 1;
                        end
                        
                        else if (kernel_flag == 16'b1111111111111111) begin
                            en_kernel = 0;
                            for (i = 0; i < 16; i = i + 1) begin
                                conv_out[26*26*i + conv_idx] = kernel_out[i];
                            end
                            conv_idx = conv_idx + 1;

                            if (conv_idx == 26*26) 
                                state <= STATE_FC;
                        end
                        
                        kernel_input[0] = input_val[(conv_idx/26  )*28 + (conv_idx%26)   ];
                        kernel_input[1] = input_val[(conv_idx/26  )*28 + (conv_idx%26)+1 ];
                        kernel_input[2] = input_val[(conv_idx/26  )*28 + (conv_idx%26)+2 ];
                        kernel_input[3] = input_val[(conv_idx/26+1)*28 + (conv_idx%26)   ];
                        kernel_input[4] = input_val[(conv_idx/26+1)*28 + (conv_idx%26)+1 ];
                        kernel_input[5] = input_val[(conv_idx/26+1)*28 + (conv_idx%26)+2 ];
                        kernel_input[6] = input_val[(conv_idx/26+2)*28 + (conv_idx%26)   ];
                        kernel_input[7] = input_val[(conv_idx/26+2)*28 + (conv_idx%26)+1 ];
                        kernel_input[8] = input_val[(conv_idx/26+2)*28 + (conv_idx%26)+2 ];
                    end                        
                end
                
                STATE_FC: begin
                    row <= 0;
                    bit_idx <= 0;
                    ones_count <= 0;
                    fc_addr <= 0;
                    state <= STATE_FC_WAIT;
                end
                
                STATE_FC_WAIT: begin
                    if (row < 10) begin
                        if (bit_idx < LENTH) begin
                            if (j < 10816) begin
                                ones_count <= ones_count + ^(~(conv_out[j][bit_idx] ^ fc_weight_out[bit_idx]));
                                fc_addr <= fc_addr + 1;
                            end else begin
                                fc_out[row][bit_idx] <= ones_count;
                                ones_count <= 0;
                                j <= 0;
                                bit_idx <= bit_idx + 1;
                                fc_addr <= row * LENTH;
                            end
                        end else begin
                            row <= row + 1;
                            bit_idx <= 0;
                        end
                    end else begin
                        state <= STATE_COMP;
                    end
                end
                
                STATE_COMP: begin
                    max_idx = 0;
                    max_count = 0;
                    for (row = 0; row < 10; row = row + 1) begin
                        count = 0;
                        for (bit_idx = 0; bit_idx < LENTH; bit_idx = bit_idx + 1) begin
                            count = count + fc_out[row][bit_idx];
//                            if (fc_out[row][bit_idx])
//                                count = count + 1;
                        end
                        count1s[row] = count;
                        if (count > max_count) begin
                            max_count = count;
                            max_idx = row;
                        end
                    end
                    output_val <= max_idx;
                    flag <= 1;
                    state <= STATE_INIT;
                end
            endcase
        end
    end
endmodule

