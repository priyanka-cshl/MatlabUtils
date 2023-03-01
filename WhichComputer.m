function [Paths] = WhichComputer()

% read computer name
[~,computername] = system('hostname');
computername = deblank(computername);

if contains(computername,'.cshl.edu') || contains(computername, 'priyanka-gupta')
    computername = 'MacLocal';
end

% default paths
Paths.Code                      = '/opt'; % where all code files are
Paths.Grid.Behavior             = '/mnt/grid-hs/pgupta/Behavior'; % raw behavior, tuning mtalab files
Paths.Grid.Ephys{1}             = '/mnt/grid-hs/pgupta/EphysData'; % raw oeps files - for PCX batch
Paths.Grid.Ephys{2}             = '/mnt/grid-hs/mdussauz/ephysdata/lever_task/Batch'; % raw oeps files - for batch O,MO, J
Paths.Grid.Ephys{3}             = '/mnt/albeanu_lab/priyanka/EphysData'; % batch Q
Paths.Local.Ephys_processed     = '/mnt/data/Sorted'; % local copy where sorted, curated spike data is stored
Paths.Grid.Ephys_processed      = '/mnt/grid-hs/mdussauz/Smellocator/Processed/Ephys'; % server copy where sorted, curated spike data is stored
Paths.Local.Behavior_processed  = '/mnt/data/Behavior'; % local copy where combined behavior and ephys preprocessed data is stored
Paths.Grid.Behavior_processed   = '/mnt/grid-hs/mdussauz/Smellocator/Processed/Behavior'; % local copy where combined behavior and ephys preprocessed data is stored
Paths.ProcessedSessions         = Paths.Grid.Behavior_processed;

% LocationMapping Experiments done by Blom on AON mice
Paths.Mapping.EphysRaw = '/mnt/grid-hs/pgupta/EphysData/odor_location';
Paths.Mapping.EphysSorted = '/mnt/grid-hs/pgupta/EphysData/odor_location/Sorted';
Paths.Mapping.StimulusFile = '/mnt/grid-hs/pgupta/Behavior';
Paths.Mapping.Processed = '/mnt/grid-hs/mdussauz/Smellocator/Processed/Mapping';

switch computername
    case 'andaman'
        %Paths.Grid.Behavior      = '/mnt/data/BehaviorRaw'; % raw behavior, tuning mtalab files
        %Paths.ProcessedSessions  = '/mnt/data/Processed/Behavior';
        %Paths.Grid.Behavior_processed = '/mnt/data/Processed/Behavior';
    case 'nicobar'
        Paths.Grid.Behavior      = '/mnt/data/BehaviorRaw'; % raw behavior, tuning mtalab files
        Paths.ProcessedSessions  = '/mnt/data/Processed/Behavior';
        Paths.Grid.Behavior_processed = '/mnt/data/Processed/Behavior';
        Paths.Grid.Ephys{1}             = '/mnt/data/Sorted';
    case 'MacLocal' % Priyanka laptop
        Paths.Code                      = '/Users/Priyanka/Desktop/github_local';
        Paths.Grid.Behavior             = '/Users/Priyanka/Desktop/LABWORK_II/Data/Behavior'; % raw behavior, tuning mtalab files
        Paths.ProcessedSessions         = '/Users/Priyanka/Desktop/LABWORK_II/Data/Smellocator/Processed/Behavior';
        Paths.Grid.Behavior_processed   = '/Users/Priyanka/Desktop/LABWORK_II/Data/Smellocator/Processed/Behavior';
        Paths.Grid.Ephys{1}             = '/Users/Priyanka/Desktop/LABWORK_II/Data/Ephys';
        Paths.Grid.Ephys{2}             = '/Users/Priyanka/Desktop/LABWORK_II/Data/Ephys/Batch';
        Paths.Grid.Ephys{3}             = '/Users/Priyanka/Desktop/LABWORK_II/Data/Ephys';
        Paths.Local.Ephys_processed     = '/Users/Priyanka/Desktop/LABWORK_II/Data/Smellocator/Processed/Ephys';
        Paths.Grid.Ephys_processed      = Paths.Local.Ephys_processed;
    case 'DESKTOP-A6NSB2F' %Marie remote
        Paths.Code                      = 'C:\Users\Marie\Documents\Code'; % where all code files are
        Paths.Grid.Behavior             = 'Z:\pgupta\Behavior'; % raw behavior, tuning mtalab files
        Paths.Grid.Ephys{1}             = 'Z:\pgupta\EphysData'; % raw oeps files - for PCX batch
        Paths.Grid.Ephys{2}             = 'Z:\mdussauz\ephysdata\lever_task\Batch'; % raw oeps files - for batch O,MO, J
        Paths.Local.Ephys_processed     = 'C:\Users\Marie\Documents\data\Sorted'; % local copy where sorted, curated spike data is stored
        Paths.Grid.Ephys_processed      = 'Z:\mdussauz\Smellocator\Processed\Ephys'; % local copy where sorted, curated spike data is stored
        Paths.Local.Behavior_processed  = 'C:\Users\Marie\Documents\data\Behavior'; % local copy where sorted, curated spike data is stored
        Paths.Grid.Behavior_processed   = 'Z:\mdussauz\Smellocator\Processed\Behavior'; % local copy where sorted, curated spike data is stored
        
        % LocationMapping Experiments done by Blom on AON mice
        Paths.Mapping.EphysRaw = 'Z:\pgupta\EphysData\odor_location';
        Paths.Mapping.EphysSorted = 'Z:\pgupta\EphysData\odor_location\Sorted';
        Paths.Mapping.StimulusFile = 'Z:\pgupta\Behavior';
        Paths.Mapping.Processed = 'Z:\mdussauz\Smellocator\Processed\Mapping';
end


end