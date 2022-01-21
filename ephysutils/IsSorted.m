function [Sortflag, Filepath] = IsSorted(AnimalName, whichdate, whichtime)

if nargin<3
    whichtime = [];
end

Filepath = []; Sortflag = 0;
if isempty(whichtime)
    NameString = [whichdate,'*'];
else
    NameString = [whichdate,'_',whichtime];
end

% where to look
Paths = WhichComputer();
if ~isempty(dir([Paths.Grid.Ephys_processed,filesep,AnimalName,filesep,NameString])) % on the server
    Sortflag = -1;
    Filepath = dir([Paths.Grid.Ephys_processed,filesep,AnimalName,filesep,NameString]);
elseif ~isempty(dir([Paths.Local.Ephys_processed,filesep,AnimalName,filesep,NameString])) % on the local drive
    Sortflag = -2;
    Filepath = dir([Paths.Local.Ephys_processed,filesep,AnimalName,filesep,NameString]);
end

% check if it has been through phy
if ~isempty(dir([fullfile(Filepath.folder,Filepath.name),filesep,'*.*sv']))
    Sortflag = abs(Sortflag);
end
