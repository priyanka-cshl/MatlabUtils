function [T tvec]=PechePourPoisson(rate,dt)
% Rate-Varying Poisson-Process generator.
% 
% T=PechePourPoisson(rate);
% T=PechePourPoisson(rate,dt);
% [T tvec]=PechePourPoisson(rate,dt);
%
% Example:
% rate=conv(randn(1,10000),ones(1,1000),'same'); 
% [T t]=PechePourPoisson(rate,.001);
% plot(t,rate); 
% addline(T); addline(0,'h'); % You may not have the addline function
%
% This function spits out a poisson process with a rate that can vary with
% time.  Each sample of the "rate" vector is considered to be the beginning
% of a time bin of width dt.  The number of events occurring in each bin is
% sampled from a Poisson Distribution.  The timing of each event within the
% bin is then randomized.
%
% Note: You can easily specify a constant-rate process running for a
% certain time by just making "rate" a scalar rate and setting dt to your
% desired time span.
%
% Inputs    Description
% "rate"    Vector representing the rate as a function of time.  Negative
%           rates are interpreted as zero rates.
% ("dt")    Optional scalar defining the time resolution of the rate
%           vector.  If neglected, dt=1, and the rate is interpreted as
%           meaning "events per time-sample".  If dt is set, rate will be
%           scaled by the value of dt.  eg, say you want 90events/s, where
%           the rate vector represents the spiking rate as a function of 
%           time with millisecond resolution.  Then dt=0.001, and 
%           rate(i)=90, where i is the particular instant with a 90event/s 
%           rate.
%
% Outputs   Description
% "T"       Vector of event times.  The first sample of "rate" is 
%           considered to be time 0.  If dt is specified, times will be
%           scaled accordingly.
% "tvec"    If you're too lazy to make your own time vector for your rate
%           vector, this function can optionally do it for you.
%
% Enjoy
% Peter
% oconnorp _at_ ethz _dot_ ch

% dt defaults to 1
if nargin<2, dt=1; end

% Determine number of events in each time bin
p=poissrnd(max(rate(:),0)'*dt);

% Find the times of non-empty bins
ix=find(p);
adds=diff([0 ix-1]);
cum=cumsum([1 p(ix)]);

% Term is same as sum(p(ix)), just avoids repeating calculation
T=zeros(cum(end)-1,1); 
T(cum(1:end-1))=adds;
six=find(~T);
T=cumsum(T);

% Sort the randoms (skipping bins with just 1 spike obviously to save time,
% thought the time taken by the interpreter to parse out this comment is
% probably even more than that, but I guess its the priniple that counts.)
T=T+rand(size(T));
sortable=sort([six(diff([0; six])>1)-1; six]);
T(sortable)=sort(T(sortable)); 
% Efficiency of this last chunk could definitely be improved but really I 
% don't care enough to do it now.

% Scale times
if dt~=1, T=T*dt; end

% For the lazy...
if nargout>1
   tvec=0:dt:(length(rate)-1)*dt;
end

end