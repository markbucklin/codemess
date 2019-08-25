ii=1;jj=1;

for i = 1:95
if contains(collected{i,2},'GE')
collect_GE(ii,1:4) = collected(i,1:4);
ii=ii+1;
elseif contains(collected{i,2},'Ctx')
collect_Ctx(jj,1:4) = collected(i,1:4);
jj=jj+1;
end
end


%%
for ii = 1: 41;
collected_Ctx{ii,1} = str2num(cell2mat(collected_Ctx{ii,1}));
end
for jj = 1: 54
collected_GE{jj,1} = str2num(cell2mat(collected_GE{jj,1}));
end

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


%%
close all
figure
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI'
load('data_trialTWO2.mat')
collect = {collected_Ctx, collected_GE};
name = {'Ctx','GE'};
for m = 1:2
    
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

subplot(2,1,m)
x = [Ctxbyweek{2,:}]/7;
y = [Ctxbyweek{3,:}];
err = [Ctxbyweek{4,:}];

sz = 40;


pbaspect([6 1 1]),ylim([0 inf])
coefficients = polyfit(x, y, 5);
xFit = linspace(min(x), max(x), 1000);
yFit = polyval(coefficients , xFit);
title(char(name(m)))
hold on;
errorbar(x,y,err,'vertical','*')

plot(xFit, yFit, '--','Color',[239/255 71/255 111/255 0.75], 'LineWidth', 2,'FontSize',20);%yline(0.5, '--','Color',[.80 0 .40],'LineWidth',2)
grid on;

scatter(x,y,sz,'MarkerEdgeColor',[0 .5 .5],...
              'MarkerFaceColor',[36 123 160]/255,...
              'LineWidth',1.5)
% plot([Ctxbyweek{2,:}],[Ctxbyweek{3,:}])
clearvars -except collect_Ctx collect_GE colorSelected colorTrial collect name ...


end



%% burst duration sorted by weeks (Figure)


clear all
cd 'Z:\Data\susie\Temp Data-Processing\New Folder\ROI'
load('data_trialTWO2.mat')
colorSelected = cell2mat({[91 192 235];[253 231 76];[155 197 61];[229 89 52];[250 121 33];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76];...
    [80 81 79];[242 95 92];[255 224 102];[36 123 160];[112 193 179];...
    [246 81 29];[255 180 0];[0 166 237];[127 184 0];[13 44 84];...
    [239 71 111];[255 209 102];[6 214 160];[17 138 178];[7 59 76]})/255;
% 
% colorTrial = {[colorSelected(1,:);colorSelected(1,:);colorSelected(2,:);colorSelected(3,:);colorSelected(3,:);...
%     colorSelected(5,:);colorSelected(5,:);colorSelected(6,:);colorSelected(7,:);colorSelected(7,:);colorSelected(8,:);...
%     colorSelected(8,:);colorSelected(12,:);colorSelected(13,:);colorSelected(14,:);colorSelected(15,:);colorSelected(16,:);colorSelected(17,:);...
%     colorSelected(18,:)];...
%     [colorSelected(1,:);colorSelected(1,:);colorSelected(2,:);colorSelected(3,:);colorSelected(3,:);...
%     colorSelected(4,:);colorSelected(5,:);colorSelected(5,:);colorSelected(6,:);colorSelected(7,:);colorSelected(7,:);colorSelected(8,:);...
%     colorSelected(8,:);colorSelected(12,:);colorSelected(13,:);colorSelected(14,:);colorSelected(16,:);colorSelected(17,:);...
%     colorSelected(18,:)]};


close all
figure
collect = {collected_Ctx, collected_GE};
name = {'Ctx','GE'};
for m = 1:2
    
collected = collect{m};
[~,~,gId]=unique(cell2mat(collected(1:end,1)),'row');
groups = splitapply( @(x){x(:,4)}, collected, gId);
days =  splitapply( @(x){x(:,1)}, collected, gId);

