function [TTLs, AuxData] = GetOepsTTLs(myKsDir, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('binary', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('ADC', false, @(x) islogical(x) || x==0 || x==1);

% extract values from the inputParser
params.parse(varargin{:});
FileType = params.Results.binary;
GetAux = params.Results.ADC;

%% defaults
OepsSampleRate = 30000; % Open Ephys acquisition rate
SampleRate = 500; % Typical Behavior Acquisition rate

if ~FileType
    %% Get Trial Timestamps from the OpenEphys Events file
    filename = fullfile(myKsDir,'all_channels.events');
    
    [data, timestamps, info] = load_open_ephys_data(filename); % data has channel IDs
    
    % adjust for clock offset between open ephys and kilosort
    [offset] = AdjustClockOffset(myKsDir);
    % offset = offset/OepsSampleRate;
    timestamps = timestamps - offset;
    
    % Get various events
    TTLTypes = unique(data);
    Tags = {'Air', 'Odor1', 'Odor2', 'Odor3', 'Trial', 'Reward', 'AirManifold', 'Licks'};
    for i = 1:numel(TTLTypes)
        On = timestamps(intersect(find(info.eventId),find(data==TTLTypes(i))));
        Off = timestamps(intersect(find(~info.eventId),find(data==TTLTypes(i))));
        % delete the first off value, if it preceeds the On
        Off(Off<On(1)) = [];
        On(On>Off(end)) = [];
        
        if length(On)>length(Off)
            keyboard;
            foo = [On(1:end-1) Off]';
            goo = foo(:);
            On(find(diff(goo)<0,1,'first')/2,:) = [];
        end
        
        temp = [On Off Off-On];
        
        % ignore any transitions faster than 1 ms - behavior resolution is 2 ms
        temp(temp(:,3)<0.001,:) = [];
        TTLs.(char(Tags(i))) = temp;
    end
end

AuxData = [];
if GetAux
    %% Get analog/digital AuxData from Oeps files - for comparison with behavior data
    if exist(dir(fullfile(myKsDir,'*_ADC1.continuous')))
        foo = dir(fullfile(myKsDir,'*_ADC1.continuous')); % pressure sensor
        filename1 = fullfile(myKsDir,foo.name);
        foo = dir(fullfile(myKsDir,'*_ADC2.continuous')); % thermistor
        filename2 = fullfile(myKsDir,foo.name);
    else
        foo = dir(fullfile(myKsDir,'*_65.continuous')); % pressure sensor
        filename1 = fullfile(myKsDir,foo.name);
        foo = dir(fullfile(myKsDir,'*_66.continuous')); % thermistor
        filename2 = fullfile(myKsDir,foo.name);
    end
        
    [Auxdata1, timestamps, ~] = load_open_ephys_data(filename1); % data has channel IDs
    [Auxdata2, ~, ~] = load_open_ephys_data(filename2); % data has channel IDs
        
    % adjust for clock offset between open ephys and kilosort
    timestamps = timestamps - offset;
    
    % downsample to behavior resolution
    
    AuxData(:,1) = 0:1/SampleRate:max(timestamps);
    AuxData(:,2) = interp1q(timestamps,Auxdata1,AuxData(:,1)); % pressure sensor
    AuxData(:,3) = interp1q(timestamps,Auxdata2,AuxData(:,1)); % thermistor
    % create a continuous TrialOn vector
    for MyTrial = 1:size(TTLs.Trial,1)
        [~,start_idx] = min(abs(AuxData(:,1)-TTLs.Trial(MyTrial,1)));
        [~,stop_idx]  = min(abs(AuxData(:,1)-TTLs.Trial(MyTrial,2)));
        AuxData(start_idx:stop_idx,4) = 1;
    end
end

end
