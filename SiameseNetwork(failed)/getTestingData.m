function [X1,X2,pairLabels] = getTestingData(featureDict, list1, list2, labels, num_coeffs, max_len_coeffs, testing_size)

    X1 = zeros(max_len_coeffs, num_coeffs + 1, 1, testing_size);
    X2 = zeros(max_len_coeffs, num_coeffs + 1, 1, testing_size);
    pairLabels = labels;
    
    for i = 1:testing_size
            X1(:,:,:,i) = featureDict(list1{i});
            X2(:,:,:,i) = featureDict(list2{i});
    end
end