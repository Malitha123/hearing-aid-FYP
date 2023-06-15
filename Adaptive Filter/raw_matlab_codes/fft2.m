function y = fft(X, M)
N = 1 << M;        
N2 = N/2;
j = 0;

for i=1:(N-1)        % 1 or 2 ????????????
k = N2;                     
                         
    while k<j+1          %// Propagate carry if bit is 1       
        j = j - k;          %// Bit tested is 1, so clear it.      
        k = k/2;            %// Set up 1 for next bit to right.    
    end
    
    j = j+k;              %// Change 1st 0 from left to 1
    if i<j               %// Test if previously swapped.
        temp1= X(j);
        X(j)= X(i);
        X(i)temp1;
    end
end

% /*==============================================================*/
% //  Do M stages of butterflys
for L=1:M
    LE = 1 << L;            %//  LE = 2**L = points is sub DFT 
    LE1 = LE/2;             %// Number of butterflys in sub-DFT
    U= 1.0;           %// U = 1 + j 0                     
    W.real = cos(PI/LE1);
    W.imag = - sin(PI/LE1); %// W = e**(-j 2 PI/LE)
end

for j=0:LE1   %//Do the LE1 butterflys per sub DFT
  
    for i=j:LE:N
        id = i + LE1;      %// Index of lower point in butterfly
        temp1.real = (X[id]).real*U.real - (X[id]).imag*U.imag;
        temp1.imag = (X[id]).imag*U.real + (X[id]).real*U.imag;
        X(id)= X(i) - temp1;
        X(i) = X(i)+temp1;
    end
%     //Recursively compute W**k as W*W**(k-1) = W*U
    temp1.real = U.real*W.real - U.imag*W.imag;
    U.imag = U.real*W.imag + U.imag*W.real;
    U.real = temp1.real;
end
end
 
