function [truePeakLocs, signalMatrix, nearSamples] = AlignSoundSpikes(time,y,fs,truePeaks,truePeakTimes,peakDistance,displayGraphs)
%--------------------------------------------------------------
%In this section we will plot all the detected spikes onto the same
%graph, with the peak of each spike aligned in the center.

%I have already comitted to using a waveform size of 5ms, so we can
%define the window size of the waveform as follows:
nearSamples = ((peakDistance/2)*fs);

%Now we know how many samples each waveform needs to contain.  In the
%case where fs = 8000 and peakDistance = 5ms, 'nearSamples' will be 20, 
%meaning that we will use 20 data points on either side of the peak,
%resulting in a total of 41 data points in the waveform

%Now let's start thinking about plotting the waveforms:
if displayGraphs == true
    figure()
    hold on
end

%First we need to set up a few variables.  'j' will help us index the
%variable called 'signalMatrix', which will hold information for all 41
%data points in each waveform (41 was calcaulated above).  Additionally,
%'truePeakLocs' will hold information about the index of each peak.
j = 1; 
signalMatrix = zeros(length(truePeaks),(nearSamples*2 + 1));
truePeakLocs = zeros(1,length(truePeaks));

%The following loop fills out the variables described above
for i = 1:length(truePeaks)
   truePeakLocs(i) = find(time == truePeakTimes(i)); %Find the location (index) of each peak
   index = truePeakLocs(i);
   thisWaveform = y(index-(nearSamples):index+(nearSamples)); %The wave is made of the peak plus the next 5ms of data points
   signalMatrix(j,:) = thisWaveform; %Store the waveform (41 data points) into the matrix
   
   %We can also plot the waveforms while we fill out the signal matrix
    if displayGraphs == true
        plot(thisWaveform, 'b')
    end
    j = j + 1;
end

if displayGraphs == true
    str= sprintf('Aligned Spikes');
    title(str); xlabel('Samples'); ylabel('Amplitude'); xlim([1,(nearSamples*2+1)]); %Axis labels, etc.
end

end