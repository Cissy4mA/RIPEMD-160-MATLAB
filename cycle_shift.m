function number = cycle_shift(v, pos)
    % 将输入值 v 转换为 32 位无符号整数
    v = uint32(v);
    
    % 初始化二进制字符串数组
    bin_str = strings(1, 32);
    
    % 将数值 v 转换为二进制字符串
    for i = 1:32
        bin_str(i) = num2str(mod(v,2));
        v = bitshift(v, -1);
    end
    bin_str = flip(bin_str);
    
    % 执行循环位移
    for i = 1:pos
        bit = bin_str(1);
        for j = 2:32
            bin_str(j - 1) = bin_str(j);
        end
        bin_str(32) = bit;
    end
    
    % 将二进制字符串转换回数值
    number = 0;
    for i = 1:32
        number = bitor(bitshift(number, 1), str2double(bin_str(i)));
    end
end