%% Hook histogram
load('output_complete.mat')

data = output_complete{:,4:6};
figure
num_flies = size(output_complete,1);
num_flies = 4
for i = 1:num_flies
    %take just the hooks for each fly
    if isempty(output_complete{i,5}) || isempty(output_complete{i,6}) %only if both exist, if either is empty then just move on to next fly so as not to throw an error
        continue %skip if there's an empty cell
    end
    try
        hook_L = output_complete{i,5}(output_complete{i,5}(:,1) > -100,:);
        hook_R = output_complete{i,6}(output_complete{i,6}(:,1) > -100,:);
        %realign these hooks on their PCs
        %left hood first
        hook_L = hook_L-mean(hook_L,1); %mean subtract
        cov_mat = (hook_L'*hook_L)/size(hook_L,1);
        [V,D] = eig(cov_mat);
        [~,order] = sort(diag(-D)); %give the order from most variance to least (ordering PCs in order of importance)
        V = V(:,order); %reorder the PCs in the eigenbassi so that first dimension is first PC, etc.
        aligned_L = hook_L*V;
        %right hook next
        hook_R = hook_R-mean(hook_R,1); %mean subtract
        cov_mat = (hook_R'*hook_R)/size(hook_R,1);
        [V,D] = eig(cov_mat);
        [~,order] = sort(diag(-D)); %give the order from most variance to least (ordering PCs in order of importance)
        V = V(:,order); %reorder the PCs in the eigenbassi so that first dimension is first PC, etc.
        aligned_R = hook_R*V;
        subplot(ceil(sqrt(num_flies)), ceil(sqrt(num_flies)), i)
        
        s1 = scatter(aligned_L(:,1),aligned_L(:,2),'g','.')
        hold on
        s2 = scatter(aligned_R(:,1),aligned_R(:,2),'m','.')
        hold off
        set([s1,s2],'MarkerEdgeAlpha',0.1)
         
         yTicks = get(gca,'YTick');
         bin = diff(yTicks(1:2))
         xTicks = get(gca,'XTick');
         xTicks = xTicks(1):bin:xTicks(end);
         xTicks(2:2:end) = [];
        set(gca,'PlotBoxAspectRatio',[2,1,1],...
            'XTick',xTicks,...
            'YTick',yTicks(1):bin:yTicks(end),'XTickLabelRotation',45,...
            'XTickLabel',xTicks)
       
        

    end
end
    