function c = xcorr(x)

% Transform the input, if necessary, so that computations can be performed
% on columns
p=size(x,1) == 1 && ~isscalar(x);
if p && coder.internal.isConst(p);
    % Make a recursive call. Row vector input becomes a column vector, N-D
    % inputs have leading ones (the constant leading ones) shifted out.
    % Note: With code generation SHIFTDIM will issue a run-time error if
    % the first dimension without a constant length of 1 has a length of 1
    % at run-time.
    [x1,nshift] = shiftdim(x);
    c1 = xcorr(x1);
    c = shiftdim(c1,-nshift);
    return
end

maxlag = size(x,1) - 1;
c = autocorr(x,maxlag);

%--------------------------------------------------------------------------

function c = autocorr(x,maxlag)
% Compute all possible auto- and cross-correlations of the columns of a
% matrix input x. Output is clipped based on maxlag but not padded when
% maxlag >= size(x,1).
coder.internal.prefer_const(maxlag);
[m,n] = size(x);
mxl = min(maxlag,m - 1);
ceilLog2 = nextpow2(2*m - 1);
m2 = 2^ceilLog2;
% Autocorrelation of a column vector.
X = fft(x,m2,1);
Cr = abs(X).^2;
c1 = real(ifft(Cr,[],1));
% Keep only the lags we want and move negative lags before positive
% lags.
c = [c1(m2 - mxl + (1:mxl)); c1(1:mxl+1)];