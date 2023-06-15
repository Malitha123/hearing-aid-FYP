function peakPeriodicity = Periodicity(input, fs)

duration = length(input);
clipThresholdFactor = 0.5;
clipThreshold = clipThresholdFactor * max(input);
output = zeros(1, duration);

% Center Clipping algorithm
for i=1:length(input)
    if (input(i) >= clipThreshold)
        output(i) = input(i) - clipThreshold;
    elseif (abs(input(i)) < clipThreshold)
        output(i) = 0;
    elseif (input(i) < - clipThreshold)
        output(i) = input(i) + clipThreshold;
    end
end
% Output now contains the center-clipped signal. Let's get it's ACF.
%[m,n]=size(output)
acf = xcorr(output);

% Now, we want the ACF only for lag values that fall within the pitch
% period limits. Let's take 2.5ms to 15ms, i.e. with a sampling rate of
% fs, that corresponds to:
lowerLagMS = 2.5;
upperLagMS = 15;
lowerLag = round((lowerLagMS * fs) / 1000);
upperLag = round((upperLagMS * fs) / 1000);

% The ACF is symmetric around 0, meaning it goes from -n to n (lag values).
% We want the ACF values for lags going from the lower to the upper lag
% limits. Because there are 2n-1 ACF values, this maps to n + the lag we
% want.
acfSectionalized = acf(duration+lowerLag:duration+upperLag);

% We normalizing the ACF with n - h and then energy per sample.
hVector = lowerLag:upperLag;
lagArray = duration - hVector;
acfNormalized = acfSectionalized ./ lagArray;

energyNormalized = acf(duration)/duration;

finalacf = acfNormalized / energyNormalized;

peakPeriodicity = max(finalacf);


return
