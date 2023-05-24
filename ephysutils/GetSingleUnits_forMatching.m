function [Sessions] = GetSingleUnits_forMatching(myKsDir)
% function to load spike times, waveforms etc after spike sorting
% manual curation in phy

% add repos if needed
Paths = WhichComputer();
addpath(genpath([Paths.Code,filesep,'open-ephys-analysis-tools']));
addpath(genpath([Paths.Code,filesep,'afterphy']));
addpath(genpath([Paths.Code,filesep,'spikes']));
addpath(genpath([Paths.Code,filesep,'npy-matlab']));
addpath(genpath([Paths.Code,filesep,'MatlabUtils']));

for i = 1:size(myKsDir,2)
    
    %% Load data from kilosort/phy
    sp = loadKSdirPriyanka_basic(myKsDir{i});
    %sp = loadKSdirPriyanka(myKsDir{i});
    % sp.st are spike times in seconds (for all spikes)
    % sp.clu are cluster identities (for all spikes)
    % sp.cids is list of unqiue clusters
    % sp.cgs are cluster defs (1 = MUA, 2 = good, 3 = Unsorted??) (1/cluster)
    % spikes from clusters labeled "noise" have already been omitted
    
    %% for waveforms
    gwfparams.dataDir = myKsDir{i};         % KiloSort/Phy output folder
    gwfparams.fileName = sp.dat_path;    % .dat file containing the raw
    gwfparams.dataType = sp.dtype;       % Data type of .dat file (this should be BP filtered)
    gwfparams.nCh = sp.n_channels_dat;   % Number of channels that were streamed to disk in .dat file
    gwfparams.wfWin = [-40 41];          % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf = 2000;                % Number of waveforms per unit to pull out
    
    %% Split data by clusters and by trials
    
    Cluster = [];
    % align to trial off of the previous trial
    for mycluster = 1:length(sp.cids) % for each cluster
        % sp.attributes = ...
        %[cluster_ID ch amp fr fractionRPV ISIViolations n_spikes]
        cluster_ID = sp.attributes(mycluster,1);
        electrode  = sp.attributes(mycluster,2);
        tetrode    = floor(electrode/4)+1 + rem(electrode,4)/10;
        channels   = (floor(tetrode)-1)*4 + (1:4);
        
        % get all spiketimes (in seconds)
        allspikes = sp.st(sp.clu==cluster_ID);
        
        % get all spike amplitudes
        thisunitamps = sp.tempScalingAmps(find(sp.clu == cluster_ID));
        
        % get n spikewaveforms for this unit (n = gwfparams.nWf)
        gwfparams.spikeTimes = allspikes*sp.sample_rate; % Vector of cluster spike times (in samples) same length as .spikeClusters
        gwfparams.spikeClusters = sp.cids(mycluster) + 0*gwfparams.spikeTimes; % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
        wf = getWaveForms(gwfparams);
        
        %     [~,channels] = sort(std(squeeze(wf.waveFormsMean),0,2),'descend');
        %     channels = ceil(channels/4);
        %     tetrode = mode(channels(1:4));
        
        % get mean WF, sd, ISI curve, Correlogram etc - concatnated on all
        % 4 channels of the tetrode
        meanWF = squeeze(wf.waveFormsMean(1,channels,:))';
        stdWF = squeeze(nanstd(squeeze(wf.waveForms(1,:,channels,:)),1))';
        %allWF = wf.waveFormsMean(1,:,channels,:);
        
        ISIs = 1000*diff(allspikes); % in milliseconds
        myHist = histcounts(ISIs,[0:1:50 Inf]);
        myHist(:,end) = [];
        %bar(myHist,1,'EdgeColor','none');
        
        SpikeTrain = zeros(ceil(max(1000*allspikes)),1);
        SpikeTrain(round(1000*allspikes),1) = 1;
        [r,lags] = xcorr(SpikeTrain,50,'coeff');
        r(lags==0) = 30000/length(SpikeTrain);
        %bar(r,1,'EdgeColor','none');
        
        % Parse the required values
        Sessions.(['Session',num2str(i)]).UnitAttributes(mycluster,:)   = [cluster_ID electrode tetrode sp.attributes(mycluster,3:end)]; %[cluster_ID ch tetrode amp fr fractionRPV ISIViolations n_spikes]
        Sessions.(['Session',num2str(i)]).MeanWaveForms(mycluster,:)    = meanWF(:);
        Sessions.(['Session',num2str(i)]).stdWaveForms(mycluster,:)     = stdWF(:);
        Sessions.(['Session',num2str(i)]).distISI(mycluster,:)          = myHist;
        Sessions.(['Session',num2str(i)]).Correlogram(mycluster,:)      = r;
    end
    
    disp(['found ',num2str(mycluster),' units']);
    
end

end