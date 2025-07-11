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
import pandas as pd

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
MAGENTA = "\033[95m"

def fit(model: nn.modules.Module, optim, lossfunc, trainloader: DataLoader, kk, lambda_polar=0):
    model.train()
    totalloss = 0
    pol_loss = 0
    for data, target in trainloader:
        data, target = data.cuda(), target.cuda()
        data=data.reshape(-1,36*36)
        bs_per_row = torch.max(torch.abs(data), dim=1, keepdim=True)[0]
        data/=bs_per_row
        data = torch.tanh(6*data)
        data=data.reshape(-1,1,36,36)
        optim.zero_grad()
        output = model(data, kk)    
        loss = lossfunc(output, target)         

        polar_loss = 0
        for module in model.modules():
            if isinstance(module, (layers.StreamLinear, layers.StreamConv)):
                polar_loss += torch.sum(torch.abs(torch.abs(module.weight) - 1))
        
        backloss = loss + polar_loss *lambda_polar

        if torch.isnan(loss):
            print("Loss became NaN. Skipping this batch.")
            continue

        backloss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        optim.step()

        with torch.no_grad():
            for module in model.modules():
                if isinstance(module, (layers.StreamLinear, layers.StreamConv)):
                    module.weight.data.clip_(-1, 1)
        
        with torch.no_grad():
            totalloss += loss.item() * data.size(0)
    return totalloss / len(trainloader.sampler)


def evaluate(
    model: nn.modules.Module, val_loader: DataLoader, lossfunc: nn.CrossEntropyLoss, kk
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
            outputs = model(inputs, kk)
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

        self.pol_ac = layers.Self_MAJ(seq_len = seq_len)
        
        self.fn1 = layers.StreamLinear(27, 10, seq_len=seq_len)  

        self.dropout1 = nn.Dropout(p=0.2)
        self.dropout2 = nn.Dropout(p=0.2)
        self.dropout3 = nn.Dropout(p=0.2)
        self.dropout4 = nn.Dropout(p=0.2)
        self.dropout5 = nn.Dropout(p=0.2)

        self.dynamic_alpha = 1

    def dynamic(self, dynamic_alpha):
        self.dynamic_alpha = dynamic_alpha
        
    def forward(self, x: torch.Tensor, kk=2):  
        x = self.pol_ac(x, kk)
        x = self.conv1(x)
        mid = self.ac1(x, x.shape[-1], self.dynamic_alpha)
        mid = self.pol_ac(mid, kk)
        mid = self.dropout1(mid)

        x = self.conv2(mid)
        mid = self.ac2(x, x.shape[-1], self.dynamic_alpha)
        mid = self.pol_ac(mid, kk)
        mid = self.dropout2(mid)
        
        x = self.conv3(mid)
        mid = self.ac3(x, x.shape[-1], self.dynamic_alpha)
        mid = self.pol_ac(mid, kk)
        mid = self.dropout3(mid)
        
        x = self.conv4(mid)
        mid = self.ac4(x, x.shape[-1], self.dynamic_alpha)
        mid = self.pol_ac(mid, kk)
        mid = self.dropout4(mid)
        
        x = self.conv5(mid)
        mid = self.ac5(x, x.shape[-1], self.dynamic_alpha)
        mid = self.pol_ac(mid, kk)
        
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


lossfunc = nn.CrossEntropyLoss().to(device)
train_loader, val_loader, test_loader = load_data()

lr = 0.01
min_val_loss = np.inf
count = 0
kk = 1

log = []

SEQ_LEN = 1024
trans = Transform(SEQ_LEN)
model = CNN(SEQ_LEN)
if torch.cuda.device_count() > 1:
    model = nn.DataParallel(model)
model.cuda()

min_val_loss, val_acc1 = evaluate(model, test_loader, lossfunc, kk)
print(f"init: val_loss: {min_val_loss}, top1_acc:{val_acc1}")


for epoch in range(400): 
    print(BLUE+f"EPOCH: {epoch+1}:"+RESET)
    
    # polarization
    if epoch % 4 == 0:
        with torch.no_grad():
            for module in model.modules():
                if isinstance(module, layers.StreamLinear):
                    tx = ((module.weight.data + 1) / 2)
                    module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
                if isinstance(module, layers.StreamConv):
                    tx = ((module.weight.data + 1) / 2)
                    module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
    
    optimi = torch.optim.SGD(model.parameters(), lr=lr, momentum=0.9, weight_decay=5e-4)
    loss = fit(model, optimi, lossfunc, train_loader, kk)
    val_loss, val_acc1 = evaluate(model, val_loader, lossfunc, kk)

    total_abs_sum = 0.0
    total_weight_count = 0
    for module in model.modules():
        if isinstance(module, (layers.StreamLinear, layers.StreamConv)):
            if hasattr(module, 'weight') and module.weight is not None:
                abs_sum = module.weight.abs().sum().item()
                count_w = module.weight.numel()
                total_abs_sum += abs_sum
                total_weight_count += count_w
    mean_abs_value = total_abs_sum / total_weight_count
    
    print(f"epoch: {epoch+1}, lr:{lr:.4f}, loss: {loss:.4f}, val_loss: {val_loss:.4f}, acc:{val_acc1:.4f}, mean_abs:{mean_abs_value:.4f}")

    if val_loss <= min_val_loss:
        count = 0
        min_val_loss = val_loss
        test_loss, test_acc1 = evaluate(model, test_loader, lossfunc, kk)
        print(MAGENTA + f"test perf: {test_acc1:.4f}" + RESET)
        torch.save(model.state_dict(), f"polarization_maj_kk_{kk}.pth")
    else:
        count = count + 1

    log.append({
        'epoch': epoch+1,
        'learning_rate': lr,
        'train_loss': loss,
        'val_loss': val_loss,
        'val_acc': val_acc1,
        'kk': kk,
        'Mean_Abs': mean_abs_value
    })

    if count == 5:
        count = 0
        kk = kk * 2
        lr = max(lr * 0.2, 1e-6)
        print(f"lr: {lr:.6f}")
        print(f"kk: {kk}")
        min_val_loss = np.inf

    df = pd.DataFrame(log)
    df.to_csv('log_maj.csv', index=False)
        
df = pd.DataFrame(log)
df.to_csv('log_maj.csv', index=False)
    
