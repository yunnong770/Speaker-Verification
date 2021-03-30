function [truePeaks, truePeakTimes] = DetectSoundPeaks(time,y,fs,peakDistance,displayGraphs)
%--------------------------------------------------------------
%In this section we will define a threshold for spike detection, and
%identify the locations of all valid spikes that exceed the threshold.

%First we need to find the thresholds.  I have chosen to use the
%root-mean-squared method of finding a fixed threshold.  In this
%method, we will find the minimum RMS of the sample, and this will be
%our baseline noise level.  We can then set the threshold well above
%that level.

L = length(y);
rmsValues = zeros(1,L); %Initialize
rmsDetectionWindow = 250; %Our RMS detection window will include the 500 nearest data points

for i = 1:L
    %We want to examine 250 values on either side of each data point,
    %but we have to be careful of indexing issues
    if i <= rmsDetectionWindow 
        window = y(1:(2*rmsDetectionWindow)); %Fix index too low
    elseif i >= (L - rmsDetectionWindow)
        window = y(L - 2*rmsDetectionWindow:L); %Fix index too high
    else
        window = y(i-rmsDetectionWindow:i+rmsDetectionWindow); %All non-extreme cases
    end
    rmsValues(i) = rms(window); %Here we find the rms value of the nearest 500 points
end
%Now that we have all the rms values, we can find the baseline noise,
%which is equal to the lowest rms value.  I have chosen a threshold of
%4 times the noise level, to ensure that no noise is accidentally labelled
%as a peak
RMS = min(rmsValues);
threshold = 4*RMS*ones(1,L);

%Now we can use MATLAB's built-in function to find all the peaks that
%exceed the threshold without being too close to each other.  I chose
%to use a minimum of 40 samples (5ms) to separate peaks.
[truePeaks,truePeakTimes] = findpeaks(y, time', 'MinPeakHeight', threshold(1),'MinPeakDistance', peakDistance);


%Before we continue, I want to eliminate any peaks that occur within
%the first 5ms of the sample, as well as peaks that occur within the
%last 5ms of the sample.  This will eliminate errors with spike
%alignment later, and will only remove a couple peaks from the analysis
j = 0; 
for i = 1:length(truePeaks)
    if (truePeakTimes(i-j) <= 0.005) || (truePeakTimes(i-j) >= (time(end)-0.005))
        truePeaks(i-j) = [];
        truePeakTimes(i-j) = [];
        j = j + 1;
    end
end

%For visualization let's plot the peaks and threshold that we found:
if displayGraphs == true
    figure()
    plot(time,y,'b',time,threshold,'r',time,-threshold,'r'); %Plot threshold
    hold on
    plot(truePeakTimes,y(ceil(truePeakTimes*fs)),'o','Color',[0.75,0.75,0]) %Plot peaks
    str= sprintf('Spike Detection');
    title(str); xlabel('Time (s)'); ylabel('Amplitude'); xlim([time(1) time(end)]) %Axis labels, etc
end

end