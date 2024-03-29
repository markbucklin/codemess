function rs = simpleRectSelection(roiRect, vidToDisplay, rectSize)

% WIP

if nargin < 1 || isempty(roiRect)
    roiRect = images.roi.Rectangle.empty();
end
if nargin < 2
    vidToDisplay = [];
end
if nargin < 3
    rectSize = [64 64];
end

% todo: numframes or refactor out
maxNumFrames = 800;
rectColors = {roiRect.Color};

if isempty(vidToDisplay)
    %%
    chunkSize=8;
    [config,control,state] = ignition.io.tiff.initializeTiffFileStream();
    warning('off','MATLAB:structOnObject');
    vid.filesrc = struct(config.fileInputObj);
    %     vid.datasetname = string(config.fileInputObj.DataSetName);
    %     vid.filename = string(config.fileInputObj.FileName);
    %     vid.filepath = string(config.fileInputObj.FullFilePath);
%     [videoFrame, streamFinishedFlag, frameIdx] = ignition.io.tiff.readTiffFileStream( config, 1:chunkSize);
    
    %%
    vidChunk = {};
    frameIdx = 0;   
    while true
        [videoFrame, streamFinishedFlag, frameIdx] = ignition.io.tiff.readTiffFileStream( config, frameIdx(end)+(1:chunkSize));
        disp(frameIdx)
        vidChunk{end+1} = videoFrame;
        if streamFinishedFlag || frameIdx(end) >= maxNumFrames
            break
        end
    end
    
    %%
    vid.frame = cat(2,vidChunk{:});
    
    %%
    
    
    vid.original = cat(3,vid.frame.Data);
    vid.min = min(vid.original,[],3);
    vid.minsmooth = imgaussfilt(vid.min,15);
    vid.minsubtract = vid.original - vid.minsmooth;
    vidToDisplay = vid.minsubtract;
else
    vid = struct.empty();
end

hImsc = imscplay(vidToDisplay);

%%
m=0;
% persistent hNextDlg;

% hNextDlg = createDialog();

% newRectFcn = @adjustRectangle;


rs.getRect = @returnRoiRect;
rs.getVid = @returnVid;
rs.adjustRectangle = @adjustRectangle;
rs.setColors = @setColors;
% rs.adjustRectangle();
hDlg = createDialog();

% assignin('base','hNextDlg',hNextDlg)

    function hDlg = createDialog()
        hDlg = msgbox('click when ready for next', 'next roi', 'none','replace');
        okbutton = findobj(hDlg.Children, 'Style','pushbutton');
        set(okbutton, 'Callback', @(varargin)adjustRectangle());
    end


    function adjustRectangle()
        disp 'adjusting rectangle'
        m = m + 1;
        if numel(roiRect) >= m && isa(roiRect(m),'images.roi.Rectangle')
            nextRect = copy(roiRect(m));
        else
            defaultColor = [0.0745 0.6235 1.000];
            if numel(rectColors)>= m
                nextColor = rectColors{m};
            else
                nextColor = defaultColor;
            end            
            nextRect = drawrectangle( hImsc.ax,...
                'AspectRatio', 1,...
                'FixedAspectRatio', true,...
                'InteractionsAllowed', 'translate',...
                'Label', string(m),...
                'tag', "rectangle_" + string(m),...
                'Color', nextColor,...
                'Position', [100 100 rectSize]);
        end
        
        roiRect(m) = nextRect;
        hDlg = createDialog();
%         hdlg = msgbox('click when ready for next', 'next roi', 'none','replace');
%         okbutton = findobj(hdlg.Children, 'Style','pushbutton');
%         set(okbutton, 'Callback', @(varargin)adjustRectangle());
        
    end

    function roi = returnRoiRect()
        for k=1:length(roiRect)
            roiRect(k).Position = floor(roiRect(k).Position);
        end
        roi = roiRect;
    end
    function v = returnVid()
        v = vid;
    end

    function setColors(numColors)
        if nargin<1
            numColors=numel(roiRect);
        end
        assert(numColors>=1,'pass number of colors to set')
        defaultColor = [0.0745 0.6235 1.000];
        for colorNum = 1:numColors
            if numel(roiRect) >= colorNum && isa(roiRect(colorNum),'images.roi.Rectangle')
                nextColor = uisetcolor( roiRect(colorNum).Color, "Next ROI Color");
                roiRect(colorNum).Color = nextColor;
            elseif numel(rectColors) >=colorNum
                nextColor = uisetcolor( rectColors{colorNum}, "Next ROI Color");
            else
                nextColor = uisetcolor( defaultColor, "Next ROI Color");
            end            
            rectColors{colorNum} = nextColor;
        end
        
    end


end






