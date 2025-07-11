`timescale 1ns/1ps

module LSFR_tb;

  reg                 clk;
  reg                 rst_n;
  reg                 ivalid;
  reg       [31:0]    seed;
  wire      [31:0]    data;

  LSFR LSFR_inst(
    .clk            (clk),
    .rst_n          (rst_n),
    .ivalid         (ivalid),
    .seed           (seed),
    .data           (data)
  );
  
  initial clk = 1'b0;
  always # 5 clk = ~clk;
  
  initial begin
  rst_n = 1'b0;
  ivalid = 1'b0;
  seed = 32'd0;
  # 201;
  
  rst_n = 1'b1;
  #200;
  
  @ (posedge clk);
  # 2;
  ivalid = 1'b1;
  seed = {$random} % 4294967295;
  @ (posedge clk);
  # 2;
  ivalid = 1'b0;
  seed = 32'd0;
  
  #200000;
  $stop;
  end

endmodule 