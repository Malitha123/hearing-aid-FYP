% *************************************************************************
% Small helper function to process audio - mono conversion, DC removal, etc
% *************************************************************************
function in = ProcessAudio(clean_speech,processed_speech)

% % Mono-fy, remove DC, normalize
% Sum = sum(inp);
% Len = length(inp);
% Mean = Sum/Len;
% Max = max(abs(inp));
% % % inp = inp - Mean;
% inp = inp/Max;
% in = 0.999*inp;

clean_speech     = clean_speech - mean(clean_speech);
processed_speech = processed_speech - mean(processed_speech);

in = processed_speech.*(max(abs(clean_speech))/ max(abs(processed_speech)));
end
