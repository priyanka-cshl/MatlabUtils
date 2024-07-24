function [TTLs] = OEPS_getTTLs_newGUI(session)

Events = session.recordNodes{1}.recordings{1}.ttlEvents('Acquisition_Board-100.Rhythm Data');
data            = Events.channel;
timestamps      = Events.timestamp;
info.eventId    = Events.state;

% adjust for clock offset between open ephys and kilosort
offset = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1);

timestamps = timestamps - offset;

%% Get various events
TTLTypes = unique(data);
Tags = {'Air', 'Odor1', 'Odor2', 'Odor3', 'Trial', 'Reward', 'AirManifold', 'Licks'};
for i = 1:numel(TTLTypes)
    On = timestamps(intersect(find(info.eventId),find(data==TTLTypes(i))));
    Off = timestamps(intersect(find(~info.eventId),find(data==TTLTypes(i))));
    % delete the first off value, if it preceeds the On
    Off(Off<On(1)) = [];
    On(On>Off(end)) = [];
    
    if length(On)>length(Off)
        keyboard;
        foo = [On(1:end-1) Off]';
        goo = foo(:);
        On(find(diff(goo)<0,1,'first')/2,:) = [];
    end
        
    temp = [On Off Off-On];
    
    % ignore any transitions faster than 1 ms - behavior resolution is 2 ms
    temp(temp(:,3)<0.001,:) = [];
    
    % sometimes lines can toggle high low quickly leading to
    % splitting of one trial into two
    splitTrials = find(abs(Off(:,1) - circshift(On(:,1),-1))<0.001);
    if any(splitTrials)
        disp(['merging ',num2str(numel(splitTrials)),' split ',char(Tags(i)),' Trials']);
        Off(splitTrials,:)  = [];
        On(splitTrials+1,:) = [];
    end
    
    temp = [On Off Off-On];
    TTLs.(char(Tags(i))) = temp;
end
end
