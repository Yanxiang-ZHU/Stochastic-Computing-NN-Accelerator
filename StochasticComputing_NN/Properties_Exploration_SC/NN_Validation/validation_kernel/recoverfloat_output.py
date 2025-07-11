import numpy as np

def binary_to_float(binary_str):
    integer_value = binary_str.count('1')
    max_value = 512
    float_value = (integer_value / max_value) * 2 - 1
    return float_value

input_file = "output_results.txt"
output_file = "converted_floats.txt"

with open(input_file, "r") as f:
    binary_sequences = f.readlines()

float_values = [binary_to_float(line.strip()) for line in binary_sequences]

with open(output_file, "w") as f:
    for value in float_values:
        f.write(f"{value:.6f}\n")

print(f"Converted {len(float_values)} binary sequences to floats and saved to '{output_file}'.")
