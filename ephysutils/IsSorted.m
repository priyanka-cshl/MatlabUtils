function [Sortflag, Filepath] = IsSorted(AnimalName,varargin)

%% parse input arguments
defaultdate = '2021-10-06';
defaulttimestamp = '';

narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('date',defaultdate,@ischar);
params.addParameter('timestamp',defaulttimestamp,@ischar);

% extract values from the inputParser
params.parse(varargin{:});
whichdate = params.Results.date;
whichtime = params.Results.timestamp;

Filepath = []; Sortflag = 0;
if isempty(whichtime)
    NameString = [whichdate,'*'];
else
    NameString = [whichdate,'_',whichtime];
end

% where to look
Paths = WhichComputer();
if ~isempty(dir([Paths.Grid.Ephys_processed,filesep,AnimalName,filesep,NameString])) % on the server
    Sortflag = 1;
    Filepath = dir([Paths.Grid.Ephys_processed,filesep,AnimalName,filesep,NameString]);
elseif ~isempty(dir([Paths.Local.Ephys_processed,filesep,AnimalName,filesep,NameString])) % on the local drive
    Sortflag = 1;
    Filepath = dir([Paths.Local.Ephys_processed,filesep,AnimalName,filesep,NameString]);
end

