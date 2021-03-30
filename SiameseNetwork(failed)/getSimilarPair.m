function [idx1,idx2,pairLabels] = getSimilarPair(list1, list2, labels)
    
    r = find(labels == 1);
    rand_idx_labels = randi([1, length(r)]);
    idx1 = list1{r(rand_idx_labels)};
    idx2 = list2{r(rand_idx_labels)};
    pairLabels = 1;
    
end