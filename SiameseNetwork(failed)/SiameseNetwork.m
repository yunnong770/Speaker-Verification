%##############################################################
% This is a sample script for evaluating the classifier quality
% of your system.
%##############################################################

clear all;
clc;

%% Define lists
allFiles = 'allList.txt';
trainList = 'trainCleanList.txt';
testList = 'testCleanList.txt';

tic

%% Load files
featureDict = containers.Map;
fid = fopen(allFiles);
myData = textscan(fid,'%s');
fclose(fid);
myFiles = myData{1};
num_coeffs = 17;
num_poles = 12;

%% Process file names for MATLAB online
% myFiles = convertFormat(myFiles);
% max_len = maxLength(myFiles);


%% Extract features
for(i = 1:length(myFiles))
    [snd,fs] = audioread(myFiles{i});
    snd = padarray(snd, max_len - length(snd), 0, 'post');
    [coeffs,delta,deltaDelta,loc] = mfcc(snd,fs, "NumCoeffs", num_coeffs);
    featureDict(myFiles{i}) = coeffs;
    if(mod(i,10)==0)
        disp(['Completed ',num2str(i),' of ',num2str(length(myFiles)),' files.']);
    end
end

max_len_coeffs = length(coeffs);

%% Preprocessing data
fid = fopen(trainList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
labels = myData{3};

%% Process file names for MATLAB online
fileList1 = convertFormat(fileList1);
fileList2 = convertFormat(fileList2);

%% Define Layers
num_features = num_coeffs + 1;
numHiddenUnits1 = 64;
numHiddenUnits2 = 32;

layers = [
    imageInputLayer([max_len_coeffs (num_coeffs+1) 1],'Name','input1','Normalization','none')
    convolution2dLayer(4,64,'Name','conv1','WeightsInitializer','narrow-normal','BiasInitializer','narrow-normal')
    reluLayer('Name','relu1')
    batchNormalizationLayer('Name', 'batchnorm1')
    maxPooling2dLayer(2,'Stride',2,'Name','maxpool1')
    convolution2dLayer(2,128,'Name','conv2','WeightsInitializer','narrow-normal','BiasInitializer','narrow-normal')
    reluLayer('Name','relu2')
    batchNormalizationLayer('Name', 'batchnorm2')
    maxPooling2dLayer(2,'Stride',2,'Name','maxpool2')
    convolution2dLayer(2,256,'Name','conv3','WeightsInitializer','narrow-normal','BiasInitializer','narrow-normal')
    fullyConnectedLayer(4096,'Name','fc1','WeightsInitializer','narrow-normal','BiasInitializer','narrow-normal')];

lgraph = layerGraph(layers);
dlnet = dlnetwork(lgraph);

fcWeights = dlarray(0.01*randn(1,4096));
fcBias = dlarray(0.01*randn(1,1));

fcParams = struct(...
    "FcWeights",fcWeights,...
    "FcBias",fcBias);

%% Specify training options
numIterations = 500;
miniBatchSize = 180;

learningRate = 1e-5;
trailingAvgSubnet = [];
trailingAvgSqSubnet = [];
trailingAvgParams = [];
trailingAvgSqParams = [];
gradDecay = 0.9;
gradDecaySq = 0.99;

executionEnvironment = "auto";

plots = "training-progress";

plotRatio = 16/9;

if plots == "training-progress"
    trainingPlot = figure;
    trainingPlot.Position(3) = plotRatio*trainingPlot.Position(4);
    trainingPlot.Visible = 'on';
    
    trainingPlotAxes = gca;
    
    lineLossTrain = animatedline(trainingPlotAxes);
    xlabel(trainingPlotAxes,"Iteration")
    ylabel(trainingPlotAxes,"Loss")
    title(trainingPlotAxes,"Loss During Training")
end


%% Train the model
% Load testing data
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
labels = myData{3};
testing_size = length(fileList1);
fileList1 = convertFormat(fileList1);
fileList2 = convertFormat(fileList2);

[X1_test,X2_test,pairLabels_test] = getTestingData(featureDict, fileList1, fileList2, labels, num_coeffs, max_len_coeffs, testing_size);
dlX1_test = dlarray(single(X1_test),'SSCB');
dlX2_test = dlarray(single(X2_test),'SSCB');

% If using a GPU, then convert data to gpuArray.
if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
   dlX1_test = gpuArray(dlX1_test);
   dlX2_test = gpuArray(dlX2_test);
end

% Load balance training data
fid = fopen(trainList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
labels = myData{3};
fileList1 = convertFormat(fileList1);
fileList2 = convertFormat(fileList2);
[X1_train,X2_train,pairLabels_train] = getBalanceData(featureDict, fileList1, fileList2, labels, num_coeffs, max_len_coeffs);

%% Loop over mini-batches.
for iteration = 1:numIterations
    
    % Extract mini-batch of image pairs and pair labels
    [X1, X2, pairLabels] = getBalanceBatch(X1_train, X2_train, pairLabels_train, miniBatchSize);

    % Convert mini-batch of data to dlarray. Specify the dimension labels
    % 'SSCB' (spatial, spatial, channel, batch) for image data
    dlX1 = dlarray(single(X1),'SSCB');
    dlX2 = dlarray(single(X2),'SSCB');
    
    % If training on a GPU, then convert data to gpuArray.
    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
        dlX1 = gpuArray(dlX1);
        dlX2 = gpuArray(dlX2);
    end  
    
    % Evaluate the model gradients and the generator state using
    % dlfeval and the modelGradients function listed at the end of the
    % example.
    [gradientsSubnet, gradientsParams,loss] = dlfeval(@modelGradients,dlnet,fcParams,dlX1,dlX2,pairLabels);
    lossValue = double(gather(extractdata(loss)));
    
    % Update the Siamese subnetwork parameters.
    [dlnet,trailingAvgSubnet,trailingAvgSqSubnet] = ...
        adamupdate(dlnet,gradientsSubnet, ...
        trailingAvgSubnet,trailingAvgSqSubnet,iteration,learningRate,gradDecay,gradDecaySq);
    
    % Update the fullyconnect parameters.
    [fcParams,trailingAvgParams,trailingAvgSqParams] = ...
        adamupdate(fcParams,gradientsParams, ...
        trailingAvgParams,trailingAvgSqParams,iteration,learningRate,gradDecay,gradDecaySq);
      
    % Update the training loss progress plot.
    if plots == "training-progress"
        addpoints(lineLossTrain,iteration,lossValue);
    end
    drawnow;
    
    dlX1_test = dlarray(single(X1_test),'SSCB');
    dlX2_test = dlarray(single(X2_test),'SSCB');
    
    % If using a GPU, then convert data to gpuArray.
    if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
       dlX1_test = gpuArray(dlX1_test);
       dlX2_test = gpuArray(dlX2_test);
    end
    
% Training FP and FN    
    dlY = predictSiamese(dlnet,fcParams,dlX1,dlX2);
     
    Y = gather(extractdata(dlY));
    Y = double(round(Y));
    
    train_C = confusionmat(pairLabels, Y);
    
    train_FP = train_C(1,2)/sum(train_C(1,:));
    train_FN = train_C(2,1)/sum(train_C(2,:));
    
% Testing FP and FN 
    dlY = predictSiamese(dlnet,fcParams,dlX1_test,dlX2_test);
     
    Y = gather(extractdata(dlY));
    Y = double(round(Y));
    
    test_C = confusionmat(pairLabels_test, Y);
    
    test_FP = test_C(1,2)/sum(test_C(1,:));
    test_FN = test_C(2,1)/sum(test_C(2,:));
    
% Print out FP and FN result
    fprintf('Training: FP = %f, FN = %f ', train_FP, train_FN);
    fprintf('Testing: FP = %f, FN = %f', test_FP, test_FN);
    
end

%% Test the classifier
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
labels = myData{3};
testing_size = length(fileList1);
fileList1 = convertFormat(fileList1);
fileList2 = convertFormat(fileList2);

[X1_test,X2_test,pairLabels_test] = getTestingData(featureDict, fileList1, fileList2, labels, num_coeffs, max_len_coeffs, testing_size);

dlX1_test = dlarray(single(X1_test),'SSCB');
dlX2_test = dlarray(single(X2_test),'SSCB');

% If using a GPU, then convert data to gpuArray.
if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
   dlX1_test = gpuArray(dlX1_test);
   dlX2_test = gpuArray(dlX2_test);
end

dlY = predictSiamese(dlnet,fcParams,dlX1_test,dlX2_test);
 
Y = gather(extractdata(dlY));
Y = round(Y);
accuracy = sum(Y == pairLabels)/200