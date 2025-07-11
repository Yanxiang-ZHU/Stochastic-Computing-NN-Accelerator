from modules.transform import Transform
from modules import layers, operations
from modules.Base import BaseModel, BaseLayer
import os
import torch
import numpy as np
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
from torch.utils.data.sampler import SubsetRandomSampler
import torch.nn.functional as F
from tqdm import tqdm
import matplotlib.pyplot as plt
from torch.optim.lr_scheduler import CosineAnnealingLR

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
MAGENTA = "\033[95m"
# # SEQ_LEN = 1024
# # trans = Transform(SEQ_LEN)
# polarization_intervals = [8]  # epoch % interval
# # sequence_lengths = [128, 256, 512, 1024, 2048]  # SEQ_LEN options

# results_file = open("model_performance_results3.txt", "w")
# results_file.write("Parameters | FP Test Accuracy | SS Test Accuracy\n")
# results_file.write("-" * 60 + "\n")


def fit(model: nn.modules.Module, optim, lossfunc, trainloader: DataLoader):
    model.train()
    totalloss = 0
    for data, target in trainloader:
        data, target = data.cuda(), target.cuda()
        data=data.reshape(-1,36*36)
        bs_per_row = torch.max(torch.abs(data), dim=1, keepdim=True)[0]
        data/=bs_per_row
        data = torch.tanh(6*data)
        data=data.reshape(-1,1,36,36)
        optim.zero_grad()
        output = model(data)    
        loss = lossfunc(output, target) 
        loss.backward()
        optim.step()
        with torch.no_grad():
            for module in model.modules():
                if isinstance(module, layers.StreamLinear):
                    module.weight.data.clip_(-1, 1)
                if isinstance(module, layers.StreamConv):
                    module.weight.data.clip_(-1, 1)
        with torch.no_grad():
            totalloss += loss.item() * data.size(0)
    return totalloss / len(trainloader.sampler)


def evaluate(
    model: nn.modules.Module, val_loader: DataLoader, lossfunc: nn.CrossEntropyLoss
):
    model.eval()
    loss = 0
    correct_top1 = 0
    total = 0
    with torch.no_grad():
        for inputs, labels in val_loader:
            inputs, labels = inputs.cuda(), labels.cuda()
            inputs=inputs.reshape(-1,36*36)
            bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
            inputs/=bs_per_row
            inputs = torch.tanh(6*inputs)
            inputs=inputs.reshape(-1,1,36,36)
            outputs = model(inputs)
            loss += lossfunc(outputs, labels).item() * inputs.size(0)
            _, predicted_top1 = torch.max(outputs, 1)
            correct_top1 += (predicted_top1 == labels).sum().item()
            total += labels.size(0)
        loss /= len(val_loader.sampler)
        acc_top1 = correct_top1 / total
    return loss, acc_top1


