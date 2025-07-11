import numpy as np

def process_files(file1, file2, output_file):
    with open(file1, "r") as f1, open(file2, "r") as f2:
        floats1 = [float(line.strip()) for line in f1.readlines()]
        floats2 = [float(line.strip()) for line in f2.readlines()]
    
    if len(floats1) != 9000 or len(floats2) != 9000:
        raise ValueError("Both files must contain exactly 9000 floats.")

    results = []
    for i in range(0, 9000, 9):
        group1 = floats1[i:i+9]
        group2 = floats2[i:i+9]
        # product_sum = np.sqrt(abs(sum(x * y for x, y in zip(group1, group2))) / 3) * np.sign(sum(x * y for x, y in zip(group1, group2)))
        product_sum = sum(x * y for x, y in zip(group1, group2))
        results.append(product_sum)
    
    with open(output_file, "w") as f_out:
        for result in results:
            f_out.write(f"{result:.6f}\n")

    print(f"Processed {len(results)} groups and saved results to '{output_file}'.")

file1 = "first_200_floats.txt"
file2 = "last_200_floats.txt"
output_file = "processed_results.txt"

process_files(file1, file2, output_file)
