function hashed = ripemd160(filename)

    fid = fopen(filename,'r');
    M = fread(fid, '*uint8')';
    fclose(fid);
    % 补位
    byte_message = M;
    len_message = numel(byte_message) * 8; % 计算原始消息的长度（以位为单位）
    byte_message(end+1) = uint8(0x80);% 在消息末尾添加一个 '1' 位（0x80 是 1000 0000 的十六进制表示）
    while mod(numel(byte_message) * 8, 512) ~= 448% 循环直到满足填充条件
        byte_message(end+1) = uint8(0x00);% 如果最后一个字节不是 0x80，则添加 '0' 位，直到满足条件
    end
    
    if len_message >= 2^64% 如果消息长度超过了 64 位整数的最大值，则进行处理
        len_message = bitand(len_message, uint64(0xFFFFFFFFFFFFFFFF));% 使用位与运算截断长度，确保长度在 64 位范围内
    end
    first_part = bitand(len_message, uint64(0xFFFFFFFF));% 获取长度的低 32 位
    second_part = bitshift(len_message, -32);
    
    % 将长度转换为字节并添加到消息末尾
    byte_message = [byte_message, typecast(int32(first_part), 'uint8'), typecast(int32(second_part), 'uint8')];
    
    % 初始化
    constant_adding = uint32([0x00000000, 0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xA953FD4E]);
    constant_adding_hatch = uint32([0x50A28BE6, 0x5C4DD124, 0x6D703EF3, 0x7A6D76E9, 0x00000000]);
    r = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, ...
         7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8, ...
         3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12, ...
         1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2, ...
         4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13];
    r_hatch = [5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12, ...
               6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2, ...
               15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13, ...
               8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14, ...
               12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11];
    s = [11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8, ...
         7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12, ...
         11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5, ...
         11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12, ...
         9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6];
    s_hatch = [8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6, ...
               9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11, ...
               9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5, ...
               15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8, ...
               8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11];
    h = uint32([0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]);
    
    % 分割消息
    separated_message = {};
    for i = 1:floor(numel(byte_message) / 64)%很不一样
        part = byte_message(64*(i-1)+1:64*i);
        separated_message{i+1} = zeros(1, 16);
        for j = 1:16
            separated_message{i+1}(j) = typecast(uint8(part(4*(j-1)+1:4*j)), 'uint32');
        end
    end
    
    % RIPEMD160 算法
    for i = 2:numel(separated_message)
        part = separated_message{i};
        A = h(1);
        B = h(2);
        C = h(3);
        D = h(4);
        E = h(5);
        A_hatch = h(1);
        B_hatch = h(2);
        C_hatch = h(3);
        D_hatch = h(4);
        E_hatch = h(5);
        
        for j = 1:80
            f = function_choose(j);
            f_hatch = function_choose(81 - j);
            if j <= 16
                k = constant_adding(1);
                k_hatch = constant_adding_hatch(1);
            elseif j <= 32
                k = constant_adding(2);
                k_hatch = constant_adding_hatch(2);
            elseif j <= 48
                k = constant_adding(3);
                k_hatch = constant_adding_hatch(3);
            elseif j <= 64
                k = constant_adding(4);
                k_hatch = constant_adding_hatch(4);
            else
                k = constant_adding(5);
                k_hatch = constant_adding_hatch(5);
            end
            
            x = part(r(j)+1);
            x_hatch = part(r_hatch(j)+1);
            T=uint32(mod((int64(A)-int64(f(B,C,D))...
            +int64(x)+int64(k)),2^32));
            T = cycle_shift(T, s(j));
            T = uint32(mod(uint64(T)+uint64(E),2^32));
            A = E;
            E = D;
            D = cycle_shift(C, 10);
            C = B;
            B = T;
            T=uint32(mod((int64(A_hatch)-int64(f_hatch(B_hatch,C_hatch,D_hatch))...
            +int64(x_hatch)+int64(k_hatch)),2^32));
            T = cycle_shift(T, s_hatch(j));
            T = uint32(mod(uint64(T) + uint64(E_hatch),2^32));
            A_hatch = E_hatch;
            E_hatch = D_hatch;
            D_hatch = cycle_shift(C_hatch, 10);
            C_hatch = B_hatch;
            B_hatch = T;
        end
        
        T=uint32(mod((uint64(h(2))+uint64(C)+uint64(D_hatch)),2^32));
        h(2)=uint32(mod((uint64(h(3))+uint64(D)+uint64(E_hatch)),2^32));
        h(3)=uint32(mod((uint64(h(4))+uint64(E)+uint64(A_hatch)),2^32));
        h(4)=uint32(mod((uint64(h(5))+uint64(A)+uint64(B_hatch)),2^32));
        h(5)=uint32(mod((uint64(h(1))+uint64(B)+uint64(C_hatch)),2^32));
        h(1)=T;
    end
    
    % 将哈希值转换为字节
    hashed=[adjust(h(1)),adjust(h(2)),adjust(h(3)),adjust(h(4)),adjust(h(5))];
end