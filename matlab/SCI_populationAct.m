%% for extracing from RGB video and get traces in clustergram 8/7/19
% Normalization - weird way
% for roiN = 1:size(roi,2)
%     clear max
%     roiNorm(:,roiN) = (xC(:,roiN)-min(xC(:,roiN)))/max((xC(:,roiN)-min(xC(:,roiN))));
% end
% figure
% for roiN = 1:size(roi,2)
%     hold on, clear max, plot(roiNorm(:,roiN), 'LineWidth',2), hold off
% end
% fig09 = get(gca,'children');
%
% cg=clustergram(roiNorm','Cluster','column','Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
% set(cg,'ShowDendrogram','off')
% cgAxes =plot(cg);
% set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [3 1 1])
% % set(cg,'ColumnLabels',[],'RowLabels',[])
% colorbar
% fig1 = get(cgAxes,'children');





clc
clear all
file=dir(fullfile(cd, '*.mat'));
load(file.name);

clearvars -except roi 
xC = [];
for roiN = 1:size(roi,2)
    maxq = squeeze(roi(roiN).vq.maxq(:,:,3,1000:end));
    mean = squeeze(roi(roiN).vq.mean(:,:,3,1000:end));
    minq = squeeze(roi(roiN).vq.minq(:,:,3,1000:end));
    %     medq = squeeze(roi(roiN).vq.medq(:,:,4,200:end));
    xC(:,roiN) = maxq;
    %     xC(:,roiN) = mean;
end

% Plot NOT notmalized
% figure
% for roiN = 1:size(roi,2)
%     hold on
%     clear max
%     plot(xC(:,roiN), 'LineWidth',2);
%     hold off
% end

% Normalization - sigmoid
for roiN = 1:size(roi,2)
    roiNorm(:,roiN) = (sigmoid(xC(:,roiN)))*2-1;
end
% figure
% for roiN = 1:size(roi,2)
%     hold on, plot(roiNorm(:,roiN), 'LineWidth',2), hold off
% end

