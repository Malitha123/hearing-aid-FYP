% Calculate time
clear all;
close all;

%% read input signals
[in_noisy_1,Fs] = audioread('Unp_Front_SB_90_180.WAV');
[in_noisy_2,Fs] = audioread('Unp_Rear_SB_90_180.WAV');
[in_clean,Fs2] = audioread('COH_SB_90_180.WAV');
N=length(in_noisy_1);
n_frame_coherance = 640;
n_frame_adaptive = 320;  % (20ms) processing frame size

%% Initialise parameters for coherence function
coherence_final=[];

%% Initialise parameters for NLMS adaptive filter 
M = 70;  %70 best
xx = zeros( M,1);
w1 = zeros( M,1);
y = [];
e = [];

%% Initialise parameters for VAD
numFrames = ceil(N/n_frame_adaptive);
outputSignal = [];

% Initialize VAD flag arrays
iVad = zeros(numFrames, 1);
fVad = zeros(numFrames, 1);

% Initialize Energy Variables
energyMin = 0;
energyMax = 0;
deltaEmin = 1;
deltaEmax = 1;
lambda = 1;
threshold = 0;
initialEnergyMin = 0;

% Initialize RMSE, periodicity, and energy ratio arrays
RMSEArray = zeros(numFrames, 1);
periodicityArray = zeros(numFrames, 1);
ratioArray = zeros(numFrames, 1);
thresholdArray = zeros(numFrames, 1);

%% Loop starts here
first = 1;
last = n_frame_coherance;
frameCounter = 1;

while numFrames>frameCounter
    noisy1 = in_noisy_1 (first:last); %input signal1 frame
    noisy2 = in_noisy_2 (first:last); %input signal2 frame
    
    %feedback
    feedback_Signal1 = Feedback(noisy1);
    feedback_Signal2 = Feedback(noisy2);
    
    %coherance function
    coherance_out=Coherence(feedback_Signal1',feedback_Signal2',Fs);
    if (last==N)
        coherance_out=coherance_out(1+(n_frame_adaptive/4):end);
    else
        coherance_out=coherance_out(1+(n_frame_adaptive/4):5*n_frame_adaptive/4);
    end
    coherence_final = [coherence_final coherance_out'];
    
    first = first+n_frame_adaptive;
    if (last+n_frame_adaptive>N)
        last = N;
    else 
        last = last + n_frame_adaptive;
    end
    
%     if (last-first<n_frame_coherance)
    %voice activity detector
    [out,iVad,fVad,RMSEArray,periodicityArray,ratioArray,thresholdArray,energyMin,energyMax,deltaEmin,deltaEmax,lambda,threshold,initialEnergyMin]=VoiceActivityDetectorLoop_new(coherance_out,Fs,frameCounter,n_frame_adaptive,iVad,fVad,RMSEArray,periodicityArray,ratioArray,thresholdArray,energyMin,energyMax,deltaEmin,deltaEmax,lambda,threshold,initialEnergyMin);
    outputSignal=[outputSignal out'];
    frameCounter = frameCounter+1;

    %NLMS Adaptive filter
    [e1, y1, w1, xx] = NLMS_Loop(coherance_out, out, w1, xx, M);
    y=[y y1'];
    e=[e e1'];
%     else
%         for i=1:n_frame_adaptive:n_frame_coherance
%             %voice activity detector
%             [out,iVad,fVad,RMSEArray,periodicityArray,ratioArray,thresholdArray,energyMin,energyMax,deltaEmin,deltaEmax,lambda,threshold,initialEnergyMin]=VoiceActivityDetectorLoop_new(coherance_out(i:i+n_frame_adaptive-1),Fs,frameCounter,n_frame_adaptive,iVad,fVad,RMSEArray,periodicityArray,ratioArray,thresholdArray,energyMin,energyMax,deltaEmin,deltaEmax,lambda,threshold,initialEnergyMin);
%             outputSignal=[outputSignal out'];
%             frameCounter = frameCounter+1;
% 
%             %NLMS Adaptive filter
%             [e1, y1, w1, xx] = NLMS_Loop(coherance_out(i:i+n_frame_adaptive-1), out, w1, xx, M);
%             y=[y y1'];
%             e=[e e1'];
%         end
%     end
end

%% normalization before getting SNRs
vad = outputSignal;
nlms = y';
e=e';
coherence_final=coherence_final';
nlms = processAudio(in_noisy_1,nlms);
noisy1 = processAudio(in_noisy_1,in_noisy_1);
noisy2 = processAudio(in_noisy_1,in_noisy_2);
coherence_final=processAudio(in_noisy_1,coherence_final);
clean = processAudio(in_noisy_1,in_clean);
vad = processAudio(in_noisy_1,vad);

%% Plot results
figure;
PLOT(in_clean,Fs,'Clean signal',1)      % Plot the clean signal as a function of time.
PLOT(in_noisy_1,Fs,'Input noisy signal 1',2)% Plot the noisy signal as a function of time.
PLOT(in_noisy_2,Fs,'Input noisy signal 2',3)                % Plot the VAD data as a function of time.
% PLOT(coherence_final,Fs,'coherence_final',3)                 % Plot the VAD data as a function of time.

figure;
PLOT(coherence_final,Fs,'coherence_final',1)% Plot the noisy signal as a function of time.
PLOT(vad,Fs,'VAD',2)                 % Plot the VAD data as a function of time.
PLOT(nlms,Fs,'NLMS output',3)        % Plot the nlms output as a function of time.

%% calculate SNR
SNR_noisy1=20*log10(norm(in_clean)/norm(in_noisy_1-in_clean));
SNR_noisy2=20*log10(norm(in_clean)/norm(in_noisy_2-in_clean));
SNR_coherence=20*log10(norm(in_clean)/norm(coherence_final-in_clean(1:length(coherence_final))));
SNR_nlms=20*log10(norm(in_clean)/norm(nlms-in_clean(1:length(nlms))));

%% save results
% audiowrite('noisy.wav', in_noisy, Fs);
% audiowrite('clean.wav', in_clean, Fs);
% audiowrite('nlms.wav', nlms, Fs);

