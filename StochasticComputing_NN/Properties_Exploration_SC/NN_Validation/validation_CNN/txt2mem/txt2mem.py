with open("conv_weight.txt", "r") as infile, open("conv_weight.mem", "w") as outfile:
    for line in infile:
        bin_value = line.strip()
        outfile.write(bin_value + "\n")

print("conv_weight.mem")

with open("fc_weight.txt", "r") as infile, open("fc_weight.mem", "w") as outfile:
    for line in infile:
        bin_value = line.strip()
        outfile.write(bin_value + "\n")

print("fc_weight.mem")
