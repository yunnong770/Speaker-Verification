function [] = AnalyzeSoundSpikes(time,y,k,truePeakTimes,truePeakLocs,pcaClusterIndices,colors)
%--------------------------------------------------------------
%In this section, we will  return to the graph of the original speech 
%signal and label each spike in accordance to its cluster identity

%First we set things up for the analyzed PCA graph:
figure(); hold on
str = sprintf('PCA Conclusion');
title(str); xlabel('Time (s)'); ylabel('Amplitude'); xlim([0,time(end)])

plot(time,y) %Plot the original filtered signal
%And now we can overlay the peak details
for i = 1:k
   thisClusterIdx = (pcaClusterIndices == i); %Select a cluster
   scatter(truePeakTimes(thisClusterIdx),y(truePeakLocs(thisClusterIdx)),36,colors(i,:)) %Plot all values of selected cluster
end


end