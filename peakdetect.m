function pk = peakdetect(data,threshold)
%PEAKDETECT   Detect peak positions above a threshold.
%   PK = PEAKDETECT(DATA,THRESHOLD) determines segments of consecutive
%   data points above THRESHOLD and returns peak positions within these
%   segments.
%
%   See also CENSOR and CUTSPIKE.

%   Balazs Hangya, TENSS 2016
%   hangya.balazs@koki.mta.hu

% Detect data segments that are above threshold
datacomp = data > threshold;
dd = diff([0 datacomp 0]);   % threshold crossings; avoid broken segments
st = find(dd==1);   % segment start points
nd = find(dd==-1) - 1;  % segment end points
numSeg = length(st);   % number of segments

% Peak detection by segment
pk = nan(1,numSeg);
for iS = 1:numSeg
    [~, mxloc] = max(data(st(iS):nd(iS)));
    pk(iS) = st(iS) + mxloc - 1;   % peak positions
end