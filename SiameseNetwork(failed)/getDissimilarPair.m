function [idx1,idx2,pairLabels] = getDissimilarPair(list1, list2, labels)
    
    r = find(labels == 0);
    rand_idx_labels = randi([1, length(r)]);
    idx1 = list1{r(rand_idx_labels)};
    idx2 = list2{r(rand_idx_labels)};
    pairLabels = 0;
    
end