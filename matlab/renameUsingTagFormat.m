

%%
parentFolder = uigetdir(pwd,'Select Parent Folder For File Name Pattern Change');
[list,bytes,allNames] = ignition.util.dirr(sprintf('%s\\*.tif',parentFolder),'name','isdir',0);

%%
% filePattern = '\<SC(?<harvestdate>\d*)-I(?<imagedate>\d*)-M(?<mousenum>\d*)(?<location>\w*)(\(?|\w*)(?<filenum>\d*)?\)'
% filePattern = '\<SC(?<harvestdate>\d*)-I(?<imagedate>\d*)-M(?<mousenum>\d*)(?<location>\w*)(?([(])(?<filenum>\d*)[)]))'
filePattern = '\<SC?(?<harvestdate>\d*)-I(?<imagedate>\d*)-M(?<mousenum>\d*)(?<location>\w*)\s*\(?(?<filenum>\d*)?\)?';

%%
for k=1:numel(allNames)
    
    [folderName,fileName,fileExt] = fileparts(allNames{k});
    oldName = [fileName,fileExt];
    oldPath = fullfile(folderName,oldName);    
    
    [match,tag,split] = regexp(fileName, filePattern, 'match','names','split');
    
    % CHANGED ALREADY??
    if isempty(tag)
        fprintf('skipping %s\n',fileName);
        continue
    end
    
    % MAKE NEW FILENAME    
    if isempty(tag.filenum)
        newName = sprintf('SC%s-M%s%s-I%s.tif',tag.harvestdate, tag.mousenum, tag.location, tag.imagedate);
    else
        newName = sprintf('SC%s-M%s%s-I%s(%s).tif',tag.harvestdate, tag.mousenum, tag.location, tag.imagedate, tag.filenum);
    end
    newPath = fullfile(folderName,newName);
    fprintf('renaming file:\t%s\t->\t%s\n',oldName,newName);
    
    % RENAME
    try
        [status,msg,msgid] = movefile( oldPath, newPath);
    catch
        beep
        keyboard
    end
    
    
end



% TAG
%     harvestdate: '0426'   SC0426
%       imagedate: '0430'   I0430
%        mousenum: '1'      M1
%        location: 'LH'     LH
