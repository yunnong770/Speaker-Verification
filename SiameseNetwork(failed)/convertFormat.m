function myFiles = convertFormat(myFiles)

    for i = 1:length(myFiles)
       myFiles{i} = strrep(myFiles{i}, '\', '/'); 
       myFiles{i} = strrep(myFiles{i}, 'WavData', '/MATLAB Drive/WavData');
    end

end