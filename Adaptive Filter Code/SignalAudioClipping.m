% Function to pre-clip the data and prepare for audiorecorder
% x = input data
% threshold = clipping level
% y = output data
% @Akhtar, 31-05-2018

function [y] = SignalAudioClipping(x,threshold)
x ( x > threshold )   =  threshold; 
x ( x < -threshold )  = -threshold;
y = x;
end