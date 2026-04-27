function cluster_info = make_cluster_info(ksDir, fs, refPeriod)
% make_cluster_info - Reconstruct cluster_info.tsv fields from Kilosort4 output
%
% Inputs:
%   ksDir      - path to Kilosort4 output directory
%   fs         - sample rate in Hz (e.g. 30000)
%   refPeriod  - refractory period in seconds for RPV calculation (e.g. 0.002)

if nargin < 3, refPeriod = 0.002; end
if nargin < 2, fs = 30000; end

% --- Load raw files ---
spikeTimes    = double(readNPY(fullfile(ksDir, 'spike_times.npy')));     % [nSpikes x 1] in samples
spikeClusters = double(readNPY(fullfile(ksDir, 'spike_clusters.npy'))); % [nSpikes x 1]
amplitudes    = double(readNPY(fullfile(ksDir, 'amplitudes.npy')));     % [nSpikes x 1]
templates     = double(readNPY(fullfile(ksDir, 'templates.npy')));      % [nTemplates x nSamples x nChannels]
spikeTemplates = double(readNPY(fullfile(ksDir, 'spike_templates.npy')));% [nSpikes x 1]

recDuration = max(spikeTimes) / fs; % seconds

clusterIDs = unique(spikeClusters);
nClusters  = numel(clusterIDs);

% --- Preallocate ---
cluster_id     = clusterIDs;
ch             = zeros(nClusters, 1);
amp            = zeros(nClusters, 1);
fr             = zeros(nClusters, 1);
n_spikes       = zeros(nClusters, 1);
fractionRPV    = zeros(nClusters, 1);
ISIViolations  = zeros(nClusters, 1);

for i = 1:nClusters
    uid  = clusterIDs(i);
    mask = spikeClusters == uid;
    
    % Spike times for this unit (seconds)
    st = spikeTimes(mask) / fs;
    
    % n_spikes
    n_spikes(i) = sum(mask);
    
    % Firing rate
    fr(i) = n_spikes(i) / recDuration;
    
    % Mean amplitude
    amp(i) = mean(amplitudes(mask));
    
    % Best channel: peak-to-trough amplitude of dominant template
    dominantTemplate = mode(spikeTemplates(mask)) + 1; % +1 for 1-indexing
    waveform = squeeze(templates(dominantTemplate, :, :)); % [nSamples x nChannels]
    peakTrough = max(waveform) - min(waveform);
    [~, ch(i)] = max(peakTrough);
    ch(i) = ch(i) - 1; % convert back to 0-indexed to match Phy
    
    % ISI violations
    isi = diff(st); % inter-spike intervals in seconds
    nViolations = sum(isi < refPeriod);
    ISIViolations(i) = nViolations;
    
    % Fraction of refractory period violations
    fractionRPV(i) = nViolations / n_spikes(i);
end

% --- Build table ---
cluster_info = table(cluster_id, ch, amp, fr, fractionRPV, ISIViolations, n_spikes);

% --- Optionally merge Phy labels if cluster_group.tsv exists ---
groupFile = fullfile(ksDir, 'cluster_group.tsv');
if isfile(groupFile)
    tbl = readtable(groupFile, 'FileType', 'text', 'Delimiter', '\t');
    tbl.Properties.VariableNames{1} = 'cluster_id';
    cluster_info = outerjoin(cluster_info, tbl, 'Keys', 'cluster_id', ...
        'MergeKeys', true, 'Type', 'left');
end

% % --- Optionally write to TSV ---
% writetable(cluster_info, fullfile(ksDir, 'cluster_info.tsv'), ...
%     'FileType', 'text', 'Delimiter', '\t');
% 
% fprintf('cluster_info.tsv written to %s\n', ksDir);
end