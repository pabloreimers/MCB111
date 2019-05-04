%% concatenate alignment data
a = load('aligned_neurons_1_10.mat');
b = load('aligned_neurons_2_23.mat');
d = load('aligned_neurons_5_1.mat');
e = load('aligned_neurons_5_29_Box1.mat');
f = load('aligned_neurons_5_29_Box2.mat');
g = load('aligned_neurons_6_15_Box1_2pm.mat');
h = load('aligned_neurons_6_15_Box1_11am.mat');
i = load('aligned_neurons_6_15_Box2_2pm.mat');
j = load('aligned_neurons_6_15_Box2_11am.mat');
k = load('aligned_neurons_7_12.mat');
l = load('aligned_neurons_7_15_Box1.mat');
m = load('aligned_neurons_7_15_Box2.mat');
n = load('aligned_neurons_10_25.mat');
o = load('aligned_neurons_8_28.mat');
l = load('aligned_neurons_9_21.mat');

aligned_neurons_complete = cat(1, a.aligned_neurons, b.aligned_neurons, d.aligned_neurons, e.aligned_neurons, f.aligned_neurons, g.aligned_neurons, h.aligned_neurons, i.aligned_neurons, j.aligned_neurons, k.aligned_neurons, l.aligned_neurons, m.aligned_neurons, n.aligned_neurons, o.aligned_neurons, l.aligned_neurons);
clearvars -except aligned_neurons_complete
%% plot correlation of matlab and imaris volumes
new_mat = zeros(size(output_complete,1), 2);
match_vect = zeros(1,size(output_complete,1));

for i = 1:size(output_complete, 1)
    if output_complete{i,3}
        new_mat(i,1) = sum(output_complete{i,1});
        new_mat(i,2) = sum(output_complete{i,2});
    end
    %match_vect(i,1) = strcat(output_complete{i,4}, '_', num2str(id));
end

