

%% Find Directories for each Session Recursively from Current Directory
rootFolderName = pwd;
foldersWithTiffs = getFoldersWithTiffFiles(rootFolderName);

% Remove Folders with 'Static' in Folder name
isStaticImageFolder = cellfun( @(str)contains(str,'static'), foldersWithTiffs);
foldersWithTiffVideos = foldersWithTiffs(~isStaticImageFolder);

%% Build 'SessionInfo' Objects Using Directories with Tiffs
failedFolder = {};
for k=numel(foldersWithTiffVideos):-1:1
    try
        session(k) = SessionInfo(foldersWithTiffVideos{k});
    catch me
        %         keyboard
        getReport(me)
        failedFolder{end+1} = foldersWithTiffVideos{k};
    end
end


%% Edit Session data to ensure correct/constistent whatebver
% for k=1:numel(session)
% 	id = session(k).MouseId;
% 	% does the MouseId have 'SC' in it??
% 	scIndex =findstr('SC', id);
% 	if ~isempty(scIndex)
% 		newId = id((scIndex+2)+(0:3)
% 		%todo -> going to doo manuallyt for now because it won't be useful to have
% 		%this function automated in the future because we're aren't going to have
% 		%stupid shit like this holding us back fvrom pumping out mega super results
% 		%at the click of a button.
% 	end
% end
unspecified = findobj(session,'CellOrigin','unspecified');
allMouseIds = unique({session.MouseId})';
ids2change = unique({unspecified.MouseId})';

% Fix IDs
for k=1:numel(ids2change)
    id = ids2change{k};
    
    selection = questdlg(sprintf('How do you want to substitute the %s',id),...
        'selection','listing','manual','cancel','listing');
    
    % Ask User for New-ID
    switch selection
        case 'listing'
            [newIdIndex, ok] = listdlg( ...
                'PromptString', sprintf( 'Select the Correct ID for %s',id),...
                'ListString', allMouseIds,...
                'ListSize', [400 680]);
            newId = allMouseIds{newIdIndex};
            currentSessionsWithId = findobj(session,'MouseId', newId);
            newCellOrigin = currentSessionsWithId(1).CellOrigin;
%             disp( {currentSessionsWithId.CellOrigin}')
        case 'manual'
            manualIdAndOrigin = inputdlg(...
                {sprintf('Correct MouseId from %s',id),...
                'Correct Cell-Origin'},...
                'MouseId',1,{id,'Ctx'});
            newId = manualIdAndOrigin{1};
            newCellOrigin = manualIdAndOrigin{2};
        otherwise
            break
    end
    
    % Find ALL Sessions that Need 'MouseId' Updated from 'id' 'newId'
    sessions2change = findobj(session,'MouseId', id);
       
    % Update ID
    set( sessions2change, 'MouseId', newId);
    
    % Update Unspecified (Cell-Origin)
    
    
    disp( {sessions2change.CellOrigin}')
    set(sessions2change, 'CellOrigin', newCellOrigin);
end

%% Fix Frames-Per-Second Glitch
fps = {session.FrameRate};
fpsEmpty = cellfun(@isempty,fps);
[fps{fpsEmpty}] = deal(40);
fps60 = cellfun(@(val) val>=6000000, fps);
fps40 = cellfun(@(val) val==4000001, fps);

set( session(fps60), 'FrameRate', 60);
set( session(fps40), 'FrameRate', 40);
set( session(fpsEmpty), 'FrameRate', 40);


%% Fix Day-After-Transplantation
DAT=[session.DayAfterTransplantation]';
idx = find(DAT > 9999);
for k = 1:length(idx)
    dat = session(idx(k)).DayAfterTransplantation;
    datStr = inputdlg(...
        sprintf('DAT fucked up. What is the correct DAT from %s?',...
        session(idx(k)).Root),...
        'DAT',1,{num2str(dat)});
    session(idx(k)).DayAfterTransplantation = str2num(datStr{1});
end


%% Display to Check
warning('off','MATLAB:structOnObject')
s = arrayfun(@struct, session);
sDataSet = struct2dataset(s(:));
sTable = struct2table(s(:));
% xlswrite(fullfile('Z:\People\Susie','sessioninfo'),struct2cell(s(:)))
save('Corrected Session Index.mat', 'session')


%%
if false
    k=100;
    currentSession = session(k)
    cd(currentSession.Root)
    tif = dir('*.tif')
    {tif.name}
    tiffLoader = scicadelic.TiffStackLoader(...
        'FileDirectory',currentSession.Root,...
        'FileName', {tif.name})
    [nextFcn,pp] = getScicadelicPreProcessor(tiffLoader, false, false)
    [f,info,mstat,frgb,srgb] = nextFcn();
end