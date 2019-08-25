for ii = 1:2;

for i = 1:length(fieldnames(sorted_filteredStruct{ii,2}))

    id = string(fieldnames(sorted_filteredStruct{ii,2}));
    [R,P,RL,RU] = corrcoef(sorted_filteredStruct{ii,2}.(id(i)));
    cg=clustergram(R,'Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
    set(cg,'ShowDendrogram','off')
    set(cg,'DisplayRatio',[0.001 0.001])

%     subplot(10,10,i)
    
% 
% hax = gca
% sax = hax
% max = axes
% mfig = figure







    cgAxes =plot(cg);
    set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [1 1 1])
        set(cg,'ColumnLabels',[],'RowLabels',[])
    addTitle(cg,id(i),'Interpreter','none')
    colorbar
    cd 'Z:\Data\susie\Temp Data-Processing\New Folder\CorrCoefFigures'
    
    
%     
%     fig = get(max,'children')
%     
%     copyobj(fig,
%     
    
    
    saveas(gcf,id(i),'png')
    
    close all hidden

end

end




%% Red and Blue Traces and Cross Correlation Matrix

subplot(2,2,1)
[Rred,P,RL,RU] = corrcoef(traceOutRed);
Rred(find(eye(size(Rred)))) = 0;
pcolor(Rred)
shading interp;
set(gca, 'clim', [0 1]);
colormap hot
colorbar
axis image
src = '0621GE-M2RH-006DAT-RedTraceROIs';
title(src);

subplot(2,2,3)
plot(bsxfun( @plus, traceOutRed(60:end,randi([1 size(traceOutRed,2)],1,50)), 3.*(0:49)))

subplot(2,2,2)
clearvars -EXCEPT traceOutBlue
[Rblue,P,RL,RU] = corrcoef(traceOutBlue);
Rblue(find(eye(size(Rblue)))) = 0;
pcolor(Rblue)
shading interp;
set(gca, 'clim', [0 1]);
colormap hot
colorbar
axis image
src = '0628Ctx-M1RH-012DAT-60fps00001-BlueTraceROIs';
title(src);

subplot(2,2,4)
plot(bsxfun( @plus, traceOutBlue(60:end,randi([1 size(traceOutBlue,2)],1,50)), 3.*(0:49)))



saveas(gcf,src,'png')
clear all
close all


%% Gather up data for correlation plots

clear all
Base = 'Z:\Data\susie\Temp Data-Processing\Traces\Archive\';
files = dir(Base);
dirFlags = [files.isdir];
subfolders = files(dirFlags);
subfoldernames = {subfolders.name};
subfoldernames(ismember(subfoldernames,{'.', '..','Figures - Trace Red and Blue and Corr Matrix'})) = [];
subfoldernames = fullfile(Base, subfoldernames);
j=1;k=1;

for iFiles = 1:numel(subfoldernames);
    foldername = subfoldernames{iFiles};
    f = dir(fullfile(foldername, '*.mat'));
    for ii = 1:length(f)
        fil = fullfile(foldername, {f.name});
        filename = fil{ii};
        clearvars trace*
        load(filename,'trace*');
        if exist('traceOutRed')
            [R,P,RL,RU] = corrcoef(traceOutRed);
            Red(j).coff = R;
            Red(j).reshapecoff = reshape(R,[],1);
            Red(j).name = f(ii).name;
            j = j + 1;
            clearvars trace* R P RL RU 
        elseif exist('traceOutBlue')
%             [R,P,RL,RU] = corrcoef(traceOutBlue);
%             Blue(k).reshapecoff = reshape(R,[],1);
%             Blue(k).coff = R;
%             Blue(k).name = f(ii).name;
%             k = k + 1;
            clearvars trace* R P RL RU 
        end
    end
end



%% Violin plot for Crosscorrelation
% load Coeff.mat

figure
match=["-RedTraceROIs.mat","-BlueTraceROIs.mat","00001","-40fps"];
color = [27 153 139; 45 48 71; 255 253 130; 255 155 113; 232 72 85; 17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128]/255;
redMtrx={}; redName={};
% subplot(2,1,1)
for n = 1:size(Red,2);
    redMtrx(n) = {Red(n).coff}';
    redName(n) = erase({Red(n).name},match);
%     blueMtrx(n) = {Blue(n).coff}';
%     blueName(n) = erase({Blue(n).name},match);
end

group{:,1}=redMtrx(1:8);group{2,1}=redName(1:8);
group{:,2}=redMtrx(9:17);group{2,2}=redName(9:17);
group{:,3}=redMtrx(18:26);group{2,3}=redName(18:26);
group{:,4}=redMtrx(27:33);group{2,4}=redName(27:33);
group{:,5}=redMtrx(34:41);group{2,5}=redName(34:41);
group{:,6}=redMtrx(42:47);group{2,6}=redName(42:47);
group{:,7}=redMtrx(48:53);group{2,7}=redName(48:53);

for n=1:7
figure
violin(group{1,n},'edgecolor','none','mc',[],'medc',[],'facecolor',color,'facealpha',0.5);
axis image
ax = gca;
set(ax,'XtickLabel',group{2,n}, 'FontSize',10)
end

% 
% subplot(2,1,2)
% violin(blueMtrx,'edgecolor','none','mc',[],'medc',[],'facecolor',color,'facealpha',0.5);
% axis image
% xlabel(blueName,'FontSize',7)


%% Red and Blue Traces and Cross Correlation Matrix

clear all
Base = 'Z:\Data\susie\Temp Data-Processing\Traces\Archive\';
files = dir(Base);
dirFlags = [files.isdir];
subfolders = files(dirFlags);
subfoldernames = {subfolders.name};
subfoldernames(ismember(subfoldernames,{'.', '..','Figures - Trace Red and Blue and Corr Matrix'})) = [];
subfoldernames = fullfile(Base, subfoldernames);
j=1;k=1;

for iFiles = 1:numel(subfoldernames);
    foldername = subfoldernames{iFiles};
    f = dir(fullfile(foldername, '*.mat'));
    for ii = 1:length(f)
        fil = fullfile(foldername, {f.name});
        filename = fil{ii};
        clearvars trace*
        load(filename,'trace*');
        if exist('traceOutRed')
            [R,P,RL,RU] = corrcoef(traceOutRed);
            cg=clustergram(R,'Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
            set(cg,'ShowDendrogram','off')
            set(cg,'DisplayRatio',[0.001 0.001])
            cgAxes =plot(cg);
            set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [1 1 1])
            set(cg,'ColumnLabels',[],'RowLabels',[])
            colorbar
            [folder, baseFileName, extension] = fileparts(filename);
            saveas(gcf,baseFileName,'png')
            clearvars trace* R P RL RU cg baseFileName
            close all
        elseif exist('traceOutBlue')
%             [R,P,RL,RU] = corrcoef(traceOutBlue);
%             clearvars trace*
%             cg=clustergram(R,'Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
%             set(cg,'ShowDendrogram','off')
%             set(cg,'DisplayRatio',[0.001 0.001])
%             cgAxes =plot(cg);
%             set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [1 1 1])
%             set (cg,'ColumnLabels',[],'RowLabels',[])
%             colorbar
%             [folder, baseFileName, extension] = fileparts(filename);
%             saveas(gcf,baseFileName,'png')
            clearvars trace* R P RL RU cg baseFileName
            close all

        end
    end
end
%% Compile correlation matrix

clear all

figure
blu = 'Z:\Data\susie\Temp Data-Processing\Traces\Archive\blueFig'
cd 'Z:\Data\susie\Temp Data-Processing\Traces\Archive\blueFig'
imgs = dir(fullfile(blu,'*.png'));
bluOrder=[];
for ij = 1:length(imgs)
    fil = fullfile(blu,{imgs.name});
    filename = fil{ij};
    [folder, baseFileName, extension] = fileparts(filename);
    tempimg{ij} = imread(strcat(baseFileName, extension));
    bluOrder{ij} = baseFileName;
end
montage(tempimg)    

clearvars
figure
red = 'Z:\Data\susie\Temp Data-Processing\Traces\Archive\redFig'
cd 'Z:\Data\susie\Temp Data-Processing\Traces\Archive\redFig'
imgs = dir(fullfile(red,'*.png'));
redOrder=[];
for ij = 1:length(imgs)
    fil = fullfile(red,{imgs.name});
    filename = fil{ij};
    [folder, baseFileName, extension] = fileparts(filename);
    tempimg{ij} = imread(strcat(baseFileName, extension));
    redOrder{ij} = baseFileName;
end
montage(tempimg)   



%%

plot(bsxfun( @plus, traceOutRed(60:end,randi([1 size(traceOutRed,2)],1,50)), 3.*(0:49)))
plot(bsxfun( @plus, traceOutBlue(60:end,randi([1 size(traceOutBlue,2)],1,50)), 3.*(0:49)))

saveas(gcf,src,'png')
clear all
close all



