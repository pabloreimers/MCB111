function image = coords2im(coords_mat, dims, intensities)
%this function creates an image from a matrix defining coordinates for
%pixels, when given dimensions of the new image. The function populates
%this blank image with pixel intensities defined by an input vector, such
%that the ith intensity is stored at the location given by the ith row of
%the coordinate matrix
        image = zeros(dims, 'uint8'); %initialize a new image for the transformed values
        for pixel = 1:size(intensities,1)
            image(round(coords_mat(pixel,1)), round(coords_mat(pixel,2)), round(coords_mat(pixel,3))) = intensities(pixel); %store in the appropriate pixel coordinates (transformed) the original intensity value
        end