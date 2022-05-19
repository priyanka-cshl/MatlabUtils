function [MyData] = GetAuxFromOEPSBinary(totalChans,whichChan)

[MyFile,MyPath] = uigetfile('*.dat');

% read the open ephys binary file
fid         = fopen(fullfile(MyPath,MyFile), 'r');
NchanTOT    = totalChans;

% from Kilosort
ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection		
ops.NT                  = 32*1024+ ops.ntbuff;% 

NT          = ops.NT ;
NTbuff      = NT + 4*ops.ntbuff;
ibatch = 0;
nsamps = 0;
nBlocks = 1;

tic
MyData = [];
for k = 1:nBlocks
    while 1
        ibatch = ibatch + 1;
        
        offset = max(0, 2*NchanTOT*((NT - ops.ntbuff) * (ibatch-1) - 2*ops.ntbuff));
        
        fseek(fid, offset, 'bof');
        samples = fread(fid, [NchanTOT NTbuff], '*int16');
        
        if isempty(samples)
            break;
        end
        
        nsampcurr = size(samples,2);
        if nsampcurr<NTbuff
            samples(:, nsampcurr+1:NTbuff) = repmat(samples(:,nsampcurr), 1, NTbuff-nsampcurr);
        end
                
        % delete the spike channels
        MyData = horzcat(MyData,samples(whichChan,:));

    end

end

fclose(fid);

X = 1:size(MyData,2);
Xq = 32:32:X(end); % to downsample from 32Khz to 1 Khz
MyData = interp1(X',single(MyData'),Xq');

toc

