// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Sun Jun 29 15:50:51 2025
// Host        : YanX running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {c:/Users/39551/Desktop/Stochastic-Computing-for-MNIST/DNN-like
//               Structure/DNN_Stochastic/DNN_Stochastic.gen/sources_1/ip/weight_fc2/weight_fc2_stub.v}
// Design      : weight_fc2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "dist_mem_gen_v8_0_14,Vivado 2023.2" *)
module weight_fc2(a, spo)
/* synthesis syn_black_box black_box_pad_pin="a[12:0],spo[127:0]" */;
  input [12:0]a;
  output [127:0]spo;
endmodule
