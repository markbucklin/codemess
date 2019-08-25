function out = getRectRoiData(roiRect, vid)

% WIP

M = numel(roiRect);
if isstruct(vid)
    out = structfun(@getRectRoiData, vid,'UniformOutput',false);
    
elseif isnumeric(vid) && ndims(vid)>=3
    
    lastDim = ndims(vid);
    sz = size(vid);
    numFrames = sz(end); %size(vid, lastDim);
    frameSize = sz(1:2);
    if lastDim>3
        numChannels = sz(3:end-1);
    else
        numChannels = 1;
    end
    %     numPixelsPerFrame = prod(frameSize);
    
    roi = struct.empty(0,M);
    
    
    for m = 1:M
        rect = roiRect(m);
        
        % extract trace from video
        bw = createMask(rect, frameSize(1), frameSize(2));
        framePxIdx = find(bw);
        numPxIdx = numel(framePxIdx);
        vidPxIdx = framePxIdx;
        for d=3:lastDim
            numPixelsPerDimsBefore = prod(sz(1:d-1));
            nextDimVec = (0:sz(d)-1).*numPixelsPerDimsBefore;
            vidPxIdx = vidPxIdx + permute(nextDimVec(:), fliplr(1:d));
        end
        
        %         vidPxIdx = framePxIdx + (0:numFrames-1)*numPixelsPerFrame;
        
        % todo: add prod(sz(1:2)) if grabbing from multichannel in 3rd dim
        
        cdata = vid(vidPxIdx);
        
        K = round(numPxIdx/4);
        vminq = mean( mink(cdata,K,1), 1);
        vmed = median(cdata,1);
        vmean = mean(cdata,1);
        vmaxq = mean( maxk(cdata,K,1), 1);
        
        vdata = reshape( cdata, [rect.Position(4), rect.Position(3), sz(3:end)]); 
        %         cdata = reshape(vid(vidPxIdx), numPxIdx, []);
        %         cdata = reshape(vid(vidPxIdx), numPxIdx, []);
        
        
        % normalize video data and get trace
        nvdata = single(cdata);
        vmin = min(nvdata,[],1);
        vmax = max(nvdata,[],1); 
        vrange = max(vmax,[],ndims(nvdata)) - vmin;
        nvdata = (nvdata - vmin).*(1./vrange);
        nvdata = reshape( nvdata, [rect.Position(4), rect.Position(3), sz(3:end)]); 
        
        % assign data into structure for each roi
        roi(m).rectobj = rect;
        roi(m).position = rect.Position;
        roi(m).mask = bw;
        roi(m).vdata = vdata;
        roi(m).nvdata = nvdata;
        roi(m).vq = struct('minq',vminq,'medq',vmed,'mean',vmean,'maxq',vmaxq);
        %         roi(m).vdata = reshape( vdata , 64, 64, []);
        %         roi(m).vtrace = vtrace(:);
        out = roi;
    end
    
else
    out = warning('need to pass either an array of raw numeric data, or a structure with each field having raw numeric data');
end
%%
