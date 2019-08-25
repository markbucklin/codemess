clear all

Base = 'Z:\Data\susie\Temp Data-Processing\New Folder';
files = dir(Base);
dirFlags = [files.isdir];
subfolders = files(dirFlags);
subfoldernames = {subfolders.name};
subfoldernames(ismember(subfoldernames,{'.', '..'})) = [];
subfoldernames = fullfile(Base, subfoldernames);


for iFiles = 1:numel(subfoldernames);
    foldername = subfoldernames{iFiles};
    cd(foldername)

matfile=dir(fullfile('*.mat'))
load(fullfile(matfile.name))

xC = {};
for roiN = 1:size(roi,2)    
    maxq = squeeze(roi(roiN).vq.maxq(:,:,:,200:end))';
    mean = squeeze(roi(roiN).vq.mean(:,:,:,200:end))';
    minq = squeeze(roi(roiN).vq.minq(:,:,:,200:end))';
    medq = squeeze(roi(roiN).vq.medq(:,:,:,200:end))';

    traceR_maxq{roiN} = maxq(:,1);
    traceG_maxq{roiN} = maxq(:,2);
    traceB_maxq{roiN} = maxq(:,3);
    
    traceR_mean{roiN} = mean(:,1);
    traceG_mean{roiN} = mean(:,2);
    traceB_mean{roiN} = mean(:,3);
    
    traceR_minq{roiN} = minq(:,1);
    traceG_minq{roiN} = minq(:,2);
    traceB_minq{roiN} = minq(:,3);
    
    traceR_medq{roiN} = medq(:,1);
    traceG_medq{roiN} = medq(:,2);
    traceB_medq{roiN} = medq(:,3);

end

traceRGB{1,1}=traceR_maxq;traceRGB{1,2}=traceG_maxq;traceRGB{1,3}=traceB_maxq;
traceRGB{2,1}=traceR_mean;traceRGB{2,2}=traceG_mean;traceRGB{2,3}=traceB_mean;
traceRGB{3,1}=traceR_minq;traceRGB{3,2}=traceG_minq;traceRGB{3,3}=traceB_minq;
traceRGB{4,1}=traceR_medq;traceRGB{4,2}=traceG_medq;traceRGB{4,3}=traceB_medq;

% traceOutRed= cell2mat(traceRGB{2,1});
% traceOutBlue= cell2mat(traceRGB{2,3});
% save('traceOutRed','traceOutBlue')

