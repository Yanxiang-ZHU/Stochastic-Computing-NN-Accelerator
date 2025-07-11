import numpy as np

def read_sequences(filename):
    with open(filename, 'r') as f:
        sequences = [line.strip() for line in f.readlines()]
    return sequences

def bitwise_majority_vote(sequences):
    bit_array = np.array([[int(bit) for bit in seq] for seq in sequences])
    majority_result = np.sum(bit_array, axis=0) >= 5 
    return ''.join(map(str, majority_result.astype(int)))

def process_sequences(file1, file2, output_file):
    first_sequences = read_sequences(file1)
    last_sequences = read_sequences(file2)
    
    num_groups = len(first_sequences) // 9  
    results = []
    
    for i in range(num_groups):
        xor_results = []
        for j in range(9):
            f_seq = np.array([int(bit) for bit in first_sequences[i * 9 + j]])
            l_seq = np.array([int(bit) for bit in last_sequences[i * 9 + j]])
            xor_result = np.logical_not(np.logical_xor(f_seq, l_seq)).astype(int) 
            xor_results.append(xor_result)
        
        compressed_seq = bitwise_majority_vote(xor_results)
        results.append(compressed_seq)
    
    with open(output_file, 'w') as f:
        f.write('\n'.join(results))

file1 = "first_200_sequences.txt"
file2 = "last_200_sequences.txt"
output_file = "output_results.txt"

process_sequences(file1, file2, output_file)
