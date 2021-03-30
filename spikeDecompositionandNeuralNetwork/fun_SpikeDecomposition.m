function [eer] = fun_SpikeDecomposition(allFiles,trainList,testList)

%Select Files
fid = fopen(allFiles);
myData = textscan(fid,'%s');
fclose(fid);
myFiles = myData{1};

%--------------------------------------------------------------
%% Extract Features
%--------------------------------------------------------------
%Initialize basic fixtures of the protocol
colors = [0,0,1;1,0,0;0,1,0;0.75,0.75,0;0,0.75,0.75;0.25,0.25,0.25;0.75,0,0.75;0.85,0.325,0.098;0.635,0.078,0.184;0.466,0.674,0.188];
k = 7; %Determines the number of detectable clusters (phonemes)
dimensionality = 20; %Determines how many eigenvectors we want to use during PCA analysis
peakDistance = 0.0055; %Determines how long each "sound spike" will be
%--------------------------------------------------------------
%Prepare to analyze all the files
myAnalyzedSounds = cell(length(myFiles),2);
%--------------------------------------------------------------
%Collect all sound data in order to find the feature eigenvectors
for i = 1:length(myAnalyzedSounds)
    [snd,fs] = audioread(myFiles{i});
     L = length(snd);
     t = linspace(0,L/fs,L); %Initialize important base variables
    [peaks, peakTimes] = DetectSoundPeaks(t',snd,fs,peakDistance,false); %Find all the "sound spikes" in each sample
    [peakLocs, signalMatrix, nearSamples] = AlignSoundSpikes(t',snd,fs,peaks,peakTimes,peakDistance,false); %Align all sound spikes into a single matrix
    normalizedSignalMatrix = NormalizeSignalMatrices(signalMatrix); %Normalize data (this prevents speaker volume from playing a major role in analysis)
    myAnalyzedSounds{i,1} = normalizedSignalMatrix; %Store matrix data for later
end
completeSignalMatrix = cat(1,myAnalyzedSounds{:}); %Combine ALL speaker data into a single matrix
[~,featureEigenvectors] = SoundEigenvictorExtraction(completeSignalMatrix,dimensionality,false); %Perform PCA on all sound spikes to find the feature eigenvectors
%If this process goes perfectly, PCA should separate the sound spikes into
%distinct clusters based on their shape.  Each cluster in the resulting
%PCA output should represent a different phoneme spoken in the sentence.
%Of course, the process will not be perfect--each speaker will have their
%sounds clustered in a slightly different location--meaning that each
%cluster only represents an "average" phoneme location.  The algorithm will
%tell the difference between the speakers by determining the euclidean
%distance between my phoneme clusters and yours.
%--------------------------------------------------------------
%Use the eigenvectors to extract cluster centroids from each audio file
featureDict = containers.Map;
for i = 1:length(myAnalyzedSounds)
   normalizedSignalMatrix = myAnalyzedSounds{i,1}; %reopen each speaker's sound spike matrix
   completePCA = ((featureEigenvectors.') * (normalizedSignalMatrix.'))'; %Project the speaker's spikes onto the PCA space
   [pcaClusters, pcaClusterIndices,centroids] = ClusterSoundSpikes(completePCA, k, colors, false); %Find the location of each of the speaker's phonemes in PCA space
   myAnalyzedSounds{i,2} = centroids; %Record the cluster centroids (aka phoneme locations) for future analysis
   featureDict(myFiles{i}) = centroids;
end

%--------------------------------------------------------------
%% Train the classifier
%--------------------------------------------------------------
fid = fopen(trainList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
labels = myData{3};
scores = zeros(length(labels),1);
for i = 1:length(labels)
    c1 = featureDict(fileList1{i});
    c2 = featureDict(fileList2{i});
    euc = zeros(k,1);
        for m = 1:k
            a = c1(m,:);
            b = c2(m,:);
            euc(m) = sqrt(sum((a-b).^2));
        end       
    scores(i) = -1*(min(euc)*median(euc)*prod(euc)/max(euc));
end
scores = normalize(scores);
[~,threshold] = compute_eer(scores,labels);

%--------------------------------------------------------------
%% Test the classifier
%--------------------------------------------------------------
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
labels = myData{3};
scores = zeros(length(labels),1);
for i = 1:length(labels)
    c1 = featureDict(fileList1{i});
    c2 = featureDict(fileList2{i});
    euc = zeros(k,1);
        for m = 1:k
            a = c1(m,:);
            b = c2(m,:);
            euc(m) = sqrt(sum((a-b).^2));
        end
    scores(i) = -1*(min(euc)*median(euc)*prod(euc)/max(euc));
end
scores = normalize(scores);
prediction = (scores>threshold);
FPR = sum(~labels & prediction)/sum(~labels);
FNR = sum(labels & ~prediction)/sum(labels);
% disp(['The false positive rate is ',num2str(FPR*100),'%.'])
% disp(['The false negative rate is ',num2str(FNR*100),'%.'])
[eer,~] = compute_eer(scores, labels);

end