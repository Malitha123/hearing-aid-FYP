function out_array = awgn2(es_ovr_n0,channel_len,in_array)
mean = 0;
es = 1;
sn_ratio = 10^( es_ovr_n0 / 10) ;
sigma = sqrt (es / ( 2 * sn_ratio ) );

%now transform the data from 0/1 to +1/-1 and add noise 
for t = 1:channel_len

    %if the binary data value is 1, the channel symbol is -1; if the
	%binary data value is 0, the channel symbol is +1.
    signal = in_array(t) + t;

    %now generate the gaussian noise point, add it to the channel symbol,
    %and output the noisy channel symbol 

    gauss_offset = GNGauss(mean,sigma);
    out_array(t) = signal + gauss_offset - t;
end


function y = GNGauss(mean,sigma) 
LRAND_MAX = 2147483647;
%randomDouble = 0;
randomDouble = bitsll( int16(rand()),1) & 65535;
randomDouble = randomDouble |(int32(rand() < 16));

% generate a uniformly distributed random number u between 0 and 1 - 1E-6
u = randomDouble / LRAND_MAX;
if (u == 1.0) 
    u = 0.999999999;
end

% generate a Rayleigh-distributed random number r using u 
r = sigma * sqrt( 2.0 * log( 1.0 / (1.0 - u) ) );

%randomDouble = 0;
randomDouble = bitsll( int16(rand()),1) & 65535;
randomDouble = randomDouble | (int32(rand() < 16));

% generate another uniformly-distributed random number u as before
u = randomDouble / LRAND_MAX;
if (u == 1.0) 
    u = 0.999999999;
end

%generate and return a Gaussian-distributed random number using r and u
y= mean + r * cos(2 * pi * u);

