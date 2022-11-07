function [] = GetPhotometryData(myephysdir)

%% Read Photoreceivers and LEDs data from open ephys file
[modData_1, Timestamps_PR_1, info_PR_1]  = load_open_ephys_data(fullfile(myephysdir,'100_ADC3.continuous'));
[modLED_1, Timestamps_LED_1, info_LED_1] = load_open_ephys_data(fullfile(myephysdir,'100_ADC5.continuous'));

%% Constants
modFreq_1          = 211;       
modAmp_1           = 0.6;
samplingRate       = info_PR_1.header.sampleRate;
lowCutoff          = 15;

%% Prepare reference data and generate 90deg shifted reference data
   
shift_modLED_1     = modLED_1 - mean(modLED_1);                            % Remove DC offset
samplesPerPeriod   = (samplingRate/modFreq_1);
quarterPeriod      = round(samplesPerPeriod/4);
shift_modLED90_1   = circshift(shift_modLED_1,[1 quarterPeriod]);

%% Quadrature decoding and filtering                                       % Element-by-element array multiplication 
   
processedData0_1    = modData_1 .* shift_modLED_1;                         % 0 degrees data correction                          
processedData90_1  = modData_1 .* shift_modLED90_1;                        % 90 degrees data correction 

%% Low pass filter
    
norm_lowCutoff     = lowCutoff/(samplingRate/2);                           % CutOff normalized by half sampling rate 
[b, a]             = butter(5, norm_lowCutoff,'low');                      % '5th order' butterworth low pass filter

paddedData0_1        = processedData0_1(1:samplingRate,1);             
paddedData90_1       = processedData90_1(1:samplingRate,1);
demodDataFilt0_1     = filtfilt(b,a,[paddedData0_1; processedData0_1]);    % pad the data to suppress windows effect upon filtering
demodDataFilt90_1    = filtfilt(b,a,[paddedData90_1; processedData90_1]);        
processedData0f_1    = demodDataFilt0_1(samplingRate + 1: end, 1);
processedData90f_1   = demodDataFilt90_1(samplingRate + 1: end, 1);
 
demodData_1          = (processedData0f_1 .^2 + processedData90f_1 .^2) .^(1/2);

%% Correct for amplitude of reference

demodDataC_1         = demodData_1*(2/modAmp_1);
     
meanF0               = mean(demodDataC_1);                                 % Mean value of baseline
medianF0             = median(demodDataC_1);                               % Median value of baseline
pc1F0                = prctile(demodDataC_1,1);                            % 1% percentile value of baseline 
pc5F0                = prctile(demodDataC_1,5);                            % 5% percentile value of baseline
pc10F0               = prctile(demodDataC_1,10);                           % 10% percentile value of baseline 
pc20F0               = prctile(demodDataC_1,20);                           % 20% percentile value of baseline
pc40F0               = prctile(demodDataC_1,40);                           % 40% percentile value of baseline 
pc80F0               = prctile(demodDataC_1,80);                           % 80% percentile value of baseline

%% F0 option
F0       = pc1F0;

%% Caclulate DFF
DFF                  = 100*((demodDataC_1-F0)/F0);

%% Get analog/digital AuxData from Oeps files - for comparison with behavior data
PhotometryData = [];
% adjust for clock offset between open ephys and kilosort
[offset] = AdjustClockOffset(myKsDir);
% adjust for clock offset between open ephys and kilosort
%timestamps = timestamps - offset; % for now timestamps is not right
Timestamps_LED_1 = Timestamps_LED_1 - offset; 

% downsample to behavior resolution
SampleRate = 500; % Samples/second

PhotometryData(:,1) = 0:1/SampleRate:max(Timestamps_LED_1); %timestamps based on behavior timestamps res
PhotometryData(:,2) = interp1q(Timestamps_LED_1,DFF,PhotometryData(:,1)); % DFF photometry signal with behavior timestamps res
end
