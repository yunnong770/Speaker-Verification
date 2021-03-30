function [pcaClusters, pcaClusterIndices,centroids] = ClusterSoundSpikes(completePCA, k, colors, displayGraphs)
%--------------------------------------------------------------
%In this section we will identify the number of clusters present in
%the PCA graphs, and identify which spikes belong to which cluster.

%The first step in determining which spikes correspond to which
%clusters is figuring out how many clusters there are in total.  My
%chosen clustering method will be 'k-means' clustering, but k-means
%doesn't have a built-in method of determining the number of clusters.

%The number of clusters in the data must be equal to the number of
%distinct, observable phonemes in the chosen sentence.  I am not fully
%confident in what that number will be because many phonemes will not
%be easily identified by the algorithm if they are short in time or low
%amplitude.  For now, we will consider the value of k to be around six
%or seven, because this is the number of distinct vowels in the phrase.
%The true number may be closer to eight or nine if we include semivowels.


[~,centroids] = kmeans(completePCA,k,'Replicates',60); %Find Centroids
centroids = sortrows(centroids); %sort centroids for consistency (very important)
[pcaClusterIndices,centroids] = kmeans(completePCA,k,'start',centroids); %Assign waveforms to centroids
pcaClusters = zeros(length(completePCA),k*3); %Initialize a matrix to hold all the PCA data separated by cluster

%Now we can start graphing the PCA clusters
if displayGraphs == true
    figure(); hold on
    %In the following loop I make sure that I only select one cluster at a
    %time, and then plot that cluster on the graph with whatever the next
    %color is in the color sequence.
    for i = 1:3:k*3
        thisClusterIdx = (pcaClusterIndices == ceil(i/3)); %select one cluster at a time
        pcaClusters(:,i:i+2) = (completePCA .* (horzcat(thisClusterIdx,thisClusterIdx,thisClusterIdx))); %Identify all points in this cluster
        scatter3(pcaClusters(:,i),pcaClusters(:,i+1),pcaClusters(:,i+2),36,colors(ceil(i/3),:)) %Graph the cluster
    end
    %Add all the graphing essentials:
    str = sprintf('Clustered PCA Analysis');
    title(str); xlabel('PC1'); ylabel('PC2'); zlabel('PC3')
end

end