% cg=clustergram(roiNorm','Cluster','column','Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
% set(cg,'ShowDendrogram','off')
% cgAxes =plot(cg);
% set(cgAxes, 'Clim', [0 1], 'PlotBoxAspectRatio', [3 1 1])
% title =  cellstr(strsplit(cd,'\'))
% title = string(title{6});
% addTitle(cg,strcat(title,"----Blue Max Sigmoid"),'FontSize',20)
% set(gcf,'units','normalized','outerposition',[0 0 1 1])


% for n=1:size(roiNorm,1)
actRate = [];
for m=1:size(roiNorm,2)
actRate(m) = trapz(roiNorm(:,m))/(size(roiNorm,1)*0.5);
end
% end


color = [27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 255 253 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 255 253 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128;...
    27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85]/255;

title =  cellstr(strsplit(cd,'\'))
title = string(title{6});
filename = strcat(title,"_Activation Rate");
cd 'Z:\Data\susie\MakingFig\Popultation Activity Pattern'
save(filename, 'actRate')

cd 'Z:\Data\susie\Temp Data-Processing\New Folder'


%% for GR activation rate (Figure)
clc
% close all
clear all
cd 'Z:\Data\susie\MakingFig\Popultation Activity Pattern'

load('combined_GE_sorted.mat')

figure

colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;

% colorTrial = colorSelected([1:8,12:14,16:18],:);

    
for m=1:size(combine_GE_sorted,1);
    corrected_GE_sorted(m) = {combine_GE_sorted{m,1}./2};
end

violin(corrected_GE_sorted(1,:),'edgecolor','none','facecolor',colorSelected,'facealpha',0.5);
% violin(actRate','edgecolor','none','facecolor',color,'facealpha',0.5);
set(gcf,'units','normalized','outerposition',[0 0 1 1])
ax = gca;
% set(ax,'Xtick',[1:1:size(combine_GE_sorted,1)],'XtickLabel',round([combine_GE_sorted{:,2}]/7), 'FontSize',20)
set(ax, 'Xtick',[], 'FontSize',30)
set(ax, 'YTick',linspace(0,1,21),'YtickLabel',linspace(0,1,21))
title('Activation rate - GE')
ylim([0 0.55])
% close all



%% for Ctx activation rate (Figure) - also added to the other code SCI_burst Characterization
% for n=1:7
clc
% close all
clear all

load('combined_Ctx_sorted.mat')

figure
colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;

for m=1:size(combined_Ctx_sorted,1);
    Ctx_sorted(1,m) = {combined_Ctx_sorted{m,1}./2};
    Ctx_sorted(2,m) = {round(combined_Ctx_sorted{m,2})};
end

[~,~,gId]=unique(cell2mat(Ctx_sorted(2,:)));

groups = splitapply( @(x){x(2,:)},Ctx_sorted, gId');
data =  splitapply( @(x){x(1,:)}, Ctx_sorted, gId');

for i = 1:size(groups,2);
    Actbydays{1,i} = unique(cell2mat(groups{i}));
    Actbydays{2,i} = cell2mat(data{1,i});
    
end

colorGroups = {colorSelected([1,1,2,3,3,4,4,5,6,6,7,7,12,13,14,15,16,17,18],:); ...
    colorSelected([1:8,12:14,16:18],:)};

violin(Actbydays(2,:),'edgecolor','none','facecolor',colorGroups{1},'facealpha',0.75);
% violin(actRate','edgecolor','none','facecolor',color,'facealpha',0.5);
set(gcf,'units','normalized','outerposition',[0 0 1 1])
ax = gca;
set(ax,'Xtick',[1:1:size(Actbydays,2)],'XtickLabel',round([Actbydays{1,:}]), 'FontSize',20)
% set(ax, 'Xtick',[], 'FontSize',30)
set(ax, 'YTick',linspace(0,1,21),'YtickLabel',linspace(0,1,21))
title('Activation rate by days - Ctx')
ylim([0 0.55])




%% 

clear all
Base = 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI';
files = dir(Base);
dirFlags = [files.isdir];
subfolders = files(dirFlags);
subfoldernames = {subfolders.name};
subfoldernames(ismember(subfoldernames,{'.', '..','Figures - Trace Red and Blue and Corr Matrix'})) = [];
subfoldernames = fullfile(Base, subfoldernames);

% Ctxselect=[74 76 77 80 83 86];
% GEselect =[41 43 45 47 51 54];

ii = 1;jj=1;
for iFiles = 1:numel(subfoldernames); %Ctxselect;
%     for iFiles = 1:Ctxselect;
    
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
        
    % Plot NOT notmalized
    % figure
    % for roiN = 1:size(roi,2)
    %     hold on
    %     clear max
    %     plot(xC(:,roiN), 'LineWidth',2);
    %     hold off
    % end
    
    % Normalization - sigmoid
    for roiN = 1:size(roi,2);
        roiNorm(:,roiN) = (sigmoid(xC(:,roiN)))*2-1;
    end
    
    actRate = [];
    for m=1:size(roiNorm,2);
        actRate(m) = trapz(roiNorm(:,m))/(size(roiNorm,1)*0.5);
    end
    clear mean;
    meanActRate = mean(actRate)/2;
    bin_roiNorm = roiNorm >= 0.5;
   
       
    % figure
    % for roiN = 1:size(roi,2)
    %     hold on, plot(bin_roiNorm(:,roiN), 'LineWidth',2), hold off
    % end
    
    % cg=clustergram(roiNorm','Cluster','column','Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
    % set(cg,'ShowDendrogram','off')
    % cgAxes =plot(cg);
    % set(cgAxes, 'Clim', [0 1], 'PlotBoxAspectRatio', [3 1 1])
    % title =  cellstr(strsplit(cd,'\'))
    % title = string(title{6});
    % addTitle(cg,strcat(title,"----Blue Max Sigmoid"),'FontSize',20)
    % set(gcf,'units','normalized','outerposition',[0 0 1 1])

    
    % for n=1:size(roiNorm,1)
    for m=1:size(roiNorm,1);
        coact_Rate(m) = trapz(bin_roiNorm(m,:))/(size(roiNorm,2));
    end
    
%     figure, plot(smoothdata(coact_Rate,'SmoothingFactor',0.05),'LineWidth',2, 'color','k');
%     yline(0.5, '--','Color',[.80 0 .40],'LineWidth',2)
%     ylim([0,1])
%     pbaspect([6 1 1]),xlim([0 1000])
%     set(gcf,'units','normalized','outerposition',[0 0 1 1])
    
    burstRate = coact_Rate >= meanActRate;
%     subplot(2,2,2), plot(burstRate,'LineWidth',2);
    
%     cd 'Z:\Data\susie\MakingFig\Popultation Activity Pattern\Coactivation'
%     saveas(gcf,strcat('Ctx',num2str(iFiles),'_withLine'),'png')
    
%     figure, plot(smoothdata(coact_Rate,'SmoothingFactor',0.05),'LineWidth',2, 'color','k');
%     ylim([0,1])
%     pbaspect([6 1 1]),xlim([0 1000])
%     
%     set(gcf,'units','normalized','outerposition',[0 0 1 1])
%     burstRate = coact_Rate >=0.5;
%     saveas(gcf,strcat('Ctx',num2str(iFiles),'_withoutLine'),'png')


    
    % burst duration
    s=burstRate;
    s = sprintf('%d',s);
    t1=textscan(s,'%s','delimiter','0','multipleDelimsAsOne',1);
    d = t1{:};
    length = cellfun('length', d);
    threshold = length >= 4;
    duration = length(threshold);
        
    % burst frequncy (burst/sec)
    frequency = size(duration,1)/(size(roiNorm,1)/40);
      
    
    
    % number of cells participating in bursts
     
 
    
    title =  cellstr(strsplit(cd,'\'));
    title = string(title{7});
    number = regexp(title,'\d*','Match');
    DAT = number(5);
    id = strsplit(title,'-');
    cellType = id(4);
    
    
    if contains(cellType,'Ctx')
        collected_Ctx{ii,1} = DAT ;
        collected_Ctx{ii,2} = cellType;
        collected_Ctx{ii,3} = frequency;
        collected_Ctx{ii,4} = duration;
        ii = ii+1;
    elseif contains(cellType,'GE')
        collected_GE{jj,1} = DAT;
        collected_GE{jj,2} = cellType;
        collected_GE{jj,3} = frequency;
        collected_GE{jj,4} = duration;
        jj= jj+1;
    end
    %
    
    
    
    clearvars -except Base files ii jj subfoldernames subfolders collected* iFile dirFlags 
    
    cd 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI'
    
end

save('data_trialTWO', 'collected_Ctx','collected_GE')


% filename = strcat(title,"_Activation Rate");
% cd 'Z:\Data\susie\MakingFig\Popultation Activity Pattern'
% save(filename, 'coactRate')



%% burst duration




%%
% close all





% clear all
% axis image
% ax = gca;
% set(ax,'XtickLabel',group{2,n}, 'FontSize',10)
% end



% colorbar
% cd 'Z:\Data\susie\MakingFig\Popultation Activity Pattern'
% saveas(gcf,strcat(title,"----Blue Max Sigmoid"),'png')
% cd 'Z:\Data\susie\Temp Data-Processing\New Folder'
% pause 
% close all hidden
% clearvars -except roi fig*