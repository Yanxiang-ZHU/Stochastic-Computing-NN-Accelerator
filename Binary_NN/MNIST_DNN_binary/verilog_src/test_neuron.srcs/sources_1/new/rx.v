`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/11 20:43:16
// Design Name: 
// Module Name: rx
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

// module rx(
//     input wire clk,
//     input wire rst_n,
//     input wire rx_pin,
//     output reg [783:0] rx_data,
//     output reg rx_data_valid
//     );

// /******************内部变量**********************/
// reg rx_reg1;
// reg rx_reg2;
// reg rx_reg3;
// reg start_flag;
// reg Byte_valid = 0;     
// reg work_en;//工作使能
// reg save;
// reg bit_flag;//比特标志
// reg [3:0] bit_cnt;//数据位计数，0-8
// reg [7:0] rx_data_reg;//数据寄存�?
// reg rx_flag_reg;//数据标识符寄存器

// reg [6:0] image_cnt;    //98个rx_data_reg拼接成一个image也即rx_data
// reg image_flag;         //当一张Image拼接完成之后,image_flag置为1,给到rx_data_valid

// reg end_flag;  //每次�?张图片结束后置为1�?10个时钟周期之后置�?0�? 解决start_flag和Work_en的冲突问�?
// reg [9:0] count_end;  //�?后的循环里end�?

// /*******************数据打拍**********************/
// //数据打拍，避免亚稳�??
// always@(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             rx_reg1=1;
//         else
//             rx_reg1=rx_pin;
//     end
 
// always@(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             rx_reg2=1;
//         else
//             rx_reg2=rx_reg1;
//     end
 
// always@(posedge clk or negedge rst_n)
//     begin
//         if(rst_n==0)
//             rx_reg3=1;
//         else
//             rx_reg3=rx_reg2;
//     end
 
// /*******************起始标志********Byte_valid和start_flag**************/
// always@(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             start_flag<=0;
//         else if (image_flag==1)
//             start_flag <= 0;
//         else if((Byte_valid == 0)&&(rx_reg1==0)&&(end_flag == 0))
//         begin
//             if (work_en==0)
//                 start_flag<=1;
//             Byte_valid = 1;
//         end
//         else if ((Byte_valid == 1)&&(bit_cnt==8)&&(end_flag == 0))
//             Byte_valid = 0;
//         else 
//             start_flag<=0;
//     end
 
// /*******************工作使能**********************/
// always@(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             work_en<=0;
//         else if (image_flag == 1)
//             work_en=0;
//         else if (start_flag==1)
//             work_en<=1;
//     end

// /*******************数据位计�?**********************/
// always@(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//         begin
//             bit_cnt=0;
//             save = 0;
//         end
//         else if((bit_cnt==8))                            
//             bit_cnt=9; 
//         else if((bit_cnt == 9))
//         begin
//             bit_cnt = 0;
//             save = 1;
//         end
//         else if((bit_cnt>0))
//             bit_cnt=bit_cnt+1;
//         else if ((((Byte_valid == 0)&&(rx_reg1==0)&&(end_flag == 0))||(Byte_valid))&&(bit_cnt==0))
//         begin
//             bit_cnt = 1;
//             save = 0;
//         end

//     end
        
// /*******************数据寄存�?**********************/
// always@(negedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             rx_data_reg=8'b0;
//         else if((bit_cnt>=2)&&(bit_cnt<=9))
//             rx_data_reg={rx_data_reg[6:0],rx_pin};                     //原数据rx_reg3
//         else
//             rx_data_reg = 8'b0;
//     end
    
// /*******************数据标识符寄存器**********************/
// always@(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             rx_flag_reg=0;
//         else if((bit_cnt==8))
//             rx_flag_reg=1;
//         else 
//             rx_flag_reg=0;
//     end

// /*******************结尾加工**********************/
// always @(posedge clk or negedge rst_n)
//     begin
//         if (!rst_n) begin
//             count_end = 0;
//             end_flag = 0;
//             image_flag = 0;
//         end
//         else if((end_flag == 1) &&(count_end != 10))
//         begin
//             count_end <= count_end + 1;
//         end
//         else if ((end_flag == 1) &&(count_end == 10))
//         begin
//             count_end = 0;
//             end_flag = 0;
//             image_flag = 0;
//         end
//         else if (image_cnt == 98)
//         begin 
//             image_flag = 1;
//             end_flag = 1;
//         end
//     end


// /*******************数据输出**********************/
// always @ (posedge clk or negedge rst_n) begin
//     if (!rst_n) 
//     begin
//         rx_data = 784'b0;
//         image_cnt = 0;
//     end 
//     else if(work_en)
//     begin
//         if (image_cnt == 0)
//         begin
//             rx_data = 784'b0;
//         end
//         if ((save) && (image_cnt < 98))
//         begin
//             // rx_data[(783-8*image_cnt)-:8] <= rx_data_reg;
//             rx_data[(image_cnt*8)+:8] <= rx_data_reg;
//             image_cnt <= image_cnt + 1;
//         end
//     end
// end


// always@(posedge clk or negedge rst_n)
//     begin
//         if(!rst_n)
//             rx_data_valid<=0;
//         else
//             rx_data_valid <= image_flag;
//     end

// endmodule


module rx(
    input wire next,
    input wire clk,
    input wire rst_n,
    input wire rx_pin,
    output reg [783:0] rx_data,
    output reg rx_data_valid
    );

wire [7:0] one_rx;
wire rx_done;
reg [6:0] image_cnt;
reg tag;

single_rx  single_rx(
    .clk    (clk),
    .rst_n  (rst_n),
    .pin    (rx_pin),
    .one_rx (one_rx),
    .rx_done (rx_done)
);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n || next == 1)
    begin
        rx_data = 0;
        rx_data_valid = 0;
        tag = 0;
        image_cnt = 0;
    end
    else if (rx_done == 0)
    begin
        tag = 0;
    end
    else if (rx_done == 1)
    begin 
        if (tag == 0)
        begin
            if (image_cnt < 98)
            begin
                // rx_data[(image_cnt*8)+:8] <= one_rx;
                rx_data[(783-8*image_cnt)-:8] <= one_rx;
                image_cnt <= image_cnt + 1;
            end
            else if (image_cnt == 98)
            begin
                rx_data_valid = 1;
            end

            tag = 1;
        end
    end
end

endmodule
