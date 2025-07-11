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
        data=data.reshape(-1,28*28)
        # bs_per_row = torch.max(torch.abs(data), dim=1, keepdim=True)[0]
        # data/=bs_per_row
        data = torch.tanh(2*data)
        data=data.reshape(-1,1,28,28)
        optim.zero_grad()
        output = model(data)    
        loss = lossfunc(output, target) 
        loss.backward()
        optim.step()
        with torch.no_grad():
            for module in model.modules():
                if isinstance(module, layers.StreamLinear):
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
            inputs=inputs.reshape(-1,28*28)
            # bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
            # inputs/=bs_per_row
            inputs = torch.tanh(2*inputs)
            inputs=inputs.reshape(-1,1,28,28)
            outputs = model(inputs)
            loss += lossfunc(outputs, labels).item() * inputs.size(0)
            _, predicted_top1 = torch.max(outputs, 1)
            correct_top1 += (predicted_top1 == labels).sum().item()
            total += labels.size(0)
        loss /= len(val_loader.sampler)
        acc_top1 = correct_top1 / total
    return loss, acc_top1


class DNN(BaseModel):
    def __init__(self, seq_len):
        super().__init__(seq_len)  
        self.ac1 = layers.MAJ(seq_len = seq_len)
        self.ac2 = layers.MAJ(seq_len = seq_len)
        self.ac3 = layers.MAJ(seq_len = seq_len)
        
        self.fn1 = layers.StreamLinear(27*27, 27*3, seq_len=seq_len) 
        self.fn2 = layers.StreamLinear(27*9, 9*3, seq_len=seq_len)
        self.fn3 = layers.StreamLinear(27, 10, seq_len=seq_len)

        self.dropout1 = nn.Dropout(p=0.2)
        self.dropout2 = nn.Dropout(p=0.2)

        self.dynamic_alpha = 1

    def forward(self, x: torch.Tensor):  
        x = x[:, :, :-1, :-1]
        x = x.reshape(x.shape[0], -1)
        x = self.fn1(x)
        x = x.view(*x.shape[:-1], 3, -1)
        x = x.reshape(x.shape[0], -1, x.shape[-1])
        x = self.ac1(x, x.shape[-1], self.dynamic_alpha)
        x = self.dropout1(x)
        x = self.fn2(x)
        x = self.ac2(x, x.shape[-1], self.dynamic_alpha)
        x = self.dropout2(x)
        x = self.fn3(x)
        x = self.ac3(x, x.shape[-1], self.dynamic_alpha)
        return x
    
    def Sforward(self, stream: torch.Tensor):        
        stream = stream[:, :, :-1, :-1, :]
        stream = stream.reshape(stream.shape[0], -1, stream.shape[-1])
        stream = self.fn1.Sforward(stream)
        stream = stream.view(*stream.shape[:-2], 3, -1, stream.shape[-1])
        stream = stream.reshape(stream.shape[0], -1, stream.shape[-2], stream.shape[-1])
        stream = stream.transpose(-1, -2)
        stream = self.ac1.Sforward(stream, stream.shape[-1], self.dynamic_alpha)
        stream = self.fn2.Sforward(stream)
        stream = stream.transpose(-1, -2)
        stream = self.ac2.Sforward(stream, stream.shape[-1], self.dynamic_alpha)
        stream = self.fn3.Sforward(stream)
        stream = stream.transpose(-1, -2)
        stream = self.ac3.Sforward(stream, stream.shape[-1], self.dynamic_alpha)
        result = self.trans.s2f(stream)
        return result

path = "/work/home/zhuyx/StochasticComputation-main/data"

def load_data():
    transform = transforms.Compose([transforms.ToTensor(), transforms.Normalize((0.1307,), (0.3081,))])
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
model = DNN(SEQ_LEN)
lossfunc = nn.CrossEntropyLoss().to(device)
train_loader, val_loader, test_loader = load_data()

lr = 0.1
counter = 0
min_val_loss = np.inf

if torch.cuda.device_count() > 1:
    model = nn.DataParallel(model)
    model.cuda()
    print(f"Using {torch.cuda.device_count()} GPUs with DataParallel")
else:
    model.cuda()
    print("Using single GPU")


min_val_loss, val_acc1 = evaluate(model, test_loader, lossfunc)
print(f"init: val_loss: {min_val_loss}, top1_acc:{val_acc1}")

for epoch in range(80):
    if counter / 8 == 1:
        counter = 0
        lr = lr * 0.5
        print(GREEN + f"lr reduced to {lr}" + RESET)

    # polarization
    if epoch > 25 and epoch % 8 == 0:
        with torch.no_grad():
            for module in model.modules():
                if isinstance(module, layers.StreamLinear):
                    tx = ((module.weight.data + 1) / 2)
                    module.weight.data = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
            
    optimi = torch.optim.SGD(model.parameters(), lr=lr, momentum=0.9, weight_decay=5e-4)
    loss = fit(model, optimi, lossfunc, train_loader)
    val_loss, val_acc1 = evaluate(model, val_loader, lossfunc)
    print(f"epoch: {epoch+1}, loss: {loss}, val_loss: {val_loss}, acc:{val_acc1}")
    if val_loss < min_val_loss:
        min_val_loss = val_loss
        counter = 0
        test_loss, test_acc1 = evaluate(model, test_loader, lossfunc)
        print(MAGENTA + f"test perf: {test_acc1}" + RESET)
        torch.save(model.state_dict(), "DNN_best.pth")
    else:
        counter += 1
        
#############################  testing  ######################################
state=torch.load("DNN_best.pth", weights_only=True)

# fp state: 
model.load_state_dict(state)
model.eval()
correct_top1 = 0
total = 0
with torch.no_grad():
    for inputs, labels in tqdm(test_loader):
        inputs = inputs.to(device)
        labels = labels.to(device)
        inputs=inputs.reshape(-1,28*28)
        # bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
        # inputs/=bs_per_row
        inputs = torch.tanh(2*inputs)
        inputs= inputs.reshape(-1,1,28,28)
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
        inputs=inputs.reshape(-1,28*28)
        # bs_per_row = torch.max(torch.abs(inputs), dim=1, keepdim=True)[0]
        # inputs/=bs_per_row
        inputs = torch.tanh(2*inputs)
        inputs= trans.f2s(inputs.reshape(-1,1,28,28))
        outputs = model.Sforward(inputs)
        _, predicted_top1 = torch.max(outputs, 1)
        correct_top1 += (predicted_top1 == labels).sum().item()
        total += labels.size(0)
        if total == 2000:
            break
    acc_top1 = correct_top1 / total
print(MAGENTA + f"SS test perf: {acc_top1}" + RESET)
