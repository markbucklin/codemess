clear all

%% Data upload by cell types and RGB

cd 'Z:\Data\susie\Temp Data-Processing\New Folder'
% load('data0621_0622.mat')
% load('partialData.mat')
load('data0621_0622_0419_0628_complete.mat')


subStr_cellType = {'GE','Ctx'};
filteredStruct={};
names = fieldnames(var);

for i = 1:size(subStr_cellType,2);
    filterStruct = rmfield(var, names(find(cellfun(@isempty, strfind(names,subStr_cellType(i))))));
    tempFN = fieldnames(filterStruct);
    filteredStruct{i,1} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Red')))));
    filteredStruct{i,2} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Blue')))));
    
    clearvars filterStruct tempFN;
end

clearvars -except filteredStruct
% %% Data upload by cell types --- Sorted also by trace extracting method squared VS. automatic

clear all
cd 'Z:\Data\susie\Temp Data-Processing\New Folder'
% load('data0621_0622.mat')
% load('partialData.mat')
load('data0621_0622_0419_0628_complete.mat')
% load('data0621_0622_0419B_0628B.mat')

subStr_Squ = {'m1LH0621GE','m1rh0621GE',...
    'm2LH0621GE','m2RH0621GE',...
    'm1LH0622Ctx','m1RH0622Ctx',...
    'm2RH0622Ctx','m2LH0622Ctx'}
 
 subStr_Auto =   {'M2LH0628GE','M2RH0628GE',...
    'M1RH0628Ctx',...
    'M2RH0621GE','M2LH0622Ctx'...
    'M1LH0419Ctx','M1RH0419GE'};


subStr_cellType = {'GE','Ctx'};
filteredStruct={};
names = fieldnames(var);

for i = 1:size(subStr_Auto,2);
    filterStruct = rmfield(var, names(find(cellfun(@isempty, strfind(names,subStr_Auto(i))))));
    tempFN = fieldnames(filterStruct);
    filteredStruct{i,1} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Red')))));
    filteredStruct{i,2} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Blue')))));
end

for i = 1:size(subStr_Squ,2);
    filterStruct = rmfield(var, names(find(cellfun(@isempty, strfind(names,subStr_Squ(i))))));
    tempFN = fieldnames(filterStruct);
    filteredStruct{i,3} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Red')))));
    filteredStruct{i,4} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Blue')))));
    filteredStruct{i,5} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Green')))));

end

filteredStruct_redAuto = catstruct(filteredStruct{1:7,1});
filteredStruct_blueAuto = catstruct(filteredStruct{1:7,2});
filteredStruct_redSqu = catstruct(filteredStruct{:,3});
filteredStruct_blueSqu = catstruct(filteredStruct{:,4});
filteredStruct_greenSqu = catstruct(filteredStruct{:,5});


% filteredStruct = filteredStruct_blueAuto;% <------- change 1,2,3
% filteredStruct = filteredStruct_blueSqu;% <------- change 1,2,3
filteredStruct = filteredStruct_redSqu;% <------- change 1,2,3
% filteredStruct = filteredStruct_redAuto;% <------- change 1,2,3
% filteredStruct = filteredStruct_greenSqu;% <------- change 1,2,3


clearvars names
names = fieldnames(filteredStruct );

for i = 1:size(subStr_cellType,2);
    filterStruct = rmfield(filteredStruct, names(find(cellfun(@isempty, strfind(names,subStr_cellType(i))))));
    tempFN = fieldnames(filterStruct);
%         filteredStructT{i,1} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'Red')))));

    filteredStructT{i,1} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'mean')))));
    filteredStructT{i,2} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'maxq')))));
    filteredStructT{i,3} = rmfield(filterStruct, tempFN(find(cellfun(@isempty, strfind(tempFN,'minq')))));
end


filteredStruct = filteredStructT;
clearvars -except filteredStruct

%% Sort by days

for i =1:2;

