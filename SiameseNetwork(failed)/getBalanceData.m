function [X1,X2,pairLabels] = getBalanceData(featureDict, list1, list2, labels, num_coeffs, max_len_coeffs)
    
    idx_similar = find(labels == 1);
    idx_dissimilar = find(labels == 0);
    rand_idx_dissimilar = randperm(length(idx_dissimilar), length(idx_similar));
    
    X1 = zeros(max_len_coeffs, num_coeffs + 1, 1, length(idx_similar)*2);
    X2 = zeros(max_len_coeffs, num_coeffs + 1, 1, length(idx_similar)*2);
    pairLabels = zeros(1,length(idx_similar)*2);
    
    for i = 1:length(idx_similar)
            X1(:,:,:,i*2-1) = featureDict(list1{idx_similar(i)});
            X2(:,:,:,i*2-1) = featureDict(list2{idx_similar(i)});
            pairLabels(i*2-1) = 1;
            X1(:,:,:,i*2) = featureDict(list1{rand_idx_dissimilar(i)});
            X2(:,:,:,i*2) = featureDict(list2{rand_idx_dissimilar(i)});
            pairLabels(i*2) = 0;
    end
end