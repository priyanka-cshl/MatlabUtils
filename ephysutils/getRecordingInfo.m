function info = getRecordingInfo(recordNodeDir)
% GETRECORDINGINFO  Extract recording metadata from an Open Ephys Record Node directory.
%
% Supports the following known GUI versions and formats:
%   0.5.3.1  OpenEphys  Continuous_Data.openephys  channel map post-record
%   0.5.5.3  OpenEphys  Continuous_Data.openephys  channel map pre-record
%   0.5.5.4  Binary     structure.oebin            ADC channels named CHxx
%   0.6.1    Binary     structure.oebin            ADC channels named ADCx
%   0.6.2    OpenEphys  structure.openephys        channel map in CUSTOM_PARAMETERS
%
% If an unrecognised GUI version is encountered, a warning is issued and
% the function attempts to continue using best-guess logic. Check outputs
% carefully in that case.
%
% USAGE:
%   info = getRecordingInfo('/path/to/Record Node 102')   % v0.6.x
%   info = getRecordingInfo('/path/to/session/folder')    % v0.5.x
%
% OUTPUT STRUCT FIELDS:
%   info.guiVersion            - GUI version string
%   info.machineName           - recording computer name
%   info.machineOS             - OS string (empty in v0.5.x)
%   info.recordingDate         - date string
%   info.format                - 'OpenEphys' or 'Binary'
%   info.sampleRate            - samples per second
%   info.startSample           - first sample number (OpenEphys only; NaN for Binary)
%
%   info.ephysFiles            - channel map ordered filenames (OpenEphys) or
%                                folder name (Binary)
%   info.ephysNames            - channel names in same order
%   info.ephysBitVolts         - conversion factors
%   info.nEphys                - number of ephys channels
%
%   info.auxFiles              - ADC filenames (OpenEphys) or folder name (Binary)
%   info.auxNames              - aux channel names
%   info.auxBitVolts           - conversion factors
%   info.nAux                  - number of aux channels
%
%   info.eventFiles            - event file/folder paths
%   info.nEvents               - number of event sources
%
%   info.channelMapApplied     - 0: none, 1: pre-record, 2: post-record (OpenEphys only)
%   info.channelMapNodeId      - node ID of channel map processor
%   info.channelMapOrder       - mapping indices in signal chain order
%   info.channelMapOrderCH     - same as 1-based CH numbers
%   info.recordNodeId          - node ID of the Record Node

% Known GUI versions
KNOWN_VERSIONS = {'0.5.3.1', '0.5.5.3', '0.5.5.4', '0.6.1', '0.6.2'};

% -------------------------------------------------------------------------
% 1. Find and parse settings.xml
% -------------------------------------------------------------------------

settingsFile = fullfile(recordNodeDir, 'settings.xml');
if ~exist(settingsFile, 'file')
    error('settings.xml not found in %s', recordNodeDir);
end

xml = readstruct(settingsFile, 'FileType', 'xml');

info.guiVersion = xml.INFO.VERSION;

% --- Check known versions ---
if ~any(strcmp(info.guiVersion, KNOWN_VERSIONS))
    warning('getRecordingInfo:unknownVersion', ...
        'GUI version %s has not been validated. Outputs may be incorrect - check carefully.', ...
        info.guiVersion);
end

% --- Version flags ---
guiMinor    = str2double(regexp(info.guiVersion, '(?<=^\d+\.)\d+', 'match', 'once'));
isOldFormat = guiMinor < 6;  % v0.5.x vs v0.6.x

% --- Machine info ---
if isOldFormat
    info.machineName = xml.INFO.MACHINE;
    info.machineOS   = '';
else
    info.machineName = xml.INFO.MACHINE.nameAttribute;
    info.machineOS   = xml.INFO.OS;
end
info.recordingDate = xml.INFO.DATE;

% -------------------------------------------------------------------------
% 2. Detect format from which structure file exists
%    Binary: look in recordNodeDir, then 2 levels deep (experiment*/recording*)
%    OpenEphys: look in recordNodeDir only
% -------------------------------------------------------------------------

% Check for binary structure file - first in dir, then 2 subfolders deep
oebinFiles = dir(fullfile(recordNodeDir, 'structure.oebin'));
if isempty(oebinFiles)
    oebinFiles = dir(fullfile(recordNodeDir, 'experiment*', 'recording*', 'structure.oebin'));
end

hasBinary      = ~isempty(oebinFiles);
hasOEStructure = ~isempty(dir(fullfile(recordNodeDir, 'structure*.openephys')));
hasOELegacy    = ~isempty(dir(fullfile(recordNodeDir, 'Continuous_Data*.openephys')));

