function [] = ConvertAvi2mp4(myAviFile)
%% function to convert an avi file (generated in bonsai to mp4)
myMp4File = strrep(myAviFile,'.avi','.mp4');

% Build ffmpeg command
% cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.0 -c:a aac -y "%s"', ...
%     myAviFile, myMp4File);

cmd = sprintf(['ffmpeg -i "%s" -c:v libx264 -pix_fmt yuv420p ' ...
    '-profile:v baseline -level 3.0 -movflags +faststart ' ...
    '-c:a aac -y "%s"'], myAviFile, myMp4File);

% Execute the command
    status = system(cmd);


% %% Batch Convert AVI to H.264 MP4 for MATLAB
% inputFolder = '/path/to/your/avi/files'; % <-- change this
% outputFolder = '/path/to/save/mp4/files'; % <-- change this
% 
% if ~exist(outputFolder, 'dir')
%     mkdir(outputFolder);
% end
% 
% aviFiles = dir(fullfile(inputFolder, '*.avi'));
% 
% for k = 1:length(aviFiles)
%     inputFile = fullfile(inputFolder, aviFiles(k).name);
    
    % Create output filename with .mp4 extension
%     [~, name, ~] = fileparts(aviFiles(k).name);
%     outputFile = fullfile(outputFolder, [name, '.mp4']);
% 
%     % Build ffmpeg command
%     cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.0 -c:a aac -y "%s"', ...
%                   inputFile, outputFile);
% 
%     fprintf('Converting %s → %s\n', aviFiles(k).name, [name, '.mp4']);
% 
%     % Execute the command
%     status = system(cmd);
% 
%     if status == 0
%         fprintf('Done: %s\n', [name, '.mp4']);
%     else
%         fprintf('Failed: %s\n', aviFiles(k).name);
%     end
% % end
% 
% %% Optional: Read converted videos in MATLAB
% mp4Files = dir(fullfile(outputFolder, '*.mp4'));
% for k = 1:length(mp4Files)
%     v = VideoReader(fullfile(outputFolder, mp4Files(k).name));
%     frame = readFrame(v);
%     imshow(frame);
%     title(['First frame of ', mp4Files(k).name]);
%     pause(1); % Pause to display
% end

end