`timescale 1ns / 1ps

module mac191
#(parameter dim_in = 191, dim_th = 7)
(
    input   wire    clk,
    input   wire    rst_n,
    input   wire    en,
    input   wire    [dim_in:0]  inp,
    input   wire    [dim_in:0]  weight,
    output  reg    [dim_th:0]  out,
    output  reg    flag
    );
    
    reg    [1:0]    step;
    reg    [dim_in:0]  mul;
    wire   [dim_th:0]  count_192;
    
    wire    [dim_th:0]  sum; 
    wire    flag_adder;
    reg    en_adder;  
    reg    [dim_in:0]  inp_adder;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || !en)
        begin
            step <= 1;
            en_adder <= 0;
            flag <= 0;
        end
        else
        begin
            if (step == 1)
            begin
                mul = inp ^ weight;
                step = 2;
            end
            else if (step == 2)
            begin
                if (flag_adder == 0)
                begin
                    inp_adder <= mul;
                    en_adder <= 1;
                end
                else if (flag_adder == 1)
                begin
                    out <= sum;
                    flag <= 1;
                    en_adder <= 0;
                end                
            end
        end
    end

    adder_192   adder192(
        .clk(clk),
        .en_adder(en_adder),
        .inp(inp_adder),
        .sum(sum),
        .flag_adder(flag_adder)
    );
    
    
endmodule