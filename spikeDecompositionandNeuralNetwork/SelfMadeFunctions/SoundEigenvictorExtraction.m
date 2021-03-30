function [completePCA,featureEigenvectors] = SoundEigenvictorExtraction(standardizedMatrix,dimensionality,displayGraphs)
%--------------------------------------------------------------
%In this section we will reduce the dimensionality of the signal matrix
%to fewer dimensions. Before this process, the dimensionality of the data is
%over 40, so it will be very difficult to analyze--and certainly difficult
%to visualize!

%We can simply use MATLAB's built-in PCA function
[coeff,score,latent] = pca(standardizedMatrix);

%To get the final PCA result, which I call 'completePCA', we
%multiply the original dataset by the feature vectors (top few PCs)
%Visualizing the data only works if the number of chosen vectors is
%3 or less.  But if we don't need to look at the data we can choose a
%value larger than 3 (in this case that value is stored in the variable
%called "dimensionality").
featureEigenvectors = coeff(:,1:dimensionality);
completePCA = ((featureEigenvectors.') * (standardizedMatrix.'))';

%And now let's plot the graph in 3D, if we can
if (displayGraphs == true) && (dimensionality ==3)
    figure();
    scatter3(completePCA(:,1),completePCA(:,2),completePCA(:,3));
    str = sprintf('PCA Analysis');
    title(str); xlabel('PC1'); ylabel('PC2'); zlabel('PC3') %Axis labels, etc.
end

end