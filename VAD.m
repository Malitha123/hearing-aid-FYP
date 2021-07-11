function [vad,iVad,fVad,RMSEArray,periodicityArray, ratioArray, thresholdArray, energyMin,energyMax,deltaEmin, deltaEmax, lambda, threshold, initialEnergyMin] = VAD(input,fs,frameCounter,n_frame, iVad,fVad,RMSEArray,periodicityArray, ratioArray, thresholdArray,energyMin,energyMax,deltaEmin, deltaEmax, lambda, threshold, initialEnergyMin)

frame = input';
initialNoiseDuration = 50*fs/1000; %50ms
outputSignal = [];

% % Initialize Energy Variables
lowerEnergyVoiceBand = 2000;
upperEnergyVoiceBand = 4000;

% Initialize Periodicity and Energy Ratio thresholds
periodicityThreshold = 1;
energyRatioThreshold = 10;

% Get the Root Mean Square Energy of the input frame
RMSE = sqrt(mean(sum(frame.^2)));

% Add to the array of RMS energies 
RMSEArray(frameCounter) = RMSE;

% NOTE: An important assumption necessarily made is that the first
% 100ms or so of the signal will be noise. So we use the first few
% frames to calculate and set Emin and Emax values.
if ((frameCounter * n_frame) < initialNoiseDuration)
    if (RMSE > energyMax)
        % Set Emax
        energyMax = 5 * RMSE;
    end

    if (energyMin == 0)
        % Initialize Emin
        energyMin = RMSE;            
        initialEnergyMin = energyMin;
    else
        if (RMSE > energyMin)
            energyMin = RMSE;
        end
    end

    % The first few frames are assumed to be noise, so no VAD
    % processing is necessary.
    iVad(frameCounter) = 0;
    fVad(frameCounter) = 0;

else                
    % Commence actual VAD processing.
    % Update running Energy threshold estimates (Emax, Emin)
    if (RMSE > energyMax)
        % We use a small delta to gradually decrease Emax to compensate
        % for anomalous spikes in energy
        energyMax = RMSE;
        deltaEmax = 1;
    else
        deltaEmax = 0.999;
    end

    if (RMSE < energyMin)
        if (RMSE == 0)
            energyMin = initialEnergyMin;
        else            
            energyMin = RMSE;
        end

        deltaEmin = 1;
    else
        % We use a small delta scaling factor to prevent complications
        % arising from energy dips (anomalies). This keeps Emin rising
        % at a gradual, minimal rate.
        deltaEmin = deltaEmin * 1.001;
    end

    % Threshold computations. Lambda is the non-linear dynamic
    % coefficient used to compute the threshold in a way that makes it
    % resistant and independent of variations in background noise.
    lambda = 1 - (energyMin/energyMax);
    threshold = ((1 - lambda) * energyMax ) + (lambda * energyMin);

    % Keep track of threshold values 
    thresholdArray(frameCounter) = threshold;

    % Get the periodicity of the frame
    periodicity = Periodicity(frame, fs);

    % Add to peridocity array 
    periodicityArray(frameCounter) = periodicity;

    % Get the ratio of the frequencies above and below 2 kHz in the voice
    % band (0 - 4 kHz). We will then use the ratio of these energies to
    % make decisions around the voicing of the frame.
    window = (hamming(size(frame,2)))';

    % FFT computation & normalization
    fftLength = 2^nextpow2(length(frame));
%     theFFT = fft(frame.*window, fftLength);
    theFFT = fft_new(frame.*window, fftLength);
    
% %     figure;
% %     t=0:fftLength-1;
% %     subplot(2,1,1);
% %     plot(t,theFFT);
% %     subplot(2,1,2);
% %     plot(t,theFFT2);
    
    fftLength = length(theFFT);
    fftSq = (theFFT).*conj(theFFT);
    fftSqNorm = fftSq/fftLength;

    % Compute the voiced energy band ratio
    energyBelow = sum(fftSqNorm(1:round((lowerEnergyVoiceBand/fs) * fftLength)));
    energyAbove = sum(fftSqNorm(round((lowerEnergyVoiceBand/fs) * fftLength):round((upperEnergyVoiceBand/fs) * fftLength)));
    energyRatio = energyAbove/energyBelow;

    % Add to ratio array
    ratioArray(frameCounter) = energyRatio;

    % Now that we have all the features extracted, make a decision about
    % the frame being voiced or not. We decide that a frame is voiced
    % if either a) the RMS Energy is above the threshold, or b) the
    % signal shows periodicity within the human voice range of pitches,
    % or c) there is significantly higher energy in the upper range of
    % the voiced band as compared to the lower range, pivoting at 2 kHz
    if ((RMSE > threshold) || (periodicity > periodicityThreshold))
        iVad(frameCounter) = 1;
    elseif (abs(energyRatio) > energyRatioThreshold)
        iVad(frameCounter) = 1;
    else
        iVad(frameCounter) = 0;
    end
end

% Construct the final signal 
if (iVad(frameCounter) == 1)
    outputSignal = frame;
else
    outputSignal = frame*0;
end

% Scale Emin and Emax to compensate for anomalies in energy spectra
energyMin = energyMin * deltaEmin;
energyMax = energyMax * deltaEmax;

vad = outputSignal' ; 
end