`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/12 13:51:02
// Design Name: 
// Module Name: tx
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


module tx(
    input wire clk,
    input wire rst_n,
    input wire [3:0] result,
    input wire en_tx,
    output reg tx_data_valid,
    output reg tx
    );

    reg [3:0] count;
    reg start_bit;
    reg end_bit;

    ////////// 波特率相关index //////////
    reg baud_valid;       //波特计数有效位
    reg [15:0] baud_cnt;         //波特率计数器
    reg baud_pulse;       //波特率采样脉冲

    reg [2:0] r_current_state;  //当前状态
    reg [2:0] r_next_state;     //次态

    localparam STATE_IDLE = 3'b000;         //空闲状态
    localparam STATE_START = 3'b001;        //开始状态
    localparam STATE_DATA = 3'b011;         //数据发送状态
    localparam STATE_END = 3'b101;          //结束状态

    reg [3:0]   r_tx_cnt;      //接收数据位计数

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            baud_cnt <= 16'h0000;
        else if(!baud_valid)
            baud_cnt <= 16'h0000;
        else if(baud_cnt == 5208 - 1)
            baud_cnt <= 16'h0000;
        else
            baud_cnt <= baud_cnt + 1'b1;
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            baud_pulse <= 1'b0;
        else if(baud_cnt == 5208/2 -1)
            baud_pulse <= 1'b1;
        else
            baud_pulse <= 1'b0;
    end

    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            r_current_state <= STATE_IDLE;
        else if(!baud_valid)
            r_current_state <= STATE_IDLE;
        else if(baud_valid && baud_cnt == 16'h0000)
            r_current_state <= r_next_state;
    end
           
    always@(*)
    begin
        case(r_current_state)
            STATE_IDLE:     r_next_state <= STATE_START;
            STATE_START:    r_next_state <= STATE_DATA;
            STATE_DATA:
                if(r_tx_cnt == 8)
                    begin
                            r_next_state <= STATE_END;  
                    end
                else
                    begin
                            r_next_state <= STATE_DATA;
                    end
            STATE_END:      r_next_state <= STATE_IDLE;
            default:;
        endcase
    end
   
   
    reg [7:0]   r_data_tx;
 
    always@(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
                begin
                    baud_valid  <= 1'b0;
                    r_data_tx   <= 8'd0;
                    tx   <= 1'b1;
                    r_tx_cnt    <= 4'd0;
                    tx_data_valid <= 0;
                end
            else
                case(r_current_state)
                    STATE_IDLE:begin
                            tx   <= 1'b1;
                            r_tx_cnt    <= 4'd0;
                            tx_data_valid <= 0;
                            if(en_tx)
                                begin
                                    baud_valid <= 1'b1;
                                    r_data_tx <= {4'b0, result[3:0]};
                                end
                        end
                    STATE_START:begin
                            if(baud_pulse)
                                tx   <= 1'b0;
                        end
                    STATE_DATA:begin
                            if(baud_pulse)
                                begin
                                    r_tx_cnt <= r_tx_cnt + 1'b1;
                                    tx <= r_data_tx[0];
                                    r_data_tx <= {1'b0 ,r_data_tx[7:1]};
                                end
                        end
                    STATE_END:begin
                            if(baud_pulse)
                                begin
                                    tx <= 1'b1;
                                    tx_data_valid <= 1;
                                    baud_valid <= 1'b0;
                                end
                        end
                    default:;
                endcase
        end

endmodule
