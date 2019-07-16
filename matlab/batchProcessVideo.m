function batchProcessVideo(numWorkers)

%% SETUP POOL
if nargin < 1
    numWorkers = 12;
end

pool = gcp('nocreate');
if isempty(pool) || (pool.NumWorkers < numWorkers)
    delete(pool)    
   parpool(numWorkers); 
end
    
%% SETUP SOURCE & DESTINATION FOLDERS
% SELECT PROCESSING OUTPUT FOLDER
localProjectDir = uigetdir('Z:\Data','Select local project folder');

% CREATE FOLDERS IF THEY DON'T EXIST
outputDirectory = [localProjectDir,filesep,'OUTPUT'];
if ~exist(outputDirectory,'dir')
    mkdir(outputDirectory)
end
localFolderName = [localProjectDir,filesep,'TEMP'];
if ~exist(localFolderName,'dir')
    mkdir(localFolderName)
end

%% SELECT REMOTE FILES
% fut = parallel.FevalFuture.empty;
numBatches = 0;
selectedDirectory = pwd;
while true
    
    % QUERY USER TO KEEP SELECTING MORE BATCHES
    selectionMode = questdlg(...
        ['Choose how you would like to specify files to add to batch list.',...
        'If finished selecting files to process, select FINISHED.'],...
        'Choose Selection Mode',...
        'Folder','File-List','Finished','Folder');
    
    % SELECT TIFF FILES
    if isempty(selectionMode) || strcmpi(selectionMode, 'Finished')
        % FINISHED --> BREAK
        break
        
    elseif strcmpi(selectionMode,'Folder')
        % SELECT CONTINUOUS FILES IN FOLDER (USING FILE-SIZE)
        selectedDirectory = uigetdir(selectedDirectory,'Select TIFF Containing Folder');
        
        % ***** NOTE **** 
        [tiffFiles, subFolders] = getFilesAndFolders(selectedDirectory);
        tiffFiles = getValidTiffFile(tiffFiles);
        if ~isempty(tiffFiles)
            multiTiffFiles = {tiffFiles};
            multiDirectory = {selectedDirectory};
        else
            multiTiffFiles = {};
            multiDirectory = {};
        end
        if ~isempty(subFolders)
            for k = 1:numel(subFolders)
                subSelectedDirectory = fullfile(selectedDirectory, subFolders(k).name);
                [tiffFiles, ~] = getFilesAndFolders( subSelectedDirectory);
                tiffFiles = getValidTiffFile(tiffFiles);
                if ~isempty(tiffFiles)
                    multiTiffFiles{end+1} = tiffFiles;
                    multiDirectory{end+1} = subSelectedDirectory;
                end
            end
        end
        
        % LOOK FOR DROP IN FILE SIZE IN SEQUENCE OF FILES TO SEPARATE MULTIPLE SEQUENCES
        for kSubFolder = 1:numel(multiTiffFiles)
            tiffFiles = multiTiffFiles{kSubFolder};
            selectedDirectory = multiDirectory{kSubFolder};
                    
            tiffBytes = uint32([tiffFiles.bytes]);       
            
            maxTiffBytes = max(tiffBytes);
            kFileInFolder = 1;
            numFiles = numel(tiffFiles);
            selectedFileList = {};
            while (kFileInFolder <= numFiles)
                selectedFileList{end+1} = tiffFiles(kFileInFolder).name;
                if tiffBytes(kFileInFolder) < maxTiffBytes
                    numBatches = numBatches + 1;
                    batchFileNameList{numBatches} = selectedFileList;
                    batchFileDir{numBatches} = selectedDirectory;
                    selectedFileList = {};
                end
                kFileInFolder = kFileInFolder + 1;
            end
        end
        
    else
        % SELECT FILES DIRECTLY
        [selectedFileList,selectedDirectory] = uigetfile([selectedDirectory,filesep,'*.tif'],'MultiSelect','on');        
        if isnumeric(selectedFileList) && (selectedFileList == 0)
            selectedDirectory = pwd;
            continue
        end
        if ischar(selectedFileList)
            selectedFileList = {selectedFileList};
        end        
        numBatches = numBatches + 1;
        batchFileNameList{numBatches} = selectedFileList;
        batchFileDir{numBatches} = selectedDirectory;
    end
    
    % BEGIN COPYING SELECTED FILES IN BACKGROUND
    
    
    %     % QUERY USER TO KEEP SELECTING MORE BATCHES
    %     keepSelecting = questdlg('Do you want to continue selecting more batches?',...
    %         'Continue Selection','yes','no','yes');
    %     if isempty(keepSelecting) || strcmpi(keepSelecting, 'no')
    %         break
    %     end
    
end


