function [Paths] = WhichComputer()

% read computer name
[~,computername] = system('hostname');
computername = deblank(computername);

if contains(computername,'Marie')
    computername = 'MarieMacCSHL';
end 

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
Paths.Widefield.Raw             = '/mnt/albeanu_lab/priyanka/Widefield';
Paths.Widefield.Processed       = '/mnt/data/Widefield'; % local copy on Andaman

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
    case 'DESKTOP-SBT7SLO' %Marie remote desktop
        Paths.Code                      = 'C:\Users\Marie\Documents\Code'; % where all code files are
        Paths.Grid.Behavior             = 'Y:\pgupta\Behavior'; % raw behavior, tuning mtalab files
        Paths.Grid.Ephys{1}             = 'Y:\pgupta\EphysData'; % raw oeps files - for PCX batch
        Paths.Grid.Ephys{2}             = 'Y:\mdussauz\ephysdata\lever_task\Batch'; % raw oeps files - for batch O,MO, J
        Paths.Local.Ephys_processed     = 'C:\Users\Marie\Documents\data\Smellocator\Processed\Ephys'; % local copy where sorted, curated spike data is stored
        Paths.Grid.Ephys_processed      = 'Y:\mdussauz\Smellocator\Processed\Ephys'; % local copy where sorted, curated spike data is stored
        Paths.Local.Behavior_processed  = 'C:\Users\Marie\Documents\data\Smellocator\Processed\Behavior'; % local copy where sorted, curated spike data is stored
        Paths.Grid.Behavior_processed   = 'Y:\mdussauz\Smellocator\Processed\Behavior'; % local copy where sorted, curated spike data is stored
        Paths.ProcessedSessions         = Paths.Grid.Behavior_processed;
        
        % LocationMapping Experiments done by Blom on AON mice
        Paths.Mapping.EphysRaw = 'Y:\pgupta\EphysData\odor_location';
        Paths.Mapping.EphysSorted = 'Y:\pgupta\EphysData\odor_location\Sorted';
        Paths.Mapping.StimulusFile = 'Y:\pgupta\Behavior';
        Paths.Mapping.Processed = 'Y:\mdussauz\Smellocator\Processed\Mapping';
   
    case 'MarieMacCSHL' %Marie laptop
        Paths.Code                      = '/Users/mariedussauze/Desktop/Analysis/Code'; % where all code files are
        Paths.Grid.Behavior             = 'smb://grid-hs/albeanu_nlsas_norepl_data/pgupta/Behavior'; % raw behavior, tuning mtalab files
        Paths.Grid.Ephys{1}             = 'smb://grid-hs/albeanu_nlsas_norepl_data/pgupta/EphysData'; % raw oeps files - for PCX batch
        Paths.Grid.Ephys{2}             = 'smb://grid-hs/albeanu_nlsas_norepl_data/mdussauz/ephysdata/lever_task/Batch'; % raw oeps files - for batch O,MO, J
        Paths.Local.Ephys_processed     = '/Users/mariedussauze/Desktop/Analysis/data/Smellocator/Processed/Ephys'; % local copy where sorted, curated spike data is stored
        Paths.Grid.Ephys_processed      = 'smb://grid-hs/albeanu_nlsas_norepl_data/mdussauz/Smellocator/Processed/Ephys'; % local copy where sorted, curated spike data is stored
        Paths.Local.Behavior_processed  = '/Users/mariedussauze/Desktop/Analysis/data/Smellocator/Processed/Behavior'; % local copy where sorted, curated spike data is stored
        Paths.Grid.Behavior_processed   = 'albeanu_nlsas_norepl_data/mdussauz/Smellocator/Processed/Behavior'; % local copy where sorted, curated spike data is stored
        Paths.ProcessedSessions         = Paths.Grid.Behavior_processed;
end


end