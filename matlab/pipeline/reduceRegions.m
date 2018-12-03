function R = reduceRegions(roi)
% This function will operate on a large set of spatial Regions Of Interest
% (ROI) generated by an image-segmentation algorithm operating on
% individual frames in a multi-frame video. The goal is to reduce the large
% set of SINGLE-FRAME-ROIs to a smaller set of SINGLE-VIDEO-ROIs by
% merging/combining similar ROIs across time (while maintaining much of the
% temporal information of the larger set). Frames will be combined using a
% Nearest-Neighbor type approach with reduced Metric, M (d dimensions),
% calculated to determine Similarity scores between ROIs in set S (N
% cardinality). The large set of ROIs will be pre-processed and partitioned
% into several spaces along planes of M and other metrics (e.g. Area) to
% reduce the number of computations necessary and facilitate parallel
% processing.
frameSize = roi(end).FrameSize;
nFrames = max(cat(1,roi.Frames),[],1);
minPartitionIncidence = .0025*nFrames;

% INITIALIZE DATA STRUCTURE FOR SEQUENTIALLLY PARTITIONED ROI-DATA
part.singleframeroi = roi;
part.current = {roi};
part = partitionBySize(part);
part = partitionByLocation(part);
nComRoi = 0;
for kSize = 1:numel(part.bysize)
  p.bylimit = part.bylimit{kSize};
  sz = size(p.bylimit);
  groupedRois = cell(sz);
  cnum = cellfun(@numel, p.bylimit);
  for ky = 1:sz(1)
    for kx = 1:sz(2)
      if cnum(ky,kx) > minPartitionIncidence        
        %         roiC = p.bycentroid{ky,kx};
        roiL = p.bylimit{ky,kx};
        roiLidx = cat(1,roiL.Idx);%rid = roi([roi.Idx] == roiLidx(1))
        groupIdx = getGroup(roiL);
        nGroups = 0;
        while any(groupIdx)
          if numel(roiL) <= minPartitionIncidence
            break
          end
          % TODO: check overlap, multiple frames --> split
          % Sort the group
          nGroups = nGroups + 1;
          newGroup = roiL(groupIdx);
          roiGroup{nGroups,1} = newGroup;
          if numel(newGroup) > minPartitionIncidence
            nComRoi = nComRoi + 1;
            %             R.cRoi(nComRoi,1) = combine(newGroup);
            R.mRoi(nComRoi,1) = merge(newGroup);
          end
          %           groupCsMean = mean(seedCsep(groupIdx));
          %           groupFoMean = mean(seedFovlp(groupIdx));
          % CONTINUED AS ABOVE
          roiL = roiL(~groupIdx); 
          groupIdx = getGroup(roiL);
          %           roiC = roiC(~fast_ismember_sorted(roiC,newGroup))
          %           csAll = centroidSeparation(roiL);
          %           csMean = mean(csAll(csAll~=0));
          %           csStd = std(csAll(csAll~=0));
          %           csThresh = csMean-csStd;
          %           ovlp = isInBoundingBox(roiL);
          %           [~,seedIdx] = max(sum(ovlp,2));
          %           seedCsep = csAll(seedIdx,:);
          %           groupIdx = seedCsep < csThresh;
          
        end        
        groupedRois{ky,kx} = roiGroup;            
        roiGroup = {};
        % Establish locally normalized threshold for metric M
        
        
      end      
    end
  end
  R.sizedGroupedRois{kSize} = groupedRois;
end

function groupIdx = getGroup(roiL)
% GROUP STATISTICS: CENTROID SEPARATION
csAll = centroidSeparation(roiL);
csMean = mean(csAll(csAll~=0));
csStd = std(csAll(csAll~=0));
csThresh = max(csMean - csStd, 1);
% GROUP STATISTICS: FRACTIONAL OVERLAP
foAll = fractionalOverlap(roiL);
%         foAll(foAll==1) = NaN;
foMean = mean(foAll((foAll>0) & (foAll<1)));
foStd = std(foAll( (foAll>0) & (foAll<1)));
foThresh = foMean + foStd;
% PULL OUT FIRST (and largest) GROUP WITH MOST OVERLAP
[foMaxCol,jIdx] = max(sum(foAll>foThresh,1));
[foMaxRow,iIdx] = max(sum(foAll>foThresh,2));
if foMaxRow > foMaxCol
  seedIdx = iIdx;
  seedCsep = csAll(seedIdx,:);
  seedFovlp = foAll(seedIdx,:);
else
  seedIdx = jIdx;
  seedCsep = csAll(:,seedIdx);
  seedFovlp = foAll(:,seedIdx);
end
groupIdx = (seedCsep < csThresh) & (seedFovlp > foThresh);





function [part,varargout] = partitionBySize(part,overlap)
% SPLIT DATA INTO BATCHES FOR PARALLEL PROCESSING
if nargin < 2
  % Overlap between segmentation boundaries, as a fraction of lower bound
  overlap = .25;