for i = 1:size(groups,1);
    Ctxbyweek{1,i} = cell2mat(groups{i});
    Ctxbyweek{2,i} = unique(cell2mat(days{i}));
end
for i = 1:size(groups,1);
        Ctxbyweek{5,i} = round([Ctxbyweek{2,i}]/7);
end
for i = 1:size(groups,1);
    Ctxbyweek{3,i} = mean(Ctxbyweek{1,i});
    Ctxbyweek{4,i} = std(Ctxbyweek{1,i});
end

% x = [Ctxbyweek{2,:}]/7;
% y = [Ctxbyweek{3,:}];
% err = [Ctxbyweek{4,:}];
% 
% subplot(2,1,m)
% violin(Ctxbyweek(1,:),'edgecolor','none','facecolor',colorTrial{m,1},'facealpha',0.5);
% % violin(actRate','edgecolor','none','facecolor',color,'facealpha',0.5);
% set(gcf,'units','normalized','outerposition',[0 0 1 1])
% ax = gca;
% set(ax,'Xtick',[1:1:size(x,2)],'XtickLabel',round(x), 'FontSize',20)
% ylim([-10 160])
% xlim([0 20])
% title(name(m))


[~,~,g2Id]=unique(cell2mat(Ctxbyweek(5,1:end)));
groups_two = splitapply( @(x){x(5,:)}, Ctxbyweek, g2Id');
data = splitapply( @(x){x(1,:)}, Ctxbyweek, g2Id');

for i = 1:size(groups_two,2);
    SortbyWeek{1,i} = unique(cell2mat(groups_two{i}));
    SortbyWeek{2,i} = cell2mat(data{1,i}(:));
end

colorTrial = {colorSelected([1:3,5:8,12:18],:); ...
    colorSelected([1:8,12:14,16:18],:)};
x = SortbyWeek(1,:);


subplot(2,1,m)
violin(SortbyWeek(2,:),'edgecolor','none','facecolor',colorTrial{m},'facealpha',0.75);
% violin(actRate','edgecolor','none','facecolor',color,'facealpha',0.5);
set(gcf,'units','normalized','outerposition',[0 0 1 1])
ax = gca;
set(ax,'Xtick',[1:1:size(x,2)],'XtickLabel',cell2mat(x), 'FontSize',20)
ylim([-10 160])
% xlim([0 15])
title(name(m))



% set(ax, 'Xtick',[], 'FontSize',30)
% set(ax, 'YTick',linspace(0,1,21),'YtickLabel',linspace(0,1,21))
% title('Activation rate - Ctx')


% sz = 40;
% scatter(x,y,sz,'MarkerEdgeColor',[0 .5 .5],...
%               'MarkerFaceColor',[0 .7 .7],...
%               'LineWidth',1.5)

% pbaspect([6 1 1]),ylim([0 1])
% coefficients = polyfit(x, y, 5);
% xFit = linspace(min(x), max(x), 1000);
% yFit = polyval(coefficients , xFit);
% title(char(name(m)))
% hold on;
% errorbar(x,y,err,'vertical','*')
% 
% plot(xFit, yFit, '--','Color',[.80 0 .40], 'LineWidth', 2);%yline(0.5, '--','Color',[.80 0 .40],'LineWidth',2)
% grid on;
% plot([Ctxbyweek{2,:}],[Ctxbyweek{3,:}])

clearvars -except collect_Ctx collect_GE colorSelected colorTrial collect name ...
    
end






% 
% 
% y = [collect_GE{:,3}];
% x = [collect_GE{:,1}];
% % scatter(x,y)
% 
% 
% y1 = [collect_Ctx{:,3}];
% x1 = [collect_Ctx{:,1}];
% scatter(x1,y1)
% plot(x1,y1)

%%
clearvars -except collect_GE collect_Ctx

weekOne =1;weekTwo =1;weekThree =1;weekFour =1;weekFive =1;weekSix =1;...
    weekSeven =1;weekEight =1;weekNine =1;weekTen =1;weekEleven =1;...
    weekTwleve =1;


collected = collect_Ctx;

whos