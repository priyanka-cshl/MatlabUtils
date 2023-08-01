%function [] = MatchUnits_acrossSortingSessions()

% % which sessions to compare
% myKsDir{1} = '/mnt/data/Sorted/Q88/2022-12-07_16-57-14';
% myKsDir{2} = '/mnt/data/Sorted/Q88/2021-12-07_16-57-14';
% 
% % get units and their attributes
% %[Sessions] = GetSingleUnits_forMatching(myKsDir);

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
        WV = [RefWaveforms MatchWaveforms];
        R1 = corrcoef(WV);
        
        % append correlogram shapes and ISI dist shapes to the waveforms
        RefWaveforms = vertcat(RefWaveforms, ...
            Sessions.Session1.distISI(RefUnits,:)', ...
            Sessions.Session1.Correlogram(RefUnits,:)');
        MatchWaveforms = vertcat(MatchWaveforms, ...
            Sessions.Session2.distISI(whichUnits,:)', ...
            Sessions.Session2.Correlogram(whichUnits,:)');
        % get correlations for all three features combined
        WV = [RefWaveforms MatchWaveforms];
        R = corrcoef(WV);
        
        %4b. between ISI dists
        R2 = corrcoef( [Sessions.Session1.distISI(RefUnits,:)' ...
            Sessions.Session2.distISI(whichUnits,:)']);
        
        %4c. and correlograms
        R3 = corrcoef( [Sessions.Session1.Correlogram(RefUnits,:)' ...
            Sessions.Session2.Correlogram(whichUnits,:)']);
        
        if TTs == 6
            keyboard;
        end
        
        clear Matches
        for i = 1:numel(RefUnits)
            % sort the units on session 2 by correlation with mean waveforms
            Corrs       = R((numel(RefUnits)+1):end,i);
            WVCorrs     = R1((numel(RefUnits)+1):end,i);
            ISIcorrs    = R2((numel(RefUnits)+1):end,i);
            CGMcorrs    = R3((numel(RefUnits)+1):end,i);
            
            % set a threshold for waveform similarity
            ignoreflag = ones(numel(WVCorrs),1);
            ignoreflag(WVCorrs<0.85) = 0;
            temp = mean([WVCorrs CGMcorrs ISIcorrs],2,'omitnan');
            temp(isnan(temp)) = -1;
            [~,BestMatches] = sortrows([temp.*ignoreflag Corrs],[1 2], 'descend');
            %[~,BestMatches] = sortrows([temp.*ignoreflag.*Corrs Corrs],[1 2], 'descend');
            %[~,BestMatches] = sortrows([ignoreflag.*Corrs temp],[1 2], 'descend');
            
            ignoreflag(find(~ignoreflag)) = NaN;
            Matches(:,:,i) = [BestMatches.*ignoreflag(BestMatches) Corrs(BestMatches) WVCorrs(BestMatches) ...
                ISIcorrs(BestMatches) CGMcorrs(BestMatches)];
        end
        
        % some curation steps
        foo = squeeze(Matches(1,1,:));
        foo(isnan(foo),:) = [];
        if numel(foo) ~= numel(unique(foo))
%             % we are all set
%             for i = 1:numel(RefUnits)
%                 x = Sessions.Session1.UnitAttributes(RefUnits(i),1);
%                 if ~isnan(Matches(1,1,i))
%                     y = Sessions.Session2.UnitAttributes(whichUnits(Matches(1,1,i)),1);
%                 else
%                     y = NaN;
%                 end
%                 MatchedUnits = vertcat(MatchedUnits, [x y]);
%             end
%         else
            [C,ia,ic] = unique(squeeze(Matches(1,1,:)));
            a_counts = accumarray(ic,1);
            value_counts = [C, a_counts];
            value_counts(isnan(value_counts(:,1)),:) = [];
            
            % work through the duplicates
            while any(value_counts(:,2)>1)
                comatched   = value_counts(find(value_counts(:,2)>1,1,'first'),1);
                unit_idx    = find(Matches(1,1,:)==comatched); 
                % simplest check - waveform similarity, ISI similarity, CGM
                % similarity
                [~,match(1)] = max(Matches(1,3,unit_idx));
                [~,match(2)] = max(Matches(1,4,unit_idx));
                [~,match(3)] = max(Matches(1,5,unit_idx));
                
                % clear winner
                if numel(unique(match))==1
                    unit_idx(match(1),:) = [];
                    for j = 1:numel(unit_idx)
                        % nullify the top-match
                        Matches(1,1,unit_idx(j)) = NaN;
                        Matches(:,:,unit_idx) = squeeze(circshift(Matches(:,:,unit_idx),-1,1));
                    end
                    [C,ia,ic] = unique(squeeze(Matches(1,1,:)));
                    a_counts = accumarray(ic,1);
                    value_counts = [C, a_counts];
                    value_counts(isnan(value_counts(:,1)),:) = [];
                elseif any(~ismember(1:numel(unit_idx),match))
                    % find the one that clearly doesn't fit
                    k = unit_idx(find(~ismember(1:numel(unit_idx),match)));
                    % nullify the top-match
                    Matches(1,1,k) = NaN;
                    Matches(:,:,k) = squeeze(circshift(Matches(:,:,k),-1,1));
                    [C,ia,ic] = unique(squeeze(Matches(1,1,:)));
                    a_counts = accumarray(ic,1);
                    value_counts = [C, a_counts];
                    value_counts(isnan(value_counts(:,1)),:) = [];
                elseif numel(find(match==mode(match)))==2
                    % any majority at all?
                    unit_idx(mode(match)) = [];
                    for j = 1:numel(unit_idx)
                        % nullify the top-match
                        % Matches(1,1,unit_idx(j)) = NaN;
                        % keep the top match in case no better candidate is
                        % actually found
                        Matches(1,1,unit_idx(j)) = -Matches(1,1,unit_idx(j));
                        Matches(:,:,unit_idx) = squeeze(circshift(Matches(:,:,unit_idx),-1,1));
                    end
                    [C,ia,ic] = unique(squeeze(Matches(1,1,:)));
                    a_counts = accumarray(ic,1);
                    value_counts = [C, a_counts];
                    value_counts(isnan(value_counts(:,1)),:) = [];
                else
                    keyboard;
                end
                
            end
        end
        
        thisTTMatch = ones(numel(RefUnits),3);
        thisTTMatch(:,3) = thisTTMatch(:,3)*TTs;
        for i = 1:numel(RefUnits)
            thisTTMatch(i,1) = Sessions.Session1.UnitAttributes(RefUnits(i),1);
            if ~isnan(Matches(1,1,i))
                thisTTMatch(i,2) = Sessions.Session2.UnitAttributes(whichUnits(Matches(1,1,i)),1);
            else
                thisTTMatch(i,2) = NaN;
            end
        end
        MatchedUnits = vertcat(MatchedUnits, thisTTMatch);
        
        
            
        %end
        
        
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