%function [] = MatchUnits()

% which sessions to compare
myKsDir{1} = '/mnt/data/Sorted/Q5/2022-11-22_16-21-07_filt_CAR';
myKsDir{2} = '/mnt/data/Sorted/Q5/2022-11-22_16-21-07';

% get units and their attributes
%[Sessions] = GetSingleUnits_forMatching(myKsDir);

%Attributes: [cluster_ID ch tetrode amp fr fractionRPV ISIViolations n_spikes]

MatchedUnits = [];
count = 0;

for TTs = 1:10
    channels = (TTs-1)*4 + (0:1:3);
    
    %1. find all units on this tetrodes
    RefUnits = find(ismember(Sessions.Session1.UnitAttributes(:,2),channels));
    
    if ~isempty(RefUnits)
        %2. get waveforms
        RefWaveforms = Sessions.Session1.MeanWaveForms(RefUnits,:)';
        
        %3. find all units on the other session on this particular tetrode
            % and get waveforms
        whichUnits = find(ismember(Sessions.Session2.UnitAttributes(:,2),channels));
        MatchWaveforms = Sessions.Session2.MeanWaveForms(whichUnits,:)';
        
        %4. get correlations
        %4a. between Waveforms 
        WV = [RefWaveforms MatchWaveforms];
        R1 = corrcoef(WV);
        
        %4b. between ISI dists 
        R2 = corrcoef( [Sessions.Session1.distISI(RefUnits,:)' ...
                Sessions.Session2.distISI(whichUnits,:)']);
            
        %4c. and correlograms
        R3 = corrcoef( [Sessions.Session1.Correlogram(RefUnits,:)' ...
                Sessions.Session2.Correlogram(whichUnits,:)']);
        
        clear Matches
        for i = 1:numel(RefUnits)
            % sort the units on session 2 by correlation with mean waveforms
            myCorrs     = R1((numel(RefUnits)+1):end,i);
            myRMS       = sqrt(mean((MatchWaveforms - RefWaveforms(:,i)).^2))';
            ISIcorrs    = R2((numel(RefUnits)+1):end,i);
            CGMcorrs    = R3((numel(RefUnits)+1):end,i);
            
            [~,BestMatches] = sortrows(...
                [(1-myCorrs).*myRMS 1-CGMcorrs 1-ISIcorrs],...
                [1 2 3],'ascend');
            
            Matches(:,:,i) = [BestMatches myCorrs(BestMatches) ...
                myRMS(BestMatches) ISIcorrs(BestMatches) CGMcorrs(BestMatches)];
        
        % get a unique match
        for i = 1:numel(RefUnits)
            % does the best match have waveform correlation higher 0.9?
            if Matches(1,2,i)>=0.9
                % any competition?
                foo = find(squeeze(Matches(1,1,i+1:end))==Matches(1,1,i)) + 1;
                % does the second best match also have a high correlation
                if Matches(2,2,i)>=0.9
                else
                    % very likely the current best match is a good match
                end
            end
        end
        
    end

end



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