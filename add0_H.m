function D_=add0_H(D_)
if 8-length(D_)~=0
    for i=1:8-length(D_)
    D_=['0',D_];
    end
end
end