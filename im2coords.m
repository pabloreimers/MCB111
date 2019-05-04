function coord_mat = im2coords(image)
%this function pulls out the coordinates of where pixels exist from an
%image composed of a masked channel, where only some pixels have an
%intensity value
     image_log = logical(image); %turn the neuron into a logical to turn from pixel space into coordinate space
     [x, y, z] = ind2sub(size(image_log),find(image_log)); %find the coordinates of each existing datapoint
     coord_mat = cat(2,x,y,z);
end
    