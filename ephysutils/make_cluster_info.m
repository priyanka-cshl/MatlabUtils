function cluster_info = make_cluster_info(ksDir, fs)

if nargin < 2, fs = 30000; end

% Load raw files
templates      = double(readNPY(fullfile(ksDir, 'templates.npy')));
spikeTemplates = double(readNPY(fullfile(ksDir, 'spike_templates.npy')));
spikeClusters  = double(readNPY(fullfile(ksDir, 'spike_clusters.npy')));
spikeTimes     = double(readNPY(fullfile(ksDir, 'spike_times.npy'))) / fs;
wmi            = double(readNPY(fullfile(ksDir, 'whitening_mat_inv.npy')));

clusterIDs = unique(spikeClusters);
nClusters  = length(clusterIDs);

% Preallocate
cluster_id    = clusterIDs(:);
ch            = zeros(nClusters, 1);
amp           = zeros(nClusters, 1);
fr            = zeros(nClusters, 1);
n_spikes      = zeros(nClusters, 1);
fractionRPV   = zeros(nClusters, 1);
ISIViolations = zeros(nClusters, 1);

tauR   = 0.002;
tauC   = 0.001;
minISI = 0.001;

for i = 1:nClusters
    uid  = clusterIDs(i);
    mask = spikeClusters == uid;
    st   = spikeTimes(mask);
    isi  = diff(st);

    % n_spikes and firing rate
    n_spikes(i) = sum(mask);
    fr(i)       = n_spikes(i) / (max(st) - min(st));

    % ISI violations (%, 1ms threshold)
    ISIViolations(i) = 100 * sum(isi < minISI) / n_spikes(i);

    % fractionRPV - Phy's quadratic estimator
    T = max(st) - min(st);
    r = sum(isi <= tauR);
    a = 2 * (tauR - tauC) * n_spikes(i) / abs(T);
    if r == 0
        fractionRPV(i) = 0;
    else
        rts = roots([-1, 1, -r/a]);
        fp  = min(rts);
        if ~isreal(fp)
            if r < n_spikes(i)
                fp = r / (2 * (tauR - tauC) * (n_spikes(i) - r));
            else
                fp = 1;
            end
        end
        fractionRPV(i) = fp;
    end

    % Unwhiten dominant template
    dominantTemplate = mode(spikeTemplates(mask)) + 1; % +1 for MATLAB indexing
    waveform         = squeeze(templates(dominantTemplate, :, :)) * wmi; % [nSamples x nChannels]
    peakTrough       = max(waveform) - min(waveform);

    % ch: best channel (0-indexed to match Phy)
    [~, ch(i)] = max(peakTrough);
    ch(i)      = ch(i) - 1;

    % amp: peak-to-trough on best channel of unwhitened template
    amp(i) = peakTrough(ch(i) + 1);
end

cluster_info = table(cluster_id, ch, amp, fr, fractionRPV, ISIViolations, n_spikes);
end