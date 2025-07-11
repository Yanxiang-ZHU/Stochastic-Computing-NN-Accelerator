import torch
import torch.nn.functional as F
from modules import Base, operations
import math
import random
from modules.transform import Transform

class StreamLinear(Base.BaseLayer):
    "Linear layer for stream tensor (multiplication only, no summing)"

    def __init__(self, in_feature, out_feature, seq_len):
        """
        StreamLinear : Linear layer for stream tensor (multiplication only, no summing)
        input (batch_size, in_feature)
        output (batch_size, out_feature, in_feature)
        sinput (batch_size, in_feature, seq_len)
        soutput (batch_size, out_feature, in_feature, seq_len)

        Parameters
        ----------
        in_feature : int
            in feature
        out_feature : int
            out feature
        seq_len : int
            sequence length
        """
        super(StreamLinear, self).__init__(seq_len)
        self.in_feature = in_feature
        self.out_feature = out_feature
        self.weight = torch.nn.Parameter(torch.Tensor(out_feature, in_feature))
        torch.nn.init.uniform_(self.weight, -0.5, 0.5)
        
    def polarize(self):
        tx = ((self.weight + 1) / 2)
        self.weight = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1

    def generate_Sparams(self):
        "genreate the params for stream deduction"
        self.Sweight = self.trans.f2s(self.weight.detach())

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return x.unsqueeze(1) * self.weight

    def Sforward(self, stream: torch.Tensor) -> torch.Tensor:
        # return torch.logical_not(torch.logical_xor(stream.unsqueeze(1), self.Sweight))
        xor_result = torch.bitwise_xor(stream.unsqueeze(1), self.Sweight)  # [N, M]
        xnor_result = torch.bitwise_not(xor_result)  # [N, M]
        return xnor_result


