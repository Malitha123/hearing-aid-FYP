function Plot = PLOT (input,Fs,Name,i)
% track=zeros(length(input),1);
% track(1600:3500)=track(1600:3500)+1;
subplot (3,1,i);
% time=(1:length(input))/Fs;  % Time vector on x-axis 
plot(input);   %hold; plot(track/2);
xlabel('Time(s)');
ylabel('Amplitude'); 
title(Name)

end