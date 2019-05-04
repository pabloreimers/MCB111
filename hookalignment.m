%% load output file with neuron images
foldername = uigetdir;
filename = dir(strcat(foldername, '\*.ims'));
vol = zeros(1,length(filename));

%create a vector to match an image to its appropriate row
temp_vect = zeros(length(filename),1);
for i = 1:length(filename)
    num = filename(i).name;
    temp = strfind(num, '.');
    num = num(1:temp-2);
    temp_vect(i) = str2num(num);
     % temp_vect(i) = sscanf(filename(i).name, '%d');
end
temp_vect = unique(temp_vect);
match_vect = cat(2, [1:length(temp_vect)]', temp_vect); %second col gives the filename, first column gives the row it should go to

output = cell(length(match_vect),4); %all lengths will be stored into this cell array. Col 1 is Left, Col 2 is Right, Col 3 is ID, 4 is date, and 5 and 6 is the aligned coordinate matrix (later named aligned) (5 is left 6 is right), 7 is voxel Volume in um^3
    
for k = 1:length(filename)
    
clearvars -except foldername filename output k vol match_vect
data = bfopen(strcat(foldername,'\',filename(k).name));
%find index for beginning of image of interest
series = 1; % Series has something to do with how compressed the images are (series 1 is 512x512 pixels to series 2 is 256x256 to 128x128). Use series 1
omeMeta = data{series, 4}; % store the metadata for an image

% %this is old code for getting the start of the masked channel.
% for i = 1:size(data{series,1},1) 
% temp = data{series,1}{i,1};
% imagesc(temp)
% pause(0.05)
%  if mode(mean(temp)) == 0 %there's always a blank slate before the masked channel that got rid of all noise, so just index after it. Make sure that imagesc stops at the blank screen
%      break
%  end
% end
% % idx = i+1;

temp_idxs = find(data{series,1}{1,2}=='/')+1; %store the information for the image. first entry is total number of planes, second is how many planes per channel, third is how many channels
total_slices=str2num(data{series,1}{1,2}(temp_idxs(1):temp_idxs(1)+3));
if contains(data{series,1}{1,2}, 'C=')
    slices_per_channel = str2num(data{series,1}{1,2}(temp_idxs(2):temp_idxs(2)+3));
else
    slices_per_channel = str2num(data{series,1}{1,2}(temp_idxs(2):end));
end

%and store the image in a brand new matrix, taking only the last channel
%because that is always the most recently masked channelv (most eroded)
neuron = cat(3,data{series,1}{(total_slices-slices_per_channel+1):end,1});
%neuron = imresize3(neuron, 0.5);

%store identifying information
temp = strfind(filename(k).name,'.');
num = filename(k).name;
num = str2double(num(1:temp-2));
left = contains(filename(k).name,'L'); %find out which column to store into in the output cell array
row = match_vect(match_vect(:,2) == num,1);
output{row,1} = sscanf(filename(k).name, '%d');
idx = strfind(foldername,'\');
date_imaged = foldername(idx(end)+1:end);
output{row,2} = date_imaged;

%Store both neurons in their appropriate bin. Flip the orientation of the x
%axis only in the left to adjust for chirality
if left
    neuron = flip(neuron, 1); %this flips along the x dimension, I believe (maybe the y)
    output{row,3} = neuron;
else
    output{row,4} = neuron;
end
end



%% Image Registration on Point Clouds. Returns registered point clouds and transformation matrices for coordinate space
%initialize an empty cell array to store into
hooks = {};
for pair = 1:size(output, 1)
    if ~isempty(output{pair,3}) || ~isempty(output{pair,4}) 
        moving = output{pair,3}; %store the left image to be algined to the right
        fixed = output{pair,4}; %store the right image
        mov_dims = size(moving); %store the image dimensions to contruct the new image after transformation
        mov_intensity = reshape(moving(logical(moving)),[],1); %store the intensity values in a 1d matrix
        fix_dims = size(fixed); %store the image dimensions to contruct the new image after transformation
        fix_intensity = reshape(fixed(logical(fixed)),[],1); %store the intensity values in a 1d matrix
        moving_log = logical(moving); %turn the neuron into a logical to turn from pixel space into coordinate space
        [x_mov, y_mov, z_mov] = ind2sub(size(moving_log),find(moving_log)); %find the coordinates of each existing datapoint
        fixed_log = logical(fixed); %turn the neuron into a logical to turn from pixel space into coordinate space
        [x_fix, y_fix, z_fix] = ind2sub(size(fixed_log),find(fixed_log)); %find the coordinates of each existing datapoint

        mov_coords = cat(2,x_mov,y_mov,z_mov); %create a 3 dimensional matrix with coordinates in x y and z axis as columns respectively
        fix_coords = cat(2,x_fix,y_fix,z_fix);

        %rotate the fixed point cloud onto it's PCs to make it easier to zoom in on
        %hooks later
        A = fix_coords; 
        A = A-mean(A,1); %mean subtract
        cov_mat = (A'*A)/size(A,1);
        [V,D] = eig(cov_mat);
        [~,order] = sort(diag(-D)); %give the order from most variance to least (ordering PCs in order of importance)
        V = V(:,order); %reorder the PCs in the eigenbassi so that first dimension is first PC, etc.
        aligned = A*V;
        aligned = aligned-min(aligned)+1;

        %repopulate imaeg for fixed, now on PCs
        fix_aligned = zeros(fix_dims, 'uint8'); %initialize a new image for the transformed values
        for pixel = 1:size(fix_intensity,1)
            fix_aligned(round(aligned(pixel,1)), round(aligned(pixel,2)), round(aligned(pixel,3))+3) = fix_intensity(pixel); %store in the appropriate pixel coordinates (transformed) the original intensity value
        end

        %make this a pointcloud object to align them
        fix_pt = pointCloud(aligned); %turn these coordinate matrices into point cloud matrices. for moving neuron, make a point cloud for completely flipped neurons (avoid local minima with lengthwise alignment in wrong orientation)

        %note, this uses pcregrigid. Use pcregistericp if using matlab 2018a or
        %later
        mov_inv_pt = pointCloud(mov_coords*[-1 0 0;0 -1 0; 0 0 1]); %flip the neuron to avoid a local minima where they're aligned in reverse
        [tform_inv,mov_reg_inv_pt,rmse_inv] = pcregrigid(mov_inv_pt,fix_pt,'Extrapolate',true, 'MaxIterations', 100);
        mov_pt = pointCloud(mov_coords); %flip the neuron to avoid a local minima where they're aligned in reverse
        [tform,mov_reg_pt,rmse] = pcregrigid(mov_pt,fix_pt,'Extrapolate',true, 'MaxIterations', 100);

        if rmse > rmse_inv %dif the inverse gave a better estimation, that's the global max (not the local case where we align on length but flipped orientation. restore values
            tform = tform_inv; %store all inv values as the desired output variable name
            mov_pt = mov_inv_pt;
            rmse = rmse_inv;
            mov_reg_pt = mov_reg_inv_pt;
        end
        mov_reg_coords = mov_reg_pt.Location(); %store the new coordinates of the transformed image
        mov_reg_coords = mov_reg_coords - min(mov_reg_coords) + 1;

        mov_reg = zeros(mov_dims, 'uint8'); %initialize a new image for the transformed values
        for pixel = 1:size(mov_intensity,1)
            mov_reg(round(mov_reg_coords(pixel,1)), round(mov_reg_coords(pixel,2)), round(mov_reg_coords(pixel,3))+3) = mov_intensity(pixel); %store in the appropriate pixel coordinates (transformed) the original intensity value
        end
        %zoom in on hooks
        last_x = round(max(aligned(:,1)))+30;
        if last_x > 512
            last_x = 512;
        end
        first_x = last_x - 80;
        last_y = round(max(aligned(:,2)))+30;
        if last_y >  512
            last_y = 512;
        end
        first_y = last_y - 80;
        
        hooks{pair,1} = output{pair,1};
        hooks{pair,2} = output{pair,2};
        hooks{pair,3} = mov_reg([first_x:last_x],[first_y:last_y],:);
        hooks{pair,4} = fix_aligned([first_x:last_x],[first_y:last_y],:);
    end
end

%% show the hook image pairs
%register the original moving image
%mov_reg = imwarp(moving, tform);
%and show this transformation in a new figure
subplot(2,2,1)
imshowpair(30*max(moving, [], 3), max(30*fixed, [], 3), 'Scaling', 'joint')
title('original Left and Right')
subplot(2,2,2)
imshowpair(30*max(moving, [], 3), 30*max(mov_reg, [], 3), 'Scaling', 'joint')
title('Original left and moved left')
subplot(2,2,3)
imshowpair(30*max(mov_reg, [], 3), 30*max(fix_aligned, [], 3), 'Scaling', 'joint')
title('Overlapped left and right, on right PCs')
subplot(2,2,4)
pcshowpair(mov_reg_pt, fix_pt)
title('aligned point clouds')
shg
%% zoom in on hooks
%hook last
last_x = round(max(aligned(:,1)))+30;
first_x = last_x - 80;
last_y = round(max(aligned(:,2)))+30;
first_y = last_y - 80;
figure
imshowpair(30*max(mov_reg([first_x:last_x],[first_y:last_y],:), [], 3), 30*max(fix_aligned([first_x:last_x],[first_y:last_y],:), [], 3), 'Scaling', 'joint')


%% Old code
% [optimizer, metric] = imregconfig('monomodal');
% optimizer.GradientMagnitudeTolerance = 1e-4;
% optimizer.MinimumStepLength = 1e-5;
% optimizerMaximumStepLength = 6.25e-2/3.5;
% optimizer.MaximumIterations = 300;
% optimizer.RelaxationFactor = 5e-1;

%Multimodal parameter values
% [optimizer, metric] = imregconfig('multimodal');
% optimizer.InitialRadius = 0.009/3.5;
% optimizer.Epsilon = 1.5e-4;
% optimizer.GrowthFactor = 1.01;
% optimizer.MaximumIterations = 300;

 moving_reg = imregister(moving, fixed, 'rigid', optimizer, metric);

figure
subplot(2,2,1)
imshowpair(30*max(moving, [], 3), max(30*fixed, [], 3), 'Scaling', 'joint')
title('original Left and Right')
subplot(2,2,2)
imshowpair(30*max(moving, [], 3), 30*max(moving_reg, [], 3), 'Scaling', 'joint')
title('Original left and moved left')
subplot(2,2,3)
imshowpair(30*max(moving_reg, [], 3), 30*max(fixed, [], 3), 'Scaling', 'joint')
title('Overlapped left and right')
shg

%% overlap the images (old)
moving = output{1,3};
fixed = output{1,4};
[optimizer, metric] = imregconfig('monomodal');
optimizer.GradientMagnitudeTolerance = 1e-4;
optimizer.MinimumStepLength = 1e-5;
optimizerMaximumStepLength = 6.25e-2/3.5;
optimizer.MaximumIterations = 300;
optimizer.RelaxationFactor = 5e-1;

%Multimodal parameter values
% optimizer.InitialRadius = 0.009/3.5;
% optimizer.Epsilon = 1.5e-4;
% optimizer.GrowthFactor = 1.01;
% optimizer.MaximumIterations = 300;

 moving_reg = imregister(moving, fixed, 'rigid', optimizer, metric);

figure
subplot(2,2,1)
imshowpair(30*max(moving, [], 3), max(30*fixed, [], 3), 'Scaling', 'joint')
title('original Left and Right')
subplot(2,2,2)
imshowpair(30*max(moving, [], 3), 30*max(moving_reg, [], 3), 'Scaling', 'joint')
title('Original left and moved left')
subplot(2,2,3)
imshowpair(30*max(moving_reg, [], 3), 30*max(fixed, [], 3), 'Scaling', 'joint')
title('Overlapped left and right')
shg