class StreamConv(Base.BaseLayer):
    "Convolution layer for stream tensor"

    def __init__(
        self, in_channels, out_channels, kernel=3, stride=1, padding=0, seq_len=1000
    ):
        """
        StreamConv : Convolution layer for stream tensor
        input (batch_size, in_channels, height, width)
        output (batch_size, out_channels, new_height, new_width, in_channels * kernel^2)
        sinput (batch_size, in_channels, height, width, seq_len)
        soutput (batch_size, out_channels, new_height, new_width, in_channels * kernel^2, seq_len)

        Parameters
        ----------
        in_channels : int
            Number of input channels
        out_channels : int
            Number of output channels
        kernel : int, optional
            Size of the convolving kernel (default: 3)
        stride : int, optional
            Stride of the convolution (default: 1)
        padding : int, optional
            (-1)-padding added to both sides of the input (default: 0)
        seq_len : int, optional
            Sequence length for stream processing (default: 1000)
        """
        super(StreamConv, self).__init__(seq_len)
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel = kernel
        self.stride = stride
        self.padding = padding
        self.weight = torch.nn.Parameter(
            torch.Tensor(out_channels, in_channels, kernel, kernel)
        )
        torch.nn.init.uniform_(self.weight, -0.5, 0.5)
        # fan_in = in_channels * kernel * kernel
        # std = math.sqrt(2.0) / math.sqrt(fan_in)
        # torch.nn.init.kaiming_normal_(self.weight, a=math.sqrt(5))

    def polarize(self):
        tx = ((self.weight + 1) / 2)
        self.weight = (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
        
    def generate_Sparams(self):
        "genreate the params for stream deduction"
        self.Sweight = self.trans.f2s(self.weight.detach())

    # def forward(self, x: torch.Tensor) -> torch.Tensor:
    #     x = F.pad(x, (self.padding,) * 4, mode="constant", value=-1)
    #     batch_size, in_channels, height, width = x.size()
    #     new_height = (height - self.kernel) // self.stride + 1
    #     new_width = (width - self.kernel) // self.stride + 1
    #     output = torch.empty(
    #         batch_size,
    #         self.out_channels,
    #         new_height,
    #         new_width,
    #         in_channels * self.kernel**2,
    #         device=x.device,
    #     )
    #     for i in range(new_height):
    #         for j in range(new_width):
    #             part = x[
    #                 ...,
    #                 i * self.stride : i * self.stride + self.kernel,
    #                 j * self.stride : j * self.stride + self.kernel,
    #             ].unsqueeze(-4)
    #             output[..., i, j, :] = (part * self.weight).reshape(
    #                 batch_size, self.out_channels, -1
    #             )
    #     return output
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:    
        x = F.pad(x, (self.padding,) * 4, mode="constant", value=-1)
        batch_size, in_channels, height, width = x.size()
        new_height = (height - self.kernel) // self.stride + 1
        new_width = (width - self.kernel) // self.stride + 1
        unfolded = F.unfold(x, kernel_size=self.kernel, stride=self.stride, padding=0)
        weight_reshaped = self.weight.view(self.out_channels, in_channels * self.kernel**2, 1)
        result = weight_reshaped.unsqueeze(0) * unfolded.unsqueeze(1)
        result = result.permute(0, 1, 3, 2)
        output = result.view(batch_size, self.out_channels, new_height, new_width, in_channels * self.kernel**2)
        return output

    # def Sforward(self, stream: torch.Tensor):
    #     stream = F.pad(
    #         stream.swapaxes(-1, -3), (self.padding,) * 4, "constant", 0
    #     ).swapaxes(-1, -3)
    #     batch_size, in_channels, height, width, seq_len = stream.size()
    #     new_height = (height - self.kernel) // self.stride + 1
    #     new_width = (width - self.kernel) // self.stride + 1
    #     output = torch.empty(
    #         batch_size,
    #         self.out_channels,
    #         new_height,
    #         new_width,
    #         in_channels * self.kernel**2,
    #         self.seq_len,
    #         device=stream.device,
    #     )

    #     for i in range(new_height):
    #         for j in range(new_width):
    #             part = stream[
    #                 ...,
    #                 i * self.stride : i * self.stride + self.kernel,
    #                 j * self.stride : j * self.stride + self.kernel,
    #                 :,
    #             ].unsqueeze(-5)
    #             output[..., i, j, :, :] = torch.logical_not(
    #                 torch.logical_xor(part, self.Sweight)
    #             ).reshape(batch_size, self.out_channels, -1, self.seq_len)
    #     output = output.transpose(-2, -1)
    #     return output

    
    def Sforward(self, stream: torch.Tensor):
        def manual_unfold(input, kernel_size, stride):
            batch_size, channels, height, width = input.shape        
            out_h = (height - kernel_size) // stride + 1
            out_w = (width - kernel_size) // stride + 1
            unfolded = input.unfold(2, kernel_size, stride).unfold(3, kernel_size, stride)
            unfolded = unfolded.permute(0,1,4,5,2,3).reshape(batch_size, channels * kernel_size * kernel_size, out_h * out_w)
            return unfolded

        
        stream = F.pad(stream.transpose(-1, -3), (self.padding,) * 4, mode="constant", value=0x00000000)
        stream = stream.transpose(-1, -3)    
        stream = stream & 0xFFFFFFFF

        batch_size, in_channels, height, width, seq_len_packed = stream.size()
        new_height = (height - self.kernel) // self.stride + 1
        new_width = (width - self.kernel) // self.stride + 1     
        unfolded = manual_unfold(
            stream.permute(0, 4, 1, 2, 3).reshape(batch_size * seq_len_packed, in_channels, height, width),
            kernel_size=self.kernel, stride=self.stride
        )
        unfolded = unfolded.reshape(batch_size, seq_len_packed, in_channels * self.kernel**2, new_height, new_width)        
        unfolded = unfolded.permute(0, 3, 4, 1, 2)
        Sweight_reshaped = self.Sweight.view(1, self.out_channels, in_channels * self.kernel**2, seq_len_packed)
        Sweight_reshaped = Sweight_reshaped.permute(0, 1, 3, 2).unsqueeze(2).unsqueeze(3)          
        output = ~(unfolded.unsqueeze(1) ^ Sweight_reshaped)
        output = output & 0xFFFFFFFF
        return output


class BTanh(Base.BaseLayer):
    def __init__(self, seq_len):
        super().__init__(seq_len)

    def generate_Sparams(self):
        return

    def Sforward(self, inputs: torch.Tensor):
        return operations.tanh(inputs.to(int))

    def forward(self, x: torch.Tensor):
        return ((x + 1) ** 2 * (2 - x)) / 2 - 1


class Majority_k(Base.BaseLayer):
    def __init__(self, in_features, k, seq_len):
        super().__init__(seq_len)
        self.in_features = in_features
        self.k = k
        assert (k < in_features) and (k >= 0)

    def generate_Sparams(self):
        return

    def Sforward(self, inputs: torch.Tensor, k=None) -> torch.Tensor:
        """apply Majority_k on input stream

        Parameters
        ----------
        inputs : torch.Tensor
            (..., in_features, seq_len), each (in_features, seq_len) in ... is streams of a probability sequence
        k : int, optional
            majority threshold, Majority_0 == any, Majority_(n-1) == all

        Returns
        -------
        torch.Tensor
            (..., seq_len), each (seq_len,) in ... is the result stream of Majority_k of input (in_features, seq_len)
        """
        if k is None:
            k = self.k

        inputs = inputs.sum(dim=-2)

        return inputs > k

    def rawforward(self, inputs: torch.Tensor, k=None) -> torch.Tensor:
        """probability calculation of Majority_k, return 1-cdf_Poisson_binomial(k)

        Parameters
        ----------
        inputs : torch.Tensor
            (..., in_features), each (in_features,) is a probability sequence in range [0,1]
        k : int, optional
            majority threshold, Majority_0 == any, Majority_(n-1) == all

        Returns
        -------
        torch.Tensor
            (...,)
        """
        
        """
        if k is None:
            k = self.k
        assert self.in_features == inputs.shape[-1]
        assert k >= 0 and k < self.in_features
        pmf = torch.zeros(inputs.shape[:-1] + (k + 1,), device=inputs.device)
        pmf[..., 0] = 1

        for i in range(self.in_features):
            p = inputs[..., i : i + 1]
            pmf_new = torch.zeros(inputs.shape[:-1] + (k + 1,), device=inputs.device)
            pmf_new[..., 1:] = pmf[..., 1:] * (1 - p) + pmf[..., :-1] * p
            pmf_new[..., 0] = pmf[..., 0] * (1 - p[..., 0])
            pmf = pmf_new

        return 1 - pmf.sum(dim=-1)
        """
        
        if k is None:
          k = self.k
        assert self.in_features == inputs.shape[-1]
        assert 0 <= k < self.in_features
        
        p_mean = inputs.mean(dim=-1, keepdim=True)  # (..., 1)
        
        pmf = torch.zeros(inputs.shape[:-1] + (k + 1,), device=inputs.device)
        pmf[..., 0] = 1
        
        for i in range(self.in_features):
          pmf_new = torch.zeros_like(pmf)
          pmf_new[..., 1:] = pmf[..., 1:] * (1 - p_mean) + pmf[..., :-1] * p_mean
          pmf_new[..., 0] = pmf[..., 0] * (1 - p_mean[..., 0])
          pmf = pmf_new
        
        return 1 - pmf.sum(dim=-1)

        

    def forward(self, inputs: torch.Tensor, k=None) -> torch.Tensor:
        """float calculation of Majority_k

        Parameters
        ----------
        inputs : torch.Tensor
            (..., in_features), each (in_features,) is a float sequence in range [-1,1]
        k : int, optional
            majority threshold, Majority_0 == any, Majority_(n-1) == all

        Returns
        -------
        torch.Tensor
            (...,)
        """
        inputs = (inputs + 1) / 2
        inputs = self.rawforward(inputs, k)
        return 2 * inputs - 1


class StreamAp(Base.BaseLayer):
    "Average Pooliing"

    def __init__(self, kernel=2, stride=2, seq_len=1000):
        super(StreamAp, self).__init__(seq_len)
        self.kernel = kernel
        self.stride = stride

    def generate_Sparams(self):
        return

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = F.avg_pool2d(x, kernel_size=self.kernel, stride=self.stride)
        return x

    def Sforward(self, stream: torch.Tensor) -> torch.Tensor:
        """
        Perform average pooling for stream data.
        Args:
            stream (torch.Tensor): Input stream of shape (batch_size, channels, length, width, seq_len).
        Returns:
            torch.Tensor: Stream output after pooling.
        """
        batch_size, channels, length, width, seq_len = stream.shape
        pooled_length = (length - self.kernel) // self.stride + 1
        pooled_width = (width - self.kernel) // self.stride + 1
        pooled = torch.zeros((batch_size, channels, pooled_length, pooled_width, seq_len), device=stream.device)
        for i in range(pooled_length):
            for j in range(pooled_width):
                start_l = i * self.stride
                end_l = start_l + self.kernel
                start_w = j * self.stride
                end_w = start_w + self.kernel
                window = stream[:, :, start_l:end_l, start_w:end_w, :] 
                random_indices = torch.randint(0, self.kernel * self.kernel, (batch_size, channels, seq_len), device=stream.device)
                flat_window = window.reshape(batch_size, channels, -1, seq_len)
                sampled = torch.gather(flat_window, 2, random_indices.unsqueeze(2))
                pooled[:, :, i, j, :] = sampled.squeeze(2)
        return pooled



class StreamUp(Base.BaseLayer):
    """Nearest Neighbor Upsampling"""

    def __init__(self, scale_factor=2, seq_len=1000):
        super(StreamUp, self).__init__(seq_len)
        self.scale_factor = scale_factor

    def generate_Sparams(self):
        return

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x (torch.Tensor): (batch_size, channels, height, width)
        Returns:
            torch.Tensor: (batch_size, channels, height*scale_factor, width*scale_factor)
        """
        return F.interpolate(x, scale_factor=self.scale_factor, mode="nearest")

    def Sforward(self, stream: torch.Tensor) -> torch.Tensor:
        """
        Args:
            stream (torch.Tensor): (batch_size, channels, height, width, seq_len)
        Returns:
            torch.Tensor: (batch_size, channels, height*scale_factor, width*scale_factor, seq_len)
        """
        batch_size, channels, height, width, seq_len = stream.shape
        up_height = height * self.scale_factor
        up_width = width * self.scale_factor
        upsampled = torch.empty((batch_size, channels, up_height, up_width, seq_len), device=stream.device)

        for i in range(up_height):
            for j in range(up_width):
                src_i = i // self.scale_factor
                src_j = j // self.scale_factor
                upsampled[:, :, i, j, :] = stream[:, :, src_i, src_j, :]
        return upsampled

class StreamGap(Base.BaseLayer):
    "Global Average Pooliing"

    def __init__(self, seq_len=1000):
        super(StreamGap, self).__init__(seq_len)

    def generate_Sparams(self):
        return

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Perform global average pooling for full-precision floating-point data.
        Args:
            x (torch.Tensor): Input tensor of shape (batch_size, channel, length, width).
        Returns:
            torch.Tensor: Pooled output of shape (batch_size, channel, 1, 1).
        """
        return x.mean(dim=(2, 3), keepdim=True)

    def Sforward(self, stream: torch.Tensor) -> torch.Tensor:
        """
        Perform global average pooling for binary stream data.
        Args:
            stream (torch.Tensor): Input stream of shape (batch_size, channel, length, width, seq_len).
        Returns:
            torch.Tensor: Pooled output of shape (batch_size, channel, 1, 1, seq_len).
        """
        batch_size, channel, length, width, seq_len = stream.shape
        flattened_stream = stream.view(batch_size, channel, -1, seq_len)
        random_indices = torch.randint(flattened_stream.size(2), (batch_size, channel, seq_len), device=stream.device)
        batch_indices = torch.arange(batch_size, device=stream.device).view(-1, 1, 1)
        channel_indices = torch.arange(channel, device=stream.device).view(1, -1, 1)
        sampled_stream = flattened_stream[batch_indices, channel_indices, random_indices]
        sampled_stream = sampled_stream.permute(0, 1, 2).unsqueeze(2).unsqueeze(3)
        return sampled_stream


class MAJ(Base.BaseLayer):
    def __init__(self, seq_len):
        super(MAJ, self).__init__(seq_len)
        self.seq_len = seq_len

    def generate_Sparams(self):
        return

    def forward(self, x: torch.Tensor, channels, alpha):
        def maj3(x):
            x = (x + 1) / 2
            x1, x2, x3 = x[..., 0], x[..., 1], x[..., 2]
            x = x1 * x2 * (1 - x3) + x1 * x3 * (1 - x2) + x2 * x3 * (1 - x1) + x1 * x2 * x3
            x = x * 2 - 1
            return x
        def maj9(x):
            x = (x + 1) / 2
            pmf = torch.zeros(x.shape[:-1] + (5,), device=x.device)
            pmf[..., 0] = 1
            for i in range(x.shape[-1]):
                p = x[..., i : i + 1]
                pmf_new = torch.zeros(x.shape[:-1] + (5,), device=x.device)
                pmf_new[..., 1:] = pmf[..., 1:] * (1 - p) + pmf[..., :-1] * p
                pmf_new[..., 0] = pmf[..., 0] * (1 - p[..., 0])
                pmf = pmf_new
            return (1 - pmf.sum(dim=-1)) * 2 - 1

        def self_maj3(x):
            tx = ((x + 1) / 2)
            return (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
        def self_maj9(x):
            p = (x + 1) / 2
            prob = 0
            for k in range(5, 10):  # k from 5 to 9
                choose = 1
                for i in range(k):
                    choose *= (9 - i) / (i + 1)
                prob += choose * (p ** k) * ((1 - p) ** (9 - k))            
            return 2 * prob - 1
            
        assert (channels % 3 == 0), "channels must be a power of 3"
        layers = 0

        # x = self_maj3(self_maj3(x))
        # x = torch.tanh(2*x)
        
        while channels > 1:
            # if channels % 9 == 0:
            #     x = x.reshape(*x.shape[:-1], channels // 9, 9)
            #     x = maj9(x)
            #     channels //= 9
            #     layers = layers + 2
            if channels % 3 == 0:  
                x = x.reshape(*x.shape[:-1], channels // 3, 3)
                x = maj3(x)
                channels //= 3
                layers = layers + 1
        x = torch.squeeze(x,dim=-1)
        
        layers = alpha * layers
        while layers > 0:
            # if layers > 1:
            #     layers = layers -2
            #     x = self_maj9(x)
            # elif layers <= 1:
            layers = layers -1
            x = self_maj3(x)        
        return x


    def Sforward(self, stream: torch.Tensor, channels: int, alpha):
        def maj3(x, seq_len=32):
            result = torch.zeros(x.shape[:-1], dtype=x.dtype, device=x.device)
            for k in range(seq_len):
                bits = (x >> k) & 1
                bit_sum = bits.sum(dim=-1)
                result |= (bit_sum >= 2).to(x.dtype) << k
            return result

        def swap_bit(original_seq: torch.Tensor, num_swaps: int) -> torch.Tensor:
            original_shape = original_seq.shape
            *prefix_shape, num_ints = original_shape
            total_elems = int(torch.tensor(prefix_shape).prod()) if prefix_shape else 1
            seq_len = num_ints * 32        
            reshaped_seq = original_seq.reshape(total_elems, num_ints)
            for _ in range(num_swaps):
                random_bits = torch.randint(0, 2, (total_elems, seq_len), device=original_seq.device)
                bits = reshaped_seq.view(total_elems, -1).unsqueeze(-1).bitwise_and(
                    1 << torch.arange(32, device=original_seq.device)
                ).ne(0).view(total_elems, seq_len)
                left_shifted = torch.roll(bits, shifts=-1, dims=-1)
                right_shifted = torch.roll(bits, shifts=1, dims=-1)
                bits = torch.where(random_bits == 1, left_shifted, right_shifted)
                reshaped_seq = torch.stack([
                    bits[:, i:i+32].flip(-1).bitwise_and(1 << torch.arange(32, device=bits.device)).sum(dim=-1)
                    for i in range(0, seq_len, 32)
                ], dim=-1)
            return reshaped_seq.reshape(*prefix_shape, num_ints)
        
        def self_maj3_full(stream, layers, seq_len=32):
            trans = Transform(self.seq_len)
            num_levels = math.ceil(layers)
            num_streams = 3 ** num_levels
            # streams = [swap_bit(stream, 2) for _ in range(num_streams)]
            streams = [trans.f2s(trans.s2f(stream)) for _ in range(num_streams)]
            for level in range(num_levels):
                next_streams = []
                for i in range(0, len(streams), 3):
                    next_streams.append(maj3(torch.stack(streams[i:i+3], dim=-1), seq_len=seq_len))
                streams = next_streams
            return streams[0]

        trans = Transform(self.seq_len)
        assert (channels % 3 == 0), "channels must be a power of 3"  # restriction: for we only apply 3-to-1 MAJ components
        layers = 0


        # ########################################################### compare ss and fp layer by layer
        # def pearson_corr(A, B):
        #     A = A.flatten()
        #     B = B.flatten()
        #     A_mean = A.mean()
        #     B_mean = B.mean()
        #     cov = ((A - A_mean) * (B - B_mean)).mean()
        #     A_std = A.std(unbiased=False)
        #     B_std = B.std(unbiased=False)
        #     return cov / (A_std * B_std)
        # def maj3_f(x):
        #     x = (x + 1) / 2
        #     x1, x2, x3 = x[..., 0], x[..., 1], x[..., 2]
        #     x = x1 * x2 * (1 - x3) + x1 * x3 * (1 - x2) + x2 * x3 * (1 - x1) + x1 * x2 * x3
        #     x = x * 2 - 1
        #     return x
        # def self_maj3_f(x):
        #     tx = ((x + 1) / 2)
        #     return (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1

        # stream1 = stream.transpose(-1, -2)
        # x = trans.s2f(stream1)
        # print(pearson_corr(trans.s2f(stream.transpose(-1, -2)), x))
        # channels1 = channels
        # layers1 = 0        
        # ############################################################


        # stream = stream.transpose(-1, -2)
        # stream = self_maj3_full(stream, 2)
        # stream = stream.transpose(-1, -2)
        
        # stream = stream.transpose(-1, -2)
        # xx = trans.s2f(stream)
        # xx = torch.tanh(2 * xx)
        # stream = trans.f2s(xx)
        # stream = stream.transpose(-1, -2)

        
        # ############################################################
        # relu = torch.nn.ReLU(inplace=True)
        # x = relu(x)
        # print(pearson_corr(trans.s2f(stream.transpose(-1, -2)), x))
        # ############################################################

        
        while channels > 1:
            if channels % 3 == 0:
                stream = stream.reshape(*stream.shape[:-1], channels // 3, 3)
                stream = maj3(stream)
                channels //= 3
                layers = layers + 1
        stream = torch.squeeze(stream, dim=-1)

        
        # ###########################################
        # while channels1 > 1:
        #     if channels1 % 3 == 0:  
        #         x = x.reshape(*x.shape[:-1], channels1 // 3, 3)
        #         x = maj3_f(x)
        #         channels1 //= 3
        #         layers1 = layers1 + 1
        # x = torch.squeeze(x,dim=-1)
        # print(pearson_corr(trans.s2f(stream), x))
        # ############################################

        
        # self majority -- need (alpha*layers) 3-to-1 MAJ
        layers = alpha * layers
        stream = self_maj3_full(stream, layers)  # Perform all layers in one go

        
        # ############################################
        # layers1 = alpha * layers1
        # while layers1 > 0:
        #     layers1 = layers1 -1
        #     x = self_maj3_f(x)
        # print(pearson_corr(trans.s2f(stream), x))
        # ############################################
            
        return stream


class Self_MAJ(Base.BaseLayer):
    def __init__(self, seq_len):
        super(Self_MAJ, self).__init__(seq_len)
        self.seq_len = seq_len

    def generate_Sparams(self):
        return

    def forward(self, x: torch.Tensor, kk):
        def self_maj3(x):
            tx = ((x + 1) / 2)
            return (tx * tx * (1 - tx) * 3 + tx**3) * 2 - 1
            
        layers = kk
        while layers > 0:
            layers = layers -1
            x = self_maj3(x)        
        return x
    
    def Sforward(self, stream: torch.Tensor, kk):
        def self_maj3_full(stream, layers, seq_len=32):
            trans = Transform(self.seq_len)
            num_levels = math.ceil(layers)
            num_streams = 3 ** num_levels
            # streams = [swap_bit(stream, 2) for _ in range(num_streams)]
            streams = [trans.f2s(trans.s2f(stream)) for _ in range(num_streams)]
            for level in range(num_levels):
                next_streams = []
                for i in range(0, len(streams), 3):
                    next_streams.append(maj3(torch.stack(streams[i:i+3], dim=-1), seq_len=seq_len))
                streams = next_streams
            return streams[0]
        
        stream = self_maj3_full(stream, kk)
        return stream
        