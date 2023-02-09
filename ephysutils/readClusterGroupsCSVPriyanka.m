

function [cids, cgs, wires] = readClusterGroupsCSVPriyanka(filename)
%function [cids, cgs] = readClusterGroupsCSV(filename)
% cids is length nClusters, the cluster ID numbers
% cgs is length nClusters, the "cluster group":
% - 0 = noise
% - 1 = mua
% - 2 = good
% - 3 = unsorted

fid = fopen(filename);
C = textscan(fid, '%s%s');
fclose(fid);

cids = cellfun(@str2num, C{1}(2:end), 'uni', false);
ise = cellfun(@isempty, cids);
cids = [cids{~ise}];

isUns = cellfun(@(x)strcmp(x,'unsorted'),C{2}(2:end));
isMUA = cellfun(@(x)strcmp(x,'mua'),C{2}(2:end));
isGood = cellfun(@(x)strcmp(x,'good'),C{2}(2:end));
cgs = zeros(size(cids));

cgs(isMUA) = 1;
cgs(isGood) = 2;
cgs(isUns) = 3;

% also read which wire it was strongest on
fid = fopen(regexprep(filename,'_group','_info'));



% N = 8;
% N = numel(regexp(headers,'\t'))+1; % no. of columns
headers = fgetl(fid);
%formatSpec = '%s';
%headers = textscan(fid,formatSpec,N);

foo = textscan(fid,'%f %f %f %*[^\n]');
wires = [cell2mat(foo(1)) cell2mat(foo(3))];
fclose(fid);