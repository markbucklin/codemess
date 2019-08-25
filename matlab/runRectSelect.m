%%
clc
% close all
clear all
cd 'Z:\Data\susie\session_samples\0503'

sessionNum = 0;

sessionRoi = {};
sessionOutputId = "selected-rect-rois" + "_" + datestr(now,'YYYYmmDDHHMM');
outputFilename  = sessionOutputId + ".json";
sessionOutFid = fopen(outputFilename,'w');

%%

sessionNum = sessionNum + 1;
roiRect = images.roi.Rectangle.empty();
rs = simpleRectSelectionRGB(roiRect);


%%

roiRect = rs.getRect();
vid = rs.getVid();
roi = getRectRoiData(roiRect, vid);

%% save roi videos as uncompressed mp4 videos
cd 'Z:\Data\susie\Temp Data-Processing\New Folder'


srcName=erase(rs.filesrc,[".tif","00001","-40fps","[","]"," "])
srcName = {['sqrRoi-Vid-',srcName]};
mkdir(string(srcName))
cd(string(srcName))


for kroi = 1:numel(roi)
   vout.data = roi(kroi).vdata;
   vout.id = join(["roi" , join(string(roi(kroi).position),".")], "_");
   vout.filename = join( [sessionOutputId, vout.id],"_") ;%todo
   futavi(kroi) = parfeval( @writeUncompressedAVI, 1, vout.filename, vout.data);
%    futmp4(kroi) = parfeval( @writeCompressedHighQualityMP4, 1, vout.filename, vout.data, {"Quality",99});
%    writer = VideoWriter( vout.filename, "Uncompressed AVI");
%    open(writer)
%    writer.writeVideo(vout.data);
%    close(writer);
end

% afterEach(fut, @(varargin) disp('success'))

%% stack and save compressed video

numRoi = numel(roi);
stack.numrows = floor(sqrt(numRoi));
stack.numcols = floor(numRoi ./ stack.numrows);
for colNum = 1:stack.numrows
    
end