% for Blue Traces
    tempFNs = string(fieldnames(filteredStruct{i,1}));% <------- change 1(mean),2(max),3(min)
    for ii = 1:size(fieldnames(filteredStruct{i,1}),1);% <------- change 1(mean),2(max),3(min)
        Acell(ii,:)=cellstr(strsplit(tempFNs(ii),'_'));
    end
    Acell=sortrows(Acell,3);

    for jj = 1:size(fieldnames(filteredStruct{i,1}),1);% <------- change 1(mean),2(max),3(min)
        Asorted(jj,:)=string(strjoin(Acell(jj,:),'_'));
    end
    Asorted = cellstr(Asorted);
    data = filteredStruct{i,1};% <------- change 1(mean),2(max),3(min)
    Sorted=orderfields(data, Asorted);
    sorted_filteredStruct{i,2}=Sorted;% 



%for Red Traces
%     tempFNs = string(fieldnames(filteredStruct{i,1}));
% 
%     for ii = 1:size(fieldnames(filteredStruct{i,1}),1);
%         Acell(ii,:)=cellstr(strsplit(tempFNs(ii),'_'));
%     end
%     
%         Acell=sortrows(Acell,3);
% 
%     for jj = 1:size(fieldnames(filteredStruct{i,1}),1);
%         Asorted(jj,:)=string(strjoin(Acell(jj,:),'_'));
%     end
% 
%     Asorted = cellstr(Asorted);
%     data = filteredStruct{i,1};
%     Sorted=orderfields(data, Asorted);
%     sorted_filteredStruct{i,1}=Sorted
    
    clearvars -except i filteredStruct sorted_filteredStruct
end

% clearvars -except sorted_filteredStruct


%%

filteredStruct = sorted_filteredStruct;
subStr_cellType = {'GE','Ctx'};

% close all
for ii=1:size(filteredStruct,2);
B = struct2cell(filteredStruct{ii,2});

tempFNs = string(fieldnames(filteredStruct{ii,2}));
dat = regexp((tempFNs),'\d*','Match');

for i = 1:size(dat,1);
A = string(dat{i});
days(i,1) = A(3);
end

clearvars -except sorted_filteredStruct subStr_cellType filteredStruct var days B subStr ii days

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
sgtitle(strcat(string(subStr_cellType(ii)),'_AutoRois'),'FontSize',25,'Color','blue');
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
N(n)=(174-testdays(n)).*20+n;
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



weeks = [round(double(days)/7)]';
set(ax2,'XGrid','on','YTick',N','YTickLabel',[fliplr(weeks)]);
zlim([-inf inf]);
xlim([500 1500]);ylim([-inf inf])
view(-140,80);
% view(-101,70);
title('Coactivation','FontSize',15);


%%%%%%%%%%%%%%%%% Violin plots of coactivation (LOG DATA) %%%%%%%%%%%%%%%%%
figure
% sgtitle(strcat(string(subStr_cellType(ii)),'_','squRois'),'FontSize',25,'Color','blue');
sgtitle({string(subStr_cellType(ii)),'greenSqu (MIN)'},'FontSize',25,'Color',[0.6350 0.0780 0.1840]);

subplot(2,1,1)

violinfig = violin(dat,'edgecolor','none','facecolor',color,'facealpha',0.25);
ax = gca;
set(ax,'XTick',[1:size(B,1)],'XtickLabel',weeks);
set(gcf,'units','normalized','outerposition',[0 0 1 1])
title('Coactivation (week) --- log scaled','FontSize',15);

% %%%%%%%%%%%%%%%%% Violin plots of activation rate %%%%%%%%%%%%%%%%%
subplot(2,1,2)

BlueQ={};
for n=1:size(B,1)
for m=1:size(B{n},2)
BlueQ{n,m} = trapz(B{n,1}(:,m));
end
end
for i=1:size(B,1)
    dat{1,i} = [BlueQ{i,:}]';
end

violinfig = violin(dat,'edgecolor','none','facecolor',color,'facealpha',0.25);
ax = gca;
set(ax,'XTick',[1:size(B,1)],'XtickLabel',weeks);
title('Activation rate (week)','FontSize',15);

fig1 = get(ax,'children');
% clearvars dat days


end