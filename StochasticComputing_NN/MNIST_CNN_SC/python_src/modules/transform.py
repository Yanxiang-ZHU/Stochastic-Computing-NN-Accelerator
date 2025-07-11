import torch


class Transform:
    """
    Transformer that transform float Tensor to Stream and the other way round  
    """
    def __init__(self, seq_len):
        self.seq_len = seq_len

    # def f2s(self, float_tensor: torch.Tensor) -> torch.Tensor:
    #     """transform float to stream

    #     Parameters
    #     ----------
    #     float_tensor : torch.Tensor
    #         tensor of shape (...)

    #     Returns
    #     -------
    #     torch.Tensor
    #         tensor stream of shape (..., seq_len)
    #     """
    #     dims = len(float_tensor.shape)
    #     float_tensor = (float_tensor + 1) / 2
    #     float_tensor = float_tensor.unsqueeze(-1)
    #     float_tensor = float_tensor.expand(*(-1,) * dims, self.seq_len)
    #     return torch.bernoulli(float_tensor)
        
    def f2s(self, float_tensor: torch.Tensor) -> torch.Tensor:
        assert self.seq_len % 32 == 0, "seq_len should be multiple of 32"
        p = (float_tensor + 1) / 2
        dims = len(float_tensor.shape)
        p = p.unsqueeze(-1).expand(*(-1,) * dims, self.seq_len)
        bits = torch.bernoulli(p)
        bits = bits.view(*bits.shape[:-1], self.seq_len // 32, 32)
        weights = torch.tensor([1 << i for i in range(32)], dtype=torch.int64, device=bits.device)
        packed = (bits.int() * weights).sum(dim=-1)
        return packed


    # def s2f(self, stream_tensor: torch.Tensor) -> torch.Tensor:
    #     """transorm stream to float, last dim of input tensor should be seq_len

    #     Parameters
    #     ----------
    #     stream_tensor : torch.Tensor
    #         tensor of shape (..., seq_len)

    #     Returns
    #     -------
    #     torch.Tensor
    #         tensor of shape (...)
    #     """
    #     assert (
    #         self.seq_len == stream_tensor.shape[-1]
    #     ), f"wrong stream length, expect {self.seq_len}, got {stream_tensor.shape[-1]}"
    #     stream_tensor = stream_tensor.sum(-1) / self.seq_len
    #     return stream_tensor * 2 - 1

    def s2f(self, packed_stream: torch.Tensor) -> torch.Tensor:
        num_ints = packed_stream.shape[-1]
        assert (
            num_ints == self.seq_len // 32
        ), f"wrong number of ints, expect {self.seq_len // 32}, got {num_ints}"    
        popcount = torch.zeros_like(packed_stream, dtype=torch.int32)
        for i in range(32):
            popcount += (packed_stream >> i) & 1
        total_ones = popcount.sum(dim=-1) 
        p = total_ones / self.seq_len
        return p * 2 - 1
