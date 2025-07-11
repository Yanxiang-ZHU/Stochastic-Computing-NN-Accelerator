def mem_to_coe(mem_filename, coe_filename, radix=2):
    with open(mem_filename, "r") as mem_file:
        lines = mem_file.readlines()

    lines = [line.strip() for line in lines if line.strip()]

    with open(coe_filename, "w") as coe_file:
        coe_file.write(f"memory_initialization_radix={radix};\n")
        coe_file.write("memory_initialization_vector=\n")
        coe_file.write(",\n".join(lines) + ";\n")

    print(f"success: {mem_filename} → {coe_filename}")

mem_to_coe("fc_weight.mem", "fc_weight.coe", radix=2)
