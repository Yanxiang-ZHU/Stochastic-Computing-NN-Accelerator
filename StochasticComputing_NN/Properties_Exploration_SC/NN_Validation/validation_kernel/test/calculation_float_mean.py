import numpy as np

with open("random_floats.txt", "r") as f:
    data = np.array([float(line.strip()) for line in f])

means = np.mean(data.reshape(-1, 729), axis=1)

with open("mean.txt", "w") as f:
    for mean in means:
        f.write(f"{mean}\n")

print("success!")