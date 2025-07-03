function [SniffTS, PIDData] = GetPIDFromOEPSBinary(myDir,myStimFile)

%myDir = '/Users/Priyanka/Desktop/LABWORK_II/Data/PID/16odors/2025-05-14_12-10-02'; myStimFile = '250514_12_10.txt';
%myDir = '/Users/Priyanka/Desktop/LABWORK_II/Data/PID/16odors/2025-05-14_15-20-57'; myStimFile = '250514_15_21.txt';


%addpath(genpath('/opt/open-ephys-matlab-tools')) % path to new open ephys data handling scripts
oeps_scripts = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'open-ephys-matlab-tools');
addpath(genpath(oeps_scripts));
OEPSSamplingRate = 30000;

% read the open ephys binary file
session = Session(myDir);

% get Events
Events = session.recordNodes{1}.recordings{1}.ttlEvents('Acquisition_Board-100.Rhythm Data');
EventTS = Events(:,3).Variables;
ch = Events(:,1).Variables; 
states = Events(:,6).Variables;
OdorTTLs(:,1) = EventTS(ch==2 & states,1);
while size(EventTS(ch==2 & ~states,1),1) > size(OdorTTLs,1)
    OdorTTLs(end,:) = [];
end
OdorTTLs(:,2) = EventTS(ch==2 & ~states,1);
OdorTTLs(1,:) = [];

% thermistor is on the 2nd ADC channel, there are 3 ADCs stacked after 1
% ephys channel
PIDCh = 3;
PID_OEPS = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').samples(PIDCh,:);
% convert to volts
VoltMultiplier = session.recordNodes{1}.recordings{1}.info.continuous.channels(PIDCh).bit_volts;
PID_OEPS = double(PID_OEPS')*VoltMultiplier;
%PID_OEPS = double(PID_OEPS')*(VoltMultiplier/2) + 2.5;

startoffset = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1);
timestamps = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps - startoffset;

% downsample to behavior resolution (500Hz)
SampleRate = 500;
PIDData(:,1) = 0:1/SampleRate:max(timestamps);
PIDData(:,2) = interp1q(timestamps,PID_OEPS,PIDData(:,1)); % thermistor

% for the first 6 repeats
StimFile = readmatrix(fullfile(fileparts(myDir),myStimFile));
StimSettings = StimFile(1:6)'; % [? pre-stim stim post-stim iti reps]
StimFile(1:6,:) = [];

OdorTTLs = OdorTTLs - startoffset;
%figure;
for i = 1:size(StimFile,1)
    whichstim = StimFile(i);
    %subplot(4,8,(whichstim*2)-1); hold on
    subplot(4,8,(whichstim*2)-0); hold on
    whichpulses = (i*2) + [-1 0];
    for n = 1:2
        OdorPeriod = OdorTTLs(whichpulses(n),:) + [-1 5]; 
        OdorTrace = PIDData(PIDData(:,1)>=OdorPeriod(1) & PIDData(:,1)<OdorPeriod(2),2);
        OdorTrace = sgolayfilt(OdorTrace,3,61);
        OdorTrace = OdorTrace - mean(OdorTrace(1:SampleRate));
        if n == 1
            if i < 97
                plot(OdorTrace,'color',Plot_Colors('p'));
            else
                plot(OdorTrace,'color',Plot_Colors('r'));
            end
        else
            if i < 97
                plot(OdorTrace,'color',Plot_Colors('pl'));
            else
                plot(OdorTrace,'color',Plot_Colors('pd'));
            end
        end
    end
end
%%
for i = 2:2:32
    % get ylims
    ylims = [];
    for j = i-1:1:i
        subplot(4,8,j);
        set(gca,'XLim',[0 5000]);
        ylims = [ylims; get(gca, 'YLim')]; 
    end
    ymax = max(ylims(:,2));
    ymax = 0.3;
    for j = i-1:1:i
        subplot(4,8,j);
        set(gca,'YLim',[-0.01 ymax]);
        line([SampleRate SampleRate],[-0.01 ymax],'color', 'k', 'LineStyle', ':');
    end
end


end