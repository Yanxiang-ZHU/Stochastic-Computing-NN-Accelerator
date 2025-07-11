//#include <stdio.h>
//#include <stdlib.h>
//
//#define MAXDIM 5 // 增加维度
//
//unsigned long long V[MAXDIM][32] = {
//    {1ULL, 2ULL, 4ULL, 8ULL, 16ULL, 32ULL, 64ULL, 128ULL, 256ULL, 512ULL, 1024ULL, 2048ULL, 4096ULL, 8192ULL, 16384ULL, 32768ULL, 65536ULL, 131072ULL, 262144ULL, 524288ULL, 1048576ULL, 2097152ULL, 4194304ULL, 8388608ULL, 16777216ULL, 33554432ULL, 67108864ULL, 134217728ULL, 268435456ULL, 536870912ULL, 1073741824ULL, 2147483648ULL},
//    {1ULL, 3ULL, 7ULL, 15ULL, 31ULL, 63ULL, 127ULL, 255ULL, 511ULL, 1023ULL, 2047ULL, 4095ULL, 8191ULL, 16383ULL, 32767ULL, 65535ULL, 131071ULL, 262143ULL, 524287ULL, 1048575ULL, 2097151ULL, 4194303ULL, 8388607ULL, 16777215ULL, 33554431ULL, 67108863ULL, 134217727ULL, 268435455ULL, 536870911ULL, 1073741823ULL, 2147483647ULL, 4294967295ULL},
//    {1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL, 1ULL},
//    {1ULL, 3ULL, 5ULL, 9ULL, 17ULL, 33ULL, 65ULL, 129ULL, 257ULL, 513ULL, 1025ULL, 2049ULL, 4097ULL, 8193ULL, 16385ULL, 32769ULL, 65537ULL, 131073ULL, 262145ULL, 524289ULL, 1048577ULL, 2097153ULL, 4194305ULL, 8388609ULL, 16777217ULL, 33554433ULL, 67108865ULL, 134217729ULL, 268435457ULL, 536870913ULL, 1073741825ULL, 2147483649ULL},
//    {1ULL, 5ULL, 11ULL, 19ULL, 37ULL, 73ULL, 145ULL, 289ULL, 577ULL, 1153ULL, 2305ULL, 4609ULL, 9217ULL, 18433ULL, 36865ULL, 73729ULL, 147457ULL, 294913ULL, 589825ULL, 1179649ULL, 2359297ULL, 4718593ULL, 9437185ULL, 18874369ULL, 37748737ULL, 75497473ULL, 150994945ULL, 301989889ULL, 603979777ULL, 1207959553ULL, 2415919105ULL, 4831838209ULL}
//};
//
//// sobseq函数
//void sobseq(float x[], int* n) {
//    static unsigned long long C[MAXDIM] = { 0 };  // C 数组
//    static unsigned long long lastN = 0;        // 上一个调用中的 n 值
//    static int init = 0;                        // 初始化标志
//
//    if (!init) {
//        for (int j = 0; j < MAXDIM; j++) {
//            C[j] = 1;  // 初始化 C 数组
//        }
//        init = 1;
//    }
//
//    // 计算 Gray 码
//    unsigned long long gray = *n ^ (*n >> 1);
//
//    // 确定最高位不同的位置
//    unsigned long long pos = 0;
//    unsigned long long mask = 1;
//    while ((*n & mask) == (lastN & mask)) {
//        mask <<= 1;
//        pos++;
//    }
//
//    // 生成新的 Sobol 序列
//    for (int j = 0; j < MAXDIM; j++) {
//        C[j] ^= V[j][pos];
//        x[j] = (float)C[j] / (1ULL << 31);
//    }
//
//    lastN = *n;  // 更新上一个 n 值
//}
//
////// 简单的线性同余生成器
////unsigned int lcg_rand(unsigned int* seed) {
////    *seed = (1103515245 * (*seed) + 12345) % (1 << 31);
////    return *seed;
////}
////
////void sobseq(int* n, float x[]) {
////    static int in, ix[MAXDIM][MAXBIT];
////    static int fac;
////    static int mdeg[MAXDIM] = { 1, 2, 3, 4, 5 }; // 调整多项式度
////    static int ip[MAXDIM] = { 0, 1, 2, 3, 4 }; // 调整初始值
////    static int iv[MAXDIM * MAXBIT] = {
////        1, 3, 7, 11, 13, 1, 3, 7, 11, 13, 1, 3, 7, 11, 13, 1, 3, 7, 11, 13, 1, 3, 7, 11, 13, 1, 3, 7, 11, 13
////    }; // 调整方向向量
////    static int initialized = 0;
////    int j, k, l;
////
////    if (!initialized) {
////        fac = 1 << (MAXBIT - 1);
////        for (k = 0; k < MAXDIM; k++) {
////            for (j = 0; j < mdeg[k]; j++) ix[k][j] = iv[j + k * MAXBIT];
////            for (j = mdeg[k]; j < MAXBIT; j++) {
////                ix[k][j] = ix[k][j - mdeg[k]] ^ (ix[k][j - mdeg[k]] >> mdeg[k]);
////                for (l = 1; l < mdeg[k]; l++) ix[k][j] ^= ((ix[k][j - l] & 1) << (mdeg[k] - l));
////            }
////        }
////        initialized = 1;
////    }
////
////    in = *n;
////    *n += 1;
////    for (k = 0; k < MAXDIM; k++) {
////        x[k] = 0.0;
////        float fac = 1.0;
////        for (j = 0; j < MAXBIT; j++) {
////            fac /= 2.0;
////            if (in & (1 << j)) {
////                x[k] += ix[k][j] * fac;
////            }
////        }
////    }
////}
//
//
//
//int main() {
//    int n = 1;
//    float x[MAXDIM];
//    int count = 10;
//
//    // 使用一个固定的种子
//    unsigned int seed = 12345;
//
//    for (int i = 0; i < count; i++) {
//        sobseq(x, &n);
//        n = n + 1;
//        // 将不同维度的值组合起来
//        float combined_value = 0.0;
//        for (int j = 0; j < MAXDIM; j++) {
//            printf("xxxxx:%f\n", x[j]);
//            combined_value += x[j];
//        }
//        combined_value = combined_value / MAXDIM;
//        // 混合伪随机数
//        //combined_value += (float)lcg_rand(&seed) / (1 << 31) * 0.1;
//        //// 确保值在0到1之间
//        //if (combined_value > 1.0) combined_value -= 1.0;
//        //if (combined_value < 0.0) combined_value += 1.0;
//        printf("%f\n", combined_value);
//    }
//
//    return 0;
//}
//
//

