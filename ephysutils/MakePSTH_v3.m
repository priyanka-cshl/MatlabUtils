function [myFR, myPSTH, myRaster] = MakePSTH_v3(Spiketimes, EventsToAlign, WindowStart, varargin)

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
myRaster = [];
for i = 1:size(Spiketimes,1) 
	% align to the specified event
	thisTrialSpikes = Spiketimes{i}{1} - EventsToAlign(i);
	% convert spike times to milliseconds and floor values
	thisTrialSpikes = ceil(1000*thisTrialSpikes);
    % remove NaNs
    thisTrialSpikes(isnan(thisTrialSpikes)) = [];
    % add the starting bin value to hav eonly positive bin indices
    thisTrialSpikes = thisTrialSpikes - WindowStart;
	% Make raster
    [C,~,ic] = unique(thisTrialSpikes);
    bin_counts = accumarray(ic,1);
    if ~isempty(C)
        % ignore any time bins less than 1 sec before trial start
        bin_counts((C<=0),:) = [];
        C(C<=0) = [];
        myRaster(i,C) = bin_counts; %#ok<AGROW>
    end
end

% Make PSTH (raw)
myPSTH = sum(myRaster,1)/i;

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