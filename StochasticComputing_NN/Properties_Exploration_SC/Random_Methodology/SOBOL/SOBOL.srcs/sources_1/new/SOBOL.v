module sobol_random #(
    parameter SAMPLES = 256,
    parameter SET_INDEX = 1000 
)(
    input clk,
    input rst_n,
    input valid,
    input [31:0] comp,
    output reg [SAMPLES-1:0] result
);

    reg [31:0] sobol_matrix[0:31];
    reg [31:0] sobol_index;
    reg [31:0] current_sample;
    reg [SAMPLES-1:0] result_reg;
    integer i;
    integer j;
    integer column;
    reg [31:0] sample;
    reg [31:0] gray_index;
    reg [31:0] tz;
    reg [31:0] lfsr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 32'hDEADBEEF;
        end else begin
            lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        end
    end

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            sobol_matrix[i] = 1 << (31 - i);
        end
    end

    function [31:0] gray;
        input [31:0] n;
        begin
            gray = n ^ (n >> 1);
        end
    endfunction

    function [31:0] trailing_zeros;
        input [31:0] n;
        reg [31:0] count;
        begin
            count = 0;
            while ((n & 1) == 0 && n > 0) begin
                count = count + 1;
                n = n >> 1;
            end
            trailing_zeros = count;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sobol_index <= SET_INDEX;
            current_sample <= 0;
            result_reg <= 0;
            result <= 0;
            column <= 0;
        end 
        else if (valid) begin
            column = 0;
            sample = 0;
            gray_index = gray(sobol_index);
            
            for (j = 0; gray_index > 0 && j < 32; gray_index = gray_index >> 1, j = j + 1) begin
                if ((gray_index & 32'b1) > 0) begin
                    sample = sample ^ sobol_matrix[column];
                end
                column = column + 1;
            end

            if (current_sample < SAMPLES) begin
                sobol_index = sobol_index + 1;
                tz = trailing_zeros(sobol_index);
                sample = sample ^ sobol_matrix[tz];
                sample = sample ^ lfsr;

                if (sample < comp) begin
                    result_reg = (result_reg << 1) | 1;
                end else begin
                    result_reg = (result_reg << 1) | 0;
                end
                current_sample <= current_sample + 1;
            end 
            else begin
                result <= result_reg;
                result_reg <= 0;
                current_sample <= 0;
            end
        end
    end
endmodule
