import random
import struct

def float_to_random_128bit(value):
    probability = (value + 1) / 2
    return ''.join(str(1 if random.random() < probability else 0) for _ in range(512))

def main():
    random_floats = [random.uniform(-1, 1) for _ in range(18000)]

    random_128bit_sequences = [float_to_random_128bit(f) for f in random_floats]

    with open('first_200_sequences.txt', 'w') as file1:
        file1.write('\n'.join(random_128bit_sequences[:9000]))

    with open('last_200_sequences.txt', 'w') as file2:
        file2.write('\n'.join(random_128bit_sequences[9000:]))

    with open('first_200_floats.txt', 'w') as file3:
        file3.write('\n'.join(map(str, random_floats[:9000])))

    with open('last_200_floats.txt', 'w') as file4:
        file4.write('\n'.join(map(str, random_floats[9000:])))

if __name__ == "__main__":
    main()