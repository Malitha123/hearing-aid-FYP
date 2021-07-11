function y=fft_new(x,nfft)

N=length(x);
y=zeros(1,nfft);

for k=1:nfft
    for n=1:N
        y(k)=y(k)+x(n)*exp(-j*2*pi*(k-1)*(n-1)/nfft);
    end
end

