import torch
import torchvision
from torchvision import transforms
from torchvision.datasets import MNIST
from torch.utils.data import DataLoader
import time
import numpy as np
import json
import pickle

def start_timer():
    return time.time()

def stop_timer(start_time):
    elapsed_time = time.time() - start_time
    return elapsed_time


with open("config_binary.json", "r") as config_file:
    config = json.load(config_file)

ker1_com = config["ker1"]
ker2_com = config["ker2"]
bias1_com = config["bias1"]
k2_com = config["k2"]
label_r = config["label_r"]
image_r = config["image_r"]

ker1_com = torch.Tensor(ker1_com).to(torch.int32).to('cuda:0')
ker2_com = torch.Tensor(ker2_com).to(torch.uint8).to('cuda:0')
bias1_com = torch.Tensor(bias1_com)
k2_com = torch.tensor(k2_com, dtype=torch.float32).to('cuda:0')
label_r = torch.Tensor(label_r).to(torch.uint8).to('cuda:0')
image_r = torch.Tensor(image_r).to(torch.int32).to('cuda:0')

thr = np.floor((784 - bias1_com) / 2).to('cuda:0')

# Build lookup table for counting ones in binary representation
sum_one = []
for i in range(65536):
    binary_representation = bin(i)[2:]
    ones = binary_representation.count('1')
    sum_one = np.append(sum_one, ones).astype(np.int8)
sum_one = torch.tensor(sum_one).to('cuda:0')

correct_count = 0
total_count = 0

start_time = start_timer()
with torch.no_grad():
    for i in range(len(label_r)):  # Process 10,000 images one by one
        label = label_r[i]
        image = image_r[i]
        temp = sum_one[torch.bitwise_xor(ker1_com, image)]
        xnor1 = torch.sum(temp, dim=1)
        xnu1 = xnor1 > thr
        xnor2 = torch.sum(torch.bitwise_xor(ker2_com, xnu1.unsqueeze(0).expand(10, -1)), dim=-1).unsqueeze(0)

        total_count += 1
        if torch.argmax(xnor2[0]) == label:
            correct_count += 1
        if total_count % 100 == 0:  # Output every 100 images processed
            print(f'Tested {total_count}/{len(label_r)} images')

elapsed_time = stop_timer(start_time)

test_accuracy = (correct_count / total_count) * 100
print(f'Test Accuracy: {test_accuracy:.2f}%')
print(f"Elapsed {elapsed_time:.2f} seconds")
