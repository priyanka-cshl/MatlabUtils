function [handle] = MyShadedErrorBar(x,y,error,whichcolor,LineProps,MyAlpha)
%plot shaded error bars such that matlab can export them as vector graphics
%   Detailed explanation goes here
if nargin<3
    disp('insufficient inputs');
    return;
elseif nargin<4
    whichcolor = 'k';
    LineProps = {'EdgeColor','none'};
    MyAlpha = 1;
elseif nargin<5
    LineProps = {'EdgeColor','none'};
    MyAlpha = 1;
elseif nargin<6
    MyAlpha = 1;
end

if isempty(LineProps)
    LineProps = {'EdgeColor','none'};
end

x_values = [x fliplr(x)];
y_values = [y+error fliplr(y-error)];

% remove NaNs
x_values(:,find(isnan(y_values))) = [];
y_values(:,find(isnan(y_values))) = [];

handle.errorbar = fill(x_values,y_values,whichcolor,LineProps{:},'FaceAlpha',MyAlpha);
hold on
handle.mean = plot(x,y,whichcolor);
end

