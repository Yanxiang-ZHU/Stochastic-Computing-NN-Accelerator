`timescale 1ns / 1ps

module MG3(
    input wire a,   
    input wire b,  
    input wire c,  
    output wire y 
);

assign y = (a & b) | (a & c) | (b & c);

endmodule
