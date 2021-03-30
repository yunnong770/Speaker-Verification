function [X1_batch, X2_batch, pairLabels_batch] = getBalanceBatch(X1, X2, pairLabels, miniBatchSize)

    rand_idx_similar = randperm(length(X1)/2, miniBatchSize/2)*2-1;
    rand_idx_dissimilar = randperm(length(X2)/2, miniBatchSize/2)*2;
    
    X1_batch_p = X1(:,:,:,rand_idx_similar);
    X2_batch_p = X2(:,:,:,rand_idx_similar);
    pairLabels_batch_p = pairLabels(rand_idx_similar);
    X1_batch_n = X1(:,:,:,rand_idx_dissimilar);
    X2_batch_n = X2(:,:,:,rand_idx_dissimilar);
    pairLabels_batch_n = pairLabels(rand_idx_dissimilar);
    
    X1_batch = cat(4,X1_batch_p,X1_batch_n);
    X2_batch = cat(4,X2_batch_p,X2_batch_n);
    
    pairLabels_batch = cat(2, pairLabels_batch_p, pairLabels_batch_n);
end