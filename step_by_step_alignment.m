%% load the data
input_fly = aligned_neurons_complete; %create a cell array, storing into it the images (as matrices) from the masked channels stored in imaris files. Each row represents a fly. First entry is its tray ID, second entry is gal4 and date run, third entry is image for left side, fourth entry is image for right side
%aligned_neurons = cell(size(input_fly)); %preallocate a new cell array to store aligned images, of the same size as the input cell array
for fly = 1:size(input_fly,1) %for each fly (row in the input)
    if isempty(input_fly{fly,3}) || isempty(input_fly{fly,4}) %check if there is an image for both sides
        continue %continue if not
    end
    disp(fly)
%% load images into variables to transform
    moving = input_fly{fly,3}; %load the data for the left neuron into a variable
    fixed = input_fly{fly,4}; %load the data for the right neuron into a variable
    %Note: left will be transformed onto right
    
    mov_dims = size(moving); %store the image dimensions to contruct the new image after transformation
    mov_intensity = reshape(moving(logical(moving)),[],1); %store the intensity values in a 1d matrix
    fix_dims = size(fixed); %store the image dimensions to contruct the new image after transformation
    fix_intensity = reshape(fixed(logical(fixed)),[],1); %store the intensity values in a 1d matrix
   
%% pull out coordinates of where pixels exist in the masked images   
    mov_coords = im2coords(moving); %pull out coordinates of where pixels exist in the masked images
    fix_coords = im2coords(fixed);
%% align coordinates onto principal components  
    mu = [0,0,0];
    mov_coords = pc_align(mov_coords, mu); %align both images, now in coordinate space, onto their principal components. optional param is mu, which will make min of the data on the coordinates given in a 1x3 array
    fix_coords = pc_align(fix_coords,mu);
    %Note: if mu is not passed, pc_align will align the coordinates and
    %recenter them on their original means
    
    %show these
    pcshowpair(pointCloud(mov_coords),pointCloud(fix_coords))
    shg
    
    %ask user if needs rotation to avoid local
    if input('rotate?: \n')
        mov_coords = mov_coords*[-1,0,0;0,1,0;0,0,-1];
        mov_coords = mov_coords - min(mov_coords) + mu; %center the flipped data on the mu described above
        %show these
        pcshowpair(pointCloud(mov_coords),pointCloud(fix_coords))
        shg
    end
    
    
%% pull out just the tails
    fac = 3;
    pieces = 2;
    flipped = input('flipped? If fat part at 0 then 0:\n'); %0 if fat part at 0, 1 if fat part at long end
    [mov_tail_coords,mov_tail_intensity] = extract_hooks(mov_coords, flipped,mov_intensity,1, fac,pieces);
    [fix_tail_coords,fix_tail_intensity] = extract_hooks(fix_coords, flipped,fix_intensity,1,fac,pieces);
    pcshowpair(pointCloud(mov_tail_coords),pointCloud(fix_tail_coords));
    shg
%     mov_tail_coords = mov_coords(mov_coords(:,1)<max(mov_coords(:,1))/1.5,:,:);
%     fix_tail_coords = fix_coords(fix_coords(:,1)<max(fix_coords(:,1))/1.5,:,:);
%     mov_tail_intensity = mov_intensity(mov_coords(:,1)<max(mov_coords(:,1))/1.5);
%     fix_tail_intensity = fix_intensity(fix_coords(:,1)<max(fix_coords(:,1))/1.5);
    
    
%% register the moving neuron onto the fixed neuron
    tic %start a timer, because this is the time consuming part
    mov_tail_reg_coords = register_pc(mov_tail_coords, fix_tail_coords); %register the left neuron onto the right neuron in coordinate space (using point cloud ICP algorithm.
    toc
    %transform them both equally
    trans = min([min(mov_tail_reg_coords);min(fix_tail_coords)]);
    mov_tail_reg_coords = mov_tail_reg_coords - trans + 1;
    fix_tail_coords = fix_tail_coords - trans + 1;
    pcshowpair(pointCloud(mov_tail_reg_coords),pointCloud(fix_tail_coords));
    shg
    
%% extract hooks from coords and prep them for image by translating both equally
    fac = 2; %cut tail into 2 pieces
    pieces = 1; %take only one half, that is the hook
    [mov_reg_hook_coords,mov_hook_intensity] = extract_hooks(mov_tail_reg_coords,flipped,mov_tail_intensity, 1, fac,pieces);
    [fix_hook_coords,fix_hook_intensity] = extract_hooks(fix_tail_coords,flipped,fix_tail_intensity, 1, fac,pieces);
    trans = min([min(mov_reg_hook_coords);min(fix_hook_coords)]);
    mov_reg_hook_coords = mov_reg_hook_coords - trans + 1;
    fix_hook_coords = fix_hook_coords - trans + 1;
%% Fill a new image with previously stored intensities and newly transformed coordinates
    dims = max(ceil([range(mov_reg_hook_coords);range(fix_hook_coords)]));
    moving_new = coords2im(mov_reg_hook_coords,dims, mov_hook_intensity); %recreate an image in pixel space by filling transformed coordinates with corresponding intensity values from original image
    fixed_new = coords2im(fix_hook_coords,dims, fix_hook_intensity);
    if flipped
        moving_new = flip(moving_new,1);
        fixed_new = flip(fixed_new,1);
    end
%% store the new information in the output cell array
    aligned_neurons_trimmed{fly,1} = input_fly{fly,1}; %store all the new information in the output cell
    aligned_neurons_trimmed{fly,2} = input_fly{fly,2};
    aligned_neurons_trimmed{fly,3} = moving_new;
    aligned_neurons_trimmed{fly,4} = fixed_new;

%end
%% show aligned images
brightness =10; %set a brightness multiplier and display the pair of neurons, max projected along the 3rd dimension.
maxproj_imshowpair(moving_new,fixed_new,brightness)
shg
end