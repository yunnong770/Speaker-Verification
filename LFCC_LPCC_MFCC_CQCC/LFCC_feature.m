%##########################################################################
% LFCC feature
%##########################################################################
clear all;
clc;

%% Setup
allFiles = 'allList.txt';
%trainList = 'trainCleanList.txt';
trainList = 'trainMultiList.txt';
%testList = 'testCleanList.txt';
testList = 'testBabbleList.txt';

use_pca = 0;
pca_latent_knob = 0.99999;

num_coeffs = 113;
use_delta = 0;
use_delta_delta = 0;

tic

%% Extract features
featureDict = containers.Map;
fid = fopen(allFiles);
myData = textscan(fid,'%s');
fclose(fid);
myFiles = myData{1};
for i = 1:length(myFiles)
    [snd,fs] = audioread(myFiles{i});
    Window_Length = 20;
    NFFT = 512;
    No_Filter = num_coeffs;
    try
        [stat,delta,double_delta] = extract_lfcc(snd,fs,Window_Length,NFFT,No_Filter); 
        if use_delta_delta == 1
            featureDict(myFiles{i}) = mean([stat,delta,double_delta]', 2);
        elseif use_delta == 1
            featureDict(myFiles{i}) = mean([stat,delta]', 2);
        else 
            featureDict(myFiles{i}) = mean(stat', 2);
        end
    catch
        disp(["No features for the file ", myFiles{i}]);
    end
    
    if(mod(i,1)==0)
        disp(['Completed ',num2str(i),' of ',num2str(length(myFiles)),' files.']);
    end
end

%% PCA
old_dim = size(featureDict(myFiles{i}), 1);
new_dim = old_dim;
if use_pca
    fid = fopen(allFiles,'r');
    myData = textscan(fid,'%s');
    fclose(fid);
    fileList = myData{1};
    wholeFeatures = zeros(length(fileList), old_dim);

    for i = 1:length(fileList)
        wholeFeatures(i,:) = featureDict(fileList{i});
    end

    [coeff,score,latent] = pca(wholeFeatures);
    new_dim = sum(cumsum(latent)./sum(latent) < pca_latent_knob)+1;
    trans_mat = coeff(:,1:new_dim);

    % apply dimension reduction
    for i = 1:length(myFiles)
        featureDict(myFiles{i}) = transpose(featureDict(myFiles{i}))*trans_mat;
    end
end

%% Train the classifier
fid = fopen(trainList,'r');
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
trainLabels = myData{3};
trainFeatures = zeros(length(trainLabels), new_dim);
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
testFeatures = zeros(length(testLabels), new_dim);
parfor i = 1:length(testLabels)
    testFeatures(i,:) = -abs(featureDict(fileList1{i})-featureDict(fileList2{i}));
end

[~,prediction,~] = predict(Mdl,testFeatures);
testScores = (prediction(:,2)./(prediction(:,1)+1e-15));
[eer,~] = compute_eer(testScores, testLabels);
disp(['The EER is ',num2str(eer),'%.']);

%%
toc