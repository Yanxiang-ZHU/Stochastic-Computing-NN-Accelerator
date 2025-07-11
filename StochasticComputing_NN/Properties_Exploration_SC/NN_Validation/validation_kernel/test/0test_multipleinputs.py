import random
import struct
import numpy as np

def float_to_random(value):
    probability = (value + 1) / 2
    return ''.join(str(1 if random.random() < probability else 0) for _ in range(512))

def generate_trend_data(size=729000, noise_level=0.01):
    base_values = np.linspace(-1, 1, size)
    noise = np.random.uniform(-noise_level, noise_level, size)
    result = np.clip(base_values + noise, -1, 1)
    return result

def main():
    random_floats = generate_trend_data()

    random_sequences = [float_to_random(f) for f in random_floats]

    with open('random_sequences.txt', 'w') as file1:
        file1.write('\n'.join(random_sequences))

    with open('random_floats.txt', 'w') as file3:
        file3.write('\n'.join(map(str, random_floats)))

if __name__ == "__main__":
    main()