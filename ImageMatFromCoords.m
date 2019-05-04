

%First, determine the size of the matrix necessary by finding the range in
%x, y, and z
xdim = max(x) - min(x);
ydim = max(y) - min(y);
zdim = max(z) - min(z);

size_mat = [xdim, ydim, zdim];

%Then, put the origin as the corner of the image so that the index that is
%output corresponds directly to coordinates of matrix
x = x + min(x);
y = y + min(y);
z = z + min(z);

%Now, you should be able to give each data point a linear index in this
%matrix
lin_idxs = sub2ind(size_mat, x, y, z);

%Make the image a logical, such that wherever a datapoint existed you have
%a logical yes in the matrix

