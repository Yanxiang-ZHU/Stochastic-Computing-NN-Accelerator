import numpy as np

def maj3(arr):
    x = (arr.sum(axis=0) >= 2).astype(int)
    decreaser = (np.random.uniform(-1, 1, 512) < 0.7).astype(int)
    return 1 - np.bitwise_xor(x, decreaser)

def binary_to_float(binary_str):
    integer_value = binary_str.count('1')
    max_value = 512
    float_value = (integer_value / max_value) * 2 - 1
    return float_value

with open("random_sequences.txt", "r") as f:
    data = np.array([list(map(int, line.strip())) for line in f])

output_sequences = []
for i in range(0, len(data), 729):
    group = data[i:i + 729]
    for _ in range(6): 
        group = np.array([maj3(group[j:j + 3]) for j in range(0, len(group), 3)])
    output_sequences.append("".join(map(str, group[0])))

float_values = [binary_to_float(line.strip()) for line in output_sequences]

with open("maj.txt", "w") as f:
    for value in float_values:
        f.write(f"{value:.6f}\n")

print("success!")