%function [] = MatchUnits()

% which sessions to compare
myKsDir{1} = '/mnt/data/Sorted/Q8/2003-12-04_22-40-13';
myKsDir{2} = '/mnt/data/Sorted/Q8/2002-12-04_22-40-13';

% get units and their attributes
%[Sessions] = GetSingleUnits_forMatching(myKsDir);

%Attributes: [cluster_ID ch tetrode amp fr fractionRPV ISIViolations n_spikes]

MatchedUnits = [];
count = 0;
figure;
for channels = 1:40
    % find matches: lets go tetrode by  tetrode
    whichChannel = channels-1; % 0 indexed
    
    %1. find all units on this channel
    RefUnits = find(Sessions.Session1.UnitAttributes(:,2)==whichChannel);
    
    if ~isempty(RefUnits)
        whichTetrode = floor(Sessions.Session1.UnitAttributes(RefUnits(1),3));
        RefWaveforms = Sessions.Session1.MeanWaveForms(RefUnits,:)';
        
        % find all units on the other session on this particular tetrode
        whichUnits = find(floor(Sessions.Session2.UnitAttributes(:,3))==whichTetrode);
        MatchWaveforms = Sessions.Session2.MeanWaveForms(whichUnits,:)';
        
        WV = [RefWaveforms MatchWaveforms];
        R = corrcoef(WV);

        for i = 1:numel(RefUnits)
            % sort the units on session 2 by correlation with mean waveforms
            myCorrs = R((numel(RefUnits)+1):end,i);
            myRMS = sqrt(mean((MatchWaveforms - RefWaveforms(:,i)).^2))';
            
            %[~,BestMatches] = sort(myCorrs,'descend');
            %[sorted, BestMatches] = sortrows([1-myCorrs myRMS],[2 1],'ascend');
            [~,BestMatches] = sort((1-myCorrs).*myRMS,'ascend');
            
            % also calculate the correlation between ISI dists and correlograms
            ISIcorr = min(unique( corrcoef( [Sessions.Session1.distISI(RefUnits(i),:)' ...
                Sessions.Session2.distISI(whichUnits(BestMatches(1)),:)']) ) );
            
            Corrcorr = min(unique( corrcoef( [Sessions.Session1.Correlogram(RefUnits(i),:)' ...
                Sessions.Session2.Correlogram(whichUnits(BestMatches(1)),:)']) ) );
            
            count = count + 1;
            MatchedUnits(count,:) = [Sessions.Session1.UnitAttributes(RefUnits(i),1) ...
                Sessions.Session2.UnitAttributes(whichUnits(BestMatches(1)),1) ...
                myCorrs(BestMatches(1)) myRMS(BestMatches(1)) ...
                ISIcorr Corrcorr];
            
            whichplot = rem(count,8);
            if ~whichplot
                whichplot = 8;
            end
            subplot(8,3,(whichplot*3)-2);
            plot(RefWaveforms(:,i),'k');
            hold on
            plot(MatchWaveforms(:,BestMatches(1)),'r');
            set(gca,'XLim',[0 328], 'XTick', []);
            title([num2str(MatchedUnits(count,1)),':',num2str(MatchedUnits(count,2)),...
                ' ',num2str(MatchedUnits(count,3)),' ',num2str(MatchedUnits(count,4))]);
            
            subplot(8,3,(whichplot*3)-1);
            plot(Sessions.Session1.distISI(RefUnits(i),:)','k');
            hold on
            plot(Sessions.Session2.distISI(whichUnits(BestMatches(1)),:)','r');
            title(num2str(MatchedUnits(count,5)))
            set(gca,'XLim',[0 50], 'XTick', []);
            
            subplot(8,3,(whichplot*3));
            plot(Sessions.Session1.Correlogram(RefUnits(i),:)','k');
            hold on
            plot(Sessions.Session2.Correlogram(whichUnits(BestMatches(1)),:)','r');
            title(num2str(MatchedUnits(count,6)))
            set(gca,'XLim',[0 100], 'XTick', []);
            
            
            if whichplot == 8
                figure;
            end
        end
    end
end
%end