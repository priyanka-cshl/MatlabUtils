function [] = PlotRaster_v2(spiketimes,rowIdx,linecolor,varargin)

narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;
params.addParameter('tickwidth', 0.5, @(x) isnumeric(x));
params.addParameter('ticklength', 1, @(x) isnumeric(x));

% extract values from the inputParser
params.parse(varargin{:});
tickwidth = params.Results.tickwidth;
ticklength = params.Results.ticklength;

X = [repmat(spiketimes(:),1,2) NaN*ones(numel(spiketimes),1)]';
Y = repmat(rowIdx+[-ticklength 0 0],numel(spiketimes),1)';
plot(X(:),Y(:),'Color',linecolor, 'Linewidth', tickwidth);
%line(X,Y,'Color',linecolor);
end