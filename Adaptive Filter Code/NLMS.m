function [e, y, w1, xx] = NLMS(noisy, vad, w1, xx, M)

noise = awgn_new(vad,20,'measured');
%noise = awgn2(20,length(vad),vad);
d = vad  + noise;    %desired signal
Ns=length(d);
y=zeros(Ns,1);
e=zeros(Ns,1);
c = 0.01;            %the constant term for normalization and is always less than 1
alpha = 0.09;        %NLMS adaption  constant,  which  optimize the convergence rate of the algorithm and should satisfy the condition 0<alpha<2

for n = 1:Ns
    xx = [xx(2:M);noisy(n)];
    xxx = flipud(xx);
    y(n) = w1' * xxx;
    e(n) = d(n) - y(n);
    mu = alpha/(c + xxx'*xxx);
    w1 = w1 + (mu * e(n) * xxx);
end

end