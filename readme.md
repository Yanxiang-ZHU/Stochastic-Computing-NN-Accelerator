# Stochastic Computing Neural Network Accelerator

## Project Overview

The rapid advancement of neural networks has led to fast-evolving architectures that achieve increasingly higher accuracy in tasks such as image processing, speech recognition, and natural language processing (NLP). This project focuses on the innovation and exploration of data representations within neural networks, particularly **Binary Neural Networks (BNNs)** and **Stochastic Computing (SC) based Neural Networks**.

While neural network inference is typically carried out on GPUs, other hardware platforms such as CPUs, TPUs, and FPGAs are also used. Compared to general-purpose GPUs, **FPGAs offer superior reconfigurability, low latency, and excellent energy efficiency**, making them highly suitable for edge inference applications.

Furthermore, the reconfigurable nature of FPGAs allows for **fine-grained bit-level control**, especially beneficial when dealing with binary data or stochastic bitstreams. This enables more efficient data utilization and faster inference speeds than traditional GPU inference, which typically operates on data with a minimum of 8-bit precision.

---

## Repository Structure

```
Stochastic-Computing-NN-Accelerator/
│
├── Binary_NN/                         # Binary Neural Network training and inference
│   ├── raw_python_source_binary/      # Python source files for binarized training
│   │   ├── readme.md
│   │   ├── mnist.py                   # MNIST classification task
│   │   ├── cifar10.py                 # CIFAR10 classification task
│   │   ├── cat_dog.py                 # Cat vs Dog classification task
│   │   └── ...
│   ├── MNIST_DNN_binary/              # PyTorch-based BNN training & FPGA inference for MNIST
│   │   ├── python_src/
│   │   ├── verilog_src/
│   │   ├── parameter/                 # Trained weights for inference
│   │   └── MNIST_Report.dox           # Project report
│   └── CIFAR10_RESNET_binary/
│       └── verilog_src_/          <-- [unfinished]
│
├── StochasticComputing_NN/            # Stochastic bitstream-based NN training and inference
│   ├── Properties_Exploration_SC/     # Exploring computing properties of stochastic sequences
│   │   ├── Countones_Methodology/     # Countones-based SC properties
│   │   ├── Random_Methodology/        # Generate stochastic sequences
│   │   ├── Majority_Methodology/      # Explore different MAJ methods, like parameter distribution under various polarization schemes
│   │   ├── NN_Validation/             # Test accuracy under single kernel / DNN / CNN
│   │   └── Archive_Components_Verilog/# Some verilog module for components like CNN kernel
│   ├── MNIST_DNN_SC/                  # SC-based DNN for MNIST: training & hardware inference
│   │   ├── python_src/
│   │   └── verilog_src/
│   │   │   ├── Method_Basic/
│   │   │   └── Method_Advanced/  <-- [unfinished]
│   ├── MNIST_CNN_SC/                  # SC-based CNN for MNIST: training & hardware inference
│   │   ├── python_src/           <-- [unfinished]
│   │   └── verilog_src/       
│   │   │   ├── Method_Basic/
│   │   │   └── Method_Advanced/  <-- [yet to start]
│   └── CIFAR10_CNN_SC/                # SC-based CNN for CIFAR10: training & hardware inference
│       ├── python_src/        <-- [unfinished]
│       └── verilog_src/       <-- [yet to start]
```

---

## Development & Execution Platforms

- **Python Version:** Python 3.7  
  - **AI Framework:** Mainly [PyTorch](https://pytorch.org/), partially [TensorFlow](https://www.tensorflow.org/)
- **HDL Version:** Verilog 2001, System Verilog
  - **Hardware Platform:** Xilinx XC7A35T and XC7A200T FPGA development boards  
  - **Development Tool:** [Xilinx Vivado Design Suite](https://www.xilinx.com/products/design-tools/vivado.html)

---

## How to Run

### 1. Running Python Scripts

- **Case 1.1:** Most training or simulation files can be directly executed, like:
  ```bash
  python mnist.py
  ```
- **Case 1.2:** Some scripts require parameter configuration within the file. Please refer to the comments inside the respective script folders.

### 2. Running Verilog Code via Vivado

- **Case 2.1:** Open the corresponding `.xpr` project file using Vivado. You can proceed with synthesis, implementation, and bitstream generation as usual.

---

## Notes

- Binary NN Python source code in `Binary-NN/raw python source - binary` refers to a reimplementation and expansion based on:  
  https://github.com/YuanshengZhao/adiabaticbinary.git
- The **"unfinished"** status in some subfolders (e.g., `CIFAR10 RESNET - binary`) indicates ongoing development.

---


## License

MIT License