class CNN(BaseModel):
    def __init__(self, seq_len):
        super().__init__(seq_len)  
        self.conv1 = layers.StreamConv(1, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.conv2 = layers.StreamConv(9, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.conv3 = layers.StreamConv(9, 9,   stride=2, padding=1, seq_len=seq_len, kernel=3)
        self.conv4 = layers.StreamConv(9, 27,  stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.conv5 = layers.StreamConv(27, 27, stride=2, padding=1, seq_len=seq_len, kernel=3)
        
        self.ac1 = layers.MAJ(seq_len = seq_len)
        self.ac2 = layers.MAJ(seq_len = seq_len)
        self.ac3 = layers.MAJ(seq_len = seq_len)
        self.ac4 = layers.MAJ(seq_len = seq_len)
        self.ac5 = layers.MAJ(seq_len = seq_len)
        self.ac6 = layers.MAJ(seq_len = seq_len)
        
        self.fn1 = layers.StreamLinear(27, 10, seq_len=seq_len)  

        self.dropout1 = nn.Dropout(p=0.2)
        self.dropout2 = nn.Dropout(p=0.2)
        self.dropout3 = nn.Dropout(p=0.2)
        self.dropout4 = nn.Dropout(p=0.2)
        self.dropout5 = nn.Dropout(p=0.2)

        self.dynamic_alpha = 1

    def dynamic(self, dynamic_alpha):
        self.dynamic_alpha = dynamic_alpha
        
    def forward(self, x: torch.Tensor):  
        x = self.conv1(x)
        mid = self.ac1(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropout1(mid)

        x = self.conv2(mid)
        mid = self.ac2(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropout2(mid)
        
        x = self.conv3(mid)
        mid = self.ac3(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropout3(mid)
        
        x = self.conv4(mid)
        mid = self.ac4(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropout4(mid)
        
        x = self.conv5(mid)
        mid = self.ac5(x, x.shape[-1], self.dynamic_alpha)

        mid = mid.reshape(mid.shape[0], mid.shape[1], -1)
        mid = self.ac6(mid, mid.shape[-1], self.dynamic_alpha)
        mid = self.dropout5(mid)

        x = mid.reshape(mid.size(0), -1)
        x = self.fn1(x)
        result = x.sum(dim=-1)
        return result
    
    def Sforward(self, stream: torch.Tensor):        
        x = self.conv1.Sforward(stream)
        mid = self.ac1.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.conv2.Sforward(mid)
        mid = self.ac2.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.conv3.Sforward(mid)
        mid = self.ac3.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.conv4.Sforward(mid)
        mid = self.ac4.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.conv5.Sforward(mid)
        mid = self.ac5.Sforward(x, x.shape[-1], self.dynamic_alpha)
        mid = mid.reshape(mid.shape[0], mid.shape[1], -1, mid.shape[-1])
        mid = mid.permute(0,1,3,2)
        mid = self.ac6.Sforward(mid, mid.shape[-1], self.dynamic_alpha)

        # mid = self.trans.s2f(mid)
        # x = mid.reshape(mid.size(0), -1)
        # x = self.fn1(x)
        # result = x.sum(dim=-1)
        
        # x = mid.reshape(mid.size(0), 27, SEQ_LEN // 32)
        x = mid.reshape(mid.size(0), 27, self.seq_len // 32)
        x = self.fn1.Sforward(x)
        x = self.trans.s2f(x)
        result = x.sum(dim=-1)
        return result

path = "/work/home/zhuyx/StochasticComputation-main/data"

def load_data():
    transform = transforms.Compose([
        transforms.Resize((36, 36)), 
        transforms.ToTensor(), 
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    train_dataset = datasets.MNIST(
        root=path, train=True, download=False, transform=transform
    )
    test_dataset = datasets.MNIST(
        root=path, train=False, download=False, transform=transform
    )

    num_samples = len(train_dataset)
    indices = list(range(num_samples))
    np.random.shuffle(indices)
    split = int(np.floor(0.2 * num_samples))
    train_idx, val_idx = indices[split:], indices[:split]
    train_sampler = SubsetRandomSampler(train_idx)
    val_sampler = SubsetRandomSampler(val_idx)

    train_loader = DataLoader(
        train_dataset, batch_size=32, sampler=train_sampler, num_workers=8
    )
    val_loader = DataLoader(
        train_dataset, batch_size=32, sampler=val_sampler, num_workers=8
    )
    test_loader = DataLoader(
        test_dataset, batch_size=2, shuffle=False, num_workers=8, pin_memory=True
    )
    return train_loader, val_loader, test_loader


device = torch.device("cuda")
# model = CNN(SEQ_LEN)
# lossfunc = nn.CrossEntropyLoss().to(device)
# train_loader, val_loader, test_loader = load_data()

# lr = 0.01
# counter = 0
# min_val_loss = np.inf

# if torch.cuda.device_count() > 1:
#     model = nn.DataParallel(model)
#     model.cuda()
#     print(f"Using {torch.cuda.device_count()} GPUs with DataParallel")
# else:
#     model.cuda()
#     print("Using single GPU")


# min_val_loss, val_acc1 = evaluate(model, test_loader, lossfunc)
# print(f"init: val_loss: {min_val_loss}, top1_acc:{val_acc1}")

# for epoch in range(100):
#     if counter / 10 == 1:
#         counter = 0
#         lr = lr * 0.5
#         print(GREEN + f"lr reduced to {lr}" + RESET)

#     # polarization
#     if epoch > 30 and epoch % 10 == 0:
#         with torch.no_grad():
#             for module in model.modules():
#                 if isinstance(module, layers.StreamLinear):
#                     tx = ((module.weight.data + 1) / 2)
#                     module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
#                 if isinstance(module, layers.StreamConv):
#                     tx = ((module.weight.data + 1) / 2)
#                     module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
            
#     optimi = torch.optim.SGD(model.parameters(), lr=lr, momentum=0.9, weight_decay=5e-4)
#     loss = fit(model, optimi, lossfunc, train_loader)
#     val_loss, val_acc1 = evaluate(model, val_loader, lossfunc)
#     print(f"epoch: {epoch+1}, loss: {loss}, val_loss: {val_loss}, acc:{val_acc1}")
#     if val_loss < min_val_loss:
#         min_val_loss = val_loss
#         counter = 0
#         test_loss, test_acc1 = evaluate(model, test_loader, lossfunc)
#         print(MAGENTA + f"test perf: {test_acc1}" + RESET)
#         torch.save(model.state_dict(), "ptemp2s4_best.pth")
#     else:
#         counter += 1

def test_model(model, state, seq_len, test_loader, mode="FP"):
    trans = Transform(seq_len)
    model.load_state_dict(state)
    model.eval()
    
    if mode == "SS":
        model.generate_Sparams()
    
    correct_top1 = 0
    total = 0
    with torch.no_grad():
        for inputs, labels in tqdm(test_loader):
            inputs = inputs.to(device)
            labels = labels.to(device)
            inputs = inputs.reshape(-1, 36*36)
            bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
            inputs /= bs_per_row
            inputs = torch.tanh(6*inputs)
            
            if mode == "FP":
                inputs = inputs.reshape(-1, 1, 36, 36)
                outputs = model(inputs)
            else:  # SS mode
                inputs = trans.f2s(inputs.reshape(-1, 1, 36, 36))
                outputs = model.Sforward(inputs)
                
            _, predicted_top1 = torch.max(outputs, 1)
            correct_top1 += (predicted_top1 == labels).sum().item()
            total += labels.size(0)
            if mode == "SS" and total == 1000:
                break
                
        acc_top1 = correct_top1 / total
    return acc_top1


# # test code (addition)
# SEQ_LEN = 1024
# model = CNN(SEQ_LEN)
# train_loader, val_loader, test_loader = load_data()
# trans = Transform(SEQ_LEN)
# if torch.cuda.device_count() > 1:
#     model = nn.DataParallel(model)
# model.cuda()

polarization_intervals = [5] 
for polarization_interval in polarization_intervals:
    print(f"Training with polarization interval: {polarization_interval}")

    lossfunc = nn.CrossEntropyLoss().to(device)
    train_loader, val_loader, test_loader = load_data()
    
    lr = 0.01
    counter = 0
    min_val_loss = np.inf
    kk = 0

    SEQ_LEN = 1024
    trans = Transform(SEQ_LEN)
    model = CNN(SEQ_LEN)
    if torch.cuda.device_count() > 1:
        model = nn.DataParallel(model)
    model.cuda()
    
    min_val_loss, val_acc1 = evaluate(model, test_loader, lossfunc)
    print(f"init: val_loss: {min_val_loss}, top1_acc:{val_acc1}")
    
    for epoch in range(100):
        if (counter == 5) or epoch % 20 == 19:
            counter = 0
            lr = lr * 0.1
            print(GREEN + f"lr reduced to {lr}" + RESET)
            
        # Different kk for Different Polarization Degree
        kk = 1.5 ** ((epoch - 10) // 10) if epoch in range(10, 100, 10) else kk
            
        # polarization
        # if epoch > 30 and epoch % polarization_interval == 0:
        if epoch > 10:
            with torch.no_grad():
                for module in model.modules():
                    if isinstance(module, layers.StreamLinear):
                        # tx = ((module.weight.data + 1) / 2)
                        # module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
                        module.weight.data = torch.tanh(kk * module.weight.data)
                    if isinstance(module, layers.StreamConv):
                        # tx = ((module.weight.data + 1) / 2)
                        # module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
                        module.weight.data = torch.tanh(kk * module.weight.data)
        
        optimi = torch.optim.SGD(model.parameters(), lr=lr, momentum=0.9, weight_decay=5e-4)
        loss = fit(model, optimi, lossfunc, train_loader)
        val_loss, val_acc1 = evaluate(model, val_loader, lossfunc)

        # calculate mean abs
        total_abs_sum = 0.0
        total_count = 0
        with torch.no_grad():
            for module in model.modules():
                if isinstance(module, layers.StreamLinear) or isinstance(module, layers.StreamConv):
                    total_abs_sum += module.weight.data.abs().sum().item()
                    total_count += module.weight.data.numel()
        mean_abs_weight = total_abs_sum / total_count if total_count > 0 else 0.0
        
        print(f"epoch: {epoch+1}, loss: {loss}, val_loss: {val_loss}, acc:{val_acc1}, abs_mean:{mean_abs_weight:.6f}")

        min_val_loss = val_loss if epoch in range(10, 100, 10) else min_val_loss
        
        if val_loss <= min_val_loss:
            min_val_loss = val_loss
            counter = 0
            test_loss, test_acc1 = evaluate(model, test_loader, lossfunc)
            print(MAGENTA + f"test perf: {test_acc1}" + RESET)
            torch.save(model.state_dict(), f"weight_polarization_sslr_{kk}.pth")
        else:
            counter += 1
            
    # best_state = torch.load(f"ptemp2s4_best_pol{polarization_interval}.pth", weights_only=True)
    # for seq_len in sequence_lengths:
    # seq_len = 1024
    # print(f"Testing with SEQ_LEN: {seq_len}")
    
    # fp_acc = test_model(model, best_state, seq_len, test_loader, mode="FP")
    # ss_acc = test_model(model, best_state, seq_len, test_loader, mode="SS")
    
    # results_file.write(f"Polarization interval: {polarization_interval}, SEQ_LEN: {seq_len} | FP: {fp_acc:.4f} | SS: {ss_acc:.4f}\n")
    # results_file.flush()
    
# results_file.close()
        
#############################  testing  ######################################
# state=torch.load("ptemp2s4_best_pol16.pth", weights_only=True)

# # fp state: 
# model.load_state_dict(state)
# model.eval()
# correct_top1 = 0
# total = 0
# with torch.no_grad():
#     for inputs, labels in tqdm(test_loader):
#         inputs = inputs.to(device)
#         labels = labels.to(device)
#         inputs=inputs.reshape(-1,36*36)
#         bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
#         inputs/=bs_per_row
#         inputs = torch.tanh(6*inputs)
#         inputs= inputs.reshape(-1,1,36,36)
#         outputs = model(inputs)
#         _, predicted_top1 = torch.max(outputs, 1)
#         correct_top1 += (predicted_top1 == labels).sum().item()
#         total += labels.size(0)
#     acc_top1 = correct_top1 / total
# print(MAGENTA + f"FP test perf: {acc_top1}" + RESET)

# # ss state:
# model.load_state_dict(state)
# model.eval()
# model.generate_Sparams()
# correct_top1 = 0
# total = 0
# with torch.no_grad():
#     for inputs, labels in tqdm(test_loader):
#         inputs = inputs.to(device)
#         labels = labels.to(device)
#         inputs=inputs.reshape(-1,36*36)
#         bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
#         inputs/=bs_per_row
#         inputs = torch.tanh(6*inputs)
#         inputs= trans.f2s(inputs.reshape(-1,1,36,36))
#         outputs = model.Sforward(inputs)
#         _, predicted_top1 = torch.max(outputs, 1)
#         correct_top1 += (predicted_top1 == labels).sum().item()
#         total += labels.size(0)
#         if total == 800:
#             break
#     acc_top1 = correct_top1 / total
# print(MAGENTA + f"SS test perf: {acc_top1}" + RESET)
