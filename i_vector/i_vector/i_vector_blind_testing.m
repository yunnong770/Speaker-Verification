clear all
clc

%% Load trained data
% Load
load('nmix32ubm.mat') % Load UBM
load('32_tvDim275_T.mat') % Load total variability space
load('Mdl.mat') % Load pre-trained KNN classifier
load('stats.mat') % Load Baum-Welch statistics from the background speakers
load('devIVs.mat') % Load i-vectors from background speakers for LDA

%% HyperParameters

allFiles = 'allList.txt';
testList = 'testCleanList.txt'; %% Specify file that contains unknown testing pairs

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

nSpeakers = length(keys(speakerData));  
fprintf('Number of Speakers: %f\n', nSpeakers);



% Uncomment to convert directory name when WavData is not in the same directory
% myFiles = convertFormat(myFiles); 

%% Do LDA on the i-Vector to find the dimensions that matter.
ldaDim = min(tvDim, nSpeakers-1);   % =final feature number
devIVbySpeaker = reshape(devIVs, tvDim, nSpeakers * nChannels);
[V, D] = lda(devIVbySpeaker, speakerID(:));
finalDevIVs = V(:, 1:ldaDim)' * devIVbySpeaker;
disp('LDA done');

%% Extract features
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
testLabels = myData{3};

featureDict = zeros(49, 2, length(testLabels));
disp(['Extracting features for the test file in the first column'])
for cnt = 1:length(fileList1)
    % Load file and perform wavelet denoise
    temp = fileList1(cnt);
    [snd,fs] = audioread(temp{1});
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
    featureDict(:, 1, cnt) = finalCurrIVs(:); % Store the i-vector in feature dictionary
    
    if(mod(cnt,1)==0)
        disp(['Completed ',num2str(cnt),' of ',num2str(length(fileList1)),' files.']);
    end
end

disp(['Extracting features for the test file in the second column'])
for cnt = 1:length(fileList1)
    % Load file and perform wavelet denoise
    temp = fileList2(cnt);
    [snd,fs] = audioread(temp{1});
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
    featureDict(:, 2, cnt) = finalCurrIVs(:); % Store the i-vector in feature dictionary
    
    if(mod(cnt,1)==0)
        disp(['Completed ',num2str(cnt),' of ',num2str(length(fileList2)),' files.']);
    end
end

%% %% Test the classifier
% Uncomment to convert directory name when WavData is not in the same directory
% fileList1 = convertFormat(fileList1);
% fileList2 = convertFormat(fileList2);

% Compute difference between the dimension-reduced i-vector between every
% testing cases
testFeatures = zeros(length(testLabels), 49);
parfor cnt = 1:length(testLabels)
    testFeatures(cnt,:) = abs(featureDict(:,1,cnt)-featureDict(:,2,cnt)); % Difference between two dimension-reduced i-vectors
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
