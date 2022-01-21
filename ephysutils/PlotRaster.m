function [] = PlotRaster(spiketimes,rowIdx,linecolor,ticklength)
if nargin<4
    ticklength = 1;
end
    X = [repmat(spiketimes(:),1,2) NaN*ones(numel(spiketimes),1)]';
    Y = repmat(rowIdx+[-ticklength 0 0],numel(spiketimes),1)';
    plot(X(:),Y(:),'Color',linecolor);
    %line(X,Y,'Color',linecolor);
end