end
cp = part.current;
for kPart = 1:numel(cp)
  roi = cp{kPart};
  %   X = constructRoiIndexMaps(roi);
  roiArea = cat(1, roi.Area);
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
    pRoi = roi(L(:,ksp));
    if ~isempty(pRoi)
      part.bysize{ksp,kPart} = pRoi;
      %       S.idx.bysize{ksp,k} = find(L(:,ksp));
      %     spIdx{ksp,k} X.setidx.roimap( and(...
      %       X.area >= partMinArea(ksp), X.area < partMaxArea(ksp));
    end
  end
end
part.current = part.bysize;
if nargout>1
  varargout{1} = L;
end

function [part,varargout] = partitionByLocation(part)
% USE R*-TREE, KD-TREE, OR OTHER SEGEMENTATION ALGORITHM TO PARTITION FRAME
cp = part.current;
for kPart = 1:numel(cp)
  try
  roi = cp{kPart};
  frameSize = roi(end).FrameSize;
  %   X = constructRoiIndexMaps(roi);
  %   roiCxy = cat(1,roi.Centroid);
  if any(cellfun(@isempty,{roi.XLim}))
    roi.updateProperties()
  end
  roiXlim = cat(1,roi.XLim);
  roiYlim = cat(1,roi.YLim);
  roiExt = [roiYlim(:,2)-roiYlim(:,1), roiXlim(:,2)-roiXlim(:,1)];
  extMax = max(roiExt(:));
  gridSpace = 2*extMax;
  nPartitions = floor(frameSize./gridSpace);
  xBound = linspace(0, frameSize(2), nPartitions(2)+1);
  yBound = linspace(0, frameSize(1), nPartitions(1)+1);
  xLowerBound = xBound(1:end-1);
  xUpperBound = xBound(2:end);
  yLowerBound = yBound(1:end-1);
  yUpperBound = yBound(2:end);
  %   L.cx = bsxfun(@and,...
  %     bsxfun(@ge, roiCxy(:,1), xLowerBound),...
  %     bsxfun(@le, roiCxy(:,1), xUpperBound));
  L.xlim = bsxfun(@and,...
    bsxfun(@ge, roiXlim(:,2), xLowerBound),...
    bsxfun(@le, roiXlim(:,1), xUpperBound));
  %   L.cy = bsxfun(@and,...
  %     bsxfun(@ge, roiCxy(:,2), yLowerBound),...
  %     bsxfun(@le, roiCxy(:,2), yUpperBound));
  L.ylim = bsxfun(@and,...
    bsxfun(@ge, roiYlim(:,2), yLowerBound),...
    bsxfun(@le, roiYlim(:,1), yUpperBound));
   % inserts dimension to expand logical array to 3 dimensions [ROIxXxY]
%   LL.cxy = bsxfun(@and, L.cx, permute(shiftdim(L.cy,-1),[2 1 3] ));
  LL.xylim = bsxfun(@and, L.xlim, permute(shiftdim(L.ylim,-1),[2 1 3] ));
  % Add rois to cell bins
  %   partbycent = cell([nPartitions(2),nPartitions(1)]);
  partbylim = cell([nPartitions(2),nPartitions(1)]);
  catch me
    showError(me)
    keyboard
  end
  for kx = 1:nPartitions(2)
    for ky = 1:nPartitions(1)
      %       roiCentIn = LL.cxy(:,kx,ky);
      roiLimIn = LL.xylim(:,kx,ky);
      %       if any(roiCentIn)
      %         partbycent{ky,kx} = roi(roiCentIn);
      %       end
      if any(roiLimIn)
        partbylim{ky,kx} = roi(roiLimIn);
      end
    end
  end
  %   part.bycentroid{kPart,1} = partbycent;
  part.bylimit{kPart,1} = partbylim;
end
part.current = part.bylimit;
if nargout>1
  varargout{1} = LL;
end

function part = partitionByShape(part)
%TODO

function part = partitionByTimeFrame(part)

function idx = constructRoiIndexMaps(roi)
% CONSTRUCT INDEX VECTORS THAT MAP PIXEL INDICES TO ROIs (FROM GROUPING VARIABLES)
roiArea = cat(1,roi.Area);
idx.roipix = cat(1,roi.PixelIdxList);
roiFirstIdxIdx = [1 ; cumsum(roiArea)+1];
r1 = roiFirstIdxIdx;
r2 = [ r1(2:end)-1 ; numel(idx.roipix)];
for kRoi = 1:numel(r1)
  idx.roimap(r1(kRoi):r2(kRoi),1) = kRoi;
end

function X = constructRoiPropsWithIndexMaps(roi)
% CONSTRUCT UNIFORM DATASET PULLING VALUES FROM EACH ROI IN THE SET
nRois = numel(roi);
X = [];
X.eccentricity = cat(1,roi.Eccentricity);
X.area = cat(1,roi.Area);
X.centroids = cat(1,roi.Centroid);
X.frames = cat(1,roi.Frames);
X.xlim = cat(1,roi.XLim);
X.ylim = cat(1,roi.YLim);
X.idx = cat(1,roi.Idx);
X.nIdx = zeros(nRois,1);
for kRoi = 1:nRois
  X.nIdx(kRoi) = numel(roi(kRoi).PixelIdxList);  
end
% CONSTRUCT INDEX VECTORS THAT MAP PIXEL INDICES TO ROIs (FROM GROUPING VARIABLES)
X.setidx.roipix = cat(1,roi.PixelIdxList);
roiFirstIdxIdx = [1 ; cumsum(X.area)+1];
r1 = roiFirstIdxIdx;
r2 = [ r1(2:end)-1 ; numel(X.setidx.roipix)];
for kRoi = 1:numel(r1)
  X.setidx.roimap(r1(kRoi):r2(kRoi),1) = kRoi;
end

function roiGroup = batchReduceRegion(roi,X)
% REDUCE NUMBER OF ROIs BY COMBINING ROIS ACROSS TIME
frameSize = roi(end).FrameSize;
ovlpMinN = 75;
similarMinN = 25;% TODO: make necessary inputs
nRois = numel(roi);
ovlproi.idx = cell(nRois,1);
ovlproi.n = NaN(nRois,1);
allSimRoi = [];
roiGroup = RegionOfInterest.empty(0,1);
tic
for kRoi=1:numel(roi)
  % (alternatively, pick rois from distributed regions in parallel)
  %
  %     thisRoi = roi(kRoi);
  %     thisCentroid = round(thisRoi.Centroid);
  if ~ismember(kRoi, allSimRoi)
    thisCentroid = round(X.centroids(kRoi,:));
    thisIdx = sub2ind(frameSize, thisCentroid(2), thisCentroid(1));
    
    
    
    ovlpRoiIdx = X.setidx.roimap(X.setidx.roipix == thisIdx); % SLOWWWWWWWWWWWWW
    ovlpRoiN = numel(ovlpRoiIdx);
    if ovlpRoiN >= ovlpMinN;
      ovlpRoi = roi(ovlpRoiIdx);
      simRoi = mostSimilar(ovlpRoi);
      if numel(simRoi) >= similarMinN
        allSimRoi = cat(1, allSimRoi, cat(1,simRoi.Idx));
        newRoiGroup = merge(simRoi);
        roiGroup = cat(1, roiGroup, newRoiGroup);
        fprintf('New ROI group with %i sub-regions\n',numel(simRoi))
      end
    end
    ovlproi.n(kRoi) = ovlpRoiN;
    ovlproi.idx{kRoi} = ovlpRoiIdx;
  end
end
toc


%%

%   k = 6010;
%   obj = roi(ovlproi.idx{k});
%   isSim = sufficientlySimilar(obj);
%   [~,idx] = max(sum(isSim));
%   simGroup = obj(isSim(idx,:));
%   show(simGroup)

% r = roi(1:1000);
% X = [cat(1,r.Centroid), cat(1,r.XLim), cat(1,r.YLim), cat(1,r.Area), cat(1,r.Perimeter)];


% allidx = cat(1,roi.PixelIdxList);
% im = zeros(roi(1).FrameSize)
% [idxfreq,idx] = fast_frequency(allidx);
% im(idx) = idxfreq;
% imagesc(imregionalmax(bwdist(imcomplement(imregionalmax(imimposemin(im,im<20))))))
% imagesc(imcomplement(imimposemin(imcomplement(imimposemin(im,im<10)), im>40)))








% function part = partitionByLocation(part)
% % USE R*-TREE, KD-TREE, OR OTHER SEGEMENTATION ALGORITHM TO PARTITION FRAME
% cp = part.current;
% for kPart = 1:numel(cp)
%   roi = cp{kPart};
%   X = constructRoiIndexMaps(roi);
%   
%   
% %   imws = getWaterShed(roi);
% %   imws = imws + 1;
% %   % imfill
% %   % imreconstruct
% %   % imdilate
% %   % allRois = roi;
% %   % xlim = cat(1,roi.XLim);
% %   % ylim = cat(1,roi.YLim);
% % %   ws = watershed(imimposemin(imcomplement(imimposemin(m, m<1)), m>50));
% %   
% %   rCent = round(cat(1,roi.Centroid));
% %   
% %   rInd = sub2ind(frameSize, rCent(:,2), rCent(:,1));
% %   nBatches = max(imws(:));
% %   rBatchIdx = imws(rInd);
% %   for kBatch = 1:nBatches
% %     roiBatchGroup{kBatch} = roi(rBatchIdx == kBatch);
% %     roiBatN(kBatch) = numel(roiBatchGroup{kBatch});
% %   end
% % %   gscatter
% end



        %         [foMaxByCol, maxRowIdxByCol] = max(foAll,[],1);
        %         [foMax, maxColIdx] = max(foMaxByCol);
        %         maxRowIdx = maxRowIdxByCol(maxColIdx);
        %         foAll(maxRowIdx,:)
          %         ovlp = isInBoundingBox(roiL);
          %         [~,seedIdx] = max(sum(ovlp,2));%[foMax,foMaxIdx] = max(sum(foAll,1))
                