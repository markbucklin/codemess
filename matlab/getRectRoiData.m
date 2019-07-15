function roi = getRectRoiData(roiRect, vid)

% WIP

M = numel(roiRect);
numFrames = numel(vid.frame);
numPixels = 1024*1024;

roi = struct.empty(0,M);


for m = 1:M    
    rect = roiRect(m);
    
    % extract trace from video
    bw = createMask(rect, 1024,1024);            
    framePxIdx = find(bw);
    numPxIdx = numel(framePxIdx);
    vidPxIdx = framePxIdx + (0:numFrames-1)*numPixels;
    cdata = reshape(vid.original(vidPxIdx), numPxIdx, []);    
    
    % normalize video data and get trace
    vdata = single(cdata);
    vmin = min(vdata,[],1);
    vmax = max(vdata,[],1);
    vrange = max(vmax,[],ndims(vdata)) - vmin;
    vdata = (vdata - vmin).*(1./vrange);
    vmaxk = maxk(vdata,16,1); % todo
    vtrace = mean( vmaxk, 1);
    
    % assign data into structure for each roi
    roi(m).rectobj = rect;
    roi(m).position = rect.Position;
    roi(m).mask = bw;
    roi(m).cdata = cdata;
    roi(m).vdata = reshape( vdata , 64, 64, []);
    roi(m).vtrace = vtrace(:);
end

%%
