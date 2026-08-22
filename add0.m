function D_=add0(D_)
if 32-length(D_)~=0
    for i=1:32-length(D_)
    D_=['0',D_];
    end
end
end