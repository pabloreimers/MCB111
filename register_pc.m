function mov_reg_coords = register_pc(mov_coords, fix_coords)
    fix_pt = pointCloud(fix_coords); %turn these coordinate matrices into point cloud matrices. for moving neuron, make a point cloud for completely flipped neurons (avoid local minima with lengthwise alignment in wrong orientation)
    mov_pt = pointCloud(mov_coords); %flip the neuron to avoid a local minima where they're aligned in reverse
        
    %[~,mov_reg_pt,rmse] = pcregistericp(mov_pt,fix_pt,'Extrapolate',true, 'MaxIterations', 20);
    [~,mov_reg_pt,~] = pcregistericp(mov_pt,fix_pt,'Extrapolate',true, 'MaxIterations', 20);
    mov_reg_coords = mov_reg_pt.Location(); %store the new coordinates of the transformed imag
    
%     %check the flipped case to avoid local minima but not global minima
%     mov_inv_pt = pointCloud(mov_reg_coords*[-1 0 0;0 -1 0;0 0 1]);
%     [~,mov_reg_inv_pt,rmse_inv] = pcregrigid(mov_inv_pt,fix_pt,'Extrapolate',true, 'MaxIterations', 20);
%     
%     if rmse > rmse_inv %if the inverse gave a better estimation, that's the global max (not the local case where we align on length but flipped orientation. restore values
%             mov_reg_coords = mov_reg_inv_pt.Location(); %store the new coordinates of the transformed imag
    end
    
    
   
    