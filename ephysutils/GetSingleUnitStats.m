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
    
    % get all spiketimes (in seconds)
%     allspikes = sp.st(sp.clu==sp.cids(mycluster));
    allspikes = sp.st(sp.clu==whichunit);
    
    % which tetrode
    tetrode = floor(sp.channels(mycluster)/4)+1 + ...
        rem(sp.channels(mycluster)-1 ,4)/10;
    
    % Outputs
    cluster(mycluster).id = sp.cids(mycluster);
    cluster(mycluster).tetrode = tetrode;
    cluster(mycluster).spikecount = numel(allspikes);
    cluster(mycluster).spikes = allspikes;
    cluster(mycluster).quality = sp.cgs(mycluster);
    [fpRate, numViolations] = ISIViolations(allspikes, 1/32000, 0.002);
    cluster(mycluster).ISIquality = [round(fpRate,2,'significant'), round(numViolations/(numel(allspikes)-1),2,'significant')];
    
    if getwaveforms
        
        % to get waveforms
        
        % get all spikewaveforms
        gwfparams.dataDir = myKsDir;         % KiloSort/Phy output folder
        gwfparams.fileName = sp.dat_path;    % .dat file containing the raw
        gwfparams.dataType = sp.dtype;       % Data type of .dat file (this should be BP filtered)
        gwfparams.nCh = sp.n_channels_dat;   % Number of channels that were streamed to disk in .dat file
        gwfparams.wfWin = [-40 41];          % Number of samples before and after spiketime to include in waveform
        gwfparams.nWf = 2000;                % Number of waveforms per unit to pull out
        gwfparams.spikeTimes = allspikes*sp.sample_rate; % Vector of cluster spike times (in samples) same length as .spikeClusters
        gwfparams.spikeClusters = sp.cids(mycluster) + 0*gwfparams.spikeTimes; % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
        wf = getWaveForms(gwfparams);
        
        %     [~,channels] = sort(std(squeeze(wf.waveFormsMean),0,2),'descend');
        %     channels = ceil(channels/4);
        %     tetrode = mode(channels(1:4));
    end
    
    if savefigs
        
        if ~exist(fullfile(myKsDir,'ClusterMaps'),'dir')
            mkdir(fullfile(myKsDir,'ClusterMaps'));
        end
        
        % plot waveform map
        figure;
        nTetrodes = 8 + 8*(sp.n_channels_dat > 40);
        % determine YLim by taking the waveform span on the strongest channel
        myLims = [min(min(wf.waveFormsMean(1,(tetrode-1)*4+[1 2 3 4],:))) ...
            max(max(wf.waveFormsMean(1,(tetrode-1)*4+[1 2 3 4],:))) ];
        myLims = 100*[floor(myLims(1)/100) ceil(myLims(2)/100)];
        for whichChannel = 1:sp.n_channels_dat
            whichPlot = 8*(sp.ycoords(whichChannel)/1000 - 1) + sp.xcoords(whichChannel);
            subplot(nTetrodes,8,whichPlot);
            %plot(squeeze(wf.waveFormsMean(1,whichChannel,:)));
            meanWF = squeeze(wf.waveFormsMean(1,whichChannel,:));
            stdWF = nanstd(squeeze(wf.waveForms(1,:,whichChannel,:)),1)';
            if ceil(whichChannel/4)==tetrode
                switch sp.cgs(mycluster)
                    case 2 % good unit
                        MyShadedErrorBar([],meanWF,stdWF,'r');
                    otherwise
                        MyShadedErrorBar([],meanWF,stdWF,'b');
                end
                
            else
                MyShadedErrorBar([],meanWF,stdWF,'k');
            end
            set(gca,'Box','off','Color','none','XColor','none','YColor','none',...
                'YLim',myLims,'XLim',[0 diff(gwfparams.wfWin)],'XTick',[],'YTick',[]);
        end
        
        % plotting Grid
        foo = reshape(1:nTetrodes*8,8,nTetrodes)';
        if nTetrodes <= 8
            WF_subplots   = foo(1:2,5:8);
            ISI_subplots  = foo(3:5,5:8);
            Corr_subplots = foo(6:8,5:8);
        else
            WF_subplots   = foo(1:4,5:8);
            ISI_subplots  = foo(5:10,5:8);
            Corr_subplots = foo(11:16,5:8);
        end
        
        % plot individual waveforms
        myLims = [];
        for n = 1:4
            whichWire = 4*(tetrode-1) + n;
            subplot(nTetrodes,8,WF_subplots(:,n));
            plot(squeeze(wf.waveForms(1,:,whichWire,:))','r');
            myLims = vertcat(myLims,get(gca,'YLim'));
        end
        for n = 1:4
            subplot(nTetrodes,8,WF_subplots(:,n));
            set(gca,'YLim',[2*min(myLims(:,1)) 2*max(myLims(:,2))],...
                'Box','off','Color','none','XColor','none','YColor','none',...
                'XLim',[0 diff(gwfparams.wfWin)],'XTick',[],'YTick',[]);
        end
        
        % plot the ISI histogram
        ISIs = 1000*diff(allspikes); % in milliseconds
        subplot(nTetrodes,8,ISI_subplots(:));
        H = histogram(ISIs,[0:1:50 Inf]);
        myHist = H.Values(1:end-1);
        bar(myHist,1,'EdgeColor','none');
        set(gca,'Color','none','YLim',[0 100*ceil(max(myHist)/100)],'XTick',[],'YTick',[]);
        title(['Cluster# ',num2str(mycluster)])
        
        % plot the autocorrelation
        SpikeTrain = zeros(ceil(max(1000*allspikes)),1);
        SpikeTrain(round(1000*allspikes),1) = 1;
        [r,lags] = xcorr(SpikeTrain,50,'coeff');
        r(lags==0) = NaN;
        subplot(nTetrodes,8,Corr_subplots(:));
        bar(r,1,'EdgeColor','none');
        set(gca,'Color','none','XTick',[],'YTick',[]);
        
        % print to pdf
        set(gcf,'renderer','Painters');
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 0.6, 0.9]);
        print(fullfile(myKsDir,'ClusterMaps',['Cluster',num2str(mycluster),'.eps']),...
            '-depsc','-tiff','-r300','-painters');
        close;
    end
    
%end

end