%%
% vid.filesrc = rs.filesrc;
sessionOutput = struct('filesrc',rs.filesrc,'position',{roiRect.Position}');
sessionRoi{end+1} = roi;

sessionOutStr = jsonencode(sessionOutput);
fwrite(sessionOutFid,sessionOutStr);

% selectedRect = findobj(rd.rect, 'Selected', 1)
% bw = createMask(selectedRect(1), 1024, 1024);
% for sr = selectedRect, disp(sr), end
% bw = false(1024,1024); for n=1:numel(selectedRect)
% bw = bw | createMask(selectedRect(n), 1024, 1024);
% end

save (string(srcName), 'roi');
close all hidden

%%

xC = {};
for roiN = 1:size(roi,2)    
    maxq = squeeze(roi(roiN).vq.maxq(:,:,:,200:end))';
    mean = squeeze(roi(roiN).vq.mean(:,:,:,200:end))';
    minq = squeeze(roi(roiN).vq.minq(:,:,:,200:end))';
    medq = squeeze(roi(roiN).vq.medq(:,:,:,200:end))';

%     xC{roiN} = maxq(:,1);
%     xCgrn{roiN} = maxq(:,2);
%     xCblu{roiN} = maxq(:,3);
    xC{roiN} = mean(:,1);
    xCgrn{roiN} = mean(:,2);
    xCblu{roiN} = mean(:,3);
%     xC{roiN} = minq(:,1);
%     xCgrn{roiN} = minq(:,2);
%     xCblu{roiN} = minq(:,3);
%     xC{roiN} = medq(:,1);
%     xCgrn{roiN} = medq(:,2);
%     xCblu{roiN} = medq(:,3);


end

%% for extracing from raw video

close all

xC = {};
for roiN = 1:size(roi,2)    
    maxq = squeeze(roi(roiN).vq.maxq(:,:,200:end));
    mean = squeeze(roi(roiN).vq.mean(:,:,200:end));
    minq = squeeze(roi(roiN).vq.minq(:,:,200:end));
    medq = squeeze(roi(roiN).vq.medq(:,:,200:end));

%     xC{roiN} = maxq(:,1);
    xC{roiN} = mean(:,1);
%     xC{roiN} = minq(:,1);
%     xC{roiN} = medq(:,1);


end

% 
% color = [91 192 235; 253 231 76; 155 197 61; 229 89 52]/255;

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
for roiN = 1:size(roi,2)
    hold on    
    clear max

    plot((xC{roiN}-min(xC{roiN}))/max((xC{roiN}-min(xC{roiN}))), 'LineWidth',8);
%     plot((xC{roiN}/max(xC{roiN})), 'LineWidth',8);

    hold off
end

hax = gca
sax = hax
max = axes
mfig = figure
max.Parent = mfig

for k=1:size(roi,2)
    mline(k) = line('XData',sax.Children(k).XData, ...
        'YData', ones(size(sax.Children(k).XData))*175*k, ...
        'ZData', sax.Children(k).YData, ...
        'Color',[color(size(roi,2)-k+1,:),0.5], 'LineWidth',2);
end
pbaspect([1 .25 .2])

axis vis3d
max.XGrid='on';
max.YTick = [];
set(gca,'XGrid','on','XTick',[linspace(0,2000,12)],'XTickLabel',[linspace(0,50,11)],'FontSize',20);

set(gca,'Position', [0 -0.2 1 1.5]);

fig2 = get(max,'children');

zlim([-inf inf]);ylim([-inf inf])
% xlim([-inf inf]);ylim([-inf inf])

% view(10,30);
view(-140,80);
set(gca,'color','none')
set(gcf,'units','normalized','outerposition',[0 0 1 1])



%% for extracing from raw video and get traces in clustergram 8/7/19
% close all hidden

xC = {};
for roiN = 1:size(roi,2)    
    maxq = squeeze(roi(roiN).vq.maxq(:,:,3,1000:end));
    mean = squeeze(roi(roiN).vq.mean(:,:,3,1000:end));
    minq = squeeze(roi(roiN).vq.minq(:,:,3,200:end));
    medq = squeeze(roi(roiN).vq.medq(:,:,3,200:end));

    xC{roiN} = maxq(:,1);
%     xC{roiN} = mean(:,1);
%     xC{roiN} = minq(:,1);
%     xC{roiN} = medq(:,1);

end


% Plot NOT notmalized
% figure
% for roiN = 1:size(roi,2)
%     hold on    
%     clear max
%     plot(xC{roiN}, 'LineWidth',2);
%     hold off
% end
% fig001 = get(gca,'children');

% Normalization - weird way
% for roiN = 1:size(roi,2)
%     clear max
%     roiNorm{roiN} = (xC{roiN}-min(xC{roiN}))/max((xC{roiN}-min(xC{roiN})));
% end
% figure
% for roiN = 1:size(roi,2)
%     hold on, clear max, plot(roiNorm{roiN}, 'LineWidth',2), hold off
% end
% fig002 = get(gca,'children');
% 
% cg=clustergram(cell2mat(roiNorm)','Cluster','column','Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
% set(cg,'ShowDendrogram','off')
% cgAxes =plot(cg);
% set(cgAxes, 'Clim', [0,1], 'PlotBoxAspectRatio', [3 1 1])
% % set(cg,'ColumnLabels',[],'RowLabels',[])
% colorbar
% fig003 = get(cgAxes,'children');

% Normalization - sigmoid
for roiN = 1:size(roi,2)
    roiNorm{roiN} = (sigmoid(xC{roiN}));
end
figure
for roiN = 1%:2%size(roi,2)
    hold on, plot(roiNorm{roiN}, 'LineWidth',2), hold off
end
% fig004 = get(gca,'children');

cg=clustergram(cell2mat(roiNorm)','Cluster','column','Colormap','redbluecmap','DisplayRange',1,'Standardize', 3,'ImputeFun', @knnimpute,'OptimalLeafOrder',[]);
set(cg,'ShowDendrogram','off')
cgAxes =plot(cg);
set(cgAxes, 'Clim', [0 1], 'PlotBoxAspectRatio', [3 1 1])
colorbar
fig005 = get(cgAxes,'children');

% figure,sgtitle('0622-M2LH-d018','FontSize',25)
% s1 = subplot(3,1,1);title('Intermediate Mean')
% s2 = subplot(3,2,3);title('Intermediate Mean Norm')
% s3 = subplot(3,2,5);title('Intermediate Mean Norm')
% s4 = subplot(3,2,4);title('Inttermediate Mean SigNorm')
% s5 = subplot(3,2,6);title('Inttermediate Mean SigNorm')


% copyobj(fig001,s1);copyobj(fig002,s2);copyobj(fig003,s3);copyobj(fig004,s4);
% copyobj(fig005,s5)


%%
Int = [];
for roiN = 1:size(roi,2)    
    Int(roiN) = trapz(xCblu{roiN});
end

histogram(Int,5)

%% corrcoeff

X = cat(2, xC{:});
Xgreen = cat(2, xCgrn{:});
Xblue = cat(2, xCblu{:});

[R,P,RL,RU] = corrcoef(X);
[grnXCorr,grnP,grnRL,grnRU] = corrcoef(Xgreen);
[bluXCorr,bluP,bluRL,bluRU] = corrcoef(Xblue);

figure

subplot(2,3,1)
R(find(eye(size(R)))) = 0;
pcolor(R)
colormap hot
colorbar
axis image

subplot(2,3,2)
grnXCorr(find(eye(size(grnXCorr)))) = 0;
pcolor(grnXCorr)
colormap hot
colorbar
axis image

subplot(2,3,3)
bluXCorr(find(eye(size(bluXCorr)))) = 0;
pcolor(bluXCorr)
colormap hot
colorbar
axis image

% 

subplot(2,3,4)
for roiN = 1:size(roi,2)
    hold on    
    plot(xC{roiN}+20*roiN);
    hold off
end

subplot(2,3,5)
for roiN = 1:size(roi,2)
    hold on    
    plot(xCgrn{roiN}+20*roiN);
    hold off
end

subplot(2,3,6)
for roiN = 1:size(roi,2)
    hold on    
    plot(xCblu{roiN}+20*roiN);
    hold off
end

src = strjoin({'Mean',rs.filesrc});
% sgtitle(src)

% saveas(gcf,src)


%%

imrgbplay(cat(1,roi.vdata))
%plot(cat(2,sessionRoi{1,1}.vtrace))
%implay(cat(1,roi.vdata))

%% after tracing - makt 3D display

hax = gca
sax = hax
max = axes
mfig = figure
max.Parent = mfig
for k=1:15, mline(k) = line('XData',sax.Children(k).XData, 'YData', ones(size(sax.Children(k).XData)).*(k-1)*100,'ZData', sax.Children(k).YData-min(sax.Children(k).YData), 'Color',sax.Children(k).Color); end
axis vis3d
ylim([0 500])



%%

fclose(sessionOutFid);