% This file is used for testing each method

%% Spike Detection
tic
allFiles = 'allList.txt';
trainList = 'trainMultiList.txt';  
testList = 'testCleanList.txt';

eer = fun_SpikeDecomposition(allFiles,trainList,testList);
disp(['The EER for Spike Decomposition is ',num2str(eer),'%.']);
toc

%% VGGVox Neural Network
tic
allFiles = 'allList.txt';
trainList = 'trainMultiList.txt';  
testList = 'testCleanList.txt';


[testScores, testLabels, eer] = fun_VggVoxNN(allFiles, ...
    trainList, testList) ;

disp(['The EER for the VGGVox NN method is ',num2str(eer),'%.']);
toc
%When using the feature dictionary that we have provided to you, this
%code should only take about 10 seconds or less to run.  If you want
%to make a new feature dictionary, it will take roughly 30 minutes.