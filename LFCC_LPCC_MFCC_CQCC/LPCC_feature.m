%##########################################################################
% LPCC feature
%##########################################################################
clear all;
clc;

%% Setup
allFiles = 'allList.txt';
%trainList = 'trainCleanList.txt';
trainList = 'trainMultiList.txt';
%testList = 'testCleanList.txt';
testList = 'testBabbleList.txt';

tic

%% Extract features
featureDict = containers.Map;
fid = fopen(allFiles);
myData = textscan(fid,'%s');
fclose(fid);
myFiles = myData{1};
for i = 1:length(myFiles)
    [snd,fs] = audioread(myFiles{i});
    try
        a = lpc(snd,12);
        lpc2cc = dsp.LPCToCepstral;
        CC = step(lpc2cc,transpose(a));
        featureDict(myFiles{i}) = CC;
    catch
        disp(["No features for the file ", myFiles{i}]);
    end
    
    if(mod(i,1)==0)
        disp(['Completed ',num2str(i),' of ',num2str(length(myFiles)),' files.']);
    end
end

%% Train the classifier
fid = fopen(trainList,'r');
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
trainLabels = myData{3};
trainFeatures = zeros(length(trainLabels),10);
parfor i = 1:length(trainLabels)
    trainFeatures(i,:) = -abs(featureDict(fileList1{i})-featureDict(fileList2{i}));
end

Mdl = fitcknn(trainFeatures,trainLabels,'NumNeighbors',15000,'Standardize',1);

%% Test the classifier
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
testLabels = myData{3};
testFeatures = zeros(length(testLabels),10);
parfor i = 1:length(testLabels)
    testFeatures(i,:) = -abs(featureDict(fileList1{i})-featureDict(fileList2{i}));
end

[~,prediction,~] = predict(Mdl,testFeatures);
testScores = (prediction(:,2)./(prediction(:,1)+1e-15));
[eer,~] = compute_eer(testScores, testLabels);
disp(['The EER is ',num2str(eer),'%.']);

%%
toc