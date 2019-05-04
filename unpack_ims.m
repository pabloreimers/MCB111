function output = unpack_ims(foldername)

%this function takes in a folder name and unpacks every imaris file in that
%folder by storing it in a cell array. Rows of the cell array correspond to
%one fly. 1st column is index in the tray, 2nd column is the folder name
%(gal4 line and date run), 3rd column is the image matrix for the left
%neuron, 4th column is the image matrix for the right side. Stores as
%uint8s. 


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

%store identifying information
temp = strfind(filename(k).name,'.');
num = filename(k).name;
num = str2double(num(1:temp-2));
left = contains(filename(k).name,'L'); %find out which column to store into in the output cell array by setting a flag boolean as left
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