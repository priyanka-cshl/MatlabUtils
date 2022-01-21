function [] = fig2eps(FileName, FigureHandle)
if nargin<2
    FigureHandle = gcf;
end
[~,~,ext] = fileparts(FileName);
if isempty(ext)
    FileName = [FileName,'.eps'];
end

set(FigureHandle,'renderer','Painters');
print(FileName,'-depsc','-tiff','-r300','-painters');

end