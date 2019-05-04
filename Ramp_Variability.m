%% Load the data
clear
load(uigetfile()); % select mat file with flyTracks output from autotracker
rturns = flyTracks.rightTurns; %store variables with easily accessible names
tstamps = flyTracks.tStamps;
tseq = flyTracks.tSeq;

%% Create (i,j) matrix with entries giivng turn direction for jth fly at frame i
turns = nan(size(rturns));

for j = 1:size(turns, 2)
    idx = ~isnan(rturns(:,j)); %find index of all turns stored by frame
    idx(find(idx,1)) = 0; %get rid of the first entry, because it is not a turn just a location
    turns(idx,j) = tseq(~isnan(tseq(:,j)),j); %store all turns into their appropriate frame
end

%% Now go through a sliding window and find turn bias for a sliding window size
wlength = 120; %set a window size in seconds
thresh = 5; %set threshold number of turns per sliding window
fr = median(diff(tstamps)); %find frame rate. NOTE SURE THIS IS THE BEST WAY TO DO THIS
frames = round(wlength/fr); %how many frames per bin
slide = 5; %number of seconds to shift frame by
fint = [1:frames]; %define the interval for a window
fslide = round(slide/fr); %define how many frames to shift in each slide


wbias = zeros((round((size(turns,1)-frames)/fslide)),size(turns,2)); %create matrix to store tbias at each window (rows) for each flow (columns)
wnturns = zeros((round((size(turns,1)-frames)/fslide)),size(turns,2)); %create matrix to store numturns at each window (rows) for each flow (columns)



for i = 1:size(wbias,1)-1 %the last bin will throw an error
    wbias(i,:) = nansum(turns(fint,:),1)./sum(~isnan(turns(fint,:)),1); %take right turns (1s) over total turns (non-nans) in the interval
    if sum(~isnan(turns(fint,:)),1) < thresh
        wbias(i,:) = nan;
    end
    wnturns(i,:) = sum(~isnan(turns(fint,:)),1);
    fint = fint + fslide; %slide the window. currently non-overlapping
end

%% Find variability over time bins
wvar = zeros(1,size(wbias,1));

for i = 1:size(wvar,2)
    wvar(i) = nanvar(wbias(i,:));
end

%% Bootstrap variability
n = 10000; %set number of bootstrap resamples
thresh = 0.67; %set percentage of data to sample
bootvar = zeros(size(wbias,1),n); %rows are variabilities over time, columns are different resamples

for i = 1:size(bootvar,2)
    idx = rand(1,size(wbias,2)) > thresh;
    bootvar(:,i) = nanvar(wbias(:,idx),[],2);
end

%% Plot this
stim_start = round(size(wvar,2)/4);
stim_end = round(size(wvar,2)/2);
figure
hax=axes; 
hold on
h1 = plot(1:size(wvar,2),wvar, 'r', 'LineWidth', 2);
h2 = plot(1:size(wvar,2),wvar+2*std(bootvar,[],2)', 'k', 'Linewidth', 0.5);
plot(1:size(wvar,2),wvar-2*std(bootvar,[],2)', 'k', 'Linewidth', 0.5)
h3 = line([stim_start stim_start],get(hax,'YLim'),'Color',[0 0 1]); %plot a vertical line where the ramp starts 60 minutes * 60 secnds per minute * numframes per second
line([stim_end stim_end],get(hax,'YLim'),'Color',[0 0 1])
title('Variance over sliding window of 2 minutes')
legend([h1,h2,h3],'signal', '2 stds', 'ramp')



%%
figure
plot(1:size(wvar,2),sum(wnturns,2), 'b', 'LineWidth', 1)
title('num turns per bin')
