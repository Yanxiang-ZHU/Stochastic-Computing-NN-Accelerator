import numpy as np
import re
import matplotlib.pyplot as plt
from scipy.stats import gaussian_kde

def load_weights(filename):
    with open(filename, 'r') as f:
        content = f.read()

    fn1_pattern = r"module\.conv1\.weight:\s*(\[\[\[\[.*?\]\]\]\])"
    match = re.search(fn1_pattern, content)

    if match:
        fn1_data = match.group(1)
        number_pattern = r"-?\d+\.\d+|-?\d+"
        weight1 = [float(m.group()) for m in re.finditer(number_pattern, fn1_data)]
        weight1 = np.array(weight1).reshape(-1,1)

    fn2_pattern = r"module\.fn1\.weight:\s*(\[\[.*?\]\])"
    fn2_data = re.search(fn2_pattern, content, re.DOTALL)

    def parse_matrix(data):
        return np.array(eval(data.group(1)))
    weight2 = parse_matrix(fn2_data) if fn2_data else None

    return weight1, weight2

def float_to_bin_sequence(matrix):
    rows, cols = matrix.shape
    bin_matrix = []

    for i in range(rows):
        row_bin = []
        for j in range(cols):
            rand_seq = np.random.uniform(-1, 1, 100)
            bin_str = ''.join(['1' if matrix[i, j] >= r else '0' for r in rand_seq])
            row_bin.append(bin_str)
        bin_matrix.append(row_bin)

    return bin_matrix

def save_to_txt(filename, bin_matrix):
    with open(filename, 'w') as f:
        for row in bin_matrix:
            f.write("\n".join(row) + "\n")

input_file = "bestmodel_conv.txt"  
weight1, weight2 = load_weights(input_file)

data = weight1.flatten()
kde = gaussian_kde(data, bw_method=0.05)
x = np.linspace(-1, 1, 1000)
y = kde(x)
plt.figure(figsize=(6, 4))
plt.plot(x, y, color='black', linewidth=1)
plt.xlabel("Value")
plt.ylabel("Density")
plt.xlim(-1, 1)
plt.ylim(0, max(y) * 1.1)
plt.grid(True, linestyle='--', linewidth=0.5, alpha=0.7)
plt.tight_layout()
plt.show()

data = weight2.flatten()
kde = gaussian_kde(data, bw_method=0.05)
x = np.linspace(-1, 1, 1000)
y = kde(x)
plt.figure(figsize=(6, 4))
plt.plot(x, y, color='black', linewidth=1)
plt.xlabel("Value")
plt.ylabel("Density")
plt.xlim(-1, 1)
plt.ylim(0, max(y) * 1.1)
plt.grid(True, linestyle='--', linewidth=0.5, alpha=0.7)
plt.tight_layout()
plt.show()

if weight1 is not None and weight2 is not None:
    bin_weight1 = float_to_bin_sequence(weight1)
    bin_weight2 = float_to_bin_sequence(weight2)

    save_to_txt("conv_weight.txt", bin_weight1)
    save_to_txt("fc_weight.txt", bin_weight2)
    print("success")
else:
    print("failure")
