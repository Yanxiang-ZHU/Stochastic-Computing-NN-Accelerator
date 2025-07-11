import matplotlib.pyplot as plt

plt.rcParams['font.family'] = 'Times New Roman'
with open('maj.txt', 'r') as f:
    converted_floats = [float(line.strip()) for line in f.readlines()]
with open('mean.txt', 'r') as f:
    processed_results = [float(line.strip()) for line in f.readlines()]

plt.figure(figsize=(10, 6))
plt.scatter(processed_results, converted_floats, color='purple', edgecolors='black', s=5, alpha=0.5)
plt.title('Multiple-layer Majority Gate for 729 bit <256bit>', fontsize=16, fontweight='bold')
plt.xlabel('Value: Mean', fontsize=14)
plt.ylabel('Value: Result from MAJ', fontsize=14)
plt.gca().set_facecolor('white')
plt.grid(True, linestyle='--', color='black', alpha=0.6)
plt.xticks(fontsize=12)
plt.yticks(fontsize=12)
plt.gca().spines['top'].set_linewidth(1.2)
plt.gca().spines['right'].set_linewidth(1.2)
plt.gca().spines['left'].set_linewidth(1.2)
plt.gca().spines['bottom'].set_linewidth(1.2)
plt.show()
