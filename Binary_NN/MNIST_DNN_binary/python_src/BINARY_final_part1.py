import numpy as np
import torch
import torchvision
from torchvision import transforms
import torch.nn as nn
import torch.optim as optim
import matplotlib.pyplot as plt
import json
# import torch.nn.functional as F
# import pandas as pd
# from torch.utils.data import DataLoader
# plt.ion()

n_epochs = 10  # Number of training epochs

# Optimizer hyperparameters
n_learning_rate = 0.001  # Learning rate
# log_interval = 10
random_seed = 1
torch.manual_seed(random_seed)

transform = transforms.Compose([
    transforms.ToTensor(),  # Convert data to PyTorch tensor
    transforms.Normalize((0.5,), (0.5,))
])

train_dataset = torchvision.datasets.MNIST(root='./data', train=True, transform=transform, download=True)
test_dataset = torchvision.datasets.MNIST(root='./data', train=False, transform=transform, download=True)

# Get data and labels from training and test sets
x_train = train_dataset.data.float()  # Training images
y_train = train_dataset.targets       # Training labels

x_test = test_dataset.data.float()    # Test images
y_test = test_dataset.targets         # Test labels

x_train = (x_train - 0.5) / 0.5
# x_train = np.where(x_train > 0, 1, 0).astype(np.float32)
x_train = torch.sign(torch.tensor(x_train).clone().detach())

x_test = (x_test - 0.5) / 0.5
# x_test = np.where(x_test > 0, 1, 0).astype(np.float32)
x_test = torch.sign(torch.tensor(x_test).clone().detach())

# print(x_train.shape)
# print(y_train.shape)
# print(x_test.shape)
# print(y_test.shape)

input_dim = 784
num_outputs = 10

# Build the network
class BinaryDense(nn.Module):
    def __init__(self, input_dim, num_outputs, use_bias):
        super(BinaryDense, self).__init__()
        self.num_outputs = num_outputs
        self.use_bias = use_bias

        self.kk = nn.Parameter(torch.tensor(10.0))
        self.nmk = nn.Parameter(torch.tensor(1.0))
        self.kernel = nn.Parameter(torch.randn(input_dim, num_outputs))
        nn.init.uniform_(self.kernel, -0.1, 0.1)
        if self.use_bias:
            self.bias = nn.Parameter(torch.zeros(num_outputs))
        self.reset_parameters()

    def reset_parameters(self):
        nn.init.uniform_(self.kernel, -0.1, 0.1)
        nn.init.constant_(self.nmk, 1.0)
        nn.init.constant_(self.kk, 10.0)
        if self.use_bias:
            nn.init.constant_(self.bias, 0.0)

    def set_kk(self, kknew):
        self.kk.data.fill_(torch.tensor(kknew))

    def forward(self, inputs):
        # print(inputs.shape, torch.tanh(self.kernel * self.kk).shape)
        if self.use_bias:
            if self.kk.item() < 1e3:
                out = self.nmk * torch.matmul(inputs, torch.tanh(self.kernel * self.kk)) + self.bias
            else:
                out = self.nmk * torch.matmul(inputs, torch.sign(self.kernel)) + self.bias
        else:
            if self.kk.item() < 1e3:
                out = self.nmk * torch.matmul(inputs, torch.tanh(self.kernel * self.kk))
            else:
                out = self.nmk * torch.matmul(inputs, torch.sign(self.kernel))
        return out

class BinaryActivation(nn.Module):
    def __init__(self):
        super(BinaryActivation, self).__init__()
        self.kk = nn.Parameter(torch.tensor(10.0))

    def reset_parameters(self):
        nn.init.constant_(self.kk, 10.0)

    def set_kk(self, kkx):
        self.kk.data.fill_(torch.tensor(kkx))

    def forward(self, inputs):
        if self.kk.item() < 1e3:
            return torch.tanh(inputs * self.kk)
        else:
            return torch.sign(inputs)

class TRAINER():
    def __init__(self, mdl):
        self.mdl = mdl
        self.kk = mdl.binary_dense1.kk.data.numpy()
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    def evaluate(self, x_test, y_test):
        self.mdl.eval()
        with torch.no_grad():
            x_test, y_test = x_test.to(self.device), y_test.to(self.device)
            outputs = self.mdl(x_test)
            _, predicted = torch.max(outputs.data, 1)
            correct = (predicted == y_test).sum().item()
            total = y_test.size(0)
            accuracy = correct / total
            return accuracy

    def set_kk(self, kk):
        self.mdl.binary_dense1.kk.data.fill_(torch.tensor(kk))
        self.mdl.binary_dense2.kk.data.fill_(torch.tensor(kk))
        self.mdl.binary_activation.kk.data.fill_(torch.tensor(kk))

    def evaluateBinary(self, x_test, y_test):
        self.set_kk(1e4)
        res = self.evaluate(x_test, y_test)
        self.set_kk(self.kk)
        return res

    def evaluateLoss(self, x_test, y_test, criterion):
        self.mdl.eval()
        total_loss = 0.0
        for i in range(0, len(x_test), 64):
            inputs, labels = x_test[i:i + 64].to(self.device), y_test[i:i + 64].to(self.device)
            outputs = self.mdl(inputs)
            loss = criterion(outputs, labels)
            total_loss += loss.item()
        average_loss = total_loss / len(x_test)
        return average_loss

    def train(self, x_train, y_train, x_test, y_test, patience=3, learning_rate=n_learning_rate):
        self.mdl.to(self.device)
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.Adam(self.mdl.parameters(), lr=learning_rate)

        tr_res = []
        vl_res = []
        kk_res = []
        binbest = 0
        wait = 0

        while True:
            torch.cuda.empty_cache()
            self.mdl.train()
            total_loss = 0.0
            for i in range(0, len(x_train), 64):
                inputs, labels = x_train[i:i + 64].to(self.device), y_train[i:i + 64].to(self.device)
                optimizer.zero_grad()
                outputs = self.mdl(inputs)
                loss = criterion(outputs, labels)
                total_loss += loss.item()
                loss.backward()
                optimizer.step()
            average_loss = total_loss / len(x_train)
            tr_res.append([average_loss, self.evaluateBinary(x_train, y_train)])
            bin_accuracy = self.evaluateBinary(x_test, y_test)
            vl_res.append([self.evaluateLoss(x_test, y_test, criterion), bin_accuracy])
            kk_res.append(self.kk)
            wait += 1
            if bin_accuracy > binbest:
                wait = 0
                binbest = bin_accuracy
            print(f" Wait: {wait}, kk: {self.kk}, Best Binary Accuracy: {binbest:.4f}")

            if wait >= patience:
                wait = 0
                self.kk *= 2
                self.set_kk(self.kk)
                print(f"Set kk: {self.kk}")

            if self.kk > 1e3:
                break
        return tr_res, vl_res, kk_res

