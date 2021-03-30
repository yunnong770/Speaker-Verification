function [normalizedMatrix] = NormalizeSignalMatrices(signalMatrix)
%--------------------------------------------------------------
%The first step towards dimensionality reduction involves standardizing
%the data (making sure each data point of each waveform is represented
%as a z-score instead of an amplitude) because we don't want to give
%unfair attention to the high-amplitude points on the signal. This is
%especially important for PCA because PCA is based on covariance.

normalizedMatrix = zeros(size(signalMatrix,1), size(signalMatrix,2)); %initialize
for i = 1:size(signalMatrix,2)
    m = mean(signalMatrix(:,i)); %find the mean of each variable
    s = std(signalMatrix(:,i)); %find the standard deviation of each variable
    normalizedMatrix(:,i) = (signalMatrix(:,i)-m)/s; %Get the z-score based on 'm' and 's'
end
end