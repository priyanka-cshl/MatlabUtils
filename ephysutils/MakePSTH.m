function [myFR, myPSTH, myRaster] = MakePSTH(Spiketimes, EventsToAlign, windowsize, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('kernelsize', 100, @(x) isnumeric(x));
params.addParameter('binsize', 1, @(x) isnumeric(x));
params.addParameter('downsample', 1000, @(x) isnumeric(x));
params.addParameter('plotfigures', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('savefigures', false, @(x) islogical(x) || x==0 || x==1);


% extract values from the inputParser
params.parse(varargin{:});
kernelsize = params.Results.kernelsize;
binsize = params.Results.binsize;
downsample = params.Results.downsample;
plotfigs = params.Results.plotfigures;
savefigs = params.Results.savefigures;

global MyFileName;

% Initialize raster
if ~isempty(windowsize)
    timeBins = windowsize(1):windowsize(2);
    myRaster = zeros(size(Spiketimes,1),numel(timeBins));
    myFR 	 = zeros(1,numel(timeBins));
else
    myRaster = 0;
end

for i = 1:size(Spiketimes,1) 
	% align to the specified event
	thisTrialSpikes = Spiketimes(i,:) - EventsToAlign(i);
	% convert spike times to milliseconds and floor values
	thisTrialSpikes = floor(1000*thisTrialSpikes);
    % remove NaNs
    thisTrialSpikes(isnan(thisTrialSpikes)) = [];
	% Make raster
    [C,~,ic] = unique(thisTrialSpikes);
    bin_counts = accumarray(ic,1);
    if ~isempty(C)
        % ignore any -ve time bins
        bin_counts((C<=0),:) = [];
        C(C<=0) = [];
        myRaster(i,C) = bin_counts;
    end
end

% Make PSTH (raw)
myPSTH = sum(myRaster,1);

% Smoothen PSTH
taxis = -500:500;  % make a time axis of 1000 ms
gauss_kernel = normpdf(taxis, 0, kernelsize);
gauss_kernel = gauss_kernel ./ sum(gauss_kernel);

if kernelsize
    myFR = 1000*conv(myPSTH,gauss_kernel,'same'); % in Hz
else
    myFR = myPSTH;
end

if downsample ~= 1000
    taxis = (1000/downsample):(1000/downsample):numel(myFR);
    myFR = interp1(myFR,taxis');
end
end