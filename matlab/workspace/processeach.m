%%

matlabpath(pathdef)

%%
dataDir = pwd;
sessionDir = dir(dataDir);
selector = {...
    @(d) d.isdir,...
    @(d) ~strcmp(d.name,'.'),...
    @(d) ~strcmp(d.name,'..'),...
    @(d) ~exist(fullfile(d.name,'export'),'dir')};
selected = cellfun(@(sel) arrayfun(sel, sessionDir), selector, 'UniformOutput',false);
sessionDir = sessionDir(all([selected{:}],2));

sessionPrefix = arrayfun( @(d) [fullfile(d.folder,d.name),filesep], sessionDir, 'UniformOutput', false);

tiffList = cellfun( @(tld) {tld.name}, cellfun(@(prefix) dir([prefix,'*.tif']), sessionPrefix,'UniformOutput', false),'UniformOutput',false);

%%
k=1;
while k < numel(sessionPrefix)
    fprintf('Processing %s\n',sessionPrefix{k});
    tiffLoader = scicadelic.TiffStackLoader('FileDirectory',sessionPrefix{k},'FileName',tiffList{k});
    [next,pp] = getScicadelicPreProcessor(tiffLoader,true,true);

    chunkInfo = {};    
    while (~pp.fcn.checkfinished())
        [~,info,~,~,~] = next();
        chunkInfo{end+1} = info;
    end
    
    jsinfo = jsonencode(cat(1,chunkInfo{:}));
    fid = fopen(fullfile(pp.env.defaultExportPath,'info.json'),'W+');
    fwrite(fid,jsinfo)
    fclose(fid);
    
    release(tiffLoader)
    k=k+1;
end

%%