#include <stdio.h>
#include <stdint.h>

#define DIMS 5
#define N 10

// 方向数表，通常需要从文献或预计算表中获取
static const uint32_t V[DIMS][32] = {
    {1, 3, 7, 11, 13, 19, 25, 31, 37, 41, 47, 55, 61, 67, 73, 79, 85, 91, 97, 103, 109, 115, 121, 127, 133, 139, 145, 151, 157, 163, 169, 175},
    {1, 1, 5, 5, 17, 17, 65, 65, 241, 241, 897, 897, 3457, 3457, 13377, 13377, 51841, 51841, 200705, 200705, 778241, 778241, 3018753, 3018753, 11744001, 11744001, 45634049, 45634049, 177641473, 177641473, 691752897, 691752897},
    {1, 1, 7, 7, 15, 15, 63, 63, 255, 255, 1023, 1023, 4095, 4095, 16383, 16383, 65535, 65535, 262143, 262143, 1048575, 1048575, 4194303, 4194303, 16777215, 16777215, 67108863, 67108863, 268435455, 268435455, 1073741823, 1073741823},
    {1, 3, 5, 15, 17, 51, 85, 255, 273, 819, 1365, 4095, 4369, 13107, 21845, 65535, 87381, 262143, 349525, 1048575, 1398101, 4194303, 5592405, 16777215, 22369621, 67108863, 89478485, 268435455, 357913941, 1073741823, 1431655765, 4294967295},
    {1, 1, 3, 3, 11, 11, 33, 33, 121, 121, 385, 385, 1449, 1449, 4897, 4897, 19521, 19521, 66561, 66561, 266305, 266305, 932353, 932353, 3735553, 3735553, 13276417, 13276417, 53084161, 53084161, 192020481, 192020481}
};

void sobol(uint32_t sobolSeq[N][DIMS]) {
    uint32_t X[N][DIMS];  // 存放生成的序列

    // 初始化第一个点为0
    for (int i = 0; i < DIMS; i++) {
        X[0][i] = 0;
    }

    // 生成序列
    for (int i = 1; i < N; i++) {
        // 计算Gray码
        int grayCode = i ^ (i >> 1);
        int lastGrayCode = (i - 1) ^ ((i - 1) >> 1);

        // 找到不同的最高位
        int k = 0;
        while (((grayCode >> k) & 1) == ((lastGrayCode >> k) & 1)) {
            k++;
        }

        // 生成新的Sobol序列点
        for (int j = 0; j < DIMS; j++) {
            X[i][j] = X[i - 1][j] ^ V[j][k];
        }
    }

    // 复制生成的序列到输出数组
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < DIMS; j++) {
            sobolSeq[i][j] = X[i][j];
            printf("xxxxx:%d", X[i][j]);
        }
    }
}

void printSobolSeq(uint32_t sobolSeq[N][DIMS]) {
    for (int j = 0; j < DIMS; j++) {
        printf("维度 %d:\n", j + 1);
        for (int i = 0; i < N; i++) {
            printf("%f ", sobolSeq[i][j]);
        }
        printf("\n");
    }
}

int main() {
    uint32_t sobolSeq[N][DIMS];
    sobol(sobolSeq);
    printSobolSeq(sobolSeq);
    return 0;
}