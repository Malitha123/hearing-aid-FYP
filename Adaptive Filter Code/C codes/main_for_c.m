%% read input signals
%[in_noisy_1,Fs] = audioread('Unp_Front_SB_90_180.WAV');
%in_noisy_1=in_noisy_1(1:6000);
%[in_noisy_2,Fs] = audioread('Unp_Rear_SB_90_180.WAV');
%in_noisy_2=in_noisy_2(1:6000);
%[in_clean,Fs2] = audioread('Clean3.WAV');
%in_clean=in_clean(1:6000);
%N=length(in_noisy_1);
n_frame_coherance = 640;
n_frame_adaptive = 320;  % (20ms) processing frame size

%% Initialise parameters for coherence function
%coherence_final=[];

%% Initialise parameters for VAD
numFrames = ceil(N/n_frame_adaptive);
%outputSignal = [];

% Initialize VAD flag arrays
%iVad = zeros(numFrames, 1);
%fVad = zeros(numFrames, 1);

% Initialize Energy Variables
energyMin = 0;
energyMax = 0;
deltaEmin = 1;
deltaEmax = 1;
lambda = 1;
threshold = 0;
initialEnergyMin = 0;

% Initialize RMSE, periodicity, and energy ratio arrays
%RMSEArray = zeros(numFrames, 1);
%periodicityArray = zeros(numFrames, 1);
%ratioArray = zeros(numFrames, 1);
%thresholdArray = zeros(numFrames, 1);

%% Initialise parameters for NLMS adaptive filter 
M = 70;  %70 best
xx = zeros( M,1);
w1 = zeros( M,1);
y = [];
e = [];

%% initialising parameters for frequency shaper
H_th = db2mag(20);   % Threshold of hearing
P_th = db2mag(70);   % Threshold of pain
Lower_limit = 2000;  % Lower limit of the hearing loss range
Upper_limit = 5000;  % Upper limit of the hearing loss range
%a=1000;              % Smoothing area
%fre_shap_final = [];

%% Loop starts here
first = 1;
last = n_frame_coherance;
frameCounter = 1;

while numFrames>frameCounter
    noisy1 = in_noisy_1 (first:last); %input signal1 frame
    noisy2 = in_noisy_2 (first:last); %input signal2 frame
    
    %feedback
%     feedback_Signal1 = Feedback(noisy1);
%     feedback_Signal2 = Feedback(noisy2);
    
    %Coherance function
    coherance_out=Coherence(noisy1,noisy2,Fs);
    %coherance_out=Coherence(feedback_Signal1',feedback_Signal2',Fs);
    if (last==N)
        coherance_out=coherance_out(1+(n_frame_adaptive/4):end);
    else
        coherance_out=coherance_out(1+(n_frame_adaptive/4):5*n_frame_adaptive/4);
    end
    %coherence_final = [coherence_final coherance_out'];
    
    %Voice activity detector
    [out,energyMin,energyMax,deltaEmin,deltaEmax,lambda,threshold,initialEnergyMin]=VAD(coherance_out,Fs,frameCounter,n_frame_adaptive,energyMin,energyMax,deltaEmin,deltaEmax,lambda,threshold,initialEnergyMin);
    %outputSignal=[outputSignal out'];

    %NLMS Adaptive filter
    [y1, w1, xx] = NLMS(coherance_out, out, w1, xx, M);
    %y=[y y1'];
    %e=[e e1'];
    
    %Frequency shaping
    fre_shaper = Freqshaper(y1,Fs,H_th,P_th,Lower_limit,Upper_limit);
    %fre_shap_final = [fre_shap_final fre_shaper];
    
    %Update framecounter, first and last variables
    frameCounter = frameCounter+1;
    first = first+n_frame_adaptive;
    if (last+n_frame_adaptive>N)
        last = N;
    else 
        last = last + n_frame_adaptive;
    end
    
end



