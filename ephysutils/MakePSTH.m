function [myFR, myPSTH, myRaster] = MakePSTH(Spiketimes, EventsToAlign, windowsize, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('kernelsize', 100, @(x) isnumeric(x));
params.addParameter('downsample', 1000, @(x) isnumeric(x));
params.addParameter('plotfigures', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('savefigures', false, @(x) islogical(x) || x==0 || x==1);


% extract values from the inputParser
params.parse(varargin{:});
kernelsize = params.Results.kernelsize;
downsample = params.Results.downsample;
plotfigs = params.Results.plotfigures;
savefigs = params.Results.savefigures;

global MyFileName;

% Initialize raster
timeBins = windowsize(1):windowsize(2);
myRaster = zeros(size(Spiketimes,1),numel(timeBins));
myFR 	 = zeros(1,numel(timeBins));

for i = 1:size(Spiketimes,1) 
	% align to the specified event
	thisTrialSpikes = Spiketimes(i,:) - EventsToAlign(i);
	% convert spike times to milliseconds and floor values
	thisTrialSpikes = floor(1000*thisTrialSpikes);

	% Make raster
	for t = 1:numel(timeBins)
		myRaster(i,t) = numel(find(thisTrialSpikes==timeBins(t)));
    end

end

% Make PSTH (raw)
myPSTH = sum(myRaster,1);

% Smoothen PSTH
taxis = -500:500;  % make a time axis of 1000 ms
gauss_kernel = normpdf(taxis, 0, kernelsize);
gauss_kernel = gauss_kernel ./ sum(gauss_kernel);

myFR = 1000*conv(myPSTH,gauss_kernel,'same'); % in Hz

if downsample ~= 1000
    taxis = (1000/downsample):(1000/downsample):numel(myFR);
    myFR = interp1(myFR,taxis');
end
end