function [SniffTS, RespirationData, AllSniffs] = GetSniffsFrom_myauxfile(myKsDir)

OEPSSamplingRate = 30000;

% load info from SessionDetails.mat
load(fullfile(myKsDir,'SessionDetails.mat')); % loads Files

if size(Files.Samples,2) > 1
    SamplesPerChan = sum(Files.Samples);
else
    SamplesPerChan = Files.Samples;
end
VoltMultiplier = Files.AuxBitVolts(1);

% get no. of channels etc from file size
X = dir(fullfile(myKsDir,'myauxfile.dat'));
Nchan       = floor(X.bytes/2/SamplesPerChan);

offset = 0;
fid = fopen(fullfile(myKsDir,'myauxfile.dat'),'r');
fseek(fid, offset, 'bof');
if size(Files.Samples,2) > 1
    MyData = fread(fid, [Nchan Files.Samples(1)], '*int16');
    for nextfile = 2:size(Files.Samples,2)
        MyData_temp = fread(fid, [Nchan Files.Samples(nextfile)], '*int16');
        keyboard; % for channel remapping
        % MyData_temp = circshift(MyData_temp,2,1);
        MyData = [MyData MyData_temp];
    end
else
    MyData = fread(fid, [Nchan SamplesPerChan], '*int16');
end
fclose(fid);

%% process thermistor
% convert to volts
%Therm_OEPS = double(MyData(3,:)')*VoltMultiplier;
Therm_OEPS = double(MyData(3,:)')*(VoltMultiplier/2) + 2.5;

clear MyData
timestamps = (0:1:length(Therm_OEPS))'*(1/OEPSSamplingRate);
timestamps(end,:) = [];

% downsample to behavior resolution (500Hz)
SampleRate = 500;
RespirationData(:,1) = 0:1/SampleRate:max(timestamps);
RespirationData(:,2) = interp1q(timestamps,Therm_OEPS,RespirationData(:,1)); % thermistor

%% get sniff timestamps
[SniffTS, RespirationData] = ProcessThermistorData(RespirationData);

% make a digital sniff trace
TraceTS = RespirationData(:,1);
DigitalSniffs = TraceTS*0;
for n = 1:size(SniffTS,1)
    idx(1) = find(TraceTS>=SniffTS(n,1),1,'first');
    idx(2) = find(TraceTS> SniffTS(n,2),1,'first') - 1;
    DigitalSniffs(idx(1):idx(2)) = 1;
end

%% make the equivalet of AllSniffs as in LeverTaskAnalysis (GetAllSniffs.m)
% Sniff Onsets and Offsets
AllSniffs = find(diff(abs(DigitalSniffs)));
AllSniffs = reshape(AllSniffs,2,[])';
AllSniffs(:,1) = AllSniffs(:,1) +  1;
AllSniffs(1:end-1,3) = AllSniffs(2:end,1); % next inhalation index
AllSniffs(end,:) = [];
AllSniffs(:,11:13) = AllSniffs(:,1:3); % keep the indices
AllSniffs(:,1:2) = TraceTS(AllSniffs(:,1:2));
AllSniffs(:,3) = AllSniffs(:,2) - AllSniffs(:,1);

end