if hasBinary
    info.format = 'Binary';
    if length(oebinFiles) > 1
        warning('getRecordingInfo:multipleRecordings', ...
            'Multiple structure.oebin files found - using first one (%s). Pass full path to recording dir for specific recording.', ...
            fullfile(oebinFiles(1).folder, oebinFiles(1).name));
    end
    oebinDir = oebinFiles(1).folder;  % actual dir containing structure.oebin
elseif hasOEStructure || hasOELegacy
    info.format = 'OpenEphys';
    oebinDir    = [];
else
    error('getRecordingInfo:unknownFormat', ...
        'No recognised structure file found in %s', recordNodeDir);
end

% -------------------------------------------------------------------------
% 3. Format-specific parsing
% -------------------------------------------------------------------------

if strcmp(info.format, 'Binary')
    info = parseBinary(info, oebinDir, isOldFormat);
else
    info = parseOpenEphys(info, xml, recordNodeDir, isOldFormat, hasOELegacy);
end

end

% =========================================================================
% BINARY FORMAT PARSER
% =========================================================================
function info = parseBinary(info, recordNodeDir, isOldFormat)

    % Initialise channel map fields (not extracted for binary)
    info.channelMapApplied = 0;
    info.channelMapNodeId  = [];
    info.channelMapOrder   = [];
    info.channelMapOrderCH = [];
    info.recordNodeId      = [];
    info.startSample       = NaN;  % use timestamps.npy instead

    oebinFile = fullfile(recordNodeDir, 'structure.oebin');
    fid = fopen(oebinFile, 'r');
    raw = fread(fid, inf, 'char=>char')';
    fclose(fid);
    oebin = jsondecode(raw);

    stream        = oebin.continuous(1);
    info.sampleRate  = stream.sample_rate;
    info.folderName  = stream.folder_name;  % path to continuous.dat

    ephysNames    = {};
    ephysBitVolts = [];
    auxNames      = {};
    auxBitVolts   = [];

    for i = 1:length(stream.channels)
        ch   = stream.channels(i);
        name = ch.channel_name;
        bv   = ch.bit_volts;

        % v0.5.5.4: ADC channels named CHxx with description 'ADC data channel'
        % v0.6.1:   ADC channels named ADCx
        isADC = startsWith(name, 'ADC') || ...
                (isOldFormat && contains(ch.description, 'ADC', 'IgnoreCase', true));

        if isADC
            auxNames{end+1}    = name; %#ok<AGROW>
            auxBitVolts(end+1) = bv;   %#ok<AGROW>
        else
            ephysNames{end+1}    = name; %#ok<AGROW>
            ephysBitVolts(end+1) = bv;   %#ok<AGROW>
        end
    end

    % For binary, all channels share one continuous.dat — return folder
    info.ephysFiles    = {stream.folder_name};
    info.ephysNames    = ephysNames;
    info.ephysBitVolts = ephysBitVolts;
    info.nEphys        = length(ephysNames);

    info.auxFiles    = {stream.folder_name};  % same folder, different indices
    info.auxNames    = auxNames;
    info.auxBitVolts = auxBitVolts;
    info.nAux        = length(auxNames);

    % Events: return folder names, exclude message center
    info.eventFiles = {};
    for i = 1:length(oebin.events)
        ev = oebin.events(i);
        if ~contains(ev.folder_name, 'Message', 'IgnoreCase', true) && ...
           ~contains(ev.folder_name, 'TEXT', 'IgnoreCase', true)
            info.eventFiles{end+1} = fullfile(recordNodeDir, ev.folder_name); %#ok<AGROW>
        end
    end
    info.nEvents = length(info.eventFiles);

end

% =========================================================================
% OPEN EPHYS FORMAT PARSER
% =========================================================================
function info = parseOpenEphys(info, xml, recordNodeDir, isOldFormat, hasOELegacy)

    % --- Signal chain: find Record Node and Channel Map ---
    processors = xml.SIGNALCHAIN.PROCESSOR;

    recordNodeIdx  = -1;
    preMapIdx      = -1;
    postMapIdx     = -1;
    info.recordNodeId      = [];
    info.channelMapApplied = 0;
    info.channelMapNodeId  = [];
    info.channelMapOrder   = [];
    info.channelMapOrderCH = [];

    for i = 1:length(processors)
        p     = processors(i);
        pname = p.nameAttribute;

        if isOldFormat
            nodeId = p.NodeIdAttribute;
        else
            nodeId = p.nodeIdAttribute;
        end

        if contains(pname, 'Record Node', 'IgnoreCase', true)
            recordNodeIdx     = i;
            info.recordNodeId = nodeId;
        end

        if contains(pname, 'Channel Map', 'IgnoreCase', true) || ...
           contains(pname, 'Channel Mapping', 'IgnoreCase', true)
            if recordNodeIdx == -1
                preMapIdx  = i;
            else
                postMapIdx = i;
            end
        end
    end

    % Priority: pre-record map wins
    if preMapIdx > 0
        activeMapIdx           = preMapIdx;
        info.channelMapApplied = 1;
    elseif postMapIdx > 0
        activeMapIdx           = postMapIdx;
        info.channelMapApplied = 2;
    else
        activeMapIdx = -1;
    end

    % --- Extract channel map order ---
    if activeMapIdx > 0
        p = processors(activeMapIdx);

        if isOldFormat
            info.channelMapNodeId = p.NodeIdAttribute;
            chNodes = p.EDITOR.CHANNEL;
            enabledMappings = [];
            for j = 1:length(chNodes)
                if chNodes(j).EnabledAttribute == 1
                    enabledMappings(end+1) = chNodes(j).MappingAttribute; %#ok<AGROW>
                end
            end
            info.channelMapOrder   = enabledMappings;
            info.channelMapOrderCH = enabledMappings;
        else
            info.channelMapNodeId = p.nodeIdAttribute;
            chNodes = p.CUSTOM_PARAMETERS.STREAM.CH;
            enabledIndices = [];
            for j = 1:length(chNodes)
                if chNodes(j).enabledAttribute == 1
                    enabledIndices(end+1) = chNodes(j).indexAttribute; %#ok<AGROW>
                end
            end
            info.channelMapOrder   = enabledIndices;
            info.channelMapOrderCH = enabledIndices + 1;
        end
    end

    % --- Parse structure file ---
    if hasOELegacy
        % v0.5.x: Continuous_Data.openephys
        structFiles     = dir(fullfile(recordNodeDir, 'Continuous_Data*.openephys'));
        structFile      = fullfile(recordNodeDir, structFiles(1).name);
        sxml            = readstruct(structFile, 'FileType', 'xml');
        info.sampleRate = sxml.RECORDING.samplerateAttribute;
        channels        = sxml.RECORDING.PROCESSOR.CHANNEL;
    else
        % v0.6.x: structure.openephys
        structFiles     = dir(fullfile(recordNodeDir, 'structure*.openephys'));
        structFile      = fullfile(recordNodeDir, structFiles(1).name);
        sxml            = readstruct(structFile, 'FileType', 'xml');
        info.sampleRate = sxml.RECORDING(1).STREAM.sample_rateAttribute;
        channels        = sxml.RECORDING(1).STREAM.CHANNEL;
    end

    % --- Separate ephys vs aux ---
    ephysFiles    = {};
    ephysNames    = {};
    ephysBitVolts = [];
    auxFiles      = {};
    auxNames      = {};
    auxBitVolts   = [];

    for i = 1:length(channels)
        ch    = channels(i);
        name  = ch.nameAttribute;
        fname = ch.filenameAttribute;
        bv    = ch.bitVoltsAttribute;

        if startsWith(name, 'ADC')
            auxFiles{end+1}    = fname; %#ok<AGROW>
            auxNames{end+1}    = name;  %#ok<AGROW>
            auxBitVolts(end+1) = bv;    %#ok<AGROW>
        else
            ephysFiles{end+1}    = fname; %#ok<AGROW>
            ephysNames{end+1}    = name;  %#ok<AGROW>
            ephysBitVolts(end+1) = bv;    %#ok<AGROW>
        end
    end

    info.ephysFiles    = ephysFiles;
    info.ephysNames    = ephysNames;
    info.ephysBitVolts = ephysBitVolts;
    info.nEphys        = length(ephysFiles);

    info.auxFiles    = auxFiles;
    info.auxNames    = auxNames;
    info.auxBitVolts = auxBitVolts;
    info.nAux        = length(auxFiles);

    % --- Event files ---
    eventFilePaths = dir(fullfile(recordNodeDir, '*.events'));
    isTTL          = ~cellfun(@(x) contains(x, 'messages'), {eventFilePaths.name});
    ttlEventFiles  = eventFilePaths(isTTL);

    info.eventFiles = cellfun(@(d,n) fullfile(d,n), ...
        {ttlEventFiles.folder}, {ttlEventFiles.name}, 'UniformOutput', false);
    info.nEvents = length(info.eventFiles);

    % --- Start sample ---
    NUM_HEADER_BYTES   = 1024;
    SAMPLES_PER_RECORD = 1024;
    RECORD_MARKER_SIZE = 10;
    recordSize = 4 + 8 + SAMPLES_PER_RECORD * 2 + RECORD_MARKER_SIZE; %#ok<NASGU>

    firstFile = fullfile(recordNodeDir, info.ephysFiles{1});
    tsMap     = memmapfile(firstFile, 'Writable', false, 'Format', 'int64', ...
                           'Offset', NUM_HEADER_BYTES, 'Repeat', 1);
    info.startSample = tsMap.Data(1);

end
