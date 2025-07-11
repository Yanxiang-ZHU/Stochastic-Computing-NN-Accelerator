`timescale 1ns / 1ps

module xadd #(
    parameter IM_LENTH = 32,
    parameter IM_DEPTH = 16
)(
    input clk,
    input rst_n,
    input en,
    input [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] x_self,
    input [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] x_add,
    output reg [IM_LENTH*IM_LENTH*IM_DEPTH*32-1:0] output_data,
    output reg flag
);

localparam SIZE = IM_LENTH * IM_LENTH * IM_DEPTH;

reg [31:0] a1_data;
reg [31:0] a2_data;
reg add_valid;
wire add_flag;
wire [31:0] add_result;

integer i, j;

addfloat batnor_add (
    .clk(clk),
    .a_tdata(a1_data),
    .b_tdata(a2_data),
    .operation_tvalid(add_valid),
    .result_tvalid(add_flag),
    .result_tdata(add_result)
);

reg [4:0] state;
localparam IDLE = 0, LOAD = 1, WAIT = 2, STORE = 3, DONE = 4;

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        state <= IDLE;
        flag <= 0;
        i <= 0;
        j <= 0;
        add_valid <= 0;
    end 
    
    else 
    begin
        case (state)
            IDLE: 
            begin
                if (en) 
                begin
                    state <= LOAD;
                    i <= 0;
                    j <= 0;
                    flag <= 0;
                end
            end

            LOAD: 
            begin
                if (i < SIZE) 
                begin
                    a1_data <= x_self[32*i+31 -: 32];
                    a2_data <= x_add[32*i+31 -: 32];
                    add_valid <= 1;
                    state <= WAIT;
                end 
                else 
                begin
                    state <= DONE;
                end
            end

            WAIT: 
            begin
                if (add_flag) 
                begin
                    add_valid <= 0;
                    state <= STORE;
                end
            end

            STORE: 
            begin
                output_data[32*i+31 -: 32] <= add_result;
                i <= i + 1;
                state <= LOAD;
            end

            DONE: 
            begin
                flag <= 1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule