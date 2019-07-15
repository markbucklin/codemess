%%
rs = simpleRectSelection();

wait
rd(1).rect = rs.getRect();
rd(1).vid = rs.getVid();

% selectedRect = findobj(rd.rect, 'Selected', 1)
% bw = createMask(selectedRect(1), 1024, 1024);
% for sr = selectedRect, disp(sr), end
% bw = false(1024,1024); for n=1:numel(selectedRect)
% bw = bw | createMask(selectedRect(n), 1024, 1024);
% end

%%


M = numel(rd.rect);
numFrames = numel(rd.vid.frame);
numPixels = 1024*1024;

roi = struct.empty(0,M);


for m = 1:M    
    rect = rd.rect(m);
    
    % extract trace from video
    bw = createMask(rect, 1024,1024);            
    framePxIdx = find(bw);
    numPxIdx = numel(framePxIdx);
    vidPxIdx = framePxIdx + (0:numFrames-1)*numPixels;
    cdata = reshape(rd.vid.original(vidPxIdx), numPxIdx, []);    
    
    % normalize video data and get trace
    vdata = single(cdata);
    vmin = min(vdata,[],1);
    vmax = max(vdata,[],1);
    vrange = max(vmax,[],ndims(vdata)) - vmin;
    vdata = (vdata - vmin).*(1./vrange);
    vmaxk = maxk(vdata,16,1); % todo
    vtrace = mean( vmaxk, 1);
    
    % assign data into structure for each roi
    roi(m).rect = rect;
    roi(m).mask = bw;
    roi(m).cdata = cdata;
    roi(m).vdata = reshape( vdata , 64, 64, []);
    roi(m).vtrace = vtrace(:);
end

%%
plot([roi.vtrace])


imscplay(cat(1, roi.vdata))