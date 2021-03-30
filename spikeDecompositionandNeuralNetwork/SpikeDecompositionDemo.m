%% Housekeeping and Disclaimer
%This code is for VISUALIZATION ONLY!!  This is NOT the final code.  Read
%through and run this code if you are interested in learning how the
%algorithm works.  For the real code, see fun_SpikeDecomposition

%To properly understand this code's function, run one section at a time!

clear; close all; clc;

% Define lists
allFiles = 'allList.txt';
trainList = 'trainCleanList.txt';
testList = 'testCleanList.txt';

%Select Files
fid = fopen(allFiles);
myData = textscan(fid,'%s');
fclose(fid);
myFiles = myData{1};

%% Demo: Setup
%--------------------------------------------------------------
%Initialize basic fixtures of the protocol
colors = [0,0,1;1,0,0;0,1,0;0.75,0.75,0;0,0.75,0.75;0.25,0.25,0.25;0.75,0,0.75;0.85,0.325,0.098;0.635,0.078,0.184;0.466,0.674,0.188];
k = 7; %Determines the number of detectable clusters (phonemes)
dimensionality = 3; %Determines how many eigenvectors we want to use during PCA analysis
peakDistance = 0.0055; %Determines how long each "sound spike" will be
%--------------------------------------------------------------

%In the following code, we will analyze just the first sound file in the
%data.  In reality, we will do this for every file.
[snd,fs] = audioread(myFiles{1});
L = length(snd);
t = linspace(0,L/fs,L); %Initialize important base variables
%% Detect Peaks
[peaks, peakTimes] = DetectSoundPeaks(t',snd,fs,peakDistance,true); %Find and display all the "sound spikes" in the sample
%The output graph of this code displays all the detected "sound spikes"
%from the original speech signal

%% Align Spikes
[peakLocs, signalMatrix, nearSamples] = AlignSoundSpikes(t',snd,fs,peaks,peakTimes,peakDistance,true); %Align all sound spikes into a single matrix
%The output graph of this code displays all the previously detected spikes
%aligned together (overlapping).  The purpose of this is to create a
%matrix with dimensionality equal to the number of data points in each
%spike.  We will reduce the dimensionality of that matrix next (so we can
%visualize the data)

%% Dimensionality Reduction
normalizedSignalMatrix = NormalizeSignalMatrices(signalMatrix); %Normalize data (this prevents speaker volume from playing a major role in analysis)
[~,featureEigenvectors] = SoundEigenvictorExtraction(normalizedSignalMatrix,dimensionality,true); %Perform PCA on all sound spikes to find the feature eigenvectors
%The output of this graph shows each spike again, except instead of
%appearing as a physical waveform, the spikes have been analyzed and
%reduced to a single point in a 3-dimensional space, where they can
%be easily compared with other spikes.  Spikes can be considered to be
%significantly different from each other when their corresponding data
%points in this 3-D space are far away from each other.
%--------------------------------------------------------------
%If this process goes perfectly, PCA should separate the sound spikes into
%distinct clusters based on their shape.  Each cluster in the resulting
%PCA output should represent a different phoneme spoken in the sentence.
%Of course, the process will not be perfect--each speaker will have their
%sounds clustered in a slightly different location--meaning that each
%cluster only represents an "average" phoneme location.  The algorithm will
%tell the difference between the speakers by determining the euclidean
%distance between my phoneme clusters and yours.
%--------------------------------------------------------------

%% Clustering
completePCA = ((featureEigenvectors.') * (normalizedSignalMatrix.'))'; %Project the speaker's spikes onto the PCA space
[pcaClusters, pcaClusterIndices,centroids] = ClusterSoundSpikes(completePCA, k, colors, true); %Find the location of each of the speaker's phonemes in PCA space
%The output of this graph is exactly the same as the output of the
%previous graph (of dimensionality reduction), with one key difference:
%we have identified the clusters of spikes.  As mentioned before, each
%cluster should represent a distinct phoneme in the sentence, and the
%variability in how a phoneme is spoken should account for the variability
%in the spikes that make up each cluster.  The centroid of each cluster
%will be calculated for each speaker, and the distance between centroids
%will determine how "similar" the speech is.  This is the score that will
%be optimized to produce the fewest number of false positives/negatives

%% Analysis
AnalyzeSoundSpikes(t,snd,k,peakTimes,peakLocs,pcaClusterIndices,colors)
%We can return to the original signal, and identify which spikes belong
%to which clusters.  This can give us information about whether or not
%we are detecting the correct number of phonemes per sentence.  If
%something seems wrong, we can adjust the basic parameters of the
%algorithm.

