function plot_aligned_colorized(aligned, x_vect, outs)
%this takes as input the matrix of aligned coordinates for a neuron
%(transformed onto its major axis), a vector of x-coordinates, and an N by
%2 matrix with x index in the first column and corresponding correlation
%coefficient of that x-index to LDM in the second column.

caxis([min(corrs) max(corrs)]); %scale the colormap to the corrs vector
%c = colormap(jet(numel(sects)));

figure
hold on
for i = 1:numel(sects) %we will go through each bin along x and plot the existing data points with the appropriate color
    temp = ceil(aligned(:,1)) == x_vect(i); %create a temporary logical which tells us which points in the aligned matrix belong to a given slice in x
    scatter3(aligned(temp,1),aligned(temp,2),aligned(temp,3),'.', 'CData', repmat(corrs(i),length(x_vect(temp)),1))
end
axis image
 view(3)
end