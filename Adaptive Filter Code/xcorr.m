function c = xcorr(x) % x=320*1

p=size(x,1); %1 then 0
if p == 1  
    x1=x';      % always a column vector  
    c1 = xcorr(x1);   
    c = c1';  
    return
end

maxlag = size(x,1) - 1; % always 319, only change if size changes
c = autocorr(x,maxlag);

function c = autocorr(x,maxlag)
[m,n] = size(x);  %320*1
mxl = min(maxlag,m - 1);
%ceilLog2 = nextpow2(2*m - 1);
ceilLog2 = ceil(log2(abs(2*m - 1)));
m2 = 2^ceilLog2;
X = fft(x,m2,1);
Cr = abs(X).^2;
c1 = real(ifft(Cr,[],1));
c = [c1(m2 - mxl + (1:mxl)); c1(1:mxl+1)];