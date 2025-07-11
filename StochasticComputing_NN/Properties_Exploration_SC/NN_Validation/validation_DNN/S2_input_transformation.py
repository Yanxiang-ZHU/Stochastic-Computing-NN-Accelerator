import numpy as np

input_file = "test.txt"
output_file = "input_val.txt"

with open(input_file, "r") as f:
    lines = f.readlines()

normalized_lines = []
for line in lines:
    numbers = np.array(list(map(float, line.strip().split())))
    max_abs = np.max(np.abs(numbers))
    if max_abs > 0:
        numbers /= max_abs
    normalized_lines.append(" ".join(map(str, numbers)))

with open(output_file, "w") as f:
    f.write("\n".join(normalized_lines))


def load_data(filename):
    return np.loadtxt(filename)

def float_to_bin_sequence(data, seq_len=256):
    data = (data + 1) / 2  # Normalize values to [0, 1]
    bin_matrix = np.random.rand(data.shape[0], data.shape[1], seq_len) < data[..., np.newaxis]
    return bin_matrix.astype(int)

def save_data(data, filename):
    with open(filename, 'w') as f:
        for row in data:
            for value in row:
                f.write(''.join(map(str, value))+'\n')

input_filename = 'input_val.txt'
output_filename = 'input_val_s.txt'

data = load_data(input_filename)
converted_data = float_to_bin_sequence(data)
save_data(converted_data, output_filename)

print("success", output_filename)
