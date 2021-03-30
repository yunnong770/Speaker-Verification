function [featureDict] = padCoeffs(featureDict, myFiles, max_len_coeffs, num_coeffs)

    num_samples = length(featureDict);
    
    for i = 1:num_samples
        sample_len = length((featureDict(myFiles{i})));
        featureDict(myFiles{i}) = padarray(featureDict(myFiles{i}), max_len_coeffs - sample_len, 0, 'post');
    end

end