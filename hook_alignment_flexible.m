%input = unpack_ims(uigetdir); %create a cell array, storing into it the images (as matrices) from the masked channels stored in imaris files. Each row represents a fly. First entry is its tray ID, second entry is gal4 and date run, third entry is image for left side, fourth entry is image for right side
%input = aligned_neurons_complete;
%aligned_neurons = cell(size(input)); %preallocate a new cell array to store aligned images, of the same size as the input cell array
for fly = 92:size(aligned_neurons) %for each fly (row in the input)
    if isempty(input{fly,3}) || isempty(input{fly,4}) %check if there is an image for both sides
        continue %continue if not
    end
    disp(fly)
    moving = input{fly,3}; %load the data for the left neuron into a variable
    fixed = input{fly,4}; %load the data for the right neuron into a variable
    %Note: left will be transformed onto right
    
    mov_dims = size(moving); %store the image dimensions to contruct the new image after transformation
    mov_intensity = reshape(moving(logical(moving)),[],1); %store the intensity values in a 1d matrix
    fix_dims = size(fixed); %store the image dimensions to contruct the new image after transformation
    fix_intensity = reshape(fixed(logical(fixed)),[],1); %store the intensity values in a 1d matrix
    
    dims = [650, 200, 200]; %this line hard codes the output, aligned image dimensions (above dimensions are not used). This was giving me problems, but this could be adjusted to be more flexible
    
    mov_coords = im2coords(moving); %pull out coordinates of where pixels exist in the masked images
    fix_coords = im2coords(fixed);
    
    mov_coords = pc_align(mov_coords); %align both images, now in coordinate space, onto their principal components. 
    fix_coords = pc_align(fix_coords);
    %Note, this alignment function centers the data at [100,100,50].
    
%     tic %start a timer, because this is the time consuming part
%     mov_reg_coords = register_pc(mov_coords, fix_coords); %register the left neuron onto the right neuron in coordinate space (using point cloud ICP algorithm.
%     toc

    moving_new = coords2im(mov_coords,dims, mov_intensity); %recreate an image in pixel space by filling transformed coordinates with corresponding intensity values from original image
    fixed_new = coords2im(fix_coords,dims, fix_intensity);

    aligned_neurons{fly,1} = input{fly,1}; %store all the new information in the output cell
    aligned_neurons{fly,2} = input{fly,2};
    aligned_neurons{fly,3} = moving_new;
    aligned_neurons{fly,4} = fixed_new;

end

brightness =10; %set a brightness multiplier and display the pair of neurons, max projected along the 3rd dimension.
maxproj_imshowpair(moving_new,fixed_new,brightness)