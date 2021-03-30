function myFiles = convertFormat(myFiles)

    for i = 1:length(myFiles)
       myFiles{i} = strrep(myFiles{i}, '\', '/');
       myFiles{i} = strrep(myFiles{i}, 'WavData', 'D:\Winter 2021\M214\Project\EE214A_Project_2021\EE214A_Project_2021\WavData');
    end

end