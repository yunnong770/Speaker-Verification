function[testScores, testLabels, eer] =  fun_VggVoxNN(allFiles, ...
    trainList, testList) 

%Load pre-trained feature dictionary, if available
featureName = 'featureVGGVox_x1.mat';
ok = exist(featureName, 'file');
if ok
    load(featureName, "featureDict", "myFiles", "cnt");
    
%--------------------------------------------------------------
%% Extract Features
%--------------------------------------------------------------
%If training has not yet been performed, we need to extract features

else
    featureDict = containers.Map;
    fid = fopen(allFiles); %Open files and prepare for analysis
    myData = textscan(fid,'%s');
    fclose(fid);
    myFiles = myData{1};
    for cnt = 1:length(myFiles)
        [snd, fs] = audioread(myFiles{cnt}); %Read file data
        try
            feat = vcc_vox_net(snd); %Call the NN feature extraction function
            featureDict(myFiles{cnt}) = feat;
        catch
            disp(["No features for the file ", myFiles{cnt}]);
        end

        if(mod(cnt,100)==0)
            disp(['Completed ',num2str(cnt),' of ',num2str(length(myFiles)),' files.']);
        end
    end
    save('featureVGGVox_x1'); %Save features to avoid long training in the future
end
new_dim = size(featureDict(myFiles{cnt}), 1);

%--------------------------------------------------------------
%% Train the classifier
%--------------------------------------------------------------
%Open files for training
fid = fopen(trainList,'r');
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
trainLabels = myData{3};
trainFeatures = zeros(length(trainLabels), new_dim); %Initialize
%Compute scores for each pair of files
parfor cnt = 1:length(trainLabels)
    trainFeatures(cnt,:) = -abs(featureDict(fileList1{cnt})-featureDict(fileList2{cnt}));
end
Mdl = fitcknn(trainFeatures,trainLabels,'NumNeighbors',15000,'Standardize',1);

%--------------------------------------------------------------
%% Test the classifier
%--------------------------------------------------------------
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
testLabels = myData{3};
testFeatures = zeros(length(testLabels), new_dim);
parfor cnt = 1:length(testLabels)
    testFeatures(cnt,:) = -abs(featureDict(fileList1{cnt})-featureDict(fileList2{cnt}));
end

[~,prediction,~] = predict(Mdl,testFeatures);
testScores = (prediction(:,2)./(prediction(:,1)+1e-15));
[eer,~] = compute_eer(testScores, testLabels);
disp(['The EER is ',num2str(eer),'%.']);


