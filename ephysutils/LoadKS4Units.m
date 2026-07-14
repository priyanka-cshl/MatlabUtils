function [SingleUnits] = LoadKS4Units(myKsDir,varargin)
%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('minSpikes', 0, @(x) isnumeric(x)); % in counts
params.addParameter('allUnits', 0, @(x) isnumeric(x)); % default is load only good units


% extract values from the inputParser
params.parse(varargin{:});
minRate = params.Results.minSpikes; % in sec
allUnits = params.Results.allUnits;

%% load KS4 units
load(fullfile(myKsDir,'quickprocesssniffs.mat')); % sniff times, KS4Units
if exist('KS4Units') %&& isempty(dir(fullfile(myKsDir,'kilosort4','cluster_info*')))
    myUnits = [[KS4Units.id]' [KS4Units.tetrode]' [KS4Units.quality]' [KS4Units.spikecount]'];
    myUnits(:,end+1) = 1:size(myUnits,1);
    switch allUnits
        case 0
            % keep only good
            myUnits(find(myUnits(:,3)~=2),:) = [];
        case 1
            % keep all
        case -1
            % keep only non-good
            myUnits(find(myUnits(:,3)==2),:) = [];
    end
    disp(['found ',num2str(size(myUnits,1)),' good units']);
    SingleUnits = KS4Units(myUnits(:,end));
    
    if minRate>0
        % remove low firing units
        sessionTime = ceil(max(arrayfun(@(x) max(x.spikes),SingleUnits)));
        lowFR = find((myUnits(:,end-1)/sessionTime)<=0.25);
        myUnits(lowFR,:) = [];
        SingleUnits = KS4Units(myUnits(:,end));
    end

else
    keyboard;
end


end