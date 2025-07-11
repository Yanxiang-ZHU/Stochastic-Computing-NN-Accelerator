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
SEQ_LEN = 1024
trans = Transform(SEQ_LEN)

def fit(model: nn.modules.Module, optim, lossfunc, trainloader: DataLoader):
    model.train()
    totalloss = 0
    for data, target in trainloader:
        data, target = data.cuda(), target.cuda()
        data=data.reshape(-1,3,36*36)
        bs_per_row = torch.max(torch.abs(data), dim=1, keepdim=True)[0]
        data/=bs_per_row
        data=data.reshape(-1,3,36,36)
        data = torch.tanh(3*data)
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
            inputs=inputs.reshape(-1,3,36*36)
            bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
            inputs/=bs_per_row
            inputs=inputs.reshape(-1,3,36,36)
            inputs = torch.tanh(3*inputs)
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
        self.conv1 = layers.StreamConv(3, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.conv2 = layers.StreamConv(9, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.conv3 = layers.StreamConv(9, 9,   stride=2, padding=1, seq_len=seq_len, kernel=3)
        self.conv4 = layers.StreamConv(9, 27,  stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.conv5 = layers.StreamConv(27, 27, stride=2, padding=1, seq_len=seq_len, kernel=3)
        self.conv6 = layers.StreamConv(27, 81, stride=1, padding=1, seq_len=seq_len, kernel=3)
        
        self.ac1 = layers.MAJ(seq_len = seq_len)
        self.ac2 = layers.MAJ(seq_len = seq_len)
        self.ac3 = layers.MAJ(seq_len = seq_len)
        self.ac4 = layers.MAJ(seq_len = seq_len)
        self.ac5 = layers.MAJ(seq_len = seq_len)
        self.ac6 = layers.MAJ(seq_len = seq_len)
        self.ac7 = layers.MAJ(seq_len = seq_len)
        
        self.fn1 = layers.StreamLinear(81, 10, seq_len=seq_len)  

        self.dropout1 = nn.Dropout(p=0.2)
        self.dropout2 = nn.Dropout(p=0.2)
        self.dropout3 = nn.Dropout(p=0.2)
        self.dropout4 = nn.Dropout(p=0.2)
        self.dropout5 = nn.Dropout(p=0.2)
        self.dropout6 = nn.Dropout(p=0.2)

        

        self.convp1 = layers.StreamConv(3, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.convp2 = layers.StreamConv(9, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.convp3 = layers.StreamConv(9, 9,   stride=2, padding=1, seq_len=seq_len, kernel=3)
        self.convp4 = layers.StreamConv(9, 27,  stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.convp5 = layers.StreamConv(27, 27, stride=2, padding=1, seq_len=seq_len, kernel=3)
        self.convp6 = layers.StreamConv(27, 81, stride=1, padding=1, seq_len=seq_len, kernel=3)
        
        self.acp1 = layers.MAJ(seq_len = seq_len)
        self.acp2 = layers.MAJ(seq_len = seq_len)
        self.acp3 = layers.MAJ(seq_len = seq_len)
        self.acp4 = layers.MAJ(seq_len = seq_len)
        self.acp5 = layers.MAJ(seq_len = seq_len)
        self.acp6 = layers.MAJ(seq_len = seq_len)
        self.acp7 = layers.MAJ(seq_len = seq_len)
        
        self.fnp1 = layers.StreamLinear(81, 10, seq_len=seq_len)  

        self.dropoutp1 = nn.Dropout(p=0.2)
        self.dropoutp2 = nn.Dropout(p=0.2)
        self.dropoutp3 = nn.Dropout(p=0.2)
        self.dropoutp4 = nn.Dropout(p=0.2)
        self.dropoutp5 = nn.Dropout(p=0.2)
        self.dropoutp6 = nn.Dropout(p=0.2)


        self.convpp1 = layers.StreamConv(3, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.convpp2 = layers.StreamConv(9, 9,   stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.convpp3 = layers.StreamConv(9, 9,   stride=2, padding=1, seq_len=seq_len, kernel=3)
        self.convpp4 = layers.StreamConv(9, 27,  stride=1, padding=1, seq_len=seq_len, kernel=3)
        self.convpp5 = layers.StreamConv(27, 27, stride=2, padding=1, seq_len=seq_len, kernel=3)
        self.convpp6 = layers.StreamConv(27, 81, stride=1, padding=1, seq_len=seq_len, kernel=3)
        
        self.acpp1 = layers.MAJ(seq_len = seq_len)
        self.acpp2 = layers.MAJ(seq_len = seq_len)
        self.acpp3 = layers.MAJ(seq_len = seq_len)
        self.acpp4 = layers.MAJ(seq_len = seq_len)
        self.acpp5 = layers.MAJ(seq_len = seq_len)
        self.acpp6 = layers.MAJ(seq_len = seq_len)
        self.acpp7 = layers.MAJ(seq_len = seq_len)
        
        self.fnpp1 = layers.StreamLinear(81, 10, seq_len=seq_len)  

        self.dropoutpp1 = nn.Dropout(p=0.2)
        self.dropoutpp2 = nn.Dropout(p=0.2)
        self.dropoutpp3 = nn.Dropout(p=0.2)
        self.dropoutpp4 = nn.Dropout(p=0.2)
        self.dropoutpp5 = nn.Dropout(p=0.2)
        self.dropoutpp6 = nn.Dropout(p=0.2)


        self.dynamic_alpha = 1
        self.accb = layers.MAJ(seq_len = seq_len)

    def dynamic(self, dynamic_alpha):
        self.dynamic_alpha = dynamic_alpha
        
    def forward(self, x: torch.Tensor):  
        origin = x
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
        mid = self.dropout5(mid)

        x = self.conv6(mid)
        mid = self.ac6(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropout6(mid)

        mid = mid.reshape(mid.shape[0], mid.shape[1], -1)
        mid = self.ac7(mid, mid.shape[-1], self.dynamic_alpha)
        mid = self.dropout5(mid)

        x = mid.reshape(mid.size(0), -1)
        result1 = self.fn1(x)

        x = origin
        x = self.convp1(x)
        mid = self.acp1(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutp1(mid)

        x = self.convp2(mid)
        mid = self.acp2(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutp2(mid)
        
        x = self.convp3(mid)
        mid = self.acp3(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutp3(mid)
        
        x = self.convp4(mid)
        mid = self.acp4(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutp4(mid)
        
        x = self.convp5(mid)
        mid = self.acp5(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutp5(mid)

        x = self.convp6(mid)
        mid = self.acp6(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutp6(mid)

        mid = mid.reshape(mid.shape[0], mid.shape[1], -1)
        mid = self.acp7(mid, mid.shape[-1], self.dynamic_alpha)
        mid = self.dropoutp5(mid)

        x = mid.reshape(mid.size(0), -1)
        result2 = self.fnp1(x)


        x = origin
        x = self.convpp1(x)
        mid = self.acpp1(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutpp1(mid)

        x = self.convpp2(mid)
        mid = self.acpp2(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutpp2(mid)
        
        x = self.convpp3(mid)
        mid = self.acpp3(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutpp3(mid)
        
        x = self.convpp4(mid)
        mid = self.acpp4(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutpp4(mid)
        
        x = self.convpp5(mid)
        mid = self.acpp5(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutpp5(mid)

        x = self.convpp6(mid)
        mid = self.acpp6(x, x.shape[-1], self.dynamic_alpha)
        mid = self.dropoutpp6(mid)

        mid = mid.reshape(mid.shape[0], mid.shape[1], -1)
        mid = self.acpp7(mid, mid.shape[-1], self.dynamic_alpha)
        mid = self.dropoutpp5(mid)

        x = mid.reshape(mid.size(0), -1)
        result3 = self.fnpp1(x)

        x = (result1 + result2 + result3)
        
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
        x = self.conv6.Sforward(mid)
        mid = self.ac6.Sforward(x, x.shape[-1], self.dynamic_alpha)
        mid = mid.reshape(mid.shape[0], mid.shape[1], -1, mid.shape[-1])
        mid = mid.permute(0,1,3,2)
        mid = self.ac7.Sforward(mid, mid.shape[-1], self.dynamic_alpha)

        # mid = self.trans.s2f(mid)
        # x = mid.reshape(mid.size(0), -1)
        # x = self.fn1(x)
        # result = x.sum(dim=-1)
        
        x = mid.reshape(mid.size(0), 81, SEQ_LEN // 32)
        x = self.fn1.Sforward(x)
        result1 = self.trans.s2f(x)



        x = self.convp1.Sforward(stream)
        mid = self.acp1.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convp2.Sforward(mid)
        mid = self.acp2.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convp3.Sforward(mid)
        mid = self.acp3.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convp4.Sforward(mid)
        mid = self.acp4.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convp5.Sforward(mid)
        mid = self.acp5.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convp6.Sforward(mid)
        mid = self.acp6.Sforward(x, x.shape[-1], self.dynamic_alpha)
        mid = mid.reshape(mid.shape[0], mid.shape[1], -1, mid.shape[-1])
        mid = mid.permute(0,1,3,2)
        mid = self.acp7.Sforward(mid, mid.shape[-1], self.dynamic_alpha)
        x = mid.reshape(mid.size(0), 81, SEQ_LEN // 32)
        x = self.fnp1.Sforward(x)
        result2 = self.trans.s2f(x)


        x = self.convpp1.Sforward(stream)
        mid = self.acpp1.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convpp2.Sforward(mid)
        mid = self.acpp2.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convpp3.Sforward(mid)
        mid = self.acpp3.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convpp4.Sforward(mid)
        mid = self.acpp4.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convpp5.Sforward(mid)
        mid = self.acpp5.Sforward(x, x.shape[-1], self.dynamic_alpha)
        x = self.convpp6.Sforward(mid)
        mid = self.acpp6.Sforward(x, x.shape[-1], self.dynamic_alpha)
        mid = mid.reshape(mid.shape[0], mid.shape[1], -1, mid.shape[-1])
        mid = mid.permute(0,1,3,2)
        mid = self.acpp7.Sforward(mid, mid.shape[-1], self.dynamic_alpha)
        x = mid.reshape(mid.size(0), 81, SEQ_LEN // 32)
        x = self.fnpp1.Sforward(x)
        result3 = self.trans.s2f(x)

        x = (result1 + result2 + result3)
        
        result = x.sum(dim=-1)
        return result

path = "/work/home/zhuyx/StochasticComputation-main/CIFAR10_Data"

def load_data(path):
    transform = transforms.Compose([
        transforms.Resize((36, 36)),
        transforms.ToTensor(),
        transforms.Normalize((0.4914, 0.4822, 0.4465), 
                             (0.2023, 0.1994, 0.2010))
    ])
    
    transform_train = transforms.Compose([
        transforms.Resize((36, 36)),
        transforms.RandomCrop(36, padding=4),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ColorJitter(
            brightness=0.2,
            contrast=0.2,
            saturation=0.2,
            hue=0.1
        ),
        transforms.ToTensor(),
        transforms.Normalize((0.4914, 0.4822, 0.4465), 
                             (0.2023, 0.1994, 0.2010))
    ])

    train_dataset = datasets.CIFAR10(
        root=path, train=True, download=False, transform=transform_train
    )
    test_dataset = datasets.CIFAR10(
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
model = CNN(SEQ_LEN)
train_loader, val_loader, test_loader = load_data(path)

lr = 0.01
counter = 0
early_stop_patience = 30
min_val_loss = np.inf
optimizer = torch.optim.SGD(model.parameters(), lr=lr, momentum=0.9, weight_decay=5e-4)
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=10, verbose=True)
lossfunc = nn.CrossEntropyLoss().to(device)

if torch.cuda.device_count() > 1:
    model = nn.DataParallel(model)
    model.cuda()
    print(f"Using {torch.cuda.device_count()} GPUs with DataParallel")
else:
    model.cuda()
    print("Using single GPU")


min_val_loss, val_acc1 = evaluate(model, test_loader, lossfunc)
print(f"init: val_loss: {min_val_loss}, top1_acc:{val_acc1}")

for epoch in range(300):
    # polarization
    if epoch > 40 and epoch % 10 == 0:
        with torch.no_grad():
            for module in model.modules():
                if isinstance(module, layers.StreamLinear):
                    tx = ((module.weight.data + 1) / 2)
                    module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
                if isinstance(module, layers.StreamConv):
                    tx = ((module.weight.data + 1) / 2)
                    module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
            
    loss = fit(model, optimizer, lossfunc, train_loader)
    val_loss, val_acc1 = evaluate(model, val_loader, lossfunc)
    scheduler.step(val_loss)
    print(f"epoch: {epoch+1}, lr:{lr}, loss: {loss}, val_loss: {val_loss}, acc:{val_acc1}")
    
    if val_loss < min_val_loss:
        min_val_loss = val_loss
        counter = 0
        test_loss, test_acc1 = evaluate(model, test_loader, lossfunc)
        print(MAGENTA + f"test perf: {test_acc1}" + RESET)
        torch.save(model.state_dict(), "CIFAR10CNN_best.pth")
    else:
        counter += 1
    if counter >= early_stop_patience:
        print("Early stopping triggered.")
        break
        
#############################  testing  ######################################
state=torch.load("CIFAR10CNN_best.pth", weights_only=True)

# fp state: 
model.load_state_dict(state)
model.eval()
correct_top1 = 0
total = 0
with torch.no_grad():
    for inputs, labels in tqdm(test_loader):
        inputs = inputs.to(device)
        labels = labels.to(device)
        inputs=inputs.reshape(-1,3,36*36)
        bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
        inputs/=bs_per_row
        inputs=inputs.reshape(-1,3,36,36)
        inputs = torch.tanh(3*inputs)
        outputs = model(inputs)
        _, predicted_top1 = torch.max(outputs, 1)
        correct_top1 += (predicted_top1 == labels).sum().item()
        total += labels.size(0)
    acc_top1 = correct_top1 / total
print(MAGENTA + f"FP test perf: {acc_top1}" + RESET)

# ss state:
model.load_state_dict(state)
model.eval()
model.generate_Sparams()
correct_top1 = 0
total = 0
with torch.no_grad():
    for inputs, labels in tqdm(test_loader):
        inputs = inputs.to(device)
        labels = labels.to(device)
        inputs=inputs.reshape(-1,3,36*36)
        bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
        inputs/=bs_per_row
        inputs=inputs.reshape(-1,3,36,36)
        inputs = torch.tanh(3*inputs)
        inputs= trans.f2s(inputs)
        outputs = model.Sforward(inputs)
        _, predicted_top1 = torch.max(outputs, 1)
        correct_top1 += (predicted_top1 == labels).sum().item()
        total += labels.size(0)
        if total == 1000:
            break
    acc_top1 = correct_top1 / total
print(MAGENTA + f"SS test perf: {acc_top1}" + RESET)