class BinaryModel(nn.Module):
    def __init__(self, n_hidden):
        super(BinaryModel, self).__init__()
        self.flatten = nn.Flatten()
        self.binary_dense1 = BinaryDense(28 * 28, n_hidden, use_bias=True)
        self.binary_activation = BinaryActivation()
        self.dropout = nn.Dropout(0.2)
        self.binary_dense2 = BinaryDense(n_hidden, 10, use_bias=False)

    def forward(self, x):
        x = self.flatten(x)
        x = self.binary_dense1(x)
        x = self.binary_activation(x)
        x = self.dropout(x)
        x = self.binary_dense2(x)
        return x

n_hidden = 192

model = BinaryModel(n_hidden)
print(model)

tr = TRAINER(model)
res = tr.train(x_train, y_train, x_test, y_test)

plt.plot(np.array(res[0])[:, 1], label="train")
plt.show()
plt.plot(np.array(res[1])[:, 1], label="test")
plt.show()

# ///Further modification needed below
# wts = model.state_dict()
# for key, value in wts.items():
#     if key == 'binary_dense1.kernel':
#         ker1 = value
#     if key == 'binary_dense2.kernel':
#         ker2 = value
#     if key == 'binary_dense1.bias':
#         bias1 = value
#     if key == 'binary_dense2.bias':
#         bias2 = value
#     print(key, value)
# print('////////////')
# print(ker1, bias1, ker2, bias2)

# Get model state dict
model_state_dict = model.state_dict()

param_names = [
    'binary_dense1.kernel', 'binary_dense2.kernel', 'binary_dense1.bias', 'binary_dense2.kk',
    'binary_dense1.kk', 'binary_dense1.nmk', 'binary_activation.kk', 'binary_dense2.nmk'
]

ker1, ker2, bias1, k2, k1, nmk1, kka, nmk2 = None, None, None, None, None, None, None, None

for key, value in model_state_dict.items():
    if key == param_names[0]:
        ker1 = torch.sign(value)
    elif key == param_names[1]:
        ker2 = torch.sign(value)
    elif key == param_names[2]:
        bias1 = value
    elif key == param_names[3]:
        k2 = value
    elif key == param_names[5]:
        nmk1 = value
    print(key, value.shape)
bias1 = bias1 / nmk1

ker1_com0 = ~(ker1.T == 1)
ker2_com = ~(ker2.T == 1)

ker1_com = torch.zeros((192, 49), dtype=torch.int32)
for i in range(192):
    for j in range(0, 784, 16):
        binary_chunk = ker1_com0[i, j:j + 16].to(torch.int16).cpu()
        binary_integer = int(''.join(map(str, binary_chunk.numpy())), 2)
        ker1_com[i, j // 16] = binary_integer

matrix_shape = (len(test_dataset), 49)
image_r = torch.full(matrix_shape, 0)
for i in range(len(test_dataset)):  # Process 10,000 images one by one
    image, label = test_dataset[i]
    image = torch.sign(image)
    image_com0 = image.flatten() == 1
    image_com = torch.zeros((49,), dtype=torch.int32)
    for j in range(0, 784, 16):
        binary_chunk = image_com0[j:j + 16].to(torch.int16)
        binary_integer = int(''.join(map(str, binary_chunk.numpy())), 2)
        image_com[j // 16] = binary_integer
    image_r[i] = image_com

label_r = torch.zeros(len(test_dataset))
for i in range(len(test_dataset)):  # Process 10,000 labels one by one
    _, label_r[i] = test_dataset[i]

ker1 = ker1_com.tolist()
ker2 = ker2_com.tolist()
bias1 = bias1.tolist()
k2 = k2.tolist()
label_r = label_r.tolist()
image_r = image_r.tolist()

config = {
    "ker1": ker1,
    "ker2": ker2,
    "bias1": bias1,
    "k2": k2,
    "label_r": label_r,
    "image_r": image_r,
}

with open("config_binary.json", "w") as config_file:
    json.dump(config, config_file)

ix = torch.randint(0, len(y_test), (1,)).item()
in1 = x_test[ix]
in1 = in1.to("cuda:0")
out1 = y_test[ix]
with torch.no_grad():
    res = model(in1.unsqueeze(0))
res = res.cpu()
res = res.numpy()
for i in range(10):
    print(i, res[0, i])
res = torch.from_numpy(res)
if torch.argmax(res) == out1:
    print("Correct prediction")
else:
    print("Incorrect prediction")
