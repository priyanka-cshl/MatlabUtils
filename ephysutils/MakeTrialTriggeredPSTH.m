function [myFR] = MakeTrialTriggeredPSTH(AllSpikes, TrialDurations, WindowStart, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('kernelsize', 100, @(x) isnumeric(x));
params.addParameter('downsample', 1000, @(x) isnumeric(x));

% extract values from the inputParser
params.parse(varargin{:});
kernelsize = params.Results.kernelsize;
downsample = params.Results.downsample;

% Initialize raster
% timeBins = windowsize(1):windowsize(2);
% myRaster = zeros(size(Spiketimes,1),numel(timeBins));
myPSTH = [];

% convert spike times to milliseconds and floor values
AllSpikes = ceil(1000*AllSpikes);
% remove NaNs
AllSpikes(isnan(AllSpikes)) = [];
% add the starting bin value to have only positive bin indices
AllSpikes = AllSpikes - WindowStart;
% Make raster
[C,~,ic] = unique(AllSpikes);
bin_counts = accumarray(ic,1);
if ~isempty(C)
    % ignore any time bins less than 1 sec before trial start
    bin_counts((C<=0),:) = [];
    C(C<=0) = [];
    myPSTH(1,C) = bin_counts; %#ok<AGROW>
end

% convert sniff durations to milliseconds and add window offset
TrialDurations = ceil(1000*TrialDurations) - WindowStart;
Trialcounts = zeros(1,max(TrialDurations));
for i = 1:numel(TrialDurations)
    Trialcounts(1,1:TrialDurations(i)) = 1 + Trialcounts(1,1:TrialDurations(i)); 
end

if numel(myPSTH) <= numel(Trialcounts)
    myPSTH(:,(numel(myPSTH)+1):numel(Trialcounts)) = 0;
else
    myPSTH(:,(numel(Trialcounts)+1):end) = [];
end

% Make PSTH (raw)
myPSTH = myPSTH./Trialcounts;

% Smoothen PSTH
taxis = -500:500;  % make a time axis of 1000 ms
gauss_kernel = normpdf(taxis, 0, kernelsize);
gauss_kernel = gauss_kernel ./ sum(gauss_kernel);

if kernelsize > 1
    myFR = 1000*conv(myPSTH,gauss_kernel,'same'); % in Hz
else
    myFR = myPSTH;
end

if downsample ~= 1000
    taxis = (1000/downsample):(1000/downsample):numel(myFR);
    if ~isempty(myFR)
        myFR = interp1(myFR,taxis');
    else
        myFR = 0*taxis;
    end
end

end