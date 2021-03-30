clear all
clc

%% 

allFiles = 'allList.txt';
trainList = 'trainMultiList.txt';
testList = 'testBabbleList.txt';

nCoeffs = 13;   % Feature num of MFCC = nDims + 1
nMixtures = 32;% Mixture num for GMM (must be power of 2)best 32
tvDim = 275;    % Dimensionality of total variability best 300/275

nChannels = 12; % Channel num per each speaker, 12 wav for each speaker
nWorkers = 2;   % Num of workers for parallel computing

%% Extract features
featureDict = containers.Map;
fid = fopen(allFiles);
myData = textscan(fid,'%s');
fclose(fid);
myFiles = myData{1};

% Label speaker ID
speakerData = containers.Map;
for cnt = 1:length(myFiles)
    title = split(myFiles{cnt},'\');
    title = title{3}(1:3);
    try
        speakerData(title) = [speakerData(title), cnt];
    catch
        speakerData(title) = [cnt];
    end
end

nSpeakers = length(keys(speakerData));  % nSpeakers = 50
fprintf('Number of Speakers: %f\n', nSpeakers);

myFiles = convertFormat(myFiles);
%% Extra MFCC feature
mfccsdata = cell(nSpeakers, nChannels);
speakerNameList = keys(speakerData);

% Compute the maximum length of all utterances
max_len = maxLength(myFiles);

% Compute the maximum amplitude of the first recording for rescale
[snd, fs] = audioread(myFiles{1});
snd = wdenoise(snd, 6,'DenoisingMethod', 'Minimax', 'Wavelet',...
'db4', 'ThresholdRule', 'Hard', 'NoiseEstimate', 'LevelDependent');
rescale_factor = max(abs(snd));

for i=1:nSpeakers
    
    % Account for unequal number of recordings for different speakers
    speakerName = char(speakerNameList(i));
    channelList = speakerData(speakerName);
    currNumChannels = length(channelList);
    for j=1:nChannels
        if j<= currNumChannels
            index = channelList(j);
        else
            index = currNumChannels;
        end
         % Load file and perform wavelet denoise
        [snd, fs] = audioread(myFiles{index});
        snd = wdenoise(snd, 6,'DenoisingMethod', 'Minimax', 'Wavelet',...
'db4', 'ThresholdRule', 'Hard', 'NoiseEstimate', 'LevelDependent');
        % Rescale the signal
        curr_max = max(abs(snd));
        snd = snd/(curr_max/rescale_factor);
        % Pad signal to the maximum length of all signals by stitching the
        % beginning to the end of the signal.
        if length(snd)<max_len
            snd_new = [];
            while length(snd_new)<max_len
                snd_new = [snd_new;snd];
            end
            snd=snd_new(1:max_len);
        elseif length(snd)>max_len
            snd = snd(1:max_len);
        end

        [mfccsdata{i, j},~] = mfcc(snd, fs, 'NumCoeffs', nCoeffs); % Extract mfccs
        speakerID(i, j) = i;
    end
    disp(['MFCC for Speaker ', speakerName, ' done']);
end

%% Begin i-vector
rng('default');     % Reset random seeds
% Step 1: Create the ubm model from all the training speaker data
nmix = nMixtures;
final_niter = 10;   % max num of iteration
ds_factor = 1;      % downsampling rate
ubm = gmm_em(mfccsdata(:), nmix, final_niter, ds_factor, nWorkers); % Compute UBM 
disp('ubm done');
save(['nmix',num2str(nmix),'ubm.mat']);    % Save UBM for future use

%% Step 2.1: Calculate the statistics needed for the i-Vector model
stats = cell(nSpeakers, nChannels);
for i=1:nSpeakers
    for j=1:nChannels
        [N, F] = compute_bw_stats(mfccsdata{i, j}, ubm); % Compute Baum-Welch statistics for every utterance
        stats{i, j} = [N; F];
    end
end

%% Step 2.2: Learn the total variability space from all the speaker data
niter = 5;
T = train_tv_space(stats(:), ubm, tvDim, niter, nWorkers); % Train the total variability space
disp('T trained');
save([num2str(nmix),'_tvDim',num2str(tvDim),'_T.mat'], 'T'); % Save total variability space for future use

%% Step 2.3: Compute the i-Vector for each speaker and channel
devIVs = zeros(tvDim, nSpeakers, nChannels);
for i=1:nSpeakers
    for j=1:nChannels
        devIVs(:, i, j) = extract_ivector(stats{i, j}, ubm, T); % Extract i-vector for every utterance of every speaker
    end
end
disp('i-Vector done');

%% Step 3.1: Do LDA on the i-Vector to find the dimensions that matter.
ldaDim = min(tvDim, nSpeakers-1);   % Reduced number of features
devIVbySpeaker = reshape(devIVs, tvDim, nSpeakers * nChannels);
[V, D] = lda(devIVbySpeaker, speakerID(:)); % Train an LDA
finalDevIVs = V(:, 1:ldaDim)' * devIVbySpeaker;
disp('LDA done');

%% Apply speaker model on all files
for cnt = 1:length(myFiles)
    % Load file and perform wavelet denoise
    [snd,fs] = audioread(myFiles{cnt});
    snd = wdenoise(snd, 6,'DenoisingMethod', 'Minimax', 'Wavelet',...
'db4', 'ThresholdRule', 'Hard', 'NoiseEstimate', 'LevelDependent');
    % Rescale the signal
    curr_max = max(abs(snd));
    snd = snd/(curr_max/rescale_factor);
    % Pad signal to the maximum length of all signals by stitching the
    % beginning to the end of the signal.
    if length(snd)<max_len
        snd_new = [];
        while length(snd_new)<max_len
            snd_new = [snd_new;snd];
        end
        snd=snd_new(1:max_len);
    elseif length(snd)>max_len
        snd = snd(1:max_len);
    end

    [coeffs,~] = mfcc(snd,fs); % Extract mfcc features
    currIVs = zeros(tvDim, 1, 1);
    [N, F] = compute_bw_stats(coeffs, ubm); % Compute Baum-Welch statistics
    currIVs(:,1,1) = extract_ivector([N; F], ubm, T); % Compute i-vector
    currIVbySpeaker = reshape(permute(currIVs, [1 3 2]), tvDim, 1); % Reshape for LDA
    finalCurrIVs = V(:, 1:ldaDim)' * currIVbySpeaker; % Perform LDA
    featureDict(myFiles{cnt}) = finalCurrIVs(:); % Store the i-vector in feature dictionary
    
    if(mod(cnt,1)==0)
        disp(['Completed ',num2str(cnt),' of ',num2str(length(myFiles)),' files.']);
    end
end

save('featureDictMFCC_ivector', 'featureDict');


%% Train the classifier
fid = fopen(trainList,'r');
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
trainLabels = myData{3};

% comment to convert directory name when WavData is in the same directory
fileList1 = convertFormat(fileList1);
fileList2 = convertFormat(fileList2);
trainLabels = myData{3};

% Compute difference between the dimension-reduced i-vector between every
% testing cases
trainFeatures = zeros(length(trainLabels), length(featureDict(fileList1{1})));
parfor cnt = 1:length(trainLabels)
    trainFeatures(cnt,:) = abs(featureDict(fileList1{cnt})-featureDict(fileList2{cnt})); % Difference between two dimension-reduced i-vectors
end

% Train a KNN classifier
Mdl = fitcknn(trainFeatures,trainLabels,'NumNeighbors', 4,'Standardize',1, 'Distance', 'cityblock');
disp('classifier finished.');

%% Test the classifier
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
testLabels = myData{3};

% comment to convert directory name when WavData is in the same directory
fileList1 = convertFormat(fileList1);
fileList2 = convertFormat(fileList2);

% Compute difference between the dimension-reduced i-vector between every
% testing case
testFeatures = zeros(length(testLabels), length(featureDict(fileList1{1})));
parfor cnt = 1:length(testLabels)
    testFeatures(cnt,:) = abs(featureDict(fileList1{cnt})-featureDict(fileList2{cnt})); % Difference between two dimension-reduced i-vectors
end

% Predicted result
[~,prediction,~] = predict(Mdl,testFeatures);
prediction = round(prediction(:,2));

% Compute FNR, FPR, EER
[eer,~] = compute_eer(prediction, testLabels);
FPR = sum(~testLabels & prediction)/sum(~testLabels);
FNR = sum(testLabels & ~prediction)/sum(testLabels);
disp(['The false positive rate is ',num2str(FPR*100),'%.'])
disp(['The false negative rate is ',num2str(FNR*100),'%.'])
disp(['The EER is ',num2str(eer),'%.']);
