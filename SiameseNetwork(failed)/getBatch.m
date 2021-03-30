function [X1,X2,pairLabels] = getBatch(featureDict, list1, list2, labels, num_coeffs, max_len_coeffs, miniBatchSize)

    X1 = zeros(max_len_coeffs, num_coeffs + 1, 1, miniBatchSize);
    X2 = zeros(max_len_coeffs, num_coeffs + 1, 1, miniBatchSize);
    pairLabels = zeros(1,miniBatchSize);
    
    for i = 1:miniBatchSize
            choice = rand(1);
            if choice < 0.5
                [pairIdx1,pairIdx2,pairLabels(i)] = getSimilarPair(list1, list2, labels);
            else
                [pairIdx1,pairIdx2,pairLabels(i)] = getDissimilarPair(list1, list2, labels);
            end
            
            X1(:,:,:,i) = featureDict(pairIdx1);
            X2(:,:,:,i) = featureDict(pairIdx2);
    end
end