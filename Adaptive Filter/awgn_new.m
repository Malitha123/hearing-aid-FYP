function y=awgn_new(sig,reqSNR,measMode)

sigPower = sum(abs(sig(:)).^2)/length(sig(:));
sigPower = 10*log10(sigPower);
p = sigPower-reqSNR;
noisePower = 10^(p/10);
y = (sqrt(noisePower))*randn(size(sig,1), size(sig,2)); %func(rows,columns)

end