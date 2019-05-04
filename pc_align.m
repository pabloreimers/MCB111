function aligned = pc_align(coord_mat, mu)
        if ~exist('mu', 'var')
            mu = mean(coord_mat,1);
        end
        
        A = coord_mat; 
        A = A-mean(A,1); %mean subtract
        cov_mat = (A'*A)/size(A,1); %find the covariance matrix
        [V,D] = eig(cov_mat); %identify vectors capturing max variance (eignevectors of covariance matrix) with their associated vairance captured (eigenvalues)
        [~,order] = sort(diag(-D)); %give the order from most variance to least (ordering PCs in order of importance)
        V = V(:,order); %reorder the PCs in the eigenbassi so that first dimension is first PC, etc.
        aligned = A*V; %project data onto these Principal Axes
        
        %recenter the data not at 0 but at 100, 100, 50. Could probably
        %code this more efficiently (take input from user of where to
        %center data)
        aligned = aligned - min(aligned) + mu;
        
%         aligned(:,1) = aligned(:,1) - min(aligned(:,1)) + 100; %this seems rather inefficient but I was getting an issue by trying to do them all at once
%         aligned(:,2) = aligned(:,2) - min(aligned(:,2)) + 100;
%         aligned(:,3) = aligned(:,3) - min(aligned(:,3)) + 50;
end