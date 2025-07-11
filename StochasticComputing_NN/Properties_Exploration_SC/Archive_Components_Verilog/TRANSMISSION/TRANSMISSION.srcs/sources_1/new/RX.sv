/*
    RX contains two parts. 
    First is receiving all fixed-point numbers ranging from 0 to 1 . 
    Second is transforming format from fixed-point to random sequence.
*/
`timescale 1ns / 1ps

module RX#(
    parameter LENTH = 256,
    parameter SIZE = 784,
    parameter BAUD = 9600
)(
    input wire clk,
    input wire rst_n,
    input wire rx_pin,
    output reg [LENTH-1:0] rx_data [0:SIZE-1],
    output reg flag
    );

    wire [7:0] one_rx;
    wire rx_done;
    reg [6:0] image_cnt;
    reg [31:0] fp_fig [0:SIZE-1];
    reg [31:0] fp_num;    // register the number of temporary fixed-point number
    reg [2:0] fp_count;
    integer i;

    localparam SET_INDEX = 1000;    // index of generation for random sequences
    reg tran_valid;
    reg [31:0] one_fp;
    wire [LENTH-1:0] one_tran;
    wire tran_flag;

    reg logic_switch;

    single_rx  #(
        .BAUD(BAUD)
    )single_rx(
        .clk    (clk),
        .rst_n  (rst_n),
        .pin    (rx_pin),
        .one_rx (one_rx),
        .rx_done (rx_done)
    );

    sobol_random #(
        .SAMPLES(LENTH),
        .SET_INDEX(SET_INDEX)
    )sobol_random(
        .clk    (clk),
        .rst_n  (rst_n),
        .valid  (tran_valid),
        .comp   (one_fp),
        .result (one_tran),
        .flag   (tran_flag)
    );

    typedef enum logic [1:0] {STATE_INIT, STATE_MID, STATE_RDY, STATE_TRANS} state_t;
    state_t state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
        begin
            flag <= 0;
            state <= STATE_INIT;
            logic_switch <= 0;       // logic_switch: 0 #FIRST LOGIC; 1 #SECOND LOGIC
        end 
        else begin
            case (state) 
                STATE_INIT: begin
                    // FIRST LOGIC: receiving figure datas
                    if (!logic_switch) begin
                        for (i = 0; i < SIZE; i = i + 1)
                            fp_fig[i] <= 0;
                        fp_count <= 0;
                        image_cnt <= 0;
                        state <= STATE_MID;
                    end

                    // SECOND LOGIC: transforming from fixed-point to random sequence
                    if (logic_switch) begin
                        one_fp <= 0;
                        tran_valid <= 0;
                        image_cnt <= 0;
                        for (i = 0; i < SIZE; i = i + 1)
                            rx_data[i] <= 0;
                        state <= STATE_TRANS;
                    end
                end

                STATE_MID: begin
                    if (rx_done) begin
                        flag <= 0;
                        fp_num[(31-8*fp_count)-:8] <= one_rx;
                        if (fp_count == 2)
                            state <= STATE_RDY;
                        fp_count <= fp_count + 1;
                    end
                end

                STATE_RDY: begin
                    if (rx_done) begin
                        fp_count = 0;
                        fp_num[7:0] = one_rx;
                        fp_fig[image_cnt] = fp_num;
                        if (image_cnt == SIZE-1) begin
                            state <= STATE_INIT;
                            logic_switch <= 1;
                        end else begin
                            image_cnt <= image_cnt + 1;
                            state <= STATE_MID;
                        end
                    end
                end

                STATE_TRANS: begin
                    if (image_cnt == SIZE) begin
                        flag <= 1;
                        state <= STATE_INIT;
                        logic_switch <= 0;
                    end else begin
                        if (tran_flag) begin
                            tran_valid <= 0;
                            rx_data[image_cnt] <= one_tran;
                            image_cnt <= image_cnt + 1;
                        end else begin
                            tran_valid <= 1;
                            one_fp <= fp_fig[image_cnt];
                        end
                    end
                end
            endcase
        end
    end
endmodule


/*
    Single_rx module is designed to decode ONE-BYTE data in UART format.
*/
module single_rx#(
    parameter BAUD = 9600
)(
    input clk,
    input rst_n,
    input pin,
    output reg [7:0] one_rx,
    output reg rx_done
);

    wire start_flag;
    reg	uart_rxd_d0;
    reg	uart_rxd_d1;
    reg	rx_flag;		
    reg	[3:0] rx_cnt;	
    reg	[15:0] bps_cnt;	
    reg	[7:0] tx_data;	

    // 50,000,000/BAUD calculates from:  (1s/BAUD)/(1/50MHz), in which 50MHz is the frequency of the target FPGA
    localparam BPS = 50000000 / BAUD;
    localparam BPS_HALF = (50000000 / BAUD) / 2;
    
    assign	start_flag = uart_rxd_d1 & (~uart_rxd_d0);
    
    // delay two clock cycles to stabilize the signal
    always@(posedge	clk	or negedge rst_n) begin
    	if(!rst_n) begin 
    		uart_rxd_d0	<= 1'b0;
    		uart_rxd_d1	<= 1'b0;
    	end else begin
    		uart_rxd_d0 <= pin;
    		uart_rxd_d1 <= uart_rxd_d0;
    	end
    end
    
    always @(posedge clk or negedge rst_n) begin
    	if(!rst_n)
    		rx_flag <= 1'b0;
    	else begin
    		if(start_flag)
    			rx_flag <= 1'b1;
    		else if(rx_cnt == 4'd9) 
    			rx_flag <= 1'b0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
    	if(!rst_n) begin
    		bps_cnt	<= 16'd0;
    		rx_cnt <= 4'd0;
    	end else if(rx_flag) begin
    		if(bps_cnt < BPS-1) begin
    			bps_cnt	<= bps_cnt + 1'b1;
    		end else begin
    			bps_cnt <= 16'd0;
    			rx_cnt <= rx_cnt + 1'b1;
    		end
        end else begin
            bps_cnt <= 16'd0;
            rx_cnt <= 4'd0;
    	end
    end
    
    always @(posedge clk or negedge rst_n) begin
    	if(!rst_n)
    		tx_data <= 8'd0;
    	else if(rx_flag) begin
            if(bps_cnt == BPS_HALF) begin
                case(rx_cnt)
                    4'd1: tx_data[0] <= uart_rxd_d1;
                    4'd2: tx_data[1] <= uart_rxd_d1;
                    4'd3: tx_data[2] <= uart_rxd_d1;
                    4'd4: tx_data[3] <= uart_rxd_d1;
                    4'd5: tx_data[4] <= uart_rxd_d1;
                    4'd6: tx_data[5] <= uart_rxd_d1;
                    4'd7: tx_data[6] <= uart_rxd_d1;
                    4'd8: tx_data[7] <= uart_rxd_d1;
                    default: ;
                endcase
            end
        end else
    		tx_data <= 8'd0;
    end
    
    always @(posedge clk or negedge rst_n)begin
    	if (!rst_n) begin
    		rx_done <= 1'b0;
    		one_rx <= 8'd0;
    	end else if(rx_cnt == 4'd9 && !rx_flag) begin
            rx_done <= 1'b1;
            one_rx <= tx_data;
    	end else begin
            rx_done <= 1'b0;
            one_rx <= 8'd0;
    	end
    end
endmodule


/*
    Sobol_random module is designed to generate 'RANDOM SEQUENCES' for fixed-point numbers
*/
module sobol_random #(
    parameter SAMPLES = 256,
    parameter SET_INDEX = 1000 
)(
    input clk,
    input rst_n,
    input valid,
    input [31:0] comp,
    output reg [SAMPLES-1:0] result,
    output reg flag
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
        integer i;
        begin
            count = 0;
            for (i = 0; i < 32; i = i + 1) begin
                if (n[0] == 1) begin
                    break;
                end
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
            flag <= 0;
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
                flag <= 0;
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
                flag <= 1;
                result_reg <= 0;
                current_sample <= 0;
            end
        end
    end
endmodule
