classdef (CaseInsensitiveProperties = true) RegionOfInterest < hgsetget %& dynamicprops & matlab.mixin.CustomDisplay
% distcomp.cacheableobject	
	
	properties % SETTINGS
		ShowMode = 'patch' % 'image' , 'patch'
	end
	% IDENTICAL TO 'REGIONPROPS' PROPERTIES
	properties 
		Area
		BoundingBox
		Centroid							% [x,y] from upper left corner		
		Eccentricity
		Extrema
		Extent
		EquivDiameter
		Image
		PixelIdxList
		PixelList
		SubarrayIdx
		MajorAxisLength
		MinorAxisLength
		Orientation
		% 	 MaxIntensity MeanIntensity MinIntensity PixelValues WeightedCentroid
	end
	properties (Dependent, Hidden) % HIDDEN SO THEY'RE NOT GENERATED UNNECESSARILY
		% 	  Mask LabelMatrix
	end
	properties
		FirstFrame
		LastFrame
		XLim
		YLim
		Width
		Height
	end
	properties
		PixelSubScripts
		PixelWeights
		PixelCounts
		UniquePixels
		UniqueArea
		BoundaryTrace
		SparseMask
		Trace%TODO
		TraceType
		FrameSize
		Color
		ColorIndex
		HaloPixIdx
		Overlay
	end
	properties
		Idx
		Frames
		% 	 PackedMask Keys CentroidIndex OverlappingRegion OuterOverlap InnerOverlap
		% 	  SubRegion SuperRegion
		NumberOfMerges = 0;
		SpatialPower
		% 	 TemporalPower
		MinSufficientOverlap = .75
	end
	properties
		isConfirmed = false
		isCombined = false
		isMerged = false
		isOverlapping = false
		isSubRegion = false
		isSuperRegion = false
	end
	properties % GRAPHICS HANDLES AND PROPS
		% 	 hIm hAx hFig hText hBg
	end
	properties
		transparency = .75
	end
	properties (Constant, Hidden)
		RegionPropInputs = {	...
			'Centroid', 'BoundingBox','Area',...
			'PixelIdxList',...
			'Image',...
			'EquivDiameter',...
			'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Eccentricity'}
	end
	
	
	
	events
	end
	
	
	
	
	methods % CONSTRUCTOR & SETUP
		function obj = RegionOfInterest(varargin)
			% 			global ROINUM
			global FRAMESIZE
			%       global ROIHANDLES
			% 			if isempty(ROINUM)
			% 				ROINUM = 1;
			% 			else
			% 				ROINUM = ROINUM + 1;
			% 			end obj.Idx = ROINUM;
			obj.Idx = now - 736110.104386;
			roiDefInput = [];
			if nargin > 1	% Input is property-value pairs
				%         keyboard
				if logical(mod(nargin,2)) % odd
					pvpairs = varargin(2:end);
					roiDefInput = varargin{1};
				else
					pvpairs = varargin(1:end);
				end
				for k = 1:2:length(pvpairs)
					obj.(pvpairs{k}) = cast(pvpairs{k+1},'like',obj.(pvpairs{k})); %TODO
				end
			elseif nargin == 1 % Input is a multi-ROI BWFRAME structure with fields 'RegionProps' and 'bwMask'
				% 		  for k=2:numel(bwvid), roi = cat(1,roi, RegionOfInterest(bwvid(k))); fprintf('Frame:
				% 		  %i\tAccumulating ROIs: %i\n',k,numel(roi)), end
				roiDefInput = varargin{1};
			end
			if isempty(roiDefInput)
				return
			end
			switch(class(roiDefInput))
				case 'RegionOfInterest'
					if numel(roiDefInput) > 1
						obj = merge(roiDefInput);
					else
						obj = roiDefInput;% TODO: regenerate after generating logical array?
					end
					return
				case 'struct'
					if isfield(roiDefInput, 'RegionProps')
						% input from generateRegionsOfInterest()
						RP = roiDefInput.RegionProps;
					elseif all(isfield(roiDefInput,{'Centroid','BoundingBox','PixelIdxList'}))
						% input from bwconncomp()
						RP = roiDefInput;
					end
					if isfield(roiDefInput,'bwMask')
						[RP.FrameSize] = deal(size(roiDefInput.bwMask));
					end
				case 'logical'
					RP = regionprops(roiDefInput,obj(1).RegionPropInputs);%...
					% 						'Centroid', 'BoundingBox','Area',...
					% 						'Eccentricity', 'PixelIdxList','Perimeter');
					if isempty(RP)
						obj = RegionOfInterest.empty(0,1);
						return
					end
					[RP.FrameSize] = deal(size(roiDefInput));
				case 'gpuArray'
					roiDefInput = gather(roiDefInput);
					RP = regionprops(roiDefInput, obj(1).RegionPropInputs{:});
					% 						'Centroid', 'BoundingBox','Area',... 'Eccentricity',
					% 						'PixelIdxList','Perimeter');
					if isempty(RP)
						obj = RegionOfInterest.empty(0,1);
						return
					end
					[RP.FrameSize] = deal(size(roiDefInput));
				otherwise
					% TODO (LabelMatrix?)
					RP = roiDefInput;
			end
			% CALL RECURSIVELY FOR INPUT DEFINING MULTIPLE ROIS
			if numel(RP) > 1
				for nr = 1:size(RP,1)
					for nc = 1:size(RP,2)
						obj(nr,nc) = RegionOfInterest(RP(nr,nc));
					end
				end
			else
				% PROCESS INPUT FOR SINGLE ROI
				rpFields = fields(RP);
				for kField = 1:numel(rpFields)
					fn = rpFields{kField};
					obj.(fn) = cast(RP.(fn), 'like',obj.(fn));
				end
			end
			if ~isempty(obj(1).FrameSize)
				FRAMESIZE = obj(1).FrameSize;
			end
			% TODO: obj.updateProperties() -> XLim, YLim, bwpack(Mask)
		end
		function varargout = updateProperties(obj)
			if any(cellfun('isempty',{obj.PixelIdxList}))
				obj = removeEmpty(obj);
			end
			% Ensure Frame Size is Consistent (or at least non-empty
			% 			missingFrameSize = cellfun('isempty',{obj.FrameSize}); if any(missingFrameSize) %
			% 			takes the most time of any line?>?????
			if numel(obj) > 1
				if isempty(obj(end).FrameSize)
					obj(end).guessFrameSize();
				end
				set(obj, 'FrameSize', obj(end).FrameSize);%if numel>1
			end
			% Calculate Sparse Matrices and Other Variables from Indices
			if any(cellfun(@isempty,{obj.PixelSubScripts}))
				imsize = obj(end).FrameSize;
				% PIXEL SUBSCRIPTS
				for kObj = 1:numel(obj)
					[isubs, jsubs] = ind2sub(imsize,obj(kObj).PixelIdxList);
					pxsub = [isubs(:) jsubs(:)];
					obj(kObj).PixelSubScripts = cast(pxsub,'like',obj(kObj).PixelSubScripts);
				end
			end
			% WEIGHTED CENTROID
			% 			supreg = [obj.isSuperRegion]';
			% 			for kSup = 1:numel(supreg)
			% 				if supreg(kSup)
			% 					obj(kSup).Centroid = cast(fliplr(...
			% 						sum(bsxfun(@times,...
			% 						single(obj(kSup).PixelSubScripts),...
			% 						single(obj(kSup).PixelWeights)))...
			% 						/ single(sum(obj(kSup).PixelWeights))),...
			% 						'like',obj(kSup).Centroid);
			% 				end
			% 			end
			% XLIM and YLIM
			if any(cellfun(@isempty,{obj.XLim}))
				bb = cat(1,obj.BoundingBox);
				xl(:,1) = floor(bb(:,1));
				xl(:,2) = ceil( bb(:,1) + bb(:,3) );
				yl(:,1) = floor(bb(:,2));
				yl(:,2) = ceil(bb(:,2)+bb(:,4));
				for kObj = 1:numel(obj)
					obj(kObj).XLim = cast(xl(kObj,:),'like',obj(kObj).XLim);
					obj(kObj).YLim = cast(yl(kObj,:),'like',obj(kObj).YLim);
				end
			end
			% WIDTH & HEIGHT
			if any(cellfun(@isempty,{obj.Width}))
				roiXlim = cat(1,obj.XLim);
				roiYlim = cat(1,obj.YLim);
				roiWidth = roiXlim(:,2)-roiXlim(:,1);
				roiHeight = roiYlim(:,2)-roiYlim(:,1);
				for kObj = 1:numel(obj)
					obj(kObj).Width = roiWidth(kObj);
					obj(kObj).Height = roiHeight(kObj);
				end
			end
			% FIRST FRAME and LAST FRAME
			if any(cellfun(@isempty,{obj.FirstFrame}))
				for kObj = 1:numel(obj)
					obj(kObj).FirstFrame = min(obj(kObj).Frames(:));
					obj(kObj).LastFrame = max(obj(kObj).Frames(:));
				end
			end
			if nargout > 0
				varargout{1} = obj;
			end
		end
		function trim(obj,freqThresh)
			if nargin < 2
				freqThresh = .25;
			end
			N = numel(obj);
			for k = 1:N
				pixFreq = obj(k).PixelWeights;
				trimPix = pixFreq > freqThresh*max(pixFreq(:));
				obj(k).PixelIdxList = obj(k).PixelIdxList(trimPix);
				obj(k).PixelSubScripts = obj(k).PixelSubScripts(trimPix,:);
				obj(k).PixelWeights = obj(k).PixelWeights(trimPix);
				obj(k).PixelCounts = obj(k).PixelCounts(trimPix);
				rp = regionprops(obj(k).createMask, obj(k).RegionPropInputs{:});
				fillPropsFromStruct(obj(k), rp);
				% 				obj(k).Area = rp.Area; obj(k).Centroid = rp.Centroid; obj(k).BoundingBox =
				% 				rp.BoundingBox;
			end
		end
	end
	methods % SHOW/DISPLAY
		function varargout = show(obj)
			%TODO: can make compatible for HG2 with: if verLessThan('matlab','8.4.0')
			global H
			% FILTER AND NORMALIZE TRACES AFTER COPYING TRACE TO RAWTRACE
			% 		needsFiltNorm = cellfun(@isempty, {obj.RawTrace}); if any(needsFiltNorm)
			% 		  R = obj(needsFiltNorm); for k = 1:numel(R)
			% 			 R(k).RawTrace = R(k).Trace;
			% 		  end R.normalizeTrace2WindowedRange R.makeBoundaryTrace R.filterTrace
			% 		end
			if any(cellfun(@isempty, {obj.BoundaryTrace}))
				makeBoundaryTrace(obj);
			end
			% SORT BY AREA SO SMALLER ROIS PLACED LAST
			% 		 [~,idx] = sort([obj.Area], 'descend'); obj = obj(idx);
			N = numel(obj);
			sz = obj(1).FrameSize;
			% SET COLORS IF NOT ALREADY ASSIGNED
			if any(cellfun(@isempty, {obj.Color}))
				setDistinguishableColors(obj);
			end
			% CREATE FIGURE IF ONE DOESN'T EXIST
			if isempty(H) || ~isvalid(H.im)
				H = obj.createShowFigure();
			end
			switch obj(1).ShowMode
				case 'image'
					cdata = zeros([sz 3]);
					adata = zeros(sz);
					idxPerFrame = prod(sz);
					for kObj = 1:N
						nPix = numel(obj(kObj).PixelIdxList);
						repRoiColor = repmat( obj(kObj).Color(1:3), [nPix 1]); %repRoiColor = repmat( obj(kObj).Color(:)', [nPix 1]); % [BEFORE TRANSPARENCY ADDITION]
						idxChan = repmat([0 idxPerFrame idxPerFrame*2], [nPix 1]);
						pixIdx = repmat(obj(kObj).PixelIdxList(:), [1 3]) + idxChan;
						cdata(pixIdx(:)) = repRoiColor(:);
						if ~isempty(obj(kObj).PixelWeights)
							adata(obj(kObj).PixelIdxList(:)) = max([ obj(kObj).PixelWeights,...
								adata(obj(kObj).PixelIdxList(:))],[], 2) ;
						end
						if ~isempty(obj(kObj).BoundaryTrace);
							H.line(kObj) = line(...
								obj(kObj).BoundaryTrace.x, obj(kObj).BoundaryTrace.y,...
								'Parent', H.ax,...
								'Color', obj(kObj).Color,...
								'PickableParts','none',...
								'HitTest','off',...
								'LineWidth', 1);
						end
					end
					H.im.CData = cdata;
					if any(adata(:) > 0)
						H.im.AlphaData = adata;
					end
				case 'patch'
					for kObj=numel(obj):-1:1
						H.hpatch(kObj) = patch(obj(kObj).BoundaryTrace.x,...
							obj(kObj).BoundaryTrace.y,...
							obj(kObj).Color(1:3) ,...
							'Parent',H.ax,...
							'FaceAlpha',obj(1).Transparency,...
							'EdgeAlpha',.8,...
							'ButtonDownFcn', @(src,evnt)roiClickFcn(obj,src,evnt),...
							'UserData',obj(kObj));
					end
				otherwise
					set(obj,'ShowMode','patch');
					H = show(obj);
			end
			
			drawnow
			if nargout
				varargout{1} = H;
			end
		end
		function hide(obj)
			persistent h;
			%TODO
			% CLEAR ANY PREVIOUSLY DRAWN ROIs
			if ~isempty(h.ax) && isvalid(h.ax)
				cla(h.ax)
			end
		end
		function varargout = showWithText(obj,propstring)
			%TODO: fix, since removing hText property
			persistent h;
			if nargin < 2
				propstring = 'Idx';
			end
			N = numel(obj);
			% 		textOffset = [-20 20]; % [dx,dy] + towards lower right
			% PROCESS AND USE DEFAULT SHOW METHOD
			obj = removeEmpty(obj);
			if any(cellfun(@isempty,{obj.XLim}))
				updateProperties(obj);
			end
			h = show(obj);
			% PROCESS TEXT COMMAND AS PROPERTY, FUNCTION, ETC.
			for kObj = 1:N
				if ischar(propstring) && isprop(obj(kObj),propstring)
					propval = obj(kObj).(propstring);
				else
					try
						if isa(propstring,'function_handle')
							propval =  feval(propstring,obj(kObj));
						else
							propval = evalin('caller',propstring);
						end
					catch me
						error('RegionOfInterest:showWithText:InvalidProperty',...
							me.message);
					end
				end
				if isnumeric(propval)
					if abs(propval-round(propval)) < eps
						propvalstring = sprintf('%i ',propval);
					else
						propvalstring = sprintf('%5.2f ',propval);
					end
				else
					propvalstring = propval;
				end
				h.text(kObj) = text(...
					'String', propvalstring,...
					'FontWeight','bold',...
					'BackgroundColor',[.1 .1 .1 .3],...
					'Margin',1,...
					'Position',round(obj(kObj).BoundingBox(1:2)) - [0 5],...
					'Parent', h.ax,...
					'Color',obj(kObj).Color	);
				% [previous position] round(obj(kObj).Centroid+textOffset
				% 				  sprintf('#%i',obj(kObj).Idx)
				% 		  h.text = handle(text(obj(kObj).XLim(1), obj(kObj).YLim(2), propvalstring));
				% 		  h.text.Color = obj(kObj).Color;
			end
			drawnow
			if nargout
				varargout{1} = h;
			end
		end
		function showAsOverlay(obj, overlayInput, varargin)
			global H
			% DISPLAY/COMPARE
			sz = obj(1).FrameSize;
			% 		 if isempty(h) || isempty(h.fig) || ~isvalid(h.fig)
			% 			h = createShowFigure(obj);
			% 		 end
			if nargin > 2
				txt = varargin{1};
				H = showWithText(obj,txt);
			else
				H = show(obj);
			end
			H.ax.NextPlot = 'add';
			% 		H.ax.ALim = inputRange; obj(1).hIm.AlphaDataMapping = 'none';
			H.bg = image(zeros([sz 3] ,'uint8'),...
				'Parent', H.ax);
			H.bg.ButtonDownFcn = @(src,evnt)roiClickFcn(obj,src,evnt);
			% 		set(obj,'hBg',hbg);
			if isnumeric(overlayInput)
				% IMAGE
				if ismatrix(overlayInput)
					H.bg.AlphaData = imcomplement(overlayInput);
					drawnow
					return
				else
					framePeriod = .05;%TODO: info structure
				end
			else % MOVIE
				ts = cat(1,overlayInput.timestamp);
				framePeriod = mean(diff(cat(1,ts.seconds)));
			end
			timerData.data = overlayInput;
			timerData.hand = H;
			t = timer(...
				'ExecutionMode','fixedRate',...
				'Period',framePeriod,...
				'UserData',timerData,...
				'TimerFcn', @(src,evnt)vidOverlayUpdate(obj(1),src,evnt));
			start(t)
		end
		function setDistinguishableColors(obj)
			N = numel(obj);
			allColors = distinguishable_colors( N , [.1 .1 .1] );
			for k=1:N
				obj(k).Color = cast([allColors(k,:) obj(k).transparency], 'like',obj(k).Color);
				obj(k).ColorIndex = cast(k,'like',obj(k).ColorIndex);
			end
		end
		function binVec = hasFrame(obj, frameNum)
			nObj = numel(obj);
			% 		nFrame = numel(frameNum); %TODO: expand for multi frame input
			binVec = false(nObj,1);
			for k=1:N
				binVec(nObj) = fast_ismember_sorted(frameNum,obj(k).Frames);
			end
		end
	end
	methods % COMPARISON METHODS
		function doesOverlap = overlaps(obj, roi)
			% Returns a logical scalar, vector, or matrix, depending on number of arguments (objects of
			% the ROI class) passed to the method. Calls can take any of the following forms for scalar
			% (1x1) ROI "a" and an array (e.g. 5x1) of ROI objects "b": >> overlaps(a,b)      --> [5x1] >>
			% overlaps(b,a)      --> [5x1] >> overlaps(b)        --> [5x5] Note: the syntax:  >>
			% overlaps(a,b) is equivalent to:  >> a.overlaps(b)
			if nargin < 2
				roi = obj;
			end
			if numel(obj) == 1 && numel(roi) == 1
				doesOverlap = any(fast_ismember_sorted(obj.PixelIdxList, roi.PixelIdxList));
			else
				doesOverlap = false(numel(obj),numel(roi));
				opixcell = {obj.PixelIdxList};
				% Use FastSet Methods to Compare Pixel-Indices (Lev Muchnik, link at end of file)
				for kRoi=1:numel(roi)
					rpix = roi(kRoi).PixelIdxList;
					for kObj=1:numel(obj)
						doesOverlap(kObj,kRoi) = any(fast_ismember_sorted(...
							rpix, opixcell{kObj}));
					end
				end
				sz = size(doesOverlap);
				% Convert to COLUMN VECTOR for a 1xK Query
				if (sz(1) == 1)
					doesOverlap = doesOverlap(:);
				end
			end
		end
		function idxOverlap = spatialOverlap(obj, roi)
			% Returns all INDICES of OVERLAPPING PIXELS in Vector If multiple ROIs are used as INPUT, a
			% CELL array  is return with the size: [nObj x nRoi]
			if nargin < 2
				roi = obj;
			end
			if numel(obj) > 1 || numel(roi) > 1
				idxOverlap = cell(numel(obj),numel(roi));
				for kRoi=1:numel(roi)
					rpix = roi(kRoi).PixelIdxList;
					for kObj=1:numel(obj)
						idxOverlap{kObj,kRoi} = fast_intersect_sorted(...
							obj(kObj).PixelIdxList, rpix)';
					end
				end
				sz = size(idxOverlap);
				% Convert to COLUMN VECTOR for a 1xK Query
				if (sz(1) == 1)
					idxOverlap = idxOverlap(:);
				end
			else
				idxOverlap = fast_intersect_sorted(obj.PixelIdxList, roi.PixelIdxList);
			end
		end
		function oFracOverlap = fractionalOverlap(obj, roi)
			% >> ovr = fractionalOverlap(obj, roi) >> ovr = fractionalOverlap(roi) used to be --> [ovr,
			% rvo] = fractionalOverlap(obj, roi) returns a fractional number (or matrix) indicating
			%	0:			'no-overlap' ovr:	'fraction of OBJ that overlaps with ROI relative to total OBJ area
			%	rvo:   'fraction of ROI that overlaps with OBJ relative to total ROI area
			%
			%  --> Now using FastStacks!
			%TODO: Check a flag to make sure indices are sorted
			if nargin < 2
				roi = obj;
			end
			estNumOverlap = sum(sum(obj.isInBoundingBox(roi)));
			if numel(obj) > 1 || numel(roi) > 1
				nIdxOverlap = spalloc(numel(obj),numel(roi), estNumOverlap);
				nPix = spalloc(numel(obj),numel(roi), estNumOverlap);
				for kRoi=1:numel(roi)
					rpix = roi(kRoi).PixelIdxList;
					for kObj=1:numel(obj)
						opix = obj(kObj).PixelIdxList;
						nIdxOverlap(kObj,kRoi) = numel(fast_intersect_sorted(opix, rpix));
						nPix(kObj,kRoi) = numel(opix);%can be further optimized
					end
				end
				oFracOverlap = nIdxOverlap ./ nPix ;
			else
				oNpix = numel(obj.PixelIdxList);
				idxOverlap = fast_intersect_sorted(obj.PixelIdxList, roi.PixelIdxList);
				oFracOverlap = numel(idxOverlap)/oNpix;
			end
			sz = size(oFracOverlap);
			% Or convert to COLUMN VECTOR for a 1xK Query
			if (sz(1) == 1)
				oFracOverlap = oFracOverlap(:);
			end
		end
		function isWithin = isInBoundingBox(obj, roi)
			try
				if nargin < 2
					roi = obj;
				end
				if numel(obj) > 1 || numel(roi) > 1
					%           isWithin = false(numel(obj),numel(roi));
					oCxy = cat(1,obj.Centroid);
					%           rCxy = cat(1,roi.Centroid)'; oXlim = cat(1,obj.XLim); oYlim = cat(1,obj.YLim);
					rXlim = cat(1,roi.XLim)';
					rYlim = cat(1,roi.YLim)';
					isWithin = bsxfun(@and,...
						bsxfun(@and,...
						bsxfun(@ge,oCxy(:,1),rXlim(1,:)),...
						bsxfun(@le,oCxy(:,1),rXlim(2,:))) , ...
						bsxfun(@and,...
						bsxfun(@ge,oCxy(:,2),rYlim(1,:)),...
						bsxfun(@le,oCxy(:,2),rYlim(2,:))));
				else
					if isempty(obj.BoundingBox) || isempty(roi.BoundingBox)
						isWithin = false;
						return
					end
					xc = obj.Centroid(1);
					yc = obj.Centroid(2);
					xbL = roi.BoundingBox(1);
					xbR = xbL + roi.BoundingBox(3);
					ybB = roi.BoundingBox(2);
					ybT = ybB + roi.BoundingBox(4);
					isWithin =  (xc >= xbL) & (xc <= xbR) & (yc >= ybB) & (yc <= ybT);
				end
				sz = size(isWithin);
				% Convert to COLUMN VECTOR for a 1xK Query
				if (sz(1) == 1)
					isWithin = isWithin(:);
				end
			catch me
				keyboard
			end
		end
		function varargout = centroidSeparation(obj, roi)
			% Calculates the EUCLIDEAN DISTANCE between ROIs. Output depends on number of arguments. For
			% one output argument the hypotenuse between centroids is returned, while for two output
			% arguments the y-distance and x-distance are returned in two separate matrices. Usage
			% examples are below: >> csep = centroidSeparation( roi(1:100) )			--> returns [100x100]
			% matrix >> [simmat.cy,simmat.cx] = centroidSeparation(roi(1:100),roi(1:100)) --> 2
			% [100x100]matrices >> csep = centroidSeparation(roi(1), roi(2:101)) --> returns [100x1]
			% vector
			if nargin < 2
				roi = obj;
			end
			if numel(obj) > 1 || numel(roi) > 1
				oCxy = cat(1,obj.Centroid);
				rCxy = cat(1,roi.Centroid);
				rCxy = rCxy';
				xdist = bsxfun(@minus, oCxy(:,1), rCxy(1,:));
				ydist = bsxfun(@minus, oCxy(:,2), rCxy(2,:));
				if nargout <= 1
					pixDist = bsxfun(@hypot, xdist, ydist);
				end
			else
				if isempty(obj.Centroid) || isempty(roi.Centroid)
					varargout{1:nargout} = inf;
					return
				end
				xdist = obj.Centroid(1) - roi.Centroid(1);
				ydist = obj.Centroid(2) - roi.Centroid(2);
				if nargout <= 1
					pixDist = hypot( xdist, ydist);
				end
			end
			if nargout <= 1
				sz = size(pixDist);
				% Convert to COLUMN VECTOR for a 1xK Query
				if (sz(1) == 1)
					pixDist = pixDist(:);
				end
				varargout{1} = pixDist;
			elseif nargout == 2
				if (size(xdist,1) == 1) || (size(ydist,1) == 1)
					xdist = xdist(:);
					ydist = ydist(:);
				end
				varargout{1} = ydist;
				varargout{2} = xdist;
			end
		end
		function limDist = limitSeparation(obj, roi)
			% Calculates the DISTANCE between ROI LIMITS, returning a single matrix 2D or 3D matrix with
			% the last dimension carrying distances ordered TOP,BOTTOM,LEFT,RIGHT. USAGE: >> limDist =
			% limitSeparation(obj(1:100)) --> returns [100x100x4] matrix >> limDist =
			% limitSeparation(obj(1),obj(1:100)) -->  [100x4] matrix
			if nargin < 2
				roi = obj;
			end
			if any(cellfun(@isempty, {obj.XLim}))
				obj.updateProperties()
			end
			if any(cellfun(@isempty, {roi.XLim}))
				roi.updateProperties()
			end
			if numel(obj) > 1 || numel(roi) > 1
				oxlim = int16( cat(1, obj.XLim));
				oylim = int16( cat(1, obj.YLim));
				rxlim = int16( cat(1, roi.XLim));
				rylim = int16( cat(1, roi.YLim));
				rxlim = rxlim';
				rylim = rylim';
				% Order in 3rd dimension is Top,Bottom,Left,Right
				oLim = cat(3,oylim(:,1),oylim(:,2),oxlim(:,1),oxlim(:,2));
				rLim = cat(3,rylim(1,:),rylim(2,:),rxlim(1,:),rxlim(2,:));
				limDist = bsxfun(@minus, oLim, rLim);
			else
				topYdist = obj.YLim(1) - roi.YLim(1);
				bottomYdist = obj.YLim(2) - roi.YLim(2);
				leftXdist = obj.XLim(1) - roi.XLim(1);
				rightXdist = obj.XLim(2) - roi.XLim(2);
				limDist = int16(cat(1, topYdist, bottomYdist, leftXdist, rightXdist));
			end
			sz = size(limDist);
			% Convert to COLUMN VECTOR for a 1xK Query
			if (sz(1) == 1)
				limDist = permute(limDist, [2 3 1]);
			elseif (sz(2) == 1)
				limDist = permute(limDist, [1 3 2]);
			end
		end
		function isSmlr = sufficientlySimilar(obj, roi)
			% Loose predictor of similarity between ROIs. Will return a logical scalar, vector, or matrix
			% depending on the number and dimensions of the input.
			if isempty([obj.MinSufficientOverlap])
				minOverlap = .75;
			else
				minOverlap = obj.MinSufficientOverlap;
			end
			if nargin < 2
				roi = obj;
			end
			nObj = numel(obj);
			nRoi = numel(roi);
			isSmlr = false([nObj nRoi]);
			for kRoi = 1:nRoi
				R2 = roi(kRoi);
				for kObj = kRoi:nObj
					R1 = obj(kObj);
					% Check whether there is ANY OVERLAP
					minProfile = min([R1.BoundingBox(3:4) R2.BoundingBox(3:4)]);
					if centroidSeparation(R1,R2) < minProfile/2
						% Check whether overlap is SUBSTANTIAL AND EXCLUSIVE
						rfo = fractionalOverlap([R1 R2]);
						if all(rfo > minOverlap)
							isSmlr(kObj,kRoi) = true;
						end
					end
				end
			end
			sz = size(isSmlr);
			% Construct TRUTH-TABLE using symmetry for INTRAGROUP KxK Query
			if (sz(1) > 1) && (sz(2) > 1) && (sz(1) == sz(2))
				isSmlr = isSmlr | isSmlr';
				% Or convert to COLUMN VECTOR for a 1xK Query
			elseif (sz(1) == 1)
				isSmlr = isSmlr(:);
			end
		end
	end
	methods % OVERLOADED METHODS FOR BUILT-IN FUNCTIONS
		function jd = eq(obj, roi)
			% 		[ofor, rfoo] = fractionalOverlap(obj,roi); eqThresh = .95; jd =  (ofor >= eqThresh) &
			% 		(rfoo >= eqThresh);
			if nargin < 2
				roi = obj;
			end
			oIdx = cat(1,obj.Idx);
			rIdx = cat(2,roi.Idx);
			jd = bsxfun(@eq, oIdx, rIdx);
			sz = size(jd);
			if (sz(1) == 1)
				jd = jd(:);
			end
		end
		function jd = ne(obj, roi)
			jd =  ~eq(obj,roi);
		end
		function jd = lt(obj, roi)
			% a larger roi that entirely encompasses a smaller (sub-)roi is deemed 'greater' ... note: the
			% roi with a fractional overlap closer to one also necessarily smaller and therefore
			% 'less-than' the roi with the smaller fractional overlap
			ofor = fractionalOverlap(obj,roi);
			rfoo = fractionalOverlap(roi,obj);
			jd = ofor > rfoo;
		end
		function jd = le(obj, roi)
			ofor = fractionalOverlap(obj,roi);
			rfoo = fractionalOverlap(roi,obj);
			jd = ofor >= rfoo;
		end
		function jd = gt(obj, roi)
			ofor = fractionalOverlap(obj,roi);
			rfoo = fractionalOverlap(roi,obj);
			jd = ofor < rfoo;
		end
		function jd = ge(obj, roi)
			ofor = fractionalOverlap(obj,roi);
			rfoo = fractionalOverlap(roi,obj);
			jd =  ofor <= rfoo;
		end
	end
	methods % COMBINATION/SUPBORDINATION METHODS
		function superRoi = merge(obj)
			% USAGE:
			% 			>> superRoi(1) = merge( subRoi(1:50) )
			% where superRoi and subRoi are both of the class 'RegionOfInterest' Returns a single ROI
			% comprising the SUBSET of pixels SHARED by SubRegions
			obj = obj(isvalid(obj));
			obj = removeEmpty(obj);
			if numel(obj) > 1
				N = numel(obj);
			else
				superRoi = obj;
				return
			end
			% 			if any(cat(1,obj.isSuperRegion))
			% 			   obj = cat(1,obj.SubRegion); obj = unique(obj); N = numel(obj);
			% 			end
			subRoi = obj;
			numMerge = mean([subRoi.NumberOfMerges]);
			% 			bwMask = false(size(obj(1).createMask));
			bwMask = false(obj(1).FrameSize);
			%         wtMask = zeros(size(bwMask), 'uint8');
			% Get Frames
			allFrames = cat(1, obj.Frames);
			uFrames = fast_unique( allFrames); % unique,
			% 			if length(allFrames)>length(uFrames)
			% 				warning('RegionOfInterest:merge',...
			% 					'ROIs with overlapping frame-assignments are being merged')
			% 			end
			%TODO: warn if numel(allFrames)>numel(uFrames)
			% Get Pixel Indices and Weigh Together
			allPix = cat(1,obj.PixelIdxList);
			uPix = fast_unique(allPix); %  -> PixelIdxList		 could also use fast_intersect_sorted
			% Assign Pixel Weights from Frequency (previously normalized to 255)
			if any(cellfun(@isempty, {obj.PixelCounts}))
				pixFreq = double(fast_frequency(allPix))';
			else % or from pixel counts if roi is previously merged
				% 			pixCountMat =  spalloc(numel(uPix), numel(uPix), numel(uPix));
				pixFreq = zeros(numel(uPix),1);
				for k = 1:numel(subRoi)
					uBin = fast_ismember_sorted(uPix, subRoi(k).PixelIdxList);
					pixFreq(uBin) = pixFreq(uBin) + subRoi(k).PixelCounts;
					% 			   pixFreq(ib pixCountMat(subRoi(k).PixelIdxList) =
					% 			   pixCountMat(subRoi(k).PixelIdxList) + subRoi(k).PixelCounts;
				end
				% 			pixFreq = full(pixCountMat(uPix));
			end
			% NEW
			bwMask(uPix) = true;
			freqMax = max(double(pixFreq(:)));
			normPixFreq = pixFreq / freqMax;
			rpSuper = regionprops(bwMask, obj(1).RegionPropInputs{:});
			if numel(rpSuper) > 1
				[~,idx] = max(cat(1,rpSuper.Area));
				rpSuper = rpSuper(idx);
			end
			superRoi = RegionOfInterest(...
				rpSuper,...
				'Frames',uFrames,...
				'isSuperRegion',true,...
				'FrameSize',size(bwMask),...
				'PixelWeights',normPixFreq(:),...
				'PixelCounts',pixFreq(:));			
			% REPLACED WITH TRIM?
			% 			freqMax = max(double(pixFreq(:)));
			% 			normPixFreq = pixFreq / freqMax;
			% 			% 		 pixFreq = uint8(ceil(pixFreq*255/freqMax)); % -> PixelWeights
			% 			% Use RegionProps (builtin function) To Get Connected Regions
			% 			keepPix = normPixFreq > .25; % TODO: use a changeable setting for 'Trim' cuttoff
			% 			uPix = uPix(keepPix);
			% 			normPixFreq = normPixFreq(keepPix);
			% 			pixFreq = pixFreq(keepPix);
			% 			bwMask(uPix) = true;
			% 			rpMulti = regionprops(bwMask, obj(1).RegionPropInputs{:});
			% 			% DISCARD SMALL ISLAND PIECES THAT ARE CUT OFF  - Maybe? TODO
			% 			if numel(rpMulti) > 1
			% 				[~,idx] = max(cat(1,rpMulti.Area));
			% 				rpMulti = rpMulti(idx);
			% 			end
			% 			superRoi = RegionOfInterest(...
			% 				rpMulti,...
			% 				'Frames',uFrames,...
			% 				'isSuperRegion',true,...
			% 				'FrameSize',size(bwMask),...
			% 				'PixelWeights',normPixFreq(:),...
			% 				'PixelCounts',pixFreq(:));
			% 			   'SubRegion',subRoi,...
			
% 						delete(subRoi);
			% UPDATE SUB-REGIONS
			% 			for kSub = 1:N
			% 			   subRoi(kSub).isMerged = true; if isempty(subRoi(kSub).SuperRegion)
			% 				  subRoi(kSub).SuperRegion = superRoi;
			% 			   else
			% 				  subRoi(kSub).SuperRegion = cat(1, subRoi(kSub).SuperRegion, superRoi);
			% 			   end subRoi(kSub).isSubRegion = true; subRoi(kSub).NumberOfMerges =
			% 			   subRoi(kSub).NumberOfMerges + 1;
			% 			end
			superRoi.NumberOfMerges = numMerge + 1;
			superRoi.isMerged = true;
			superRoi.updateProperties();
			% 			trim(superRoi); % Default frequency trimming is 25%
		end
		function roiGroup = reduceRegions(obj)
			% 		 roiGroup = [];
			if numel(obj) <= 1
				return
			end
			roiSet = obj;
			nFrames = max(cat(1,obj.Frames));
			if isempty(nFrames)
				nFrames = 2000;
			end
			% 		  % PARTITION BY SIZE 
			% 			partBySize = partitionBySize(roiSet);
			% 			for kSz = 1:numel(partBySize)
			% 				roiSubSet = partBySize{kSz};
			% PARTITION BY LOCATION
			% 			partByLoc = partitionByLocation(roiSet);
			partByLoc = partitionByLocationDensity(roiSet);
			partByLoc = partByLoc(:);
			% 			nyLoc = size(partByLoc,1);
			% 			nxLoc = size(partByLoc,2);
			% 			roiCellGroup = cell(nyLoc, nxLoc);
			roiCellGroup = cell(numel(partByLoc),1);
			parfor kLoc = 1:numel(partByLoc) % PARFOR
				% 				for kyLoc = 1:nyLoc
				% 					localRoi = partByLoc{kyLoc,kxLoc};
				localRoi = partByLoc{kLoc};
				if isempty(localRoi), continue; end
				localRoi = localRoi(isvalid(localRoi));
				% CALL 'FINDGROUPS' SUBFUNCTION TO CLUSTER LOCAL ROIS INTO GROUPS
				if numel(localRoi) > max(2,nFrames/1000)
					localGroup  = findGroups(localRoi);
					roiCellGroup{kLoc,1} = localGroup;
					% 						roiCellGroup{kyLoc,kxLoc} = localGroup;
				end
				% 				end
			end
			% MERGE CLUSTERED ROIS INTO SUPER-ROIS
			for kLoc = 1:numel(roiCellGroup)
				if isempty(roiCellGroup(kLoc)), continue; end %isempty(roiCellGroup{kLoc})
				localGroup = roiCellGroup{kLoc};%
				if isempty(localGroup), continue; end
				localMerge = RegionOfInterest.empty(0,1);
				parfor kGrp = 1:numel(localGroup) % PARFOR
					localMerge(kGrp,1) = merge(localGroup{kGrp});
					% 			   if isempty(roiGroup)
					% 				  roiGroup = merge(localGroup{kGrp});
					% 			   else
					% 				  roiGroup = cat(1,roiGroup, merge(localGroup{kGrp}));
					% 			   end
				end
				if ~isempty(localMerge)
					roiCellGroup{kLoc} = removeEmpty(localMerge);
				end
			end
			roiGroup = cat(1, roiCellGroup{:});
		end
		function [groupedObj, varargout] = findGroups(obj, varargin)
			% USAGE EXAMPLE:
			%	[localGroup, localOutlier] = findGroups(localRoi);
			groupedObj = {};
			
			if nargin < 2
				groupingMin = 3; % was 10
			else
				groupingMin = varargin{1};
			end
			if nargin < 3
				simLim = .5;%was .9
			else
				simLim = varargin{2};
			end
			if numel(obj) <= 1
				return
			end
			% GET DESCRIPTIVE INFORMATION ABOUT EACH ROI
			nGroups = 0;
			obj = obj(:);
			nObj = numel(obj);
			fprintf('Finding groups for %i Regions Of Interest\n',nObj);
			if nObj > 20000
				cs1 = obj(1).centroidSeparation(obj(2:end));
				[freq, win] = hist(cs1((cs1 >= (mode(round(cs1)))) & (cs1 <= mode(round(cs1(cs1 > mode(round(cs1))))))));
				[~,idx] = min(freq);
				cutoff = win(idx);
				obj1 = obj(cs1 <= cutoff);
				obj2 = obj(cs1 > cutoff);
				fprintf('Splitting  %i ROIs for processing as a group of %i and %i\n', nObj, numel(obj1), numel(obj2))
				groupedObj1 = findGroups(obj1);
				groupedObj2 = findGroups(obj2);
				groupedObj = cat(1,groupedObj1(:), groupedObj2(:));
				return
			end
			% 			% GET DISTANCE MATRICES FROM DIFFERENCE OF CENTROIDS AND XY-BOUNDARIES
			% 			[simmat.cy,simmat.cx] = centroidSeparation(obj); limsep = limitSeparation(obj);
			% 			objWidth = cat(1,obj.Width); objHeight = cat(1,obj.Height); % NORMALIZE CENTROID
			% 			DISTANCE BY HEIGHT AND WIDTH OF EACH REGION hMat = sqrt(objHeight * objHeight'); wMat
			% 			= sqrt(objWidth * objWidth'); simmat.cx = simmat.cx ./ wMat; simmat.cy = simmat.cy ./
			% 			hMat; % NORMALIZE LIMIT/BORDER DISTANCE BY HEIGHT AND WIDTH
			% 			(Dim3:top,bottom,left,right) simmat.btop = limsep(:,:,1) ./ hMat; simmat.bbot =
			% 			limsep(:,:,2) ./ hMat; simmat.bleft = limsep(:,:,3) ./ wMat; simmat.bright =
			% 			limsep(:,:,4) ./ wMat; clearvars hMat wMat limsep
			%
			% 			% CONSTRUCT A SIMILARITY MATRIX FROM EACH DISTANCE MATRIX sepsigma = 1.5; % TODO:
			% 			determine the effect of this parameter and optimize dmatfields = fields(simmat); for
			% 			kfld = 1:numel(dmatfields)
			% 				fn = dmatfields{kfld}; simmat.(fn) = exp(-((simmat.(fn) -
			% 				simmat.(fn)').^2)/(2*sepsigma^2));
			% 			end similarityMatrix = ...
			% 				simmat.cx .* simmat.cy ... .* simmat.btop .* simmat.bbot ... .* simmat.bleft .*
			% 				simmat.bright;%TODO: make sparse?
			similarityMatrix = exp(-single(centroidSeparation(obj)).^2) .* mean(exp(-single(limitSeparation(obj)).^2),3);
			
			% CHECK MEMORY
			mem = memory;
			memusedgb = mem.MemUsedMATLAB/2^30;
			if memusedgb > 64
				fprintf('Using %3.4g GB\n', memusedgb)
			end
			
			% CONSTRUCT INDEXING STRUCTURE TO REDUCE RUNTIME COMPLEXITY
			unVisitedBin = true(size(obj));
			groupedBin = false(size(obj));
			groupedIdx = [];
			unGroupedMat = similarityMatrix >= simLim;
			unGroupedBin = any(unGroupedMat,2);
			superLooping = false;
			% ITERATIVELY FIND GROUPS WITH REMAINING/UNGROUPED ROIS
			while sum(unGroupedBin) >= groupingMin
				unGroupedIdx = find(unGroupedBin);
				seedIdx = unGroupedIdx(1);
				unVisitedBin(seedIdx) = false;
				ngBin = unGroupedMat(:,seedIdx);
				ngBinMat = bsxfun( @or, ngBin, unGroupedMat(:,ngBin));
				ngBinMat = bsxfun( @and, ngBinMat, unGroupedMat(:,ngBin));
				ngBin = logical(round(sum(ngBinMat,2)));
				ngIdx = find(ngBin);
				unGroupedBin(ngIdx) = false;
				groupedBin(ngIdx) = true;
				groupedIdx = cat(1, groupedIdx(:), ngIdx(:));
				unGroupedMat(ngIdx, ngIdx) = false;
				
				
				if numel(ngIdx) > groupingMin
					nGroups = nGroups + 1;
					newGroup = obj(ngIdx);
					groupedObj{nGroups,1} = newGroup;
					superLooping = false;
				else
					if superLooping
						break
					else
						superLooping = true;
					end
				end
			end
			if nargout > 1
				unGroupedObj = obj(~groupedBin);
				varargout{1} = unGroupedObj(:);
			end
		end
		function [part,varargout] = partitionBySize(obj,overlap)
			% SPLIT DATA INTO BATCHES FOR PARALLEL PROCESSING
			if nargin < 2
				% Overlap between segmentation boundaries, as a fraction of lower bound
				overlap = .15;
			end
			roiArea = cat(1, obj.Area);
			aMin = min(roiArea(:));
			aMax = max(roiArea(:));
			nPartitions = ceil(log2( aMax / aMin ));
			lowerBound = aMin * 2.^[ 0 , 1:nPartitions-1];
			upperBound = aMin * 2.^(1:nPartitions);
			lowerBound = lowerBound - lowerBound*overlap;
			upperBound = upperBound + upperBound*overlap;
			L = bsxfun(@and,...
				bsxfun(@ge, roiArea(:), lowerBound),...
				bsxfun(@le, roiArea(:), upperBound));
			for ksp = 1:nPartitions
				pRoi = obj(L(:,ksp));
				if ~isempty(pRoi)
					part{ksp,1} = pRoi;
				end
			end
			if nargout>1
				varargout{1} = L;
			end
		end
		function [part,varargout] = partitionByLocation(obj)
			% USE R*-TREE, KD-TREE, OR OTHER SEGEMENTATION ALGORITHM TO PARTITION FRAME
			% 			try
			frameSize = obj(end).FrameSize;
			if ~any(cellfun(@isempty,{obj.XLim}))
				% 					obj.updateProperties()
				roiXlim = cat(1,obj.XLim);% could also use obj.Width and obj.Height
				roiYlim = cat(1,obj.YLim);
			else
				bb = cat(1,obj.BoundingBox);
				roiXlim = fix([bb(:,1) bb(:,1)+bb(:,3)]);
				roiYlim = fix([bb(:,2) bb(:,2)+bb(:,4)]);
			end
			roiCentroid = cat(1,obj.Centroid);
			overlap = 3;
			roiExt = double([roiYlim(:,2)-roiYlim(:,1), roiXlim(:,2)-roiXlim(:,1)]);
			% 				extMax = max(roiExt(:)); gridSpace = 1.1*extMax; nPartitions =
			% 				floor(frameSize./gridSpace);
			extMed = median(roiExt(:));
			gridSpace = 1.25*extMed;
			nPartitions = min(floor(frameSize./gridSpace), [15 15]);
			xBound = linspace(0, frameSize(2), nPartitions(2)+1);
			yBound = linspace(0, frameSize(1), nPartitions(1)+1);
			xLowerBound = xBound(1:end-1);
			xUpperBound = xBound(2:end);
			yLowerBound = yBound(1:end-1);
			yUpperBound = yBound(2:end);
			% 		  L.xlim = bsxfun(@and,...
			% 			 bsxfun(@ge, roiXlim(:,2), xLowerBound),... bsxfun(@le, roiXlim(:,1), xUpperBound));
			% 		  L.ylim = bsxfun(@and,...
			% 			 bsxfun(@ge, roiYlim(:,2), yLowerBound),... bsxfun(@le, roiYlim(:,1), yUpperBound));
			L.xlim = bsxfun(@and,...
				bsxfun(@ge, roiCentroid(:,1), xLowerBound - overlap),...
				bsxfun(@le, roiCentroid(:,1), xUpperBound + overlap));
			L.ylim = bsxfun(@and,...
				bsxfun(@ge, roiCentroid(:,2), yLowerBound - overlap),...
				bsxfun(@le, roiCentroid(:,2), yUpperBound + overlap));
			% inserts dimension to expand logical array to 3 dimensions [ROIxXxY]
			LL.xylim = bsxfun(@and, L.xlim, permute(shiftdim(L.ylim,-1),[2 1 3] ));
			part = cell([nPartitions(2),nPartitions(1)]);
			% 			catch me
			% 				showError(me) keyboard
			% 			end
			for kx = 1:nPartitions(2)
				for ky = 1:nPartitions(1)
					roiLimIn = LL.xylim(:,kx,ky);
					if any(roiLimIn)
						part{ky,kx} = obj(roiLimIn);
					end
				end
			end
			if nargout>1
				varargout{1} = LL;
			end
		end
		function part = partitionByLocationDensity(obj)
			
			frameSize = obj(end).FrameSize;
			if ~any(cellfun(@isempty,{obj.XLim}))
				% 					obj.updateProperties()
				roiXlim = cat(1,obj.XLim);% could also use obj.Width and obj.Height
				roiYlim = cat(1,obj.YLim);
			else
				bb = cat(1,obj.BoundingBox);
				roiXlim = fix([bb(:,1) bb(:,1)+bb(:,3)]);
				roiYlim = fix([bb(:,2) bb(:,2)+bb(:,4)]);
			end
			
			cxy = cat(1,obj.Centroid);
			
			gridSpace = 8;
			idx = gridSpace/2:gridSpace:max(frameSize);
			h3 = bsxfun(@and,...
				(abs(bsxfun(@minus, cxy(:,1), idx(:)')) < gridSpace+1) ,...
				(abs(bsxfun(@minus, cxy(:,2), reshape(idx, 1,1,[]))) < gridSpace+1));
			
			% 			imagesc(squeeze(sum(h3,1)))
			
			hGridSum = squeeze(sum(h3,1));
			[~, gridIdx] = sort(hGridSum(:),'descend');
			groups = cell.empty(numel(gridIdx),0);
			% 			[gRow,gCol] = ind2sub(frameSize, gridIdx);
			
			h3r = reshape(h3, size(h3,1),[]);
			
			for k=1:numel(gridIdx)
				groups{k} = obj( h3r(:,gridIdx(k)) );
			end
			
			groups = groups(~cellfun('isempty',groups));
			numInGroup = cellfun(@numel, groups);
			% 			lonelyGroups = groups(numInGroup == 1); pairGroups = groups(numInGroup == 2);
			part = groups(numInGroup >= 1);
		end
		function redObj = reduceSuperRegions(obj, sepThresh)
			if nargin < 2
				sepThresh = 10;
			end
			N = numel(obj);
			sepMat = mean(abs(limitSeparation(obj)),3) + centroidSeparation(obj) ;
			closeMat = sepMat < sepThresh;
			touched = false(N,1);
			grouped = cell(N,1);
			for k=1:N
				if ~touched(k)
					closeVec = closeMat(:,k) & ~touched;
					grouped{k} = obj(closeVec);
					touched = touched | closeVec;
				end
				% 			hIm.CData = touched;
			end
			grouped = grouped(~cellfun(@isempty, grouped));
			n = cellfun(@numel, grouped);
			redObj = cat(1,grouped{n==1});
			needsMerge = grouped(n>1);
			for k=1:numel(needsMerge)
				needsMerge{k} = merge(needsMerge{k});
			end
			redObj = cat(1, redObj, needsMerge{:});
			redObj = redObj( cellfun(@length, {redObj.PixelIdxList}) == cellfun(@length, {redObj.PixelWeights}));
		end
		function nFrameOverlap = findTemporalOverlap(obj)
			allFrames = cat(1, obj.Frames);
			uFrames = fast_unique( allFrames); % unique,
			nFrameOverlap = length(allFrames) - length(uFrames);			
		end
		function superRoi = combine(obj)
			% Returns single ROI (deletes the other)
			%TODO: perhaps add a function for and differentiate from 'combine(obj,roi)' ?
			% 			try
			if numel(obj) > 1
				N = numel(obj);
			else
				superRoi = obj;
				return
			end
			subRoi = obj;
			multiMask = false(size(obj(1).createMask));
			multiPix = obj(1).PixelIdxList;
			multiFrames = obj(1).Frames;
			for kRoi = 1:N
				multiPix = fast_union_sorted( obj(kRoi).PixelIdxList, multiPix);
				multiFrames = fast_union_sorted( obj(kRoi).Frames, multiFrames); % unique
			end
			multiPix = multiPix(:);
			multiFrames = multiFrames(:);
			multiMask(multiPix) = true;
			rpMulti = regionprops(multiMask, obj(1).RegionPropInputs{:});
			% 					'Centroid', 'BoundingBox','Area',... 'Eccentricity', 'PixelIdxList');
			superRoi = RegionOfInterest(...
				rpMulti,...
				'Frames',multiFrames,...
				'isSuperRegion',true,...
				'FrameSize',size(multiMask));
			if numel(superRoi) > 1
				[~,idx] = max(cat(1,superRoi.Area));
				superRoi = superRoi(idx);
			elseif numel(superRoi) < 1
				% 					keyboard
			end
			superRoi.updateProperties();
			% 			catch me
			% 				fprintf('%s\n',me.message) superRoi = RegionOfInterest.empty(0,1);
			% 			end
		end
		function simGroup = mostSimilar(obj)
			isSim = sufficientlySimilar(obj);
			[~,idx] = max(sum(isSim));
			simGroup = obj(isSim(idx,:));
		end
		function obj = addSubRoi(obj, roi)
			% 		 nSub = numel(obj.SubRegion)+1; obj.SubRegion(nSub) = roi; obj.isSuperRegion = true;
			% 		 roi.isSubRegion = true;
			
			%TODO: merge sub and super to make whole-super, (super-super?)?
		end
		function roi = add2SuperRoi(obj, roi)
			roi = addSubRoi(roi,obj);
		end
		function uObj = unique(obj)
			uObj = obj;
			k=1;
			while k<numel(uObj)% TODO: Not efficient (now that each has unique ID
				uRem = uObj(k+1:end);
				c = uObj(k) == uRem;
				uRem = uRem(~c);
				uObj = [uObj(1:k) ; uRem(:)];
				k=k+1;
			end
		end
		function obj = removeEmpty(obj)
			obj = obj(isvalid(obj));
			if numel(obj) > 1
				for k=1:numel(obj)
					notEmpty(k) = ~isempty(obj(k).PixelIdxList);
				end
				obj = obj(notEmpty);
			end
		end		
	end
	methods % DATA GENERATION, STORAGE, & RETRIEVAL
		function varargout = makeTraceFromVid(obj, data)
			meanIm = mean(data,ndims(data));
			meanIm = (meanIm-min(meanIm(:)))./range(meanIm(:));
			% 			pctiles = prctile(meanIm(:), [1 99.5]); meanIm = imadjust(mat2gray(meanIm),
			% 			pctiles/max(meanIm(:)), [0 1], 1.3);
			set(obj, 'Overlay', meanIm);%max(data,[],ndims(data)) - min(data,[],ndims(data))
			haloCompensationDilationFactor = ceil(sqrt(mean([obj.Area])));
			% halved to give additional inner radial pixels of halo (aka donut), doubled to give outer
			nObj = numel(obj);
			sz = size(data);
			nFrames = sz(ndims(data));
			x = zeros([nFrames,1],'double');
			xType = struct(...
				'allpixels', x+1,...
				'incidenceweighted', x+1,...
				'uniquepixels', x+1,...
				'halo', x+1);
			set(obj,'Trace',x);
			set(obj,'TraceType', xType);
			% 		xWeighted = zeros([nFrames,nObj],'double'); xUnique = zeros([nFrames,nObj],'double');
			% 		xNonSurroundCompensated = zeros([nFrames,nObj],'double');
			% CONSTRUCT BINARY ARRAYS FOR SURROUND COMPENSATION
			cellMaskAll = obj.createMask;
			cellMaskAllDilated = imdilate(cellMaskAll, strel('disk',round(haloCompensationDilationFactor/2),8));
			firstFrame = data(:,:,1);
			% RESHAPE VIDEO DATA FRAMES TO COLUMNS
			data = reshape(data, [numel(firstFrame), nFrames]);
			for kRoi = 1:nObj
				% 				try
				pixIdx = obj(kRoi).PixelIdxList(:);
				pixWt = obj(kRoi).PixelWeights(:);
				if isempty(pixWt)
					pixWt = ones(size(pixIdx));
				end
				uniquePixIdx = pixIdx(obj(kRoi).UniquePixels);
				if isempty(uniquePixIdx) %TODO
					uniquePixIdx = pixIdx;
				end
				cellMask = createMask(obj(kRoi));
				haloMask = ...
					imdilate(cellMask, strel('disk', round(haloCompensationDilationFactor*2), 8)) ...
					& ~cellMaskAllDilated;
				haloPixIdx = find(haloMask(:));
				if isempty(haloPixIdx)
					haloPixIdx = find(imdilate(cellMask, strel('disk', round(haloCompensationDilationFactor*2), 8)));
				end
				% COMPUTE TRACE IN MULTIPLE WAYS
				obj(kRoi).TraceType.allpixels = mean(data(pixIdx,:), 1)' ;
				obj(kRoi).TraceType.incidenceweighted = double(data(pixIdx,:)') * (pixWt./sum(pixWt));
				obj(kRoi).TraceType.uniquepixels = mean(data(uniquePixIdx,:), 1)' ;
				obj(kRoi).TraceType.halo = mean(data(haloPixIdx, :), 1)';
				obj(kRoi).HaloPixIdx = haloPixIdx;
				% ASSIGN TRACE FROM DEFAULT TYPE
				obj(kRoi).Trace = obj(kRoi).TraceType.uniquepixels;
				% 				catch me
				% 					keyboard
				% 				end
			end
			normalizeTrace2WindowedRange(obj);
			filterTrace(obj);
			reassignIdx(obj);
			if nargout
				varargout{1} = cat(2, obj.Trace);
			end
		end
		function varargout = makeTraceFromVidOld(obj, vid)
			nObj = numel(obj);
			% GATHER PIXEL WEIGHTS
			% 		if nObj > 1
			% 		  nIdx = cat(1,obj.Area); maxIdx = max(nIdx); idxByColumn =
			% 		  zeros([maxIdx,nObj],'double'); for k=1:numel(obj)
			% 			 idxByColumn(1:nIdx(k), k) = obj(k).PixelIdxList(:);
			% 		  end isPixWeighted = ~cellfun(@isempty, {obj.PixelWeights}); if any(isPixWeighted)
			% 			 pixWeightByColumn = zeros([maxIdx,nObj],'double'); for k=1:numel(obj)
			% 				if isPixWeighted(k)
			% 				  pixWeightByColumn(1:nIdx(k), k) = double(obj(k).PixelWeights(:));
			% 				end
			% 			 end
			% 		  end
			% 		else
			% 		  nIdx = obj.Area;
			% 		end
			% GET RESHAPED VIDEO-ARRAY FROM VID INPUT
			if isstruct(vid)
				nFrames = numel(vid);
				% Preallocate Trace Array
				f = zeros([nFrames,nObj],'double');
				for kRoi = 1:nObj
					% 			 pixIdx = idxByColumn( 1:nIdx(kRoi), kRoi); nPix = nIdx(kRoi);
					pixIdx = obj(kRoi).PixelIdxList(:);
					pixWt = obj(kRoi).PixelWeights(:);
					uniquePix = obj(kRoi).UniquePixels;
					nPix = numel(pixIdx);
					nUniquePix = sum(double(uniquePix));
					% APPLY PIXEL WEIGHTS
					% 			 if isPixWeighted(kRoi)
					% 				pixWt = pixWeightByColumn( 1:nIdx(kRoi), kRoi); pixWt = pixWt/255; for kFrame =
					% 				1:nFrames
					% 				  f(kFrame,kRoi) = sum( double(vid(kFrame).cdata(pixIdx)) .* pixWt , 1) / nPix;
					% 				end
					% 			 else
					for kFrame = 1:nFrames
						f(kFrame,kRoi) = sum( double(vid(kFrame).cdata(pixIdx)), 1) / nPix ;
					end
					% 			 end
				end
			elseif isnumeric(vid)  % For 3D matrix vid input
				nFrames = size(vid,ndims(vid));
				im = vid(:,:,1);
				f = zeros([nFrames,nObj],'double');
				vid = reshape(vid,[numel(im) nFrames]);
				for kRoi = 1:nObj
					pixIdx = idxByColumn( 1:nIdx(kRoi), kRoi);
					% APPLY PIXEL WEIGHTS
					if isPixWeighted(kRoi)
						pixWt = pixWeightByColumn( 1:nIdx(kRoi), kRoi);
						pixWt = pixWt/255;
						f(:,kRoi) = double(vid(pixIdx,:)') * pixWt ;
					else
						f(:,kRoi) = sum( double(vid(pixIdx,:)'), 2)./nIdx(kRoi);
					end
				end
			end
			% NORMALIZE TRACE TO A BASELINE
			% 		f = detrend(f, 'linear');
			fnan = f;
			% 			fnan( bsxfun(@ge, f, mean(f,1)+std(f,[],1))) = NaN;
			% 			fnan( bsxfun(@le, f, mean(f,1)-std(f,[],1))) = NaN;
			fmed = median(f,1);
			fstd = std(f,[],1);
			fnan( bsxfun(@ge, f, fmed+fstd)) = NaN;
			fnan( bsxfun(@le, f, fmed-fstd)) = NaN;
			f = bsxfun(@rdivide, bsxfun(@minus, f, nanmean(fnan,1)), nanvar(fnan,1));
			% ASSIGN TRACE TO ROIs
			for kRoi = 1:nObj
				obj(kRoi).Trace = f(:,kRoi);
			end
			if nargout > 0
				varargout{1} = f;
			end
		end
		function varargout = normalizeTrace2WindowedRange(obj)
			X = [obj.Trace];
			fs=20; % TODO
			winsize = 1*fs;
			numwin = floor(size(X,1)/winsize)-1;
			xRange = zeros(numwin,size(X,2));
			xBaseline = zeros(numwin,size(X,2));
			for k=1:numwin
				windex = (winsize*(k-1)+1):(winsize*(k-1)+20);
				xRange(k,:) = range(detrend(X(windex,:)), 1);
				xBaseline(k,:) = mean(X(windex,:));
			end
			X = bsxfun(@rdivide, bsxfun(@minus, X, median(xBaseline,1)) , mean(xRange,1));
			for k=1:numel(obj)
				obj(k).Trace = X(:,k);
			end
			if nargout > 0
				varargout{1} = X;
			end
		end
		function varargout = filterTrace(obj, fcut)%TODO
			Fs = 20;
			if nargin < 2
				fcut = 2;
			end
			ws = 2 * fcut/Fs;
			[b,a] = butter(Fs/2, ws, 'low');
			X = single(filtfilt(b, a, double([obj.Trace])));
			for k = 1:numel(obj)
				obj(k).Trace = X(:,k);
			end
			if nargout
				varargout{1} = X;
			end
		end
		function wtMask = weightedMask3D(obj)
			fs = obj(1).FrameSize;
			nObj = numel(obj);
			wtMask = zeros([fs nObj]);
			for kObj = 1:nObj
				wm = zeros(fs);
				wm(obj(kObj).PixelIdxList) = obj(kObj).PixelWeights;
				wtMask(:,:,kObj) = wm;
			end
		end
		function wtMask = weightedMask(obj)
			fs = obj(1).FrameSize;
			nObj = numel(obj);
			wtMask = zeros(fs);
			wm = zeros(fs);
			for kObj = 1:nObj
				idx = obj(kObj).PixelIdxList;
				wm(idx) = obj(kObj).PixelWeights;
				wtMask(idx) = max([wm(idx), wtMask(idx)], [], 2);
			end
		end
		function cIm = centroidImage(obj)
			% TODO: Use Accumarray
			nRois = numel(obj);
			frameSize = obj(1).FrameSize;
			cIm = zeros(frameSize);
			roivec.area = cat(1,obj.Area);
			roivec.centroids = cat(1,obj.Centroid);
			for kRoi = 1:nRois
				roivec.nIdx(kRoi) = numel(obj(kRoi).PixelIdxList);
			end
			idx.roipix = cat(1,obj.PixelIdxList);
			roiFirstIdxIdx = [1 ; cumsum(roivec.area)+1];
			r1 = roiFirstIdxIdx;
			r2 = [ r1(2:end)-1 ; numel(idx.roipix)];
			for kRoi = 1:numel(r1)
				idx.roimap(r1(kRoi):r2(kRoi),1) = kRoi;
			end
			upix = unique(idx.roipix);
			[idx.maxidx, idx.maxoccur] = mode(idx.roipix);
			w = 1/idx.maxoccur;
			for kIdx = 1:numel(upix)
				thisIdx = upix(kIdx);
				%         ovlpRoiIdx = idx.roimap(idx.roipix == thisIdx); ovlpRoiN = numel(ovlpRoiIdx);
				ovlpRoiN = sum(idx.roipix == thisIdx);
				cIm(thisIdx) = w*ovlpRoiN;
			end
		end
		function varargout = createMask(obj)
			% Will return BINARY IMAGE from a single ROI or Array of ROI objects
			pxIdx = cat(1,obj.PixelIdxList);
			% 			if any(cellfun(@isempty,{obj.FrameSize}))
			% 				obj.guessFrameSize();
			% 			end
			if isempty(obj(1).FrameSize)
				guessFrameSize(obj(1:min(10,numel(obj))));
			end
			mask = false(obj(1).FrameSize);
			mask(pxIdx) = true;
			if nargout
				varargout{1} = mask;
			end
		end
		function varargout = makeSparseMask(obj)
			if any(cellfun(@isempty,{obj.PixelSubScripts}))
				obj = removeEmpty(obj);
			end
			imsize = obj(end).FrameSize;
			npix = cat(1,obj.Area);
			for kObj = 1:numel(obj)
				% PIXEL SUBSCRIPTS
				[isubs, jsubs] = ind2sub(imsize,obj(kObj).PixelIdxList);
				% SPARSE MASK
				obj(kObj).SparseMask = sparse(isubs,jsubs,...
					true,imsize(1),imsize(2),npix(kObj));
			end
			if nargout
				varargout{1} = cat(3,obj.SparseMask);
			end
		end
		function varargout = makeBoundaryTrace(obj)
			for k = 1:numel(obj)
				mask = obj(k).createMask;
				[pRow, pCol] = find(mask, 1, 'first');
				b = bwtraceboundary(mask, [pRow, pCol], 'N');
				obj(k).BoundaryTrace = struct(...
					'x',uint32(b(:,2)),...
					'y',uint32(b(:,1)));
			end
			if nargout
				varargout{1} = cat(1, obj.BoundaryTrace);
			end
		end
		function varargout = makeUniquePixels(obj)
			N = numel(obj);
			ovArray = spatialOverlap(obj);
			for k=1:N
				allPix = uint32(ovArray{k,k});
				switch k
					case 1
						ovPix = fast_unique(uint32(cat(1, ovArray{k, (2:N)})));
					case N
						ovPix = fast_unique(uint32(cat(1, ovArray{k, (1:N-1)})));
					otherwise
						ovPix = fast_unique(uint32(cat(1, ovArray{k, ([1:k-1, k+1:N])})));
				end
				uPix = ~fast_ismember_sorted(allPix, ovPix);
				obj(k).UniquePixels = uPix';
				obj(k).UniqueArea = sum(double(uPix));
			end
			if nargout
				varargout{1} = {obj.UniquePixels};
			end
		end
		function reassignIdx(obj,varargin)
			N = numel(obj);
			if nargin > 1
				newIdx = varargin{1};
				if numel(newIdx) == 1
					set(obj,'Idx', newIdx);
					return
				elseif numel(newIdx) == N
					for k=1:N
						obj(k).Idx = newIdx(k);
					end
					return
				end
			end
			newIdx = 1:N;
			for k=1:N
				obj(k).Idx = newIdx(k);
			end
		end
		function fillPropsFromStruct(obj, structSpec)
			fn = fields(structSpec);
			for kf = 1:numel(fn)
				if isprop(obj, fn{kf})
					set(obj, fn{kf}, structSpec.(fn{kf}));
				end
			end
		end
	end
	methods % PRIVATE MANAGEMENT FUNCTIONS
		function varargout = guessFrameSize(obj)
			global FRAMESIZE
			if ~isempty(FRAMESIZE)
				fsz = FRAMESIZE;
			else
				% assume square & power-of-2 frame size based on pixel indices TODO: get frame size by
				% checking subregions or superregions
				if numel(obj) > 1
					fsz = cat(1,obj.FrameSize);
					if ~isempty(fsz)
						fsz = max(fsz,[],1);
					else
						fsz = guessFrameSize(obj(end));
					end
				else
					maxidx = max(obj.PixelIdxList);
					sqsize = 2.^(1:12);
					framePow2 = find(sqsize > sqrt(maxidx),1,'first');
					fsz = [2^framePow2 2^framePow2];
					warning('Assuming frame size')
				end
			end
			set(obj, 'FrameSize', fsz);
			if nargout
				varargout{1} = fsz;
			end
		end
		function h = createShowFigure(obj)
			global H
			if isempty(obj(1).Overlay)
				cdata = zeros([obj(1).FrameSize 3], 'double');
			else
				cdata = obj(1).Overlay;
			end
			pos = [0 0 obj(1).FrameSize];
			H.im = handle(imshow(cdata));
			H.ax = handle(gca);
			H.fig = handle(gcf);
			assignin('base','h',H);
			% SAVE ACCESS TO GRAPHICS HANDLES
			% 		set(obj,'hIm', h.im); set(obj, 'hAx', h.ax); set(obj, 'hFig',  h.fig);
			
			% FIGURE PROPERTIES
			set(H.fig,...
				'Color',[.2 .2 .2],...
				'NextPlot','add',...
				'Units','normalized',...
				'Color',[.25 .25 .25],...
				'MenuBar','figure',...
				'Name','Region Of Interest',...
				'NumberTitle','off',...
				'HandleVisibility', 'callback',...
				'Clipping','on')
			% 		H.fig.Position(3:4) = obj(1).FrameSize + 20; H.fig.Units = 'normalized';
			% 		H.fig.Position(1:2) = [ .05 .1];
			%     'Colormap' 'GraphicsSmoothing' 'Alphamap' 'WindowButtonDownFcn' 'WindowStyle'
			%     'DockControls' 'Resize' 'SelectionType' 'SizeChangedFcn'
			% AXES PROPERTIES
			set(H.ax,...
				'xlimmode','manual',...
				'ylimmode','manual',...
				'zlimmode','manual',...
				'climmode','manual',...
				'alimmode','manual',...
				'GridColor',[0 0 0],...
				'GridLineStyle','none',...
				'MinorGridColor',[0 0 0],...
				'TickLabelInterpreter','none',...
				'XGrid','off',...
				'YGrid','off',...
				'Visible','off',...
				'Layer','top',...
				'Clipping','on',...
				'NextPlot','replacechildren',...
				'TickDir','out',...
				'YDir','reverse',...
				'Units','normalized',...
				'DataAspectRatio',[1 1 1]);
			% 			'GridAlpha',0,... 'MinorGridAlpha',0,...
			if isprop(H.ax, 'SortMethod')
				H.ax.SortMethod = 'childorder';
			else
				H.ax.DrawMode = 'fast';
			end
			H.ax.Units = 'normalized';
			H.ax.Position = [0 0 1 1];
			% IMAGE PROPERTIES
			H.im.ButtonDownFcn = @(src,evnt)roiClickFcn(obj,src,evnt);
			h = H;
			
			
			% H.ax.Position([4 3]) = size(mdata);
		end
		function roiClickFcn(obj,src,evnt)
			persistent hAx
			persistent hFig
			persistent roiAx
			persistent hTx
			persistent hLine
			persistent roiShowingTrace
			if numel(obj(1).Trace) < 1
				return
			end
			fps = 20; %TODO, use time vector
			sz = get(0,'ScreenSize');
			hp = .4;
			vp = .5625;
			% 		vp = sz(3)/sz(4); textOffset = [-35 25]; % [dx dy]
			
			
			selectedObj = RegionOfInterest.empty(1,0);
			if isa(src,'patch')
				selectedObj = src.UserData;
			else
				% RETRIEVE CLICK LOCATION ON LABEL-MATRIX IMAGE
				cp = fliplr(evnt.IntersectionPoint(1:2));
				clickPoint = cat(3, ...
					[floor(cp(1)), floor(cp(2))],...
					[floor(cp(1)), ceil(cp(2))],...
					[ceil(cp(1)), floor(cp(2))],...
					[ceil(cp(1)), ceil(cp(2))]);
				kSel = 0;
				for k = 1:numel(obj)
					if any(bsxfun(@eq,obj(k).PixelSubScripts, clickPoint))
						kSel = kSel+1;
						selectedObj(kSel) = obj(k);
					end
					roiShowingTrace(k) = true;
				end
			end
			
			if isempty(hFig) || ~isvalid(hFig)
				hFig = src.Parent.Parent;
				roiAx = src.Parent;
				% 		  roiAx = hFig.Children;
				if sz(4) > sz(3) % (vertical)
					roiAx.Position = [0 0 1 vp];
				else				% (horizontal)
					roiAx.Position = [0 0 hp 1];
				end
			end
			if isempty(hAx) || ~isvalid(hAx)
				if sz(4) > sz(3) % (vertical)
					p = vp+.005;
					hAx = handle(axes('Position',[.01, p, .98, .995-p],'Parent',hFig));
				else				% (horizontal)
					p = hp;
					hAx = handle(axes('Position',[p, .01, .99-p, .98],'Parent',hFig));
				end
			end
			if isempty(roiShowingTrace)
				roiShowingTrace = false(numel(obj),1);
			end
			switch evnt.Button;
				case 1 % LEFT-BUTTON: PLOT NEW TRACE
					if ~isempty(selectedObj)
						% New Plot
						if ~isempty(hLine)
							try
								delete(hLine)
								hLine = [];
							catch me
								hLine = [];
							end
							set(hFig, 'HandleVisibility', 'callback')
							try
								delete(hTx)
								hTx = [];
							catch me
								delete(findobj(roiAx, 'type', 'text'))
								hTx = [];
							end
						end
						for k = 1:numel(selectedObj)
							hLine(k) = handle(line((1:numel(selectedObj(k).Trace))./fps, selectedObj(k).Trace,...
								'Color',selectedObj(k).Color, 'Parent',hAx,'LineWidth',1.5));
							
							hTx(k) = handle(text(...
								'String', sprintf('%i',selectedObj(k).Idx),...
								'FontWeight','bold',...
								'BackgroundColor',[.1 .1 .1 .3],...
								'Margin',1,...
								'Position', round(selectedObj(k).BoundingBox(1:2)) - [0 5],...
								'Parent', src.Parent,...
								'Color',selectedObj(k).Color	));%round(obj(k).Centroid+textOffset) -> previous position
							% 							roiShowingTrace(k) = true; if rand > (k/numel(obj)), break, end
						end
					end
				case 2 % MIDDLE-BUTTON: RESET
					% Remove Plot
					if ~isempty(hAx) && isvalid(hAx)
						cla(hAx);
					end
					hLine = [];
					% Remove Text
					try
						delete(hTx)
						hTx = [];
					catch me
						delete(findobj(roiAx, 'type', 'text'))
						hTx = [];
					end
					roiShowingTrace = false(numel(obj),1);
				case 3 % RIGHT-BUTTON: PLOT MULTIPLE TRACES
					if ~isempty(selectedObj)
						for k = 1:numel(selectedObj)
							% Add Plot
							set(hAx, 'NextPlot','add')
							hLine(numel(hLine)+1) = handle(line((1:numel(selectedObj(k).Trace))./fps, selectedObj(k).Trace,...
								'Color',selectedObj(k).Color, 'Parent',hAx,'LineWidth',1.5));
							% Add Text
							hTx(numel(hTx)+1) = handle(text(...
								'String', sprintf('%i',selectedObj(k).Idx),...
								'FontWeight','bold',...
								'Color',selectedObj(k).Color,...
								'BackgroundColor',[.1 .1 .1 .3],...
								'Margin',1,...
								'Position', round(selectedObj(k).BoundingBox(1:2)) - [0 5],...
								'Parent', src.Parent));
							% 							roiShowingTrace(k) = true;
						end
					end
			end
			hAx.YColor = [1 1 1];
			hAx.YTick = [0];
			hAx.YTickLabel = {};
			hAx.XColor = [1 1 1];
			hAx.XLim = [0 numel(obj(1).Trace)/fps];
			hAx.Box = 'off';
			hAx.Color = [hAx.Parent.Color .1];
		end
		function vidOverlayUpdate(obj,src,~)
			try
				k = get(src,'TasksExecuted')+1;
				udata = src.UserData;
				overlayInput = udata.data;
				h = udata.hand;
				if isnumeric(overlayInput)
					N = size(overlayInput, ndims(overlayInput));
				else
					N = numel(overlayInput);
				end
				if k > N		% Finished
					stop(src);
					delete(src);
				else
					if isnumeric(overlayInput)
						h.bg.AlphaData = imcomplement(overlayInput(:,:,k));
					else
						h.bg.AlphaData = imcomplement(overlayInput(k).cdata);
					end
					% 			 obj(1).hIm.AlphaData = vid(k).cdata; hText.String = sprintf('Frame %i/%i',k,N);
					drawnow('expose')
				end
			catch me
				fprintf('Video CLOSED\n')
				stop(src)
				return
			end  % localTimer
		end
	end
	
	
end







% TIMING INFO for 100 x 100 calculation
%      fractionalOverlap: 2.7137 --> 0.6672 (FastSet) --> 0.1338 (unrecurs)
%        isInBoundingBox: 0.4519 --> 0.00068(bsxfun)
%     centroidSeparation: 0.1230 --> 0.0004 (bsxfun)
%               overlaps: 1.2500 --> 0.4386 (symmetry) --> 0.0454 (FastSet)
%         spatialOverlap: 2.4983 --> 0.1315 (FastSet)
% Tremendous speed-up provided by using FastSet, a MATLAB TOOLBOX built by Lev Muchnik and made
% available at the following site:
% http://www.levmuchnik.net/Content/ProgrammingTips/MatLab/FastSet/FastSet.html

% TIMING INFO for 1000 x 1000 calculation
%	>> [simmat.cy,simmat.cx] = centroidSeparation(obj)	--> 0.0087
%  >> csep = centroidSeparation(obj)			--> 0.0143
%	>> limsep = limitSeparation(obj)				--> 0.0190


% updateProperties(44058) --> 10.62 seconds




% d = sum(centroidSimilarity,2); D = diag(d); A = centroidSimilarity; P = inv(D)*A; imagesc(P) help
% eig [vecs,vals] = eig(P); [maxeigval, mevidx] = max(vals)



% 			 % ASSESS CONCENSUS FROM 'GROUP MEMBERS' dgConsesusMat = false([numel(dgBinVec), dgNum]);
% 			 for kdg = 1:dgNum
% 				gmIdx = dgSimVec(dgNum); gmSimVec = ugSimilarityMatrix(:, gmIdx); gmBinVec = gmSimVec >
% 				simThresh; dgConsesus(dgBinVec & gmBinVec) = dgConsesus(dgBinVec & gmBinVec) + 1;
% 				dgConsesus(dgBinVec & gmBinVec) = dgConsesus(dgBinVec & gmBinVec) + 1;


%
% 		  for kLim = 1:size(limsep,3)
% 			 limsep(:,:,kLim) = limsep(:,:,kLim) * ctranspose(limsep(:,:,kLim));
% 		  end

% centroidSimilarity = (1./(simmat.cx.^2 + 1) + 1./(simmat.cy.^2 + 1)) ./ 2;



% 		function delete(obj)
		% 			try if numel(obj) > 1
		% 				for k=1:numel(obj)
		% 					delete(obj(k))
		% 				end
		% 		  elseif ~isempty(obj.SubRegion)
		% 			 delete(obj.SubRegion)
		% 			end catch end
		% 		end








% SSSSSSSS== SUBFUNCTIONS ==SSSSSSSSS SUBFUNCTION: GET DENSEST GROUP NOT USED !!!!!!!!
% 		function dgBinVec = getDenseGroup(ugSimilarityMatrix)
% 		  % EXTRACT A 'DENSE GROUP' USING A HIGH THRESHOLD simThresh = .5; [ugIdx,dgIdx] =
% 		  find(ugSimilarityMatrix > simThresh); while numel(ugIdx) < max(nObj/1000,50)
% 			 simThresh = simThresh *.95; [ugIdx,dgIdx] = find(ugSimilarityMatrix > simThresh); if
% 			 simThresh <= .01
% 				dgBinVec = false([size(ugSimilarityMatrix,1) 1]); return
% 			 end
% 		  end ugIdx = ugIdx(1); % 		  dgSimVec = ugSimilarityMatrix(ugIdx,:); dgSimVec =
% 		  mean(ugSimilarityMatrix(ugIdx,:), 1); % 		  simThresh = .8; % LOWER THRESHOLD TO LOOSEN
% 		  GROUP IF DOING SO INCREASES GROUP DISTINCTION while true
% 			 % CHOOSE 'DENSE GROUP' USING CURRENT THRESHOLD -> DECREASE IF GROUP# TOO LOW dgBinVec =
% 			 dgSimVec > simThresh; if sum(dgBinVec) < 25;
% 				simThresh = .9*simThresh; continue
% 			 end
%
% 			 dgSimVec = find(dgBinVec); dgNum = sum(dgBinVec(:)); % LOWER THRESHOLD AND CHOOSE A 'LOOSE
% 			 GROUP' FOR COMPARISON simThresh = .95*simThresh; lgBinVec = dgSimVec > simThresh; lgSimVec
% 			 = mean(ugSimilarityMatrix(:, find(lgBinVec)),2); lgNum = sum(lgBinVec); if lgNum <= dgNum
% 				if all(lgBinVec == dgBinVec)
% 				  continue
% 				end
% 			 end % CALCULATE A DISTINCTION LEVEL FOR THIS GROUPING SCENARIO dgDistinction =
% 			 mean(dgSimVec(dgBinVec)) / mean(dgSimVec(~dgBinVec)); lgDistinction =
% 			 mean(lgSimVec(lgBinVec)) / mean(lgSimVec(~lgBinVec)); % IF DISTINCTION INCREASES -> UPDATE
% 			 SIMILARITY VECTOR TO MATCH NEW MEAN fprintf(['Similarity Threshold: %+3.4g',...
% 				'\tdenseGroup Distinction: %-3.4g (%i rois)',... '\tLooseGroup Distinction: %-3.4g (%i
% 				rois)\n'],... simThresh,dgDistinction, dgNum, lgDistinction, lgNum );
% 			 if (lgDistinction - dgDistinction) >= 0
% 				dgSimVec = lgSimVec; continue
% 			 else
% 				fprintf('=============================================================\n') break
% 			 end
% 		  end
% 		end

%









%
%










%

% 		vs = getVidSample(vid,500); inputRange = [min(min( cat(1,vs.cdata), [],1), [],2) , max(max(
% 		cat(1,vs.cdata), [],1), [],2)];
% fileString = vid(1).info.Filename;