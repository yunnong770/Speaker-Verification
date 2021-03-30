function [maximumLength] = maxLength(myFiles)

    maximumLength = 0;
    for i = 1:length(myFiles)
        [snd,~] = audioread(myFiles{i});
        if length(snd) > maximumLength
            maximumLength = length(snd);
        end
    end

end