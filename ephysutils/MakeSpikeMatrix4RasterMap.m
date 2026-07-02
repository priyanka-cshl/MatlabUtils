function [] = MakeSpikeMatrix4RasterMap(myKsDir,varargin)
%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('binSize', 20, @(x) isnumeric(x)); % in ms

% extract values from the inputParser
params.parse(varargin{:});
binSize = params.Results.binSize/1000; % in sec

%% load KS4 units
% load(fullfile(myKsDir,'quickprocesssniffs.mat')); % sniff times, KS4Units
% if exist('KS4Units') && isempty(dir(fullfile(myKsDir,'kilosort4','cluster_info*')))
%     myUnits = [[KS4Units.id]' [KS4Units.tetrode]' [KS4Units.quality]'];
%     myUnits(:,4) = 1:size(myUnits,1);
%     % session wasn't curated in phy, keep only 'good' units
%     myUnits(find(myUnits(:,3)~=2),:) = [];
%     disp(['found ',num2str(size(myUnits,1)),' good units']);
%     SingleUnits = KS4Units(myUnits(:,4));
% else
%     keyboard;
% end
SingleUnits = LoadKS4Units(myKsDir,'minSpikes',0.25);
disp(['found ',num2str(size(SingleUnits,2)),' good, >0.25Hz units']);

% for the spike matrix
maxTime = ceil(max(arrayfun(@(x) max(x.spikes),SingleUnits)));
nBins = ceil(maxTime/binSize);
nUnits = size(SingleUnits,2);
spikeMatrix = zeros(nUnits, nBins, 'single');

for i = 1:nUnits
    st = SingleUnits(i).spikes;
    binIdx = min(floor(st/binSize)+1,nBins);
    counts = accumarray(binIdx, 1, [nBins, 1]);
    spikeMatrix(i,:) = counts;
end

writeNPY(spikeMatrix, fullfile(myKsDir,'spike_matrix.npy'));
unsortedUnitIds = [SingleUnits.id]';
save(fullfile(myKsDir,'unsortedUnitIds.mat'),'unsortedUnitIds');

end