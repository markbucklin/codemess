%% Gather up data for correlation plots & activation cluster (8/17/19)

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
%             [R,P,RL,RU] = corrcoef(traceOutRed);
%             Red(j).coff = R;
%             Red(j).reshapecoff = reshape(R,[],1);
%             Red(j).name = f(ii).name;
%             j = j + 1;
            clearvars trace* R P RL RU 
        elseif exist('traceOutBlue')
            roi = traceOutBlue(1000:end,:);
            for roiN = 1:size(roi,2);
                roiNorm(:,roiN) = (sigmoid(roi(:,roiN)))*2-1;
            end
            figure
            cg=clustergram((roiNorm)','Cluster','column','Colormap','redbluecmap','DisplayRange',50,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
            set(cg,'ShowDendrogram','off')
           
            cgAxes =plot(cg);
            
            titleID =  cellstr(strsplit(filename,'\'));
            titleID = string(titleID(8))
            match=["-RedTraceROIs.mat","-BlueTraceROIs.mat","00001","-40fps"];
            id = erase(titleID,match);               
            title(cgAxes,id, 'FontSize',20)
            set(cgAxes, 'Clim', [0 1], 'PlotBoxAspectRatio', [3 1 1])
            colorbar
            cd 'Z:\Data\susie\MakingFig\2_Popultation Activity Pattern\from Auto-Rois'       
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
            saveas(gcf,strcat(id,'__LC__cluster'),'png')
            
            
            bin_roiNorm = roiNorm >= 0.5;
            % for n=1:size(roiNorm,1)
            for m=1:size(roiNorm,1);
                coact_Rate(m) = trapz(bin_roiNorm(m,:))/(size(roiNorm,2));
            end
            
            figure,plot(smoothdata(coact_Rate,'SmoothingFactor',0.05),'LineWidth',2, 'color','k');
            %     yline(0.5, '--','Color',[.80 0 .40],'LineWidth',2)
            ylim([0,1])
            pbaspect([6 1 1])
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
            title(id, 'FontSize',20)
            saveas(gcf,strcat(id,'__LC__trace'),'png')    
            
            [R,P,RL,RU] = corrcoef(roiNorm);
            cg=clustergram(R,'Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
            set(cg,'ShowDendrogram','off')
            set(cg,'DisplayRatio',[0.001 0.001])
            cgAxes =plot(cg);
            set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [1 1 1])
            title(cgAxes,id, 'FontSize',20)
            set(cg,'ColumnLabels',[],'RowLabels',[])
            colorbar
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
            
            saveas(gcf,id,'png')
            save(id, 'R' ,'P', 'RL', 'RU')
            clearvars -except Base dirFlags files subfoldernames ii jj subfolders iFile foldername f
            close all hidden
        end
    end
end



%% Cross correlation violin plots (Figure) 8/10/19

clc
clear all
% close all
cd 'Z:\Data\susie\MakingFig\2_Popultation Activity Pattern\from Auto-Rois'
file=dir(fullfile(cd, '*.mat'));
XCorr_GE={};XCorr_Ctx={};

ii = 1; jj=1;
colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;
% colorGroups = {colorSelected([1,1,2,3,3,4,4,5,6,6,7,7,12,13,14,15,16,17,18],:); ...
%     colorSelected([1,1,2,3,3,5,5,6,7,7,8,8,12,13,14,15,16,17,18],:)};

for n = 1:size(file,1)
    load(file(n).name);
    
    if contains(file(n).name, 'GE');
        XCorr_GE(ii).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        XCorr_GE(ii).DAT = str2double(preDAT(3));
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
        XCorr_Ctx(jj).DAT = str2double(preDAT(3));
        XCorr_Ctx(jj).CorrReshaped = reshape(R,[],1);
        XCorr_Ctx(jj).R = R;
        XCorr_Ctx(jj).P = P;
        XCorr_Ctx(jj).RL = RL;
        XCorr_Ctx(jj).RU = RU;
        
        jj=jj+1;
        clearvars R P RL RU preDAT
    end
    
end


collect = {XCorr_Ctx; XCorr_GE};

name = {'Ctx','GE'};
% m=1;% <============= for Ctx
m=2;% <============= for GE
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

day  = round(cell2mat(XCorr_R(:,1)')/7)
colorGroups = colorSelected([day],:)


% figure

subplot(1,2,1)
violin (R,'edgecolor','none','facecolor',colorGroups,'facealpha',0.5);
ax = gca;
set(ax,'Xtick',[1:1:size(XCorr_R,1)],'XtickLabel',[XCorr_R{:,1}], 'FontSize',20)
%         pbaspect([3 1 1])
pbaspect([2 1 1])

match=['.mat'];
% title(strcat('Individual cells vs. Individual cells---',erase(string(XCorr_GE(1).name),match)),'FontSize',20)
title('Individual cells vs. Individual cells---','FontSize',20)

ylim([-1,1.5])
clearvars R XCorr gId
set(gcf,'units','normalized','outerposition',[0 0 1 1])


%% Crosscorrelation population vs. individual (8/10/19)

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
%             [R,P,RL,RU] = corrcoef(traceOutRed);
%             Red(j).coff = R;
%             Red(j).reshapecoff = reshape(R,[],1);
%             Red(j).name = f(ii).name;
%             j = j + 1;
            clearvars trace* R P RL RU 
        elseif exist('traceOutBlue')
            roi = traceOutBlue(1000:end,:);
            for roiN = 1:size(roi,2);
                roiNorm(:,roiN) = (sigmoid(roi(:,roiN)))*2-1;
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
    
   titleID =  cellstr(strsplit(filename,'\'));
            titleID = string(titleID(8))
            match=["-RedTraceROIs.mat","-BlueTraceROIs.mat","00001","-40fps"];
            id = erase(titleID,match);          

    
    if contains(id,'Ctx')
        R_Ctx{1,1} = Rpop_bin';
        R_Ctx{1,2} = Rpop';
        
    elseif contains(id,'GE')
        R_GE{1,1} = Rpop_bin';
        R_GE{1,2} = Rpop';
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
    
    clearvars -except Base dirFlags files subfoldernames ii jj subfolders iFile foldername f
    
    %     close all hidden
    
        end
    end
end



%% Cross correlation violin plots population vs. individual (Figure) 8/10/19

clc
clear all
% close all
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\CorrCoeff - population_VS_individual'
file=dir(fullfile(cd, '*.mat'));

ii = 1; jj=1;
colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;

for n = 1:51%size(file,1)
    load(file(n).name);
    if contains(file(n).name, 'GE');
        Corr_PvI_GE(ii).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        Corr_PvI_GE(ii).DAT = str2double(preDAT(3));
        Corr_PvI_GE(ii).BinaryPop = cell2mat(R_GE(1));
        Corr_PvI_GE(ii).Pop = cell2mat(R_GE(2));
        
        ii=ii+1;
        clearvars R_GE preDAT
        
    elseif contains(file(n).name, 'Ctx');
        Corr_PvI_Ctx(jj).name = file(n).name;
        preDAT = regexp(file(n).name,'\d*','Match');
        Corr_PvI_Ctx(jj).DAT = str2double(preDAT(3));
        Corr_PvI_Ctx(jj).BinaryPop = cell2mat(R_Ctx(1));
        Corr_PvI_Ctx(jj).Pop = cell2mat(R_Ctx(2));
        
        jj=jj+1;
        clearvars R_Ctx preDAT
    end
end

% m=1;% <============= for Ctx
m=2;% <============= for GE
if contains(file(n).name, 'Ctx');
    collect = {Corr_PvI_Ctx; Corr_PvI_GE};
    XCorr_PvI = collect{m};
    
else
    XCorr_PvI = Corr_PvI_GE;
end
name = {'Ctx','GE'};

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

day  = round(cell2mat(XCorr_R(:,1)')/7)
colorGroups = colorSelected([day],:)


%     figure
subplot(1,2,2)
violin (R1,'edgecolor','none','facecolor',colorGroups,'facealpha',0.5);
ax = gca;
set(ax,'Xtick',[1:1:size(XCorr_R,1)],'XtickLabel',[XCorr_R{:,1}], 'FontSize',20)
%     pbaspect([3 1 1])
pbaspect([2 1 1])
title('Individual cells vs. Population', 'FontSize',20)
%     subplot(2,1,2)
%     violin (R2,'edgecolor','none','facecolor',colorGroups{m},'facealpha',0.5);
%     ax = gca;
%     set(ax,'Xtick',[1:1:size(XCorr_R,1)],'XtickLabel',[XCorr_R{:,1}], 'FontSize',20)
%     pbaspect([3 1 1])
%     title('vs. not binarized population','FontSize',20)
ylim([-1,1.5])
clearvars R XCorr gId
set(gcf,'units','normalized','outerposition',[0 0 1 1])


sgtitle(strcat('Cross correlation __ ',name(m)),'FontSize',20)


%% burst duration and frequency sorted by weeks (All 3 figures) 8/9/19


close all
clear all
clc
name = {'Ctx','GE'};
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI'
load('data_trialTWO2.mat')
load('collectedBoth')
collect = {collected_Ctx, collected_GE};
activation_collect = {combined_Ctx_sorted, combine_GE_sorted};

colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;

for m = 1:2
    figure
    %%%%%%%%%%%%%%% BURST FREQUENCY %%%%%%%%%%%%%%%
    
    
    collected = collect{m};
    [~,~,gId]=unique(cell2mat(collected(1:end,1)),'row');
    groups = splitapply( @(x){x(:,3)}, collected, gId);
    days =  splitapply( @(x){x(:,1)}, collected, gId);
    
    for i = 1:size(groups,1);
        Ctxbyweek{1,i} = cell2mat(groups{i});
        Ctxbyweek{2,i} = unique(cell2mat(days{i}));
        
    end
    
    for i = 1:size(groups,1);
        Ctxbyweek{3,i} = mean(Ctxbyweek{1,i});
        Ctxbyweek{4,i} = std(Ctxbyweek{1,i});
    end
    
    subplot(3,2,[1 2])
    x = [Ctxbyweek{2,:}]/7;
    y = [Ctxbyweek{3,:}];
    err = [Ctxbyweek{4,:}];
    
    sz = 40;
    
    
    pbaspect([6 1 1]),ylim([0 inf])
    coefficients = polyfit(x, y, 5);
    xFit = linspace(min(x), max(x), 1000);
    yFit = polyval(coefficients , xFit);
    title('Burst frequency by weeks')
    hold on;
    errorbar(x,y,err,'vertical','*')
    
    plot(xFit, yFit, '--','Color',[239/255 71/255 111/255 0.75], 'LineWidth', 2);%yline(0.5, '--','Color',[.80 0 .40],'LineWidth',2)
    axes = gca;
    set(axes,'FontSize',20)
    grid on;
    
    scatter(x,y,sz,'MarkerEdgeColor',[0 .5 .5],...
        'MarkerFaceColor',[36 123 160]/255,...
        'LineWidth',1.5)
    % plot([Ctxbyweek{2,:}],[Ctxbyweek{3,:}])
    clearvars -except collect_Ctx collect_GE colorSelected colorTrial collect name m ...
        combine_GE_sorted combined_Ctx-sorted activation_collect
        

    %%%%%%%%%%%%%%% BURST DURATION %%%%%%%%%%%%%%%

    collected = collect{m};
    [~,~,gId]=unique(cell2mat(collected(1:end,1)),'row');
    groups = splitapply( @(x){x(:,4)}, collected, gId);
    days =  splitapply( @(x){x(:,1)}, collected, gId);
    
%     for i = 1:size(groups,1);
%         Ctxbyweek{1,i} = cell2mat(groups{i});
%         Ctxbyweek{2,i} = unique(cell2mat(days{i}));
%     end
%     for i = 1:size(groups,1);
%         Ctxbyweek{5,i} = round([Ctxbyweek{2,i}]/7);
%     end
%     for i = 1:size(groups,1);
%         Ctxbyweek{3,i} = mean(Ctxbyweek{1,i});
%         Ctxbyweek{4,i} = std(Ctxbyweek{1,i});
%     end
%     
%     
%     [~,~,g2Id]=unique(cell2mat(Ctxbyweek(5,1:end)));
%     groups_two = splitapply( @(x){x(5,:)}, Ctxbyweek, g2Id');
%     data = splitapply( @(x){x(1,:)}, Ctxbyweek, g2Id');
%     colorTrial = {colorSelected([1:3,5:8,12:18],:); ...
%         colorSelected([1:8,12:14,16:18],:)};


    for i = 1:size(groups,1);
        Ctxbyday{1,i} = cell2mat(groups{i});
        Ctxbyday{2,i} = unique(cell2mat(days{i}));
    end
    for i = 1:size(groups,1);
        Ctxbyday{5,i} = round([Ctxbyday{2,i}]);
    end
    for i = 1:size(groups,1);
        Ctxbyday{3,i} = mean(Ctxbyday{1,i});
        Ctxbyday{4,i} = std(Ctxbyday{1,i});
    end
    
    
    [~,~,g2Id]=unique(cell2mat(Ctxbyday(5,1:end)));
    groups_two = splitapply( @(x){x(5,:)}, Ctxbyday, g2Id');
    data = splitapply( @(x){x(1,:)}, Ctxbyday, g2Id');
    
    
        
    for i = 1:size(groups_two,2);
        SortbyWeek{1,i} = unique(cell2mat(groups_two{i}));
        SortbyWeek{2,i} = cell2mat(data{1,i}(:));
    end
    
    colorTrial = {colorSelected([1,1,2,3,3,4,4,5,6,6,7,7,12,13,14,15,16,17,18],:); ...
        colorSelected([1,1,2,3,3,5,5,6,7,7,8,8,12,13,14,15,16,17,18],:)};
    x = SortbyWeek(1,:);


    subplot(3,2,[3 5])
    violin(SortbyWeek(2,:),'edgecolor','none','facecolor',colorTrial{m},'facealpha',0.75);
    % violin(actRate','edgecolor','none','facecolor',color,'facealpha',0.5);
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
    ax = gca;
    
    set(ax,'Xtick',[1:1:size(x,2)],'XtickLabel',cell2mat(x))
    set(ax,'Ytick',[0:20:160],'YtickLabel',[0:20:160]/40,'FontSize',20)
    

    ylim([-10 160])
    % xlim([0 15])
    title('Burst duration by days')
    sgtitle(name(m),'FontSize',20)
    
    clearvars -except collect_Ctx collect_GE colorSelected colorTrial collect name m ...
        combine_GE_sorted combined_Ctx-sorted activation_collect
        

    %%%%%%%%%%%%%%% ACTIVATION RATE %%%%%%%%%%%%%%%

    act_sorted = activation_collect{m};
    
    
    for ii=1:size(act_sorted,1);
        activation(1,ii) = {act_sorted{ii,1}./2};
        activation(2,ii) = {round(act_sorted{ii,2})};
    end
    
    [~,~,gId]=unique(cell2mat(activation(2,:)));
    groups = splitapply( @(x){x(2,:)},activation, gId');
    data =  splitapply( @(x){x(1,:)},activation, gId');
    
    
    Actbydays={};
    
    if m == 1;
        for jj = 1:size(groups,2);
            Actbydays{1,jj} = unique(cell2mat(groups{jj}));
            Actbydays{2,jj} = cell2mat(data{jj});
        end
    elseif m ==2;
        for jj = 1:size(groups,2);
            Actbydays{1,jj} = unique(cell2mat(groups{jj}));
            Actbydays{2,jj} = cell2mat(data{jj}(:));
        end
    end
    
    colorGroups = {colorSelected([1,1,2,3,3,4,4,5,6,6,7,7,12,13,14,15,16,17,18],:); ...
        colorSelected([1,1,2,3,3,5,5,6,7,7,8,8,12,13,14,15,16,17,18],:)};
    
    subplot(3,2,[4 6])
    violin(Actbydays(2,:),'edgecolor','none','facecolor',colorGroups{m},'facealpha',0.75);
    % violin(actRate','edgecolor','none','facecolor',color,'facealpha',0.5);
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
    ax = gca;
    set(ax,'Xtick',[1:1:size(Actbydays,2)],'XtickLabel',round([Actbydays{1,:}]), 'FontSize',20)
    % set(ax, 'Xtick',[], 'FontSize',30)
    set(ax, 'YTick',linspace(0,1,21),'YtickLabel',linspace(0,1,21))
    title('Activation rate by days')
    ylim([0 0.55])
    
    clearvars -except collect_Ctx collect_GE colorSelected colorTrial collect name m ...
        combine_GE_sorted combined_Ctx-sorted activation_collect
    
    

end