function [hook, intensity] = extract_hooks(coord_mat,flipped,intensity, dim, fac, pieces)
%expects fat part to be at 0, if not then flipped =1
    tmp = round(max(coord_mat(:,dim))/fac);
    if flipped
        tmp = tmp*pieces;
        hook = coord_mat(coord_mat(:,dim)<tmp,:,:);
        intensity = intensity(coord_mat(:,dim)<tmp);
    else
        tmp = (fac-pieces)*tmp;
        hook = coord_mat(coord_mat(:,dim)>tmp,:,:);
        intensity = intensity(coord_mat(:,dim)>tmp,:,:);
    end