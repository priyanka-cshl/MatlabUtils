function [cluster] = GetSingleUnitStats(myKsDir, whichunit, options)
% function to load spike times, waveforms etc after spike sorting
% manual curation in phy

% add repos if needed
Paths = WhichComputer();
addpath(genpath([Paths.Code,filesep,'open-ephys-analysis-tools']));
addpath(genpath([Paths.Code,filesep,'afterphy']));
addpath(genpath([Paths.Code,filesep,'spikes']));
addpath(genpath([Paths.Code,filesep,'npy-matlab']));
addpath(genpath([Paths.Code,filesep,'MatlabUtils']));

if nargin<3
    getwaveforms = 0;
    savefigs = 0;
else
    switch options
        case 0
            getwaveforms = 0;
            savefigs = 0;
        case 1
            getwaveforms = 1;
            savefigs = 0;
        case 2
            getwaveforms = 1;
            savefigs = 1;
        otherwise
            error('Envalid input argument for options! Valid values: 0,1,2');
    end
end

%% Load data from kilosort/phy
sp = loadKSdirPriyanka(myKsDir);
% sp.st are spike times in seconds (for all spikes)
% sp.clu are cluster identities (for all spikes)
% sp.cids is list of unqiue clusters
% sp.cgs are cluster defs (1 = MUA, 2 = good, 3 = Unsorted??) (1/cluster)
% spikes from clusters labeled "noise" have already been omitted


%% Split data by clusters and by trials

% align to trial off of the previous trial
%for mycluster = 1:length(sp.cids) % for each cluster
    mycluster = 10;
    % get all spiketimes (in seconds)
    allspikes = sp.st(sp.clu==sp.cids(mycluster));
    
    % which tetrode
    tetrode = floor(sp.channels(mycluster)/4)+1 + ...
        rem(sp.channels(mycluster),4)/10;
    
    % Outputs
    cluster(mycluster).id = sp.cids(mycluster);
    cluster(mycluster).tetrode = tetrode;
    cluster(mycluster).spikecount = numel(allspikes);
    cluster(mycluster).spikes = allspikes;
    cluster(mycluster).quality = sp.cgs(mycluster);
    [fpRate, numViolations] = ISIViolations(allspikes, 1/32000, 0.002);
    cluster(mycluster).ISIquality = [round(fpRate,2,'significant'), round(numViolations/(numel(allspikes)-1),2,'significant')];
    cluster(mycluster).spikescaling = sp.tempScalingAmps;
    cluster(mycluster).clusterscalingorder = sp.clu;
    
    if getwaveforms
        
        % to get waveforms
        
        % get all spikewaveforms
        gwfparams.dataDir = myKsDir;         % KiloSort/Phy output folder
        gwfparams.fileName = sp.dat_path;    % .dat file containing the raw
        gwfparams.dataType = sp.dtype;       % Data type of .dat file (this should be BP filtered)
        gwfparams.nCh = sp.n_channels_dat;   % Number of channels that were streamed to disk in .dat file
        gwfparams.wfWin = [-40 41];          % Number of samples before and after spiketime to include in waveform
        gwfparams.nWf = 2000;                % Number of waveforms per unit to pull out
        gwfparams.spikeTimes = int32(allspikes*sp.sample_rate); % Vector of cluster spike times (in samples) same length as .spikeClusters
        gwfparams.spikeClusters = sp.cids(mycluster) + 0*gwfparams.spikeTimes; % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
        wf = getWaveForms(gwfparams);
        
        %     [~,channels] = sort(std(squeeze(wf.waveFormsMean),0,2),'descend');
        %     channels = ceil(channels/4);
        %     tetrode = mode(channels(1:4));
    end
    
    whichchannels = (floor(tetrode)*4) + [-3:1:0];
    wf.spikeTimeKeeps = wf.spikeTimeKeeps/sp.sample_rate;
    figure,
    for chunk = 1:3
        whichspikes = intersect(find(wf.spikeTimeKeeps<=1500*chunk),find(wf.spikeTimeKeeps>=1500*(chunk-1)));
        for ch = 1:4
            subplot(3,4,ch+(chunk-1)*4);            
            meanWF = mean(squeeze(wf.waveForms(1,whichspikes,whichchannels(ch),:)),1);
            stdWF = nanstd(squeeze(wf.waveForms(1,whichspikes,whichchannels(ch),:)),1);
            plot(meanWF,'k');
            hold on
            plot(meanWF+stdWF,'b');
            plot(meanWF-stdWF,'b');
            semWF = stdWF/sqrt(numel(whichspikes));
            plot(meanWF+semWF,'r');
            plot(meanWF-semWF,'r');
            %MyShadedErrorBar(1:length(meanWF),meanWF,stdWF,'r');
        end
    end

    
    
%end

end