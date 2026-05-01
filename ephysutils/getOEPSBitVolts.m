function [] = getOEPSBitVolts(myKsDir)

load(fullfile(myKsDir,'SessionDetails.mat')); % loads Files

% data path
if ~isempty(dir(fullfile(Files.name,'*_ADC*')))
    Allfiles = dir(fullfile(Files.name,'*_ADC*'));
    for i = 1:size(Allfiles,1)
        filename = fullfile(Files.name,Allfiles(i).name);
        fid = fopen(filename);
        NUM_HEADER_BYTES = 1024;
        fseek(fid,0,'bof');
        hdr = fread(fid, NUM_HEADER_BYTES, 'char*1');
        eval(char(hdr'));
        info.header = header;
        fclose(fid);
        bitVolts(i) = info.header.bitVolts;
    end
    if ~any((bitVolts-mean(bitVolts))>0.00001)
        Files.AuxBitVolts(1) = mean(bitVolts);
    else
        keyboard;
    end
    save(fullfile(myKsDir,'SessionDetails.mat'),'Files','-append');
else
    keyboard;
end

end