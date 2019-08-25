clear all

cd 'Z:\Data\susie\Temp Data-Processing\New Folder'
% load('data0621_0622.mat')
% load('partialData.mat')
load('data0621_0622_0419B_0628B.mat')

names = fieldnames(var);
subStr = {'m1LH0621GE','m1rh0621GE',...
    'm2LH0621GE','m2RH0621GE',...
    'm1LH0622Ctx','m1RH0622Ctx',...
    'm2RH0622Ctx','m2LH0622Ctx',...
    'M2LH0628GE','M2RH0628GE',...
    'M1RH0628Ctx',...
    'M2RH0621GE','M2LH0622Ctx'...
    'M1LH0419Ctx','M1RH0419GE'};


filteredStruct={};
for i = 1:size(subStr,2);
    filterStruct = rmfield(var, names(find(cellfun(@isempty, strfind(names,subStr(i))))));
    tempFN = fieldnames(filterStruct);
    filteredStruct{i,1} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Red')))));
    filteredStruct{i,2} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Blue')))));
    
    clearvars filterStruct tempFN
end

clearvars -except filteredStruct var subStr

%% Violin plot of cell coactivation (area underthe curve per frame) and traces
clc
close all
for ii=1:8%size(filteredStruct,1);
B = struct2cell(filteredStruct{ii,2});

tempFNs = string(fieldnames(filteredStruct{ii,2}));
dat = regexp((tempFNs),'\d*','Match');

for i = 1:size(dat,1);
A = string(dat{i});
days(i,1) = A(3);
end

clearvars -except filteredStruct var days B subStr ii days

color = [27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 255 253 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 255 253 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128;...
    27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128;...
    27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128]/255;


figure
sgtitle(strcat(string(subStr(ii)),'_squRois'),'FontSize',25,'Color','blue');
s2 = subplot(2,2,[3,4]);

% Cells over time
BlueQ={};
for n=1:size(B,1)
for m=1:size(B{n},1)
BlueQ{n,m} = (trapz(B{n,1}(m,:)));

end
end

h2=figure
hold on
for m=1:size(B,1)
    logData = log([BlueQ{m,:}]);
    logData(logData < 0) = 0;
    dat{1,m} = logData';
    %     dat{1,m} = [BlueQ{m,:}]';
    plot(smoothdata(logData,'SmoothingFactor',0),...
        'Color',[color(m,:) 0.5]);
end
hold off

hax = gca
sax = hax
max = axes
mfig = figure
testdays = double(days);
max.Parent = mfig

for n=1:size(B,1)
N(n)=(testdays(size(B,1))-testdays(n)).*20;
end
N=sort(N);

for k=1:m
    mline(k) = line('XData',sax.Children(k).XData, ...
        'YData', ones(size(sax.Children(k).XData)).*(N(k)), ...
        'ZData', sax.Children(k).YData-min(sax.Children(k).YData), ...
        'Color',[color(m-k+1,:) 0.5]);
end

axis vis3d
max.XGrid='on';
max.YTick = [];
set(gca,'Position', [0 0.1 1 0.7]);

fig2 = get(max,'children');

copyobj(fig2,s2);
close(h2,mfig);
ax2 = gca;
set(ax2,'XGrid','on','YTick',sort(N),'YTickLabel',[fliplr(days')]);
zlim([-0.3 inf]);
xlim([200 1800]);ylim([-inf inf])
view(-140,80);
% view(-101,70);
title('Coactivation','FontSize',15);


%%%%%%%%%%%%%%%%% Violin plots of coactivation (LOG DATA) %%%%%%%%%%%%%%%%%
subplot(2,2,1)

violinfig = violin(dat,'edgecolor','none','facecolor',color,'facealpha',0.8);
ax = gca;
set(ax,'XTick',[1:size(B,1)],'XtickLabel',days');
set(gcf,'units','normalized','outerposition',[0 0 1 1])
title('Coactivation','FontSize',15);

%%%%%%%%%%%%%%%%% Violin plots of activation rate %%%%%%%%%%%%%%%%%
subplot(2,2,2)

BlueQ={};
for n=1:size(B,1)
for m=1:size(B{n},2)
BlueQ{n,m} = trapz(B{n,1}(:,m));
end
end
for i=1:size(B,1)
    dat{1,i} = [BlueQ{i,:}]';
end

violinfig = violin(dat,'edgecolor','none','facecolor',color,'facealpha',0.5);
ax = gca;
set(ax,'XtickLabel',days')
title('Activation rate','FontSize',15);

fig1 = get(ax,'children');
clearvars dat days


end











%% Violin plot of cell coactivation (area underthe curve per frame) and traces
%%%%%%%%%%%%%%%%%%%%%%% FOR 9 TO 15

clc
% close all
for ii=9:size(filteredStruct,1);
B = struct2cell(filteredStruct{ii,2});

tempFNs = string(fieldnames(filteredStruct{ii,2}));
dat = regexp((tempFNs),'\d*','Match');

for i = 1:size(dat,1);
A = string(dat{i});
days(i,1) = A(3);
end

clearvars -except filteredStruct var days B subStr ii 

color = [27 153 139; 45 48 71; 197 14 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 255 253 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128; ...
    27 153 139; 45 48 71; 255 253 130; 255 155 113; 232 72 85; ...
    17 70 87; 44 23 91; 198 35 48; 197 14 87; 128 128 128]/255;


figure
sgtitle(strcat(string(subStr(ii)),'_autoRois'),'FontSize',25,'Color','blue');
s2 = subplot(2,2,[3,4]);

% Cells over time
BlueQ={};
for n=1:size(B,1)
for m=1:size(B{n},1)
BlueQ{n,m} = (trapz(B{n,1}(m,:)));
end
end

h2=figure
hold on
for m=1:size(B,1)
%     logData = log([BlueQ{m,:}]);
%     logData(logData < 0) = 0;
%     dat{1,m} = logData';
%     %     dat{1,m} = [BlueQ{m,:}]';
%     plot(smoothdata(logData,'SmoothingFactor',0.1),...
%         'Color',[color(m,:) 0.5]);

    noneg_BlueQ = [BlueQ{m,:}];
    noneg_BlueQ(noneg_BlueQ < 0) = 0;
    logData =log(noneg_BlueQ);
    logData(logData < 0) = 0;
    dat{1,m} = logData';
    %     dat{1,m} = [BlueQ{m,:}]';
    plot(smoothdata(logData,'SmoothingFactor',0),...
        'Color',[color(m,:) 0.5]);

end
hold off

hax = gca
sax = hax
max = axes
mfig = figure
testdays = double(days);
max.Parent = mfig

for n=1:size(B,1)
N(n)=(testdays(size(B,1))-testdays(n)).*20;
end
N=sort(N);

for k=1:m
    mline(k) = line('XData',sax.Children(k).XData, ...
        'YData', ones(size(sax.Children(k).XData)).*(N(k)), ...
        'ZData', sax.Children(k).YData-min(sax.Children(k).YData), ...
        'Color',[color(m-k+1,:) 0.5]);
end

axis vis3d
max.XGrid='on';
max.YTick = [];
set(gca,'Position', [0 0.1 1 0.7]);

fig2 = get(max,'children');

copyobj(fig2,s2);
close(h2,mfig);
ax2 = gca;
set(ax2,'XGrid','on','YTick',sort(N),'YTickLabel',[fliplr(days')]);
zlim([-0.3 inf]);
xlim([3200 4800]);ylim([-inf inf])
view(-140,80);
title('Coactivation','FontSize',15);


%%%%%%%%%%%%%%%%% Violin plots of coactivation (LOG DATA) %%%%%%%%%%%%%%%%%
subplot(2,2,1)

violinfig = violin(dat,'edgecolor','none','facecolor',color,'facealpha',0.8);
ax = gca;
set(ax,'XTick',[1:size(B,1)],'XtickLabel',days');
set(gcf,'units','normalized','outerposition',[0 0 1 1])
title('Coactivation','FontSize',15);

%%%%%%%%%%%%%%%%% Violin plots of activation rate %%%%%%%%%%%%%%%%%
subplot(2,2,2)

BlueQ={};
for n=1:size(B,1)
for m=1:size(B{n},2)
BlueQ{n,m} = trapz(B{n,1}(:,m));
end
end
for i=1:size(B,1)
    dat{1,i} = [BlueQ{i,:}]';
end

violinfig = violin(dat,'edgecolor','none','facecolor',color,'facealpha',0.5);
ax = gca;
set(ax,'XtickLabel',days')
title('Activation rate','FontSize',15);

fig1 = get(ax,'children');
clearvars dat days


end

%% Histogram

figure
subplot(1,7,1)
histogram([BlueQ{1,:}]);
subplot(1,7,2)
histogram([BlueQ{2,:}]);
subplot(1,7,3)
histogram([BlueQ{3,:}]);
subplot(1,7,4)
histogram([BlueQ{4,:}]);
subplot(1,7,5)
histogram([BlueQ{5,:}]);
subplot(1,7,6)
histogram([BlueQ{6,:}]);
subplot(1,7,7)
histogram([BlueQ{7,:}]);

histogram([BlueQ{:,:}]);







