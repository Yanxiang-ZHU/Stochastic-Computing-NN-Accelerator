`timescale 1ns / 1ps

module single_rx(
    input clk,
    input rst_n,
    input pin,
    output reg [7:0] one_rx,
    output reg rx_done
    );

wire                start_flag;
reg					uart_rxd_d0;
reg					uart_rxd_d1;
reg					rx_flag;
reg		[3:0]		rx_cnt;	
reg		[15:0]		bps_cnt;
reg		[7:0]		tx_data;
 
assign	start_flag	=	uart_rxd_d1	&	(~uart_rxd_d0);	
 
always@(posedge	clk	or	negedge	rst_n)
begin
	if(!rst_n)
        begin
		uart_rxd_d0		<=		1'b0;
		uart_rxd_d1		<=		1'b0;
		end
	else	
        begin
		uart_rxd_d0		<=		pin;
		uart_rxd_d1		<=		uart_rxd_d0;
		end
end
 
always@(posedge	clk	or	negedge	rst_n)
begin
	if(!rst_n)
		rx_flag			<=		1'b0;
	else	
		if(start_flag)
			rx_flag		<=		1'b1;
		else if((bps_cnt == 5208/2)  &&	(rx_cnt	== 4'd9))
			rx_flag		<=		1'b0;
		else
			rx_flag		<=		rx_flag;
end
 
always@(posedge	clk	or	negedge	rst_n)
begin
	if(!rst_n)
        begin
		bps_cnt			<=		16'd0;
		rx_cnt			<=		4'd0;
		end
	else if(rx_flag)
        begin
		if(bps_cnt	<	5208-1)
            begin
			bps_cnt		<=		bps_cnt	+	1'b1;
			rx_cnt		<=		rx_cnt;
			end
		else	
            begin
			bps_cnt		<=		16'd0;
			rx_cnt		<=		rx_cnt	+	1'b1;
			end
        end
	else	
        begin
            bps_cnt		<=		16'd0;
            rx_cnt		<=		4'd0;
		end
end
 
always@(posedge	clk	or	negedge	rst_n)begin
	if(!rst_n)
		tx_data			<=		8'd0;
	else	if(rx_flag)		
			if(bps_cnt ==	5208/2)begin
				case(rx_cnt)
					4'd1	:	tx_data[0]	<=	uart_rxd_d1;
					4'd2	:	tx_data[1]	<=	uart_rxd_d1;
					4'd3	:	tx_data[2]	<=	uart_rxd_d1;
					4'd4	:	tx_data[3]	<=	uart_rxd_d1;
					4'd5	:	tx_data[4]	<=	uart_rxd_d1;
					4'd6	:	tx_data[5]	<=	uart_rxd_d1;
					4'd7	:	tx_data[6]	<=	uart_rxd_d1;
					4'd8	:	tx_data[7]	<=	uart_rxd_d1;
					default	:	;
				endcase
				end
			else
				tx_data		<=		tx_data;
	else
		tx_data		<=		8'd0;
end
	
always@(posedge	clk	or	negedge	rst_n)begin
	if(!rst_n)begin
		rx_done		<=		1'b0;
		one_rx	    <=		8'd0;
		end
	else	if(rx_cnt == 4'd9)begin
				rx_done		<=		1'b1;
				one_rx	<=		tx_data;
			end
	else	begin
			rx_done	<=		1'b0;
			one_rx	<=		8'd0;
			end
end

endmodule
