function D_=nega(D_)
for i=1:32
    if D_(i)=='1'
        D_(i)='0';
    elseif D_(i)=='0'
        D_(i)='1';
    end
end
end