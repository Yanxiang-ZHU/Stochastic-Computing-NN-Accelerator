import copy
from functools import reduce

class Sobol:
    @staticmethod
    def generate(matrix, index=0):
        sample = Sobol.sample(matrix, gray(index))
        while True:
            index += 1
            sample ^= matrix[trailing_zeros(index)]
            yield sample

    @staticmethod
    def sample(matrix, index):
        column = 0
        output = 0
        while index > 0:
            if index & 1 > 0:
                output ^= matrix[column]
            index >>= 1
            column += 1
        return output

    def matrix(self, d, i, o, reverse=False):
        m = self.directions(d, i)
        v = self.invert(m, o)
        if reverse:
            v = list(map(lambda v_i: reverse_bits(v_i, i), v))
        return v

    def invert(self, m, p):
        return [reverse_bits(m_i, i, p) for (i, m_i) in enumerate(m, 1)]

    def directions(self, d, n):
        if d == 0:
            return [1 for _ in range(n)]

        s = self.s[d - 1]
        a = self.a[d - 1]
        m = copy.deepcopy(self.m_i[d - 1])

        def xor(a, b):
            return a ^ b

        def bit(a, n):
            return (a >> (n - 1)) & 1

        while len(m) < n:
            m_i = reduce(xor, [bit(a, d) * m[-d] << d for d in range(1, s)], 0)
            m_i ^= m[-s] << s
            m_i ^= m[-s]
            m.append(m_i)

        return m

    @staticmethod
    def load(path):
        s = []
        a = []
        m_i = []

        with open(path, "r") as file:

            next(file)

            for line in file:
                _, _s, _a, *_m_i = [int(i) for i in line.strip().split()]
                s.append(_s)
                a.append(_a)
                m_i.append(_m_i)

        return Sobol(s, a, m_i)

    def __init__(self, s, a, m_i):
        self.s = s
        self.a = a
        self.m_i = m_i

def gray(n):
    return n ^ (n >> 1)


def trailing_zeros(n):
    count = 0
    while n & 1 == 0:
        count += 1
        n >>= 1
    return count


def reverse_bits(n, b, p=None):
    if p is None:
        p = b
    return int("{:0{}b}".format(n, b)[:p][::-1], 2)


def sobol_generator(sobol, dimension):
    matrix = sobol.matrix(dimension, 32, 32, reverse=True)
    return Sobol.generate(matrix, index=set_index)

if __name__ == "__main__":
    samples = 128   # circuit input *1*
    dimension = 0   # circuit input *2*
    set_index = 1000   # circuit input *3*
    comp = 0b10011000000000000000000000000000     # circuit input *4*

    xg = None
    result = ""
    sobol = Sobol.load("data/new-joe-kuo-6.21201")
    xg = sobol_generator(sobol, dimension)
    xs = [next(xg) for _ in range(samples)]
    for xs_n in xs:
        if xs_n < comp:
            result = result + "1"
        else:
            result = result + "0"
    print(result)

