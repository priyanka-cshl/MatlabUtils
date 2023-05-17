function [] = MatchUnits(myKsDir)

% add repos if needed
Paths = WhichComputer();
addpath(genpath([Paths.Code,filesep,'open-ephys-analysis-tools']));
addpath(genpath([Paths.Code,filesep,'afterphy']));
addpath(genpath([Paths.Code,filesep,'spikes']));
addpath(genpath([Paths.Code,filesep,'npy-matlab']));
addpath(genpath([Paths.Code,filesep,'MatlabUtils']));

for i = 1:size(myKsDir,1)
    %% Load data from kilosort/phy
    sp = loadKSdirPriyanka(myKsDir);
    % sp.st are spike times in seconds (for all spikes)
    % sp.clu are cluster identities (for all spikes)
    % sp.cids is list of unqiue clusters
    % sp.cgs are cluster defs (1 = MUA, 2 = good, 3 = Unsorted??) (1/cluster)
    % sp.channels is the primary channel for that spike
    % spikes from clusters labeled "noise" have already been omitted
    
    Session{i} = sp;
end

for i = size(Session,1)
    
end

end