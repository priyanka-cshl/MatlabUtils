function [] = GetSortingSummary(myKsDir)
% function to load spike times, waveforms etc after spike sorting
% manual curation in phy

% add repos if needed
Paths = WhichComputer();
addpath(genpath([Paths.Code,filesep,'open-ephys-analysis-tools']));
addpath(genpath([Paths.Code,filesep,'afterphy']));
addpath(genpath([Paths.Code,filesep,'spikes']));
addpath(genpath([Paths.Code,filesep,'npy-matlab']));
addpath(genpath([Paths.Code,filesep,'MatlabUtils']));

%% Load data from kilosort/phy
sp = loadKSdirPriyanka(myKsDir);
% sp.st are spike times in seconds (for all spikes)
% sp.clu are cluster identities (for all spikes)
% sp.cids is list of unqiue clusters
% sp.cgs are cluster defs (1 = MUA, 2 = good, 3 = Unsorted??) (1/cluster)
% spikes from clusters labeled "noise" have already been omitted


%% Split data by clusters and by trials

% align to trial off of the previous trial
for mycluster = 1:length(sp.cids) % for each cluster
    
    % get all spiketimes (in seconds)
    allspikes = sp.st(sp.clu==sp.cids(mycluster));
    
    % which tetrode
    tetrode = floor(sp.channels(mycluster)/4)+1;
    
    % Outputs
    Cluster(mycluster,1) = sp.cids(mycluster); % id
    Cluster(mycluster,2) = tetrode; % tetrode
    Cluster(mycluster,3) = sp.cgs(mycluster); % quality
    [fpRate, numViolations] = ISIViolations(allspikes, 1/32000, 0.002);
    Cluster(mycluster,4:5) = [round(fpRate,2,'significant'), round(numViolations/(numel(allspikes)-1),2,'significant')]; %  ISIquality

end

% Sort by tetrode
Cluster = sortrows(Cluster,[2 3]);
[~,y] = unique(Cluster(:,2)); % get starting index for each tt
% units per tetrode
perTT = diff([y; 1+size(Cluster,1)]);

disp(['found ',num2str(sum(perTT)),'(',num2str(numel(find(Cluster(:,3)==2))),') units']);
disp(['Units per tetrode: ',num2str(perTT')]);

end