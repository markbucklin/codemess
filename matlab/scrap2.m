function roi = scrap2(currentSession)
%%

% load session.mat or run file to index data as SessionInfo object array

% currentDAT = 15;
% s = findobj(session,'MouseId','0419GE_M1RH')
% s = findobj(s,'FrameRate',40)
% currentSession = findobj(s, 'DayAfterTransplantation',currentDAT)


%%
dataDir = pwd;
cd(dataDir)
tif = dir('*.tif');
tiffLoader = scicadelic.TiffStackLoader(...
	'FileDirectory',tif.folder,...
	'FileName', {tif.name});


% cd(currentSession.Root)
% tif = dir('*.tif');
% tiffLoader = scicadelic.TiffStackLoader(...
% 	'FileDirectory',currentSession.Root,...
% 	'FileName', {tif.name});



%%
writeGray = false;
writeRGB = false;
[nextFcn,pp] = getScicadelicPreProcessor(tiffLoader, writeGray, writeRGB);
assignin('base','nextFcn',nextFcn)
assignin('base','pp',pp)

%% Init for Pre-Run
red.thresh = {};
red.mask = {};
blue.thresh = {};
blue.mask = {};
numFrames = tiffLoader.NumFrames;
frameSize = tiffLoader.FrameSize;
numPixels = prod(frameSize);
frameIdx = 0;
numPreFrames = numFrames/8;
numFramesPerChunk = tiffLoader.FramesPerStep;
numChunks = tiffLoader.NumSteps;
% pxl.red = scicadelic.PixelLabel;
% pxl.blue = scicadelic.PixelLabel;
PL = scicadelic.PixelLabel;
SCq = scicadelic.StatisticCollector;
SCf = scicadelic.StatisticCollector;
SCft = scicadelic.StatisticCollector;
% errorFlag = false;

%% Pre-Run
while frameIdx(end) < numPreFrames
	[out.f,out.info,out.mstat,out.frgb,out.srgb] = nextFcn();
	% Update Index and Timestamp
	frameIdx = out.info.idx;
	t = out.info.timestamp;
	if t(1)>15
		
		% Update Statistics for Pre-Processed Image Pixel Intensity
		step(SCf, out.f);
		% 		if numel(t) > 1
		% 			ft_quickdirty = bsxfun( @rdivide, diff(out.f,[],3), reshape(diff(t),1,1,[]));
		% 			step(SCft, ft_quickdirty);
		% 		end
		
		% Get Pixel-Activation Metric Sources from Current Chunk
		pixelActivationSource = {...
			out.srgb.marginalKurtosisOfIntensity,...
			out.srgb.marginalSkewnessOfIntensityChange};
		
		% Fix NaNs -> 0
		for kq = 1:numel(pixelActivationSource)
			q = pixelActivationSource{kq};
			qNanMatch = isnan(q(:));
			if any(qNanMatch)
				q(qNanMatch) = 0;
				pixelActivationSource{kq} = q;
			end
		end
		
		% Combine Sources Using Customizable Function (default is max(Qa,Qb)
		combinationDim = max(cellfun(@ndims,pixelActivationSource)) + 1;
		combinationFcn = @(qs) max(qs, [], combinationDim);
		Qs = cat(combinationDim, pixelActivationSource{:});
		Q = combinationFcn(Qs);
		
		% Update Statistics of Activation Metric
		step(SCq, Q);
		
		% Submit Pixel-Activation Training Data (Update scicadelic.PixelLabel
		update( PL, Q);
		
	end
	% Update Visual with Max-Projection of Current Chunk
	fChunk = oncpu( uint8(max(out.frgb,[],4)));
	try
		if exist('hmp','var')
			hmp.CData = fChunk;
		else
			hmp = imshow(fChunk);
			set(hmp.Parent.Title,...
				'String', sprintf('Time: % 22g seconds',t(end)),...
				'Color', [0 0 0]);
			drawnow update
		end
	catch
		hmp = imshow(fChunk);
	end
	
	
end


%% Specify Signals Extracted from Each Chunk --> {'signalname': source_variable}
getInputSignals = @(nextOut) struct(...
	'intensity', nextOut.f,...
	'red', nextOut.srgb.marginalKurtosisOfIntensity,...
	'blue', nextOut.srgb.marginalSkewnessOfIntensityChange);

%% Extract Label-Matrix & Region-Props from scicadelic.PixelLabel object
L = gather(PL.PrimaryRegionIdxMap);
roiIncludedPixelIdx = label2idx(L);
rp = regionprops(L,SCq.Mean,'all');
[reg.label, reg.pixelidx, reg.labelidx] = unique(L(:));

%
%
%				CONTINUE HERE ###########################################
%			
[seed.y, seed.x, seed.currentlabel] = find(PL.RegisteredRegionSeedIdxMap)
seed.pixelidx = sub2ind(frameSize, seed.y, seed.x);


% %%
% seedIdxMap = gather(PL.RegisteredRegionSeedIdxMap);
% [roiSeed.pixelRow, roiSeed.pixelCol, roiSeed.regionIdx] = find(seedIdxMap);
% roiSeed.pixelIndex = sub2ind(frameSize, roiSeed.pixelRow, roiSeed.pixelCol)
%
%
% roiSeedPixelIdx = label2idx(seedIdxMap);
%
% numPixelIdx = cellfun( @numel, roiIncludedPixelIdx);
% roiIncludedPixelIdx = roiIncludedPixelIdx(numPixelIdx >= MIN_PIXEL_IDX_CNT);
% regProp2PixelLabelProp = struct(...
% 	'Area', PL.RegionArea',...
% 	'BoundingBox', 'RegionBoundingBox',...
% 	'Centroid', 'RegionCentroid');
%

% 	'Area', 'RegionArea',...
% 	'BoundingBox', 'RegionBoundingBox',...
% 	'Centroid', 'RegionCentroid')

% SHAPE MEASUREMENTS
%	  'Area'              'EulerNumber'       'Orientation'
%     'BoundingBox'       'Extent'            'Perimeter'
%     'Centroid'          'Extrema'           'PixelIdxList'
%     'ConvexArea'        'FilledArea'        'PixelList'
%     'ConvexHull'        'FilledImage'       'Solidity'
%     'ConvexImage'       'Image'             'SubarrayIdx'
%     'Eccentricity'      'MajorAxisLength'
%     'EquivDiameter'     'MinorAxisLength'
% PIXEL-VALUE MEASUREMENTS
%	  'MaxIntensity'
%     'MeanIntensity'
%     'MinIntensity'
%     'PixelValues'
%     'WeightedCentroid'

%% Define Functions for Extracting Pixel-Values from Each Chunk to form Traces
groupPixelsInIdxCell = @(f) cellfun( @(roiidx) gather(f(roiidx,:)'), roiIncludedPixelIdx, 'UniformOutput',false);
extractRoiPixelTrace = @(f) groupPixelsInIdxCell( reshape( f, numPixels, []));

% Map Pixels to ROIs
tmp = cellfun( @(pxidx,roiidx) ones(size(pxidx)) .* roiidx,...
	roiIncludedPixelIdx,...
	num2cell(1:numel(roiIncludedPixelIdx)),'UniformOutput',false);
idxMap.pixel = cat(1,roiIncludedPixelIdx{:});
idxMap.roi = cat(1,tmp{:});
pixelBatchMat = @(f) reshape( f, size(f,1)*size(f,2), [])


%% Reset Frame-Idx to Zero and Pre-Allocate
pixelTraceChunk = struct.empty(0,numChunks);
reset(tiffLoader);
frameIdx = 0;
batchIdx = 0;
batchOut = struct.empty(0,numChunks); % TODO: move up to Pre-Run

%% Saving
save(sprintf('label matrix (%s)',strrep(datestr(now),':','_')),'L','-nocompression')
saveRGB = @(f) writeBinaryData( oncpu(f), 'rgb', false);

%% Run Processing on All Frames with Trace Extraction for Each ROI
while frameIdx(end) < numFrames
	tStart = tic;
	[out.f, out.info, out.mstat, out.frgb, out.srgb] = nextFcn();
	if isempty(out.f)
		break
	end
	frameIdx = out.info.idx;
	t = out.info.timestamp;
	batchIdx = batchIdx + 1;	
	
	% Gather any Batch-Output that should be Preserved in Memory
	batchOut(batchIdx).info = out.info;
	
	% Save RGB
	% 	saveRGB(out.frgb);
	
	% Extract Traces from Current Frames
	signal = getInputSignals(out);
	signalNames = fields(signal);
	for ksig = 1:numel(signalNames)
		name = signalNames{ksig};
		c = extractRoiPixelTrace( signal.(name) );
		pixelTraceChunk(batchIdx).(name) = c;
	end
	
	chunkDur = toc(tStart);
	fprintf('Frame %d to %d\t\t[%22g ms/frame]\n', frameIdx(1), frameIdx(end), 1000*chunkDur/numel(frameIdx));
end


%% Un-Chunkify Roi Pixel Traces -> save in 'roi' structure
numRegion = numel(roiIncludedPixelIdx);
roi = struct('idx',roiIncludedPixelIdx,'trace',cell(size(roiIncludedPixelIdx)));
roiPixelTrace = struct.empty(0,numRegion);
for k=1:numel(roi), roi(k).props = rp(k); end

for ksig = 1:numel(signalNames)
	name = signalNames{ksig};
	chunkedTrace = cat(1,pixelTraceChunk.(name));
	for k=1:numRegion
		roi(k).trace.(name) = cat(1,chunkedTrace{:,k});
	end
	chunkedTrace = {};
end
pixelTraceChunk(:) = [];

% Put Function Handle for Plotting in WOrkspace
roiPixelTracePlotFcn = getRoiPixelTracePlotFcn(roi);
assignin('base', 'roiPixelTracePlotFcn', roiPixelTracePlotFcn)


%% Get Noise Distribution by Sampling Randomly Selected Pixels from SCf and SCq

keyboard

% ---> Instead use 'getRoiPixelTracePlotFcn.m'


end



function [thresh,maskidx] = getRoiMask(f)
[ny,nx,nt] = size(f);
[autoThresh,metric] = graythresh( gather(max(f,[],3)));
mask = bsxfun( @gt, f, autoThresh);
f(~mask) = 0;
[rowidx,colidx,fxy] = find(f);
offsetidx = floor(colidx/nt);
colidx = mod( colidx-1, nx) + 1;
maskidx.row = gather(rowidx);
maskidx.col = gather(colidx);
maskidx.offset = gather(offsetidx);
maskidx.f = gather(fxy);
thresh.level = gather(autoThresh);
thresh.metric = gather(metric);
end


function roi = getSingleFrameRegions(src)

f = accumarray([src.row, src.col, src.offset+1 ],...
	double(src.f),...
	[frameSize, max(src.offset)+1], @sum, 0, false);
Fmask = applyFunction2D( @bwareaopen, Fmask, 8);
Fmask = applyFunction2D( @bwmorph, Fmask, 'close');
end



