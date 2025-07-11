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

def convert_to_128bit_probability(data):
    random_matrix = np.random.uniform(-1, 1, (data.shape[0], data.shape[1], 256))
    return (random_matrix <= data[..., np.newaxis]).astype(int)

def save_data(data, filename):
    with open(filename, 'w') as f:
        for row in data:
            for value in row:
                f.write(''.join(map(str, value))+'\n')

input_filename = 'input_val.txt'
output_filename = 'input_val_s.txt'

data = load_data(input_filename)
converted_data = convert_to_128bit_probability(data)
save_data(converted_data, output_filename)

print("success", output_filename)