%% COPY REMOTE TO LOCAL (IN PARALLEL FOR SPEED/EFFICIENCY)
kBatch = 1;
while kBatch <= numBatches
    selectedFileList = batchFileNameList{kBatch};
    selectedDirectory = batchFileDir{kBatch};    
    useParFor = kBatch == 1;        
    fprintf('Copying files from %s to %s:\n', selectedDirectory, localFolderName)
    fprintf('\t%s\n',selectedFileList{:});
    copyFinFcn{kBatch} = copyFiles(selectedFileList,selectedDirectory,localFolderName,useParFor);
    kBatch = kBatch + 1;
end


%% PROCESS SELECTED FILES ONCE THEY FINISH COPYING
isCopyFinished = false(1,numBatches);
isProcessed = false(1,numBatches);
while true
    %     isCopyFinished = strcmp('finished', {fut.State});
    for k = 1:numBatches
        if ~isCopyFinished(k)
            isCopyFinished(k) = copyFinFcn{k}();
        end
    end
    if any(isCopyFinished & ~isProcessed)
        processNextIdx = find( isCopyFinished & ~isProcessed, 1, 'first');
        try
            processFiles( batchFileNameList{processNextIdx})
            isProcessed(processNextIdx) = true;
        catch me
            fprintf('Process error\n')
            disp(me.message)
            keyboard
            pause(2)
        end
    else
        pause(2)
    end
    if all(isProcessed) %|| ~any(strcmp('running', {fut.State}))
        break
    end
end

% copy all videos from [localProjectDir,'\TEMP\export'] to
% [localProjectDir,'\OUTPUT']


%% SUBFUNCTION FOR PROCESSING    

    function processFiles(rawFileNames)
        tl = scicadelic.TiffStackLoader('FileDirectory',localFolderName,...
            'FileName',rawFileNames, 'FrameInfoOutputPort', true, 'FramesPerStep', 8);
        exportVidFilePath = runScicadelicVidGen(tl);
        isMoveSuccess = movefile(exportVidFilePath,outputDirectory);
        if isMoveSuccess
            [~,exportName,exportExt] = fileparts(exportVidFilePath);
            %             fprintf('Exported video moved to %s:\t%s\n',outputDirectory,[exportName,exportExt]);
            exportVidFilePath = fullfile(outputDirectory, [exportName,exportExt]);
            fprintf('Exported video moved to OUTPUT: <a href="matlab:winopen(''%s'')">%s</a>\n',exportVidFilePath,exportVidFilePath);
        end
        pause(1)
    end




end

function [selFiles, subDir] = getFilesAndFolders(selDir)
% CHECK IF MULTIPLE FOLDERS WITHIN SELECTED FOLDER
allFiles = dir( selDir);
allFiles(1:2) = [];
subDir = allFiles([allFiles.isdir]);

% GET TIFF FILES IN SELECTED FOLDER
selFiles = dir(fullfile(selDir,'*.tif*'));


% SORT THEM CHRONOLOGICALLY
tiffDateNum = [selFiles.datenum];
[~,chronologicalIdx] = sort( tiffDateNum, 2, 'ascend');
selFiles = selFiles(chronologicalIdx);
end

function copyFinishedFcn = copyFiles(rawFileNames, remoteFolderName, localFolderName, useParFor)
if nargin < 3
    useParFor = false;
end
if useParFor
    parfor k = 1:numel(rawFileNames)        
        remotePath = fullfile(remoteFolderName, rawFileNames{k});
        localPath = fullfile(localFolderName, rawFileNames{k});
        if ~exist(localPath, 'file')            
           copySuccess(k) = copyfile( remotePath, localPath);    
        else
            copySuccess(k) = true;
        end        
    end
    copyFinishedFcn = @()all(copySuccess);
else
    for k = 1:numel(rawFileNames)
        remotePath = fullfile(remoteFolderName, rawFileNames{k});
        localPath = fullfile(localFolderName, rawFileNames{k});
        fut(k) = parfeval(@bgCopy,1,remotePath,localPath);
    end
    copyFinishedFcn = @()all(strcmp('finished',{fut.State}));
end

end
function copySuccess = bgCopy(remotePath,localPath)
if ~exist(localPath, 'file')
    copySuccess = copyfile(remotePath,localPath);
else
    copySuccess = true;
end
end

function validTiffFiles = getValidTiffFile(tiffFiles)

minNumFrames = 64;
minFileSize = minNumFrames * 2 * 2^20;
if  isempty(tiffFiles)
    validTiffFiles = [];
else
    tiffFileSize = [tiffFiles.bytes];
    validTiffFiles = tiffFiles( tiffFileSize > minFileSize);
end
    
end
