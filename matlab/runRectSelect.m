%%

sessionNum = 0;
sessionRoi = {};
outputFilename = ['selected-rect-rois.',datestr(now,'YYYYmmDD_HHMM'),'.json'];
sessionOutFid = fopen(outputFilename,'w');

%%

sessionNum = sessionNum + 1;
roiRect = images.roi.Rectangle.empty();
rs = simpleRectSelection(roiRect);

%%
roiRect = rs.getRect();
vid = rs.getVid();
roi = getRectRoiData(roiRect, vid);


sessionOutput = struct('filesrc',vid.filesrc,'position',{roiRect.Position}');
sessionRoi{end+1} = roi;

sessionOutStr = jsonencode(sessionOutput);
fwrite(sessionOutFid,sessionOutStr);

% selectedRect = findobj(rd.rect, 'Selected', 1)
% bw = createMask(selectedRect(1), 1024, 1024);
% for sr = selectedRect, disp(sr), end
% bw = false(1024,1024); for n=1:numel(selectedRect)
% bw = bw | createMask(selectedRect(n), 1024, 1024);
% end

%%

fclose(sessionOutFid);