A=string(strsplit(char(subfoldernames(iFiles)),'\'));
dat = regexp(A(6),'\d*','Match');
B = strsplit(A(6),'-');
% id_R = strcat(B(4),'_Red','_',dat(5),'DAT');
% id_B = strcat(B(4),'_Blue','_',dat(5),'DAT');
% var.(id_R) = cell2mat(traceRGB{2,1});
% var.(id_B) = cell2mat(traceRGB{2,3});

id_R_maxq = strcat(B(4),'_Red','_',dat(5),'DAT_maxq');
id_R_mean = strcat(B(4),'_Red','_',dat(5),'DAT_mean');
id_R_minq = strcat(B(4),'_Red','_',dat(5),'DAT_minq');
id_R_medq = strcat(B(4),'_Red','_',dat(5),'DAT_medq');
var.(id_R_maxq) =cell2mat(traceRGB{1,1});
var.(id_R_mean) =cell2mat(traceRGB{2,1});
var.(id_R_minq) =cell2mat(traceRGB{3,1});
% var.(id_R_medq) =cell2mat(traceRGB{4,1});

id_G_maxq = strcat(B(4),'_Green','_',dat(5),'DAT_maxq');
id_G_mean = strcat(B(4),'_Green','_',dat(5),'DAT_mean');
id_G_minq = strcat(B(4),'_Green','_',dat(5),'DAT_minq');
id_G_medq = strcat(B(4),'_Green','_',dat(5),'DAT_medq');
var.(id_G_maxq) =cell2mat(traceRGB{1,2});
var.(id_G_mean) =cell2mat(traceRGB{2,2});
var.(id_G_minq) =cell2mat(traceRGB{3,2});
% var.(id_B_medq) =cell2mat(traceRGB{4,2});

id_B_maxq = strcat(B(4),'_Blue','_',dat(5),'DAT_maxq');
id_B_mean = strcat(B(4),'_Blue','_',dat(5),'DAT_mean');
id_B_minq = strcat(B(4),'_Blue','_',dat(5),'DAT_minq');
id_B_medq = strcat(B(4),'_Blue','_',dat(5),'DAT_medq');

var.(id_B_maxq) =cell2mat(traceRGB{1,3});
var.(id_B_mean) =cell2mat(traceRGB{2,3});
var.(id_B_minq) =cell2mat(traceRGB{3,3});
% var.(id_G_medq) =cell2mat(traceRGB{4,3});

clearvars -except var subfoldernames
cd 'Z:\Data\susie\Temp Data-Processing\New Folder'

end


%%
clear all

cd 'Z:\Data\susie\Temp Data-Processing\New Folder'
load partialData

names = fieldnames(var);
subStr = {'m1LH0621GE','m1rh0621GE',...
    'm2LH0621GE','m2RH0621GE',...
    'm1LH0622Ctx','m1RH0622Ctx',...
    'm2RH0622Ctx','m2LH0622Ctx'};

filteredStruct={};
for i = 1:size(subStr,2);
    filterStruct = rmfield(var, names(find(cellfun(@isempty, strfind(names,subStr(i))))));
    tempFN = fieldnames(filterStruct);
    filteredStruct{i,1} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Red')))));
    filteredStruct{i,2} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Blue')))));
    
    clearvars filterStruct tempFN
end

clearvars -except filteredStruct var


%%%%%%%%%%%%%%%%%%%%%% Above Squared 0621 and 0622 %%%%%%%%%%%%%%%%%%%%%%  

%%

%%%%%%%%%%%%%%%%%%%%%% Below Automated Partial 0419 and 0628 %%%%%%%%%%%%%%%%%%%%%%  
% clear all 
fileDir_Blue = ["Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-014DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-022DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-034DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-046DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-056DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-084DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-088DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-013DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-017DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-029DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-037DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-042DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-050DAT-60fps00002-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-078DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-082DAT-60fps00002-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-009DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-015DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-077DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-100DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-120DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-145DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-152DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-167DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-174DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-009DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-015DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-077DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-100DAT-40fps-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-120DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-145DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-152DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-174DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-013DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-017DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-029DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-037DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-042DAT-60fps00002-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-083DAT-60fps00002-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0621GE-M2RH\0621GE-M2RH-015DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0621GE-M2RH\0621GE-M2RH-023DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0621GE-M2RH\0621GE-M2RH-031DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0621GE-M2RH\0621GE-M2RH-044DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0621GE-M2RH\0621GE-M2RH-057DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0621GE-M2RH\0621GE-M2RH-082DAT-40fps00003-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0621GE-M2RH\0621GE-M2RH-089DAT-40fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2RH\0628GE-M2RH-014DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2RH\0628GE-M2RH-017DAT-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2RH\0628GE-M2RH-029DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2RH\0628GE-M2RH-037DAT-60fps00002-BlueTraceROIs.mat"...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2RH\0628GE-M2RH-042DAT-60fps00001-BlueTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2RH\0628GE-M2RH-083DAT-60fps00001-BlueTraceROIs.mat"];


for i = 1:size(fileDir_Blue,2)
    
    load(fileDir_Blue(i));
    A = string(strsplit(char(fileDir_Blue(i)),'\'));
    dat = regexp(A(8),'\d*','Match');
    B = strsplit(A(8),'-');
    id_B = strcat(B(2),B(1),'_Blue','_',dat(3),'DAT');
    var.(id_B) = traceOutBlue;
    clearvars A dat B id_B traceOutBlue;
    
end



%%

% clear all

fileDir_Red = ["Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-145DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-120DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-152DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-077DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-009DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-015DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-174DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-167DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419GE-M1RH\0419GE-M1RH-100DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-014DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-034DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-056DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-084DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-022DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-046DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0622Ctx-M2LH\0622Ctx-M2LH-088DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-083DAT-60fps00002-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-013DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-017DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-029DAT-60fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-037DAT-60fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628GE-M2LH\0628GE-M2LH-042DAT-60fps00002-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-078DAT-60fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-050DAT-60fps00002-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-037DAT-60fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-029DAT-60fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-017DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-042DAT-60fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-013DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0628Ctx-M1RH\0628Ctx-M1RH-082DAT-60fps00002-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-145DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-015DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-077DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-009DAT-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-120DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-152DAT-40fps00001-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-100DAT-40fps-RedTraceROIs.mat" ...
"Z:\Data\susie\Temp Data-Processing\Traces\Archive\0419Ctx-M1LH\0419Ctx-M1LH-174DAT-40fps00001-RedTraceROIs.mat"];




for i = 1:size(fileDir_Red,2)
    
    load(fileDir_Red(i));
    A = string(strsplit(char(fileDir_Red(i)),'\'));
    dat = regexp(A(8),'\d*','Match');
    B = strsplit(A(8),'-');
    id_R = strcat(B(2),B(1),'_Red','_',dat(3),'DAT');
    var.(id_R) = traceOutRed;
    clearvars A dat B id_B traceOutRed;
    
end







