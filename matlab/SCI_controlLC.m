clc;, close all;, close hidden;
clear all
Base = 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI- control';
files = dir(Base);
dirFlags = [files.isdir];
subfolders = files(dirFlags);
subfoldernames = {subfolders.name};
subfoldernames(ismember(subfoldernames,{'.', '..','Figures - Trace Red and Blue and Corr Matrix'})) = [];
subfoldernames = fullfile(Base, subfoldernames);
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI- control';

for iFiles = 1:numel(subfoldernames); %Ctxselect;
    
    foldername = subfoldernames{iFiles};
    f = dir(fullfile(foldername, '*.mat'));
    cd(foldername);
    
    file=dir(fullfile(cd, '*.mat'));
    load(file.name);
    
    xC = [];
    for roiN = 1:size(roi,2);
        maxq = squeeze(roi(roiN).vq.maxq(:,:,3,1000:end));
        mean = squeeze(roi(roiN).vq.mean(:,:,3,1000:end));
        minq = squeeze(roi(roiN).vq.minq(:,:,3,1000:end));
        %     medq = squeeze(roi(roiN).vq.medq(:,:,4,200:end));
        xC(:,roiN) = maxq;
        %     xC(:,roiN) = mean;
    end
    
    for roiN = 1:size(roi,2);
        roiNorm(:,roiN) = (sigmoid(xC(:,roiN)))*2-1;
    end
    
    
    
    cd 'Z:\Data\susie\MakingFig\2_Popultation Activity Pattern\LC'
