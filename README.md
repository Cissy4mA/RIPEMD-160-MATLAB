# RIPEMD-160 in MATLAB · MATLAB 实现 RIPEMD-160 哈希函数

A self-contained, dependency-free MATLAB implementation of the **RIPEMD-160**
cryptographic hash function. It is byte-accurate and verified against the
standard RIPEMD-160 test vectors (see [Test vectors](#test-vectors-测试向量)).

一个**零依赖、纯 MATLAB** 实现的 **RIPEMD-160** 加密哈希函数。字节级精确，
并已通过标准 RIPEMD-160 测试向量验证（见[测试向量](#test-vectors-测试向量)）。

> RIPEMD-160 produces a 160-bit (20-byte) digest and is used in Bitcoin
> address generation (applied after SHA-256, as `RIPEMD-160(SHA-256(pubkey))`).
> RIPEMD-160 输出 160 位（20 字节）摘要，在比特币地址生成中用于
> `RIPEMD-160(SHA-256(公钥))` 这一步。

---

## Features · 特性

- Pure MATLAB, **no toolboxes, no MEX, no external libraries**.
  纯 MATLAB 实现，**不依赖任何工具箱、MEX 或外部库**。
- Reads arbitrary binary input from a file (byte-exact padding).
  从文件读取任意二进制输入，补位严格按字节精确处理。
- Includes a test script (`ripemd160_test.m`) covering 7 standard vectors.
  自带测试脚本，覆盖 7 组标准测试向量。

---

## Algorithm · 算法原理

RIPEMD-160 is a Merkle–Damgård hash with a distinctive **two-parallel-line**
(dual-branch) compression function. Each message block updates two independent
80-step lines (left and right), which are then combined.

RIPEMD-160 是一种 Merkle–Damgård 结构哈希，其特点是**双线并行**（dual-branch）
压缩函数：每个消息块同时驱动两条独立的 80 步线路（左线与右线），最后合并。

### 1. Message preprocessing · 消息预处理

1. Append a single `1` bit, i.e. the byte `0x80`.
   先补一个 `1` 位，即字节 `0x80`。
2. Append `0` bits until the message length ≡ 448 (mod 512).
   再补 `0` 位，直到消息总长度 ≡ 448 (mod 512)。
3. Append the original message length as a **64-bit little-endian** integer.
   最后追加原始消息长度的 **64 位小端（little-endian）** 表示。
4. The result is split into 512-bit (64-byte) blocks, each viewed as
   sixteen 32-bit little-endian words `X[0..15]`.
   结果按 512 位（64 字节）分块，每块视为 16 个 32 位小端字 `X[0..15]`。

### 2. Constants · 常量

Five additive constants per line (left / right):

| Step 步数 | `K` (left) | `K` (right) |
|----------:|-----------:|------------:|
| 1  (0–15) | `0x00000000` | `0x50A28BE6` |
| 2  (16–31)| `0x5A827999` | `0x5C4DD124` |
| 3  (32–47)| `0x6ED9EBA1` | `0x6D703EF3` |
| 4  (48–63)| `0x8F1BBCDC` | `0x7A6D76E9` |
| 5  (64–79)| `0xA953FD4E` | `0x00000000` |

The full 80-element message-word selection arrays `r` / `r_hatch` and rotation
arrays `s` / `s_hatch` are defined inline in `ripemd160.m`.
完整的 80 元素消息字选择数组 `r` / `r_hatch` 与循环移位数组 `s` / `s_hatch`
均内联定义在 `ripemd160.m` 中。

### 3. Compression function · 压缩函数

Initial state (fixed initialization vector, identical for both lines):

初始状态（固定初始向量，两条线相同）：
`h = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]`

For each block, run **80 steps = 5 rounds × 16 steps**. The left line uses
rounds 1→5 in order; the right line uses rounds 5→1 (mirrored). Each step:

每个消息块执行 **80 步 = 5 轮 × 16 步**。左线按 1→5 轮顺序，右线按 5→1 轮
（镜像）。单步更新：

```
T = (A + f(B,C,D) + X[r] + K)  mod 2^32
T = ROL(T, s)
T = (T + E)                    mod 2^32
A = E ;  E = D ;  D = ROL(C,10) ;  C = B ;  B = T
```

Five Boolean functions `f1..f5` (used per round, both lines):

五个布尔函数 `f1..f5`（每轮使用一种，两条线共用）：

| Round | f(x,y,z) |
|------:|----------|
| 1 | `x XOR y XOR z` |
| 2 | `(x AND y) OR (NOT x AND z)` |
| 3 | `(x OR NOT y) XOR z` |
| 4 | `(x AND z) OR (y AND NOT z)` |
| 5 | `x XOR (y OR NOT z)` |

### 4. Final combination · 结果合并

After all steps, combine the two lines (`L` = left results, `R` = right results)
with the previous state `h`:

全部步完成后，将两条线结果（`L` 左线 / `R` 右线）与前一状态 `h` 合并：

```
h0 = (h1 + CL + DR) mod 2^32
h1 = (h2 + DL + ER) mod 2^32
h2 = (h3 + EL + AR) mod 2^32
h3 = (h4 + AL + BR) mod 2^32
h4 = (h0 + BL + CR) mod 2^32
```

Each resulting 32-bit word is then **byte-swapped** for little-endian output,
equivalent to reordering its 8 hex digits as **7,8,5,6,3,4,1,2**. The five
words are concatenated to form the 40-character (160-bit) hex digest.
每个 32 位字再做**字节交换**（等价于把 8 位十六进制按 **7,8,5,6,3,4,1,2** 重排），
五个字拼接成 40 字符（160 位）十六进制摘要。

---

## Usage · 使用方法

The function reads the message **from a file** (raw bytes):

该函数**从文件**读取消息（原始字节）：

```matlab
h = ripemd160('examples/abc.txt');   % -> '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc'
disp(lower(h));
```

To hash an in-memory string, write it to a file first (no trailing newline):

若要哈希内存中的字符串，先写入文件（不要带结尾换行）：

```matlab
fid = fopen('msg.txt','w'); fwrite(fid, 'hello world'); fclose(fid);
h = ripemd160('msg.txt');
```

Run the built-in self-test:

运行自带测试：

```matlab
ripemd160_test   % prints 7 vectors, ends with "All test vectors passed: true"
```

---

## Test vectors · 测试向量

| Input | RIPEMD-160 digest |
|-------|-------------------|
| `""` (empty) | `9c1185a5c5e9fc54612808977ee8f548b2258d31` |
| `"a"` | `0bdc9d2d256b3ee9daae347be6f4dc835a467ffe` |
| `"abc"` | `8eb208f7e05d987a9b044a8e98c6b087f15a0bfc` |
| `"message digest"` | `5d0689ef49d2fae572b881b123a85ffa21595f36` |
| `"abcdefghijklmnopqrstuvwxyz"` | `f71c27109c692c1b56bbdceb5b9d2865b3708dbc` |
| `"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"` | `12a053384a9c0c88e405a06c27dcf49ada62eb2b` |
| `"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"` | `b0e20b6e3116640286ed3a87a5713079b21f5189` |

---

## Files · 文件说明

| File | Purpose |
|------|---------|
| `ripemd160.m` | Main entry point: padding, block loop, dual-branch compression, final combination. 主函数。 |
| `function_choose.m` | Returns the round-dependent Boolean function `f1..f5`. 按轮次返回布尔函数。 |
| `cycle_shift.m` | 32-bit left rotation (ROL). 32 位循环左移。 |
| `adjust.m` / `add0_H.m` | Byte-swap / zero-pad a 32-bit word for output. 输出字节交换与补零。 |
| `add0.m` / `plus1.m` / `nega.m` | Bit-string helpers used by the Boolean functions. 布尔函数所用的位串辅助函数。 |
| `ripemd160_test.m` | Self-test against the 7 standard vectors. 标准向量自测。 |
| `examples/abc.txt`, `examples/a.txt` | Sample inputs. 示例输入。 |

---

## Implementation notes · 实现说明

- **Endianness**: message words and the length field are interpreted as
  **little-endian** (via `typecast` on little-endian platforms). All common
  platforms (x86, ARM) are little-endian, so no change is needed.
  **字节序**：消息字与长度字段按**小端**解释（在常见的小端平台 x86 / ARM 上无需改动）。
- **uint32 safety**: the Boolean functions are implemented through binary-string
  two's-complement arithmetic (`nega` + `plus1`) to stay correct for the full
  32-bit range without relying on signed-integer overflow behavior.
  **32 位安全性**：布尔函数通过二进制串的二补码运算（`nega` + `plus1`）实现，
  以正确处理整个 32 位取值范围。

---

## License · 许可证

Released under the [MIT License](LICENSE).
采用 [MIT 许可证](LICENSE) 发布。
