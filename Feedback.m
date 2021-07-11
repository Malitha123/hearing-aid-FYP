function Output_Signal = Feedback(Input)
    Input      =   Input(:)';
    Input      =   Input - mean(Input);
    len    =   length(Input);
    VAR_sn  =   var(Input);

    % Parameters
    gain_Gz     = 10;          
    SNR_prob    = 0;            % Set SNR for Probe-Signal Variance
    alpha_W1z   = 1e-4;      	% Regularization Parameter for W1z
    alpha_W2z   = 1e-4;         % Regularization Parameter for W2z
    lambda_W2z  = 0.97;         % forgetting factors
    lambda_W1z  = 0.97;
    mu_W1z      = 1e-3;         % Step size for W1z
    mu_W2z      = 1e-4;         % Step size for W2z
    muw1_min    = 1e-6;         % Min bound for step-size W1
    muw2_min    = 1e-6;         % Min bound for step-size W2
    Th_T1       = 1e-3;         % Thresholding paramter T1
    Th_T2       = 1;            % Thresholding paramter T2   should be less than 1
    Th_T3       = 1;            % Thresholding paramter T3
    Th_T4       = 10;           % Thresholding paramter T4   should estimated from pe2n

    % Generate simple delay-gain feedforward Path G(z)
    M1 =64 ;                       % Filter length for modeling filter
    M2 = M1;                        % Filter length for supporting filter
    delay   = 80 ;                        % Delay in feedforward path
    DELAY   = 40 ;         % Appended DELAY
    Gz      = [zeros(1, delay) gain_Gz]'; % Simple feedforward path
    N       = length (Gz);                  % length of feedforward path

    % geneate prob signal
    probe_var = 10^(-SNR_prob/10) * VAR_sn;  %----> probe_var = var(Input)
    probe = randn(size(Input));
    probe = sqrt(probe_var/var(probe)) * probe;  

    % Siganl Definition
    xn          = zeros(1,len);    % Mic input
    vn          = zeros(1,len);    % Probe input
    un          = zeros(1,len);    % Reconstructed input to Feedforward Path
    yn          = zeros(1,len);    % Output of Feedforward Path
    yn_total    = zeros(1,len);    % Louspeaker Signal
    y1n         = zeros(1,len);    % Hearing Aid Ouput (for y(n)) after apended delay
    v1n         = zeros(1,len);    % Hearing Aid Ouput (for v(n)) after apended delay
    yn_Fz       = zeros(1,len);    % output of FBP F(z) due to y(n): yf(n)
    vn_Fz       = zeros(1,len);    % output of FBP F(z) due to probe signal v(n): vf(n)
    en          = zeros(1,len);    % Error signal for adaptive F^(z)
    Pn_en       = zeros(1,len);    % Power estimate of e(n)
    yn_W1z      = zeros(1,len);    % output of H(z)
    gn          = zeros(1,len);    % Error of H(z)
    Pn_gn       = zeros(1,len);    % Power estimate of g(n)
    mun_W2z     = zeros(1,len);    % varying step size for F^(z)
    mun_W1z     = zeros(1,len);    % Varying step size for H(z)
    Diff_Fz_hat1= zeros(1,len);    % Estimation in F^(z) in W1(z)
    Diff_Fz_hat2= zeros(1,len);    % Estimation in F^(z) in W2(z)
    rho1        = zeros(1,len);    
    rho2        = zeros(1,len);
    msg_off 	= zeros(1,len);    % Maximum Stable Gain w/o feedback cancellation
    msg         = zeros(1,len);    % Maximim Stable Gain with feedback cancellation
    asg         = zeros(1,len);    % Added stable gain because of AFC
    probe_new   = zeros(1,len);
    probe_gain  = zeros(1,len);
    NSD         = zeros(1,len);

    %Initialization
    Fd_z        = [ zeros(1,DELAY), 1]'; % Appended Delay
    Fd_z_hat1   = ones(DELAY,1) ;
    Fz_hat1     = zeros(M1,1);           % Initialize filter coefs to 0
    W1z         = [Fd_z_hat1; Fz_hat1];  % Initialize adaptive filter W1(z)
    Fd_z_hat2   = ones(DELAY,1) ;
    Fz_hat2     = zeros(M2,1);           % Initialize filter coefs to 0
    W2z         = [Fd_z_hat2; Fz_hat2];  % Initialize adaptive filter W2(z)
    u_Gz        = zeros(N,1);            % vector for input to feedforward-path G(z)
    y_Gz        = zeros(M1+DELAY,1);     % vector for ouput signal y(n) & input to W1z
    v_W2z       = zeros(M2+DELAY,1);     % vector for probe input to W2      
    P_en        = 1;         % initialize power estimate for e(n)
    P_gn        = 1;         % initialize power estimate for g(n)
    Nsh1        = 1;         % Used in adaptive algorithm for W1(z)
    Nsh2        = 1;         % Used in adaptive algorithm for W2(z)
    yGz         = 0;         % initial output of feedforward path
    vprobe      = 0;         % initiall value for prob signal
    OPT_SOL     = [];        % Ooptimal solution empty

    for n = 1:len
        yn(n)       = yGz;          % loudspeaker output signal
        vn(n)       = vprobe;       % update probe signal input to W2z
        y_Gz        = [ yn(n); y_Gz( 1 : M1+DELAY-1 ) ];
        v_W2z       = [vn(n); v_W2z(1 : M2+DELAY-1)];
        y1n(n)      = Fd_z' * y_Gz(1:DELAY+1);   % output of Apended Block (for y(n))
        v1n(n)      = Fd_z' * v_W2z(1:DELAY+1);   % output of Apended Block (for y(n))
        yn_total (n) = y1n(n) + v1n(n);  % Total output of Hearing Aid
        xn(n)       = Input(n);

        %  Update Overall Adaptive FILTER W1z
        yn_W1z(n)   = W1z' * y_Gz;
        gn(n)       = xn(n) - yn_W1z(n);
        Nsh1        = (lambda_W1z * Nsh1) + ( (1 - lambda_W1z) *((W1z(1:DELAY)'*W1z(1:DELAY))*(y_Gz(1:DELAY)'*y_Gz(1:DELAY))/DELAY));
        P_gn        = (lambda_W1z * P_gn ) + ( (1 - lambda_W1z) * ( gn(n)^2 ));
        Pn_gn(n)    = P_gn;
        mun_W1z(n)  = Nsh1 / ( P_gn + alpha_W1z);
        if mun_W1z(n) <= muw1_min
            mun_W1z(n) = muw1_min;
        end
        if isempty(OPT_SOL)
            W1z = W1z + ( ( mun_W1z(n) * gn(n) ) / (  (y_Gz' * y_Gz) + alpha_W1z ) ) * (y_Gz) ;
        end

        % Update Overall Adaptive FILTER W2z
        en(n)       = gn(n) - ( W2z' * v_W2z);
        Nsh2        = (lambda_W2z * Nsh2) + ( (1 - lambda_W2z) *((W2z(1:DELAY)'*W2z(1:DELAY))*(v_W2z(1:DELAY)'*v_W2z(1:DELAY))/DELAY));
        P_en        = (lambda_W2z * P_en ) + ( (1 - lambda_W2z) * ( en(n)^2 ));
        Pn_en(n)    = P_en;
        mun_W2z(n)  = Nsh2 / ( P_en + alpha_W2z) ;
        if mun_W2z(n) <= muw2_min
            mun_W2z(n) = muw2_min;
        end
        W2z = W2z + (( mun_W2z(n) * en(n)) / (  (v_W2z'*v_W2z) + alpha_W2z ) ) * (v_W2z) ;

        % Modeling Error 
        Fd_z_hat1   = W1z( 1 : DELAY );
        Fd_z_hat2   = W2z( 1 : DELAY );
        Fz_hat1     = W1z( DELAY+1 : DELAY + M1);
        Fz_hat2     = W2z( DELAY+1 : DELAY + M2);
        rho1 (n)    = ( norm(Fd_z_hat1)^2 ) / DELAY;
        rho2 (n)    = ( norm(Fd_z_hat2)^2 ) / DELAY;

        % compute input to the feedforward path G(z)
        un(n)   = en(n);
        u_Gz    = [un(n); u_Gz(1:N-1)];     % update the input of feedforward path
        yGz     = Gz' * u_Gz;   % compute the output of feedforward path

        % probe gain and new probe signal
        probe_gain(n)   = rho2(n)/(rho2(n)+1.5);
        probe_new(n)    = probe_gain(n) * probe(n);
        vprobe          = probe_new(n); % obtaine the probe sample

        %Coefficient transfer logic 
        if isempty(OPT_SOL) %No OPTIMAL Solution Available 
            if rho1 (n) < rho2 (n) && rho2 (n) > Th_T1
                W2z( DELAY+1 : DELAY + M2)   = W1z( DELAY+1 : DELAY + M1) ;
            end
            if rho1 (n) < Th_T1 && rho2(n) < Th_T2
                OPT_SOL =  W1z( DELAY+1 : DELAY + M1);
                %disp(strcat('OPT_SOL Reached at n = ',num2str(n)))
            end
        elseif ~isempty(OPT_SOL) %OPT_SOLUTION is Available 
            NSD(n) =  ( sum((OPT_SOL - W2z( DELAY+1 : DELAY + M2)).^2) / sum(OPT_SOL.^2) );
            if  rho2(n) > Th_T2  &&  NSD(n) > Th_T3  &&   Pn_en(n) > Th_T4
                % Check if NORM is reduced & ERR has increased 
                disp(strcat('PATH CHANGE Detected at n = ',num2str(n)))
                OPT_SOL   = [];     % reset optimal solution
                W1z( 1 : DELAY ) = ones(DELAY,1) ;
                W2z( 1 : DELAY ) = ones(DELAY,1) ;
                W1z( DELAY+1 : DELAY + M1) = zeros (1,M1);
                W2z( DELAY+1 : DELAY + M2) = zeros (1,M1);
            else
                if ( rho1(n) < rho2(n) && rho2(n) > Th_T1 )
                    W2z( DELAY+1 : DELAY + M2)   = W1z( DELAY+1 : DELAY + M1);
                end
                if ( rho2(n) <= rho1(n) && rho2(n) <= Th_T1 )
                    W1z( DELAY+1 : DELAY + M1) =  W2z( DELAY+1 : DELAY + M2);
                end
            end
        end
    end
%     Input_Signal    = signal_audio_clipping(sn,1);
%     Input_Gz        = signal_audio_clipping(un,1);
%     Output_Gz       = signal_audio_clipping(yn,gain_Gz);
    Output_Signal    = SignalAudioClipping(yn_total,gain_Gz);
end