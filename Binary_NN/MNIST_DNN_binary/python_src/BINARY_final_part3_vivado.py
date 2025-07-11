import json
import math
import pickle


def decimal_to_binary(decimal_num, num_bits):
    binary_str = bin(decimal_num)[2:]
    return binary_str.zfill(num_bits)


def main():
    image_r = []
    with open("config_binary.json", "r") as file:
        config = json.load(file)

    ker1_com = config["ker1"]
    ker1_com = [[int(element) for element in row] for row in ker1_com]

    ker2_com = config["ker2"]
    bias1_com = config["bias1"]
    label_r = config["label_r"]

    image_r = config["image_r"]
    image_r = [[int(element) for element in row] for row in image_r]

    ker1 = ""
    for line in ker1_com:
        line_str = ""
        for decimal_num in line:
            line_str += decimal_to_binary(decimal_num, 16)
        ker1 += line_str + "\n"

    image = ""
    for line in image_r:
        line_str = ""
        for decimal_num in line:
            line_str += decimal_to_binary(decimal_num, 16)
        image += line_str + "\n"

    ker2 = ""
    for line in ker2_com:
        binary_line = ""
        for value in line:
            if value:
                binary_line += '1'
            else:
                binary_line += '0'
        ker2 += binary_line + "\n"

    bias = ""
    for b in bias1_com:
        bias += "0" + bin(math.floor((784 - b) / 2))[2:] + "\n"

    label = ' '.join(map(str, label_r))


    with open("ker1.txt", "w") as file:
        file.write(ker1)

    with open("image.txt", "w") as file:
        file.write(image)

    with open("ker2.txt", "w") as file:
        file.write(ker2)

    with open("bias.txt", "w") as file:
        file.write(bias)

    with open('label.txt', 'w') as file:
        file.write(label)

if __name__ == "__main__":
    main()
