function y=ifft_new(x,R)

y=zeros(1,R);

for n = 1:R
    for k = 1:R %loop as per the IFFT formula
        y(n) = y(n)+(1/R)*x(k)*exp(j*2*pi*(k-1)*(n-1)/R);
    end
end