%     figure
%     cg=clustergram(roiNorm','Cluster','column','Colormap','redbluecmap',...
%         'DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
%     set(cg,'ShowDendrogram','off')
%     cgAxes =plot(cg);
%     set(cgAxes, 'Clim', [0 1], 'PlotBoxAspectRatio', [3 1 1])
%     
%     colorbar
     titleID =  cellstr(strsplit(foldername,'\'));
    id = string(titleID(7));
%     title(id, 'FontSize',20)
%         set(gcf,'units','normalized','outerposition',[0 0 1 1])
%     saveas(gcf,strcat(id,'__LC__cluster'),'png')
%     
    
    
    
    bin_roiNorm = roiNorm >= 0.5;
    % for n=1:size(roiNorm,1)
    for m=1:size(roiNorm,1);
        coact_Rate(m) = trapz(bin_roiNorm(m,:))/(size(roiNorm,2));
    end
    
    figure,plot(smoothdata(coact_Rate,'SmoothingFactor',0.05),'LineWidth',2, 'color','k');
%     yline(0.5, '--','Color',[.80 0 .40],'LineWidth',2)
    ylim([0,1])
    pbaspect([6 1 1]),xlim([0 1000])
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
%         title(id, 'FontSize',20)
            saveas(gcf,strcat(id,'__LC__trace'),'png')


    close all
    
   
    % set(gcf,'units','normalized','outerposition',[0 0 1 1])
    % saveas(gcf,id,'png')
end









%% Crosscorrelation plot and data from square ROI (8/9/19)

clear all
Base = 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI- control';
files = dir(Base);
dirFlags = [files.isdir];
subfolders = files(dirFlags);
subfoldernames = {subfolders.name};
subfoldernames(ismember(subfoldernames,{'.', '..','Figures - Trace Red and Blue and Corr Matrix'})) = [];
subfoldernames = fullfile(Base, subfoldernames);
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI- control';

for iFiles = 1:numel(subfoldernames); %Ctxselect;
    
    foldername = subfoldernames{iFiles};
    f = dir(fullfile(foldername, '*.mat'));
    cd(foldername);
    
    file=dir(fullfile(cd, '*.mat'));
    load(file.name);
    
    xC = [];
    for roiN = 1:size(roi,2);
        maxq = squeeze(roi(roiN).vq.maxq(:,:,3,1000:end));
        mean = squeeze(roi(roiN).vq.mean(:,:,3,1000:end));
        minq = squeeze(roi(roiN).vq.minq(:,:,3,1000:end));
        %     medq = squeeze(roi(roiN).vq.medq(:,:,4,200:end));
        xC(:,roiN) = maxq;
        %     xC(:,roiN) = mean;
    end
    
    for roiN = 1:size(roi,2);
        roiNorm(:,roiN) = (sigmoid(xC(:,roiN)))*2-1;
    end
    
    
    [R,P,RL,RU] = corrcoef(roiNorm);
    cg=clustergram(R,'Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
    set(cg,'ShowDendrogram','off')
    set(cg,'DisplayRatio',[0.001 0.001])
    cgAxes =plot(cg);
    set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [1 1 1])
    set(cg,'ColumnLabels',[],'RowLabels',[])
    colorbar
    
    title =  cellstr(strsplit(foldername,'\'));
    id = string(title(7));
    
    
    cd 'Z:\Data\susie\Temp Data-Processing\New Folder\CorrCoeffData - fromSquData'
    saveas(gcf,id,'png')
    
    save(id, 'R' ,'P', 'RL', 'RU')
    
    clearvars -except Base dirFlags files subfoldernames ii jj subfolders iFile
    
    close all hidden
    
end



%% Cross correlation violin plots (Figure) 8/10/19

clc
clear all
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\CorrCoeffData - fromSquData'
file=dir(fullfile(cd, '*.mat'));

ii = 1; jj=1;kk=1;
colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;

colorGroups = {colorSelected([1,1,2,3,3,4,4,5,6,6,7,7,12,13,14,15,16,17,18],:); ...
    colorSelected([1,1,2,3,3,5,5,6,7,7,8,8,12,13,14,15,16,17,18],:);...
    colorSelected([2,3,4,12],:)};
for n = 1:size(file,1)
    load(file(n).name);
    
    if contains(file(n).name, 'GE');
        XCorr_GE(ii).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        XCorr_GE(ii).DAT = str2double(preDAT(5));
        XCorr_GE(ii).CorrReshaped = reshape(R,[],1);
        XCorr_GE(ii).R = R;
        XCorr_GE(ii).P = P;
        XCorr_GE(ii).RL = RL;
        XCorr_GE(ii).RU = RU;
        
        ii=ii+1;
        clearvars R P RL RU preDAT
    elseif contains(file(n).name, 'Ctx');
        XCorr_Ctx(jj).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        XCorr_Ctx(jj).DAT = str2double(preDAT(5));
        XCorr_Ctx(jj).CorrReshaped = reshape(R,[],1);
        XCorr_Ctx(jj).R = R;
        XCorr_Ctx(jj).P = P;
        XCorr_Ctx(jj).RL = RL;
        XCorr_Ctx(jj).RU = RU;
        
        jj=jj+1;
        clearvars R P RL RU preDAT
        
        
    elseif contains(file(n).name, 'LC');
        XCorr_LC(kk).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        XCorr_LC(kk).DAT = str2double(preDAT(3));
        XCorr_LC(kk).CorrReshaped = reshape(R,[],1);
        XCorr_LC(kk).R = R;
        XCorr_LC(kk).P = P;
        XCorr_LC(kk).RL = RL;
        XCorr_LC(kk).RU = RU;
        
        kk=kk+1;
        clearvars R P RL RU preDAT
        
        
    end
    
end


collect = {XCorr_Ctx; XCorr_GE; XCorr_LC};

name = {'Ctx','GE','LC'};
% m=1;% <============= for Ctx
% m=2;% <============= for GE
m=3;% <============= for LC
XCorr = collect{m};

[~, gId] = unique([XCorr.DAT].', 'rows', 'stable');
XCorr = XCorr(gId);

XCorr_R = {};
for j = 1:size(XCorr,2)
    XCorr_R{j,2} = XCorr(j).CorrReshaped;
    XCorr_R(j,1) = {XCorr(j).DAT};
end
XCorr_R = sortrows(XCorr_R,1);
R = XCorr_R(:,2)';




figure

subplot(1,5,2)
violin (R,'edgecolor','none','facecolor',colorGroups{m},'facealpha',0.5);
ax = gca;
set(ax,'Xtick',[1:1:size(XCorr_R,1)],'XtickLabel',[XCorr_R{:,1}], 'FontSize',20)
%         pbaspect([3 1 1])
pbaspect([1 3 1])


title('Individual cells vs. Individual cells','FontSize',20)
ylim([-1,1.5])
clearvars R XCorr gId
set(gcf,'units','normalized','outerposition',[0 0 1 1])







%% Autocorrelation

%% Crosscorrelation population vs. individual (8/10/19)

clear all
Base = 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI- control';
files = dir(Base);
dirFlags = [files.isdir];
subfolders = files(dirFlags);
subfoldernames = {subfolders.name};
subfoldernames(ismember(subfoldernames,{'.', '..','Figures - Trace Red and Blue and Corr Matrix'})) = [];
subfoldernames = fullfile(Base, subfoldernames);
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI- control';

for iFiles = 1:numel(subfoldernames); %Ctxselect;
    
    foldername = subfoldernames{iFiles};
    f = dir(fullfile(foldername, '*.mat'));
    cd(foldername);
    
    file=dir(fullfile(cd, '*.mat'));
    load(file.name);
    
    xC = [];
    for roiN = 1:size(roi,2);
        maxq = squeeze(roi(roiN).vq.maxq(:,:,3,1000:end));
        mean = squeeze(roi(roiN).vq.mean(:,:,3,1000:end));
        minq = squeeze(roi(roiN).vq.minq(:,:,3,1000:end));
        %     medq = squeeze(roi(roiN).vq.medq(:,:,4,200:end));
        xC(:,roiN) = maxq;
        %     xC(:,roiN) = mean;
    end
    
    % roi not binarized
    for roiN = 1:size(roi,2);
        roiNorm(:,roiN) = (sigmoid(xC(:,roiN)))*2-1;
    end
    
    bin_roiNorm = roiNorm >= 0.5;
    
    % coactiavation binarized
    coact_Rate = [];
    for m=1:size(roiNorm,1);
        coact_Rate(m) = trapz(bin_roiNorm(m,:))/(size(roiNorm,2));
    end
    
    % coactivation not binarized
    coact_Rate2 = [];
    for m=1:size(roiNorm,1);
        coact_Rate2(m) = trapz(roiNorm(m,:))/(size(roiNorm,2))';
    end
    
    
    for i = 1:size(roiNorm,2);
        [R,P,RL,RU] = corrcoef(roiNorm(:,i),coact_Rate(1,:)');
        Rpop_bin(i) = R(2);
        
        [R2,P2,RL2,RU2] = corrcoef(roiNorm(:,i),coact_Rate2(1,:)');
        Rpop(i) = R2(2);
    end
    
    
    
    title =  cellstr(strsplit(foldername,'\'));
    id = string(title(7));
    
    if contains(id,'Ctx')
        R_Ctx{1,1} = Rpop_bin';
        R_Ctx{1,2} = Rpop';
        
    elseif contains(id,'GE')
        R_GE{1,1} = Rpop_bin';
        R_GE{1,2} = Rpop';
            elseif contains(id,'LC')
        R_LC{1,1} = Rpop_bin';
        R_LC{1,2} = Rpop';
        
    end
    
    %     cg=clustergram(R,'Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
    %     set(cg,'ShowDendrogram','off')
    %     set(cg,'DisplayRatio',[0.001 0.001])
    %     cgAxes =plot(cg);
    %     set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [1 1 1])
    %     set(cg,'ColumnLabels',[],'RowLabels',[])
    %     colorbar
    
    cd 'Z:\Data\susie\Temp Data-Processing\New Folder\CorrCoeff - population_VS_individual'
    %     saveas(gcf,id,'png')
    
    save(id, 'R_*')
    
    clearvars -except Base dirFlags files subfoldernames ii jj subfolders iFile
    
    %     close all hidden
    
end


%% Cross correlation violin plots population vs. individual (Figure) 8/10/19

clc
clear all
% close all
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\CorrCoeff - population_VS_individual'
file=dir(fullfile(cd, '*.mat'));

ii = 1; jj=1;kk=1;
colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;
colorGroups = {colorSelected([1,1,2,3,3,4,4,5,6,6,7,7,12,13,14,15,16,17,18],:); ...
    colorSelected([1,1,2,3,3,5,5,6,7,7,8,8,12,13,14,15,16,17,18],:);...
    colorSelected([2,3,4,12],:)};

for n = 1:size(file,1)
    load(file(n).name);
    if contains(file(n).name, 'GE');
        Corr_PvI_GE(ii).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        Corr_PvI_GE(ii).DAT = str2double(preDAT(5));
        Corr_PvI_GE(ii).BinaryPop = cell2mat(R_GE(1));
        Corr_PvI_GE(ii).Pop = cell2mat(R_GE(2));
        
        ii=ii+1;
        clearvars R_GE preDAT
        
    elseif contains(file(n).name, 'Ctx');
        Corr_PvI_Ctx(jj).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        Corr_PvI_Ctx(jj).DAT = str2double(preDAT(5));
        Corr_PvI_Ctx(jj).BinaryPop = cell2mat(R_Ctx(1));
        Corr_PvI_Ctx(jj).Pop = cell2mat(R_Ctx(2));
        
        jj=jj+1;
        clearvars R_Ctx preDAT
        
            elseif contains(file(n).name, 'LC');
        Corr_PvI_LC(kk).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        Corr_PvI_LC(kk).DAT = str2double(preDAT(3));
        Corr_PvI_LC(kk).BinaryPop = cell2mat(R_LC(1));
        Corr_PvI_LC(kk).Pop = cell2mat(R_LC(2));
        
        kk=kk+1;
        clearvars R_LC preDAT
        
        
        
    end
end

% m=1;% <============= for Ctx
% m=2;% <============= for GE
m=3;% <============= for LC

% if contains(file(n).name, 'Ctx');
%     collect = {Corr_PvI_Ctx; Corr_PvI_GE; Corr_PvI_LC};
%     XCorr_PvI = collect{m};
% else 
%     XCorr_PvI = Corr_PvI_GE;
% end
XCorr_PvI = Corr_PvI_LC;
name = {'Ctx','GE','LC'};

[~, gId] = unique([XCorr_PvI.DAT].', 'rows', 'stable');
XCorr_PvI = XCorr_PvI(gId);

XCorr_R = {};
for j = 1:size(XCorr_PvI,2)
    XCorr_R(j,1) = {XCorr_PvI(j).DAT};
    XCorr_R{j,2} = XCorr_PvI(j).BinaryPop;
    XCorr_R{j,3} = XCorr_PvI(j).Pop;
end

XCorr_R = sortrows(XCorr_R,1);
R1 = XCorr_R(:,2)';
R2 = XCorr_R(:,3)';


%     figure
subplot(1,5,4)
violin (R1,'edgecolor','none','facecolor',colorGroups{m},'facealpha',0.5);
ax = gca;
set(ax,'Xtick',[1:1:size(XCorr_R,1)],'XtickLabel',[XCorr_R{:,1}], 'FontSize',20)
%     pbaspect([3 1 1])
% pbaspect([2 1 1])
title('Individual cells vs. Population', 'FontSize',20)
%     subplot(2,1,2)
%     violin (R2,'edgecolor','none','facecolor',colorGroups{m},'facealpha',0.5);
%     ax = gca;
%     set(ax,'Xtick',[1:1:size(XCorr_R,1)],'XtickLabel',[XCorr_R{:,1}], 'FontSize',20)
    pbaspect([1 3 1])
%     title('vs. not binarized population','FontSize',20)
ylim([-1,1.5])
clearvars R XCorr gId
set(gcf,'units','normalized','outerposition',[0 0 1 1])


sgtitle(strcat('Cross correlation __ ',name(m)),'FontSize',20)

%% Figure Cross correaltion combined 8/10/19

