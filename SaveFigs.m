function [] = SaveFigs(FileName, FigureHandle)
if nargin<2
    FigureHandle = gcf;
end
[~,FileNameNoExt,ext] = fileparts(FileName);
if isempty(ext)
    ext = 'pdf';
end

set(FigureHandle,'renderer','Painters');
%print(FileName,'-depsc','-tiff','-r300','-painters');
saveas(FigureHandle, FileNameNoExt, ext);
end