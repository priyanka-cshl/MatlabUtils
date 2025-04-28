function [] = read_myauxfile(myKsDir)

OEPSSamplingRate = 30000;

% load info from SessionDetails.mat
load(fullfile(myKsDir,'SessionDetails.mat'));


% get no. of channels etc from file size
X = dir(fullfile(myKsDir,'myauxfile.dat'));
SamplesPerChan = Files.Samples;
Nchan       = floor(X.bytes/2/SamplesPerChan);

offset = 0;
fid = fopen(fullfile(myKsDir,'myauxfile.dat'),'r');
fseek(fid, offset, 'bof');
MyData = fread(fid, [Nchan SamplesPerChan], '*int16');
fclose(fid);

%% process thermistor


end