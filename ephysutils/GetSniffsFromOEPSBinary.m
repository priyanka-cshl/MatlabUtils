function [SniffTS, RespirationData] = GetSniffsFromOEPSBinary(myDir,thermistorCh)

if nargin<2
    thermistorCh = 3; % 3rd ADC channel
    plotting = 0;
else
    plotting = 1;
end
thermistorCh = 8 - thermistorCh;

addpath(genpath('/opt/open-ephys-matlab-tools')) % path to new open ephys data handling scripts
OEPSSamplingRate = 30000;

% read the open ephys binary file
session = Session(myDir);
SamplesPerChan = size(session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps,1);

% get Events if needed
Events = session.recordNodes{1}.recordings{1}.ttlEvents('Acquisition_Board-100.Rhythm Data');

% thermistor is on the 3rd ADC channels, there are 8 ADCs stacked at the
% recording
VoltMultiplier = session.recordNodes{1}.recordings{1}.info.continuous.channels(end-thermistorCh).bit_volts;
Therm_OEPS = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').samples(end-thermistorCh,:);
% convert to volts
Therm_OEPS = double(Therm_OEPS')*VoltMultiplier;
%Therm_OEPS = double(Therm_OEPS')*(VoltMultiplier/2) + 2.5;

timestamps = (0:1:length(Therm_OEPS))'*(1/OEPSSamplingRate);
timestamps(end,:) = [];

% downsample to behavior resolution (500Hz)
SampleRate = 500;
RespirationData(:,1) = 0:1/SampleRate:max(timestamps);
RespirationData(:,2) = interp1q(timestamps,Therm_OEPS,RespirationData(:,1)); % thermistor

%% get sniff timestamps
[SniffTS, RespirationData] = ProcessThermistorData(RespirationData,plotting);

end