function [F, F0, A] = temporallyAdaptiveTemporalFilterRunGpuKernel(F, F0, A0, N0Max)
% temporalStabilityRunGpuKernel
%
%
% SEE ALSO:
%
%
% Mark Bucklin


% TODO: use subsequent frame xor


% ============================================================
% INFO ABOUT INPUT
% ============================================================
[numRows,numCols,numFrames,numChannels] = size(F);
rowSubs = int32(gpuArray.colon(1,numRows)');
colSubs = int32(gpuArray.colon(1,numCols));
frameSubs = int32(reshape(gpuArray.colon(1, numFrames), 1,1,numFrames));
chanSubs =  int32(reshape(gpuArray.colon(1, numChannels), 1,1,1,numChannels));

% INPUT -> BUFFERED OUTPUT FROM PREVIOUS CALL
if (nargin < 4)
	N0Max = [];
	if nargin < 3
		A0 = [];
		if nargin < 2
			F0 = [];			
		end
	end
end

% ON FIRST CALL RETURN F AS F0
if isempty(F0)	
	F0 = F;
	A = gpuArray.zeros(numRows,numCols, 'single');
	return
end

% FILTER ORDER & MAX TIME-CONSTANT
if isempty(A0)
	A0 = gpuArray.zeros(numRows, numCols, 1, numChannels, 'single');
end
if isempty(N0Max)
	N0Max = single(50);
end

% OTHER DEFAULT PARAMETERS (todo)
filterOrder = single(min(2, size(F0,3)));
edgeSuppressionDist = int32(1);
Fbase = single(mean(F0(:))); % Fbase = single(min(F0(:)));
N0md = single(numFrames);
A0md = single(exp(-1/N0md));



% ============================================================
% DETERMINE/UPDATE FILTER COEFFICIENT FOR EACH PIXEL
% ============================================================

% DETECT TEMPORAL ACTIVITY FOR EACH PIXEL & EACH FRAME
Ft = arrayfun(@logTemporalGradientKernel, F, rowSubs, colSubs, frameSubs, chanSubs);

% RESTRICT FILTERING TO EDGES (todo)
% Ft = arrayfun(@suppressNonEdgeKernel, rowSubs, colSubs, frameSubs, chanSubs); % TODO

% DETECT FRAME-WISE NON-SMOOTH CHANGES IN PIXEL TEMPORAL ACTIVITY (INDICATOR OF UNCORRECTED MOTION ARTIFACT)
% Ftmean = mean(mean(Ft));
% chunkThresh = mean(Ftmean) ./ 8;  % Ft = bsxfun(@minus, Ft, Ftmean);
% motionIndicator = pnz(bsxfun(@ge, Ft, chunkThresh));


A = Ft;

F0 = F;

% A = arrayfun(@normalizedSpatialGradientMagnitudeKernelFcn, max(F0,[],3), rowSubs, colSubs, chanSubs);

% F0 = single(mean(F,3));

% F0 = arrayfun(@movingFilterKernel, F0, rowSubs, colSubs, chanSubs);







% ##################################################
% STENCIL-OP SUB-FUNCTION -> RUNS ON GPU
% ##################################################

% ============================================================
% SPATIAL GRADIENT DETERMINES FILTER COEFFICIENT
% ============================================================
	function ft = logTemporalGradientKernel(f, rowIdx, colIdx, frameIdx, chanIdx)		
		a = A0md;
		
		% TEMPORALLY FILTER PREVIOUS BUFFERED FRAMES
		k = frameIdx;
		% 		f0 = single(F0(rowIdx,colIdx,k,chanIdx));
		fsum = single(F0(rowIdx,colIdx,k,chanIdx));
		while k < numFrames
			k = k + 1;
			% 			f0 = (1-a)*f0 + a*single(F0(rowIdx,colIdx,k,chanIdx));
			fsum = fsum + single(F0(rowIdx,colIdx,k,chanIdx));
		end
		
		% CONTINUE TEMPORALLY FILTERING USING PREVIOUS FRAMES
		k = 0;
		while k < frameIdx
			k = k + 1;
			% 			f0 = (1-a)*f0 + a*single(F(rowIdx,colIdx,k,chanIdx));
			fsum = fsum + single(F(rowIdx,colIdx,k,chanIdx));
		end
		
		% SUBTRACT TEMPORALLY FILTERED PREVIOUS FRAME SET AND TAKE LOG
		fk = single(f);
		f0 = fsum/single(numFrames);
		ft = -log2(abs(fk-f0)/max(Fbase,max(fk,f0)));
		% 		fnum = max( single(f), f0);
		% 		fden = min( single(f), f0);
		% 		ft = log2( min(2, fnum/fden));
		
	end
	function fmin = minFilterKernel(fmin0, rowIdx, colIdx, chanIdx)
		% Recursive  filter along third dimension (presumably time)
		k=1;
		fmin = F(rowIdx,colIdx,k,chanIdx);
		while k < numFrames
			k = k + 1;
			fmin = min( fmin, F(rowIdx,colIdx,k,chanIdx));
		end
		a = double(Aminmax);
		fmin = min( fmin, (1-a)*fmin + a*fmin0);
		
	end
	function fmax = maxFilterKernel(fmax0, rowIdx, colIdx, chanIdx)
		% Recursive  filter along third dimension (presumably time)
		k=1;
		fmax = F(rowIdx,colIdx,k,chanIdx);
		while k < numFrames
			k = k + 1;
			fmax = max( fmax, F(rowIdx,colIdx,k,chanIdx));
		end
		a = double(Aminmax);
		fmax = max( fmax, (1-a)*fmax + a*fmax0);
		
	end
	function ft = movingDiffMagnitudeKernelFcn(f, f0, frameIdx)
		nk = double(numFrames) + double(N0md) - double(frameIdx);
		a = exp(-1/nk);
		f0 = (1-a)*single(f) + a*f0;
		ft = abs(single(f)-f0);
	end
	function f0 = movingFilterKernel(f0, rowIdx, colIdx, chanIdx)
		% Recursive  filter along third dimension (presumably time)
		k=1;
		fsum = single(F(rowIdx,colIdx,k,chanIdx));
		while k < numFrames
			k = k + 1;
			fsum = fsum + single(F(rowIdx,colIdx,k,chanIdx));
		end
		fmean = fsum/k;
		nk = double(numFrames) + double(N0md);
		a = exp(-1/nk);		
		f0 = (1-a)*single(fmean) + a*f0;
		
	end
% 	function ft = extremeDiffMagnitudeKernelFcn(f, fmin, fmax)
% 		
% 		fmindiff = single(f) - single(fmin);
% 		fmaxdiff = single(fmax) - single(f);
% 		
% 		% 		ft = fmindiff + fmaxdiff;
% 		ft = max(fmindiff,fmaxdiff);
% 		
% 	end
% 	function yk = minmaxFilterKernel(xk, ykm1)
% 		% Recursive  filter along third dimension (presumably time)
% 		
% 		a = double(Aminmax);
% 		yk = (1-a)*xk + a*ykm1;
% 		
% 	end
% 	function ft = temporalGradientMagnitudeKernelFcn(rowIdx, colIdx, frameIdx, chanIdx)
%
% 		% 		if frameIdx > 1
% 		% 			fkm1 = single(F(rowIdx,colIdx,frameIdx-1,chanIdx));
% 		% 		else
% 		% 			fkm1 = single(Fmin(rowIdx,colIdx,int32(filterOrder),chanIdx));
% 		% 		end
%
% 		fk = single(F(rowIdx,colIdx,frameIdx,chanIdx));
%
% 		ft = (fk - fkm1).^2;
%
% 	end
	function ft = suppressNonEdgeKernel(rowIdx, colIdx, frameIdx, chanIdx)
		
		f0 = single(F0(rowIdx,colIdx,1,chanIdx)) + single(Fbase(1,1,1,chanIdx));
		ft = single(Ft(rowIdx,colIdx,frameIdx,chanIdx)) ./ f0;
		d = edgeSuppressionDist;
		
		% CALCULATE SUBSCRIPTS FOR SURROUNDING (NEIGHBOR) PIXELS
		rowU = int32(max( 1, rowIdx-d));
		rowD = int32(min( numRows, rowIdx+d));
		colL = int32(max( 1, colIdx-d));
		colR = int32(min( numCols, colIdx+d));
		
		% RETRIEVE NEIGHBOR PIXEL INTENSITY VALUES
		% 		fUL = single(Ft(rowU, colL, 1, chanC));
		% 		fUC = single(Ft(rowU, colC, 1, chanC));
		% 		fUR = single(Ft(rowU, colR, 1, chanC));
		% 		fCL = single(Ft(rowC, colL, 1, chanC));
		% 		fCR = single(Ft(rowC, colR, 1, chanC));
		% 		fDL = single(Ft(rowD, colL, 1, chanC));
		% 		fDC = single(Ft(rowD, colC, 1, chanC));
		% 		fDR = single(Ft(rowD, colR, 1, chanC));
		fU = single(Ft(rowU, colIdx, frameIdx, chanIdx));
		fL = single(Ft(rowIdx, colL, frameIdx, chanIdx));
		fR = single(Ft(rowIdx, colR, frameIdx, chanIdx));
		fD = single(Ft(rowD, colIdx, frameIdx, chanIdx));
		
		fud = min(fU,fD) ./ f0;
		flr = min(fL,fR) ./ f0;
		udNonEdge = fud > (ft/2);
		lrNonEdge = flr > (ft/2);
		nonEdgeSuppression = single(udNonEdge & lrNonEdge) * .95;
		
		ft = ft .* (1-nonEdgeSuppression);
		
		% 		ft = ft .* (1-udSuppression) .* (1-lrSuppression);
		
	end
% 		a0 = A0(rowC,colC,1,chanC);
%
% 		% CALCULATE SUBSCRIPTS FOR SURROUNDING (NEIGHBOR) PIXELS
% 		rowU = int32(max( 1, rowC-1));
% 		rowD = int32(min( numRows, rowC+1));
% 		colL = int32(max( 1, colC-1));
% 		colR = int32(min( numCols, colC+1));
%
% 		% RETRIEVE NEIGHBOR PIXEL INTENSITY VALUES
% 		fUL = single(F0(rowU, colL, 1, chanC));
% 		fUC = single(F0(rowU, colC, 1, chanC));
% 		fUR = single(F0(rowU, colR, 1, chanC));
% 		fCL = single(F0(rowC, colL, 1, chanC));
% 		fCR = single(F0(rowC, colR, 1, chanC));
% 		fDL = single(F0(rowD, colL, 1, chanC));
% 		fDC = single(F0(rowD, colC, 1, chanC));
% 		fDR = single(F0(rowD, colR, 1, chanC));
%
% 		% COMPUTE DIFFERENCE BETWEEN CURRENT PIXEL & NEIGHBORING SAMPLES
% 		df000 = fCR - fCL;
% 		df045 = fUR - fDL;
% 		df090 = fUC - fDC;
% 		df135 = fUL - fDR;
%
% 		% COMPUTE MEAN INTENSITY & GRADIENT
% 		fNeighSum = f + fUL + fUC + fUR + fCL + fCR + fDL + fDC + fDR;
% 		fNeighMean = single(1/9) * fNeighSum;
%
% 		meanSpatialDiff = single(1/4) * ( abs(df000) + abs(df045) + abs(df090) + abs(df135));
% 		% 		maxSpatialDiff = max(max(max(abs(df000),abs(df045)),abs(df090)),abs(df135));
% 		% 		minSpatialDiff = min(min(min(abs(df000),abs(df045)),abs(df090)),abs(df135));
%
% 		% 		d = meanSpatialDiff*(maxSpatialDiff - minSpatialDiff) / fNeighMean^2;
% 		d = min(1, meanSpatialDiff/fNeighMean); % max(0,f-fNeighMean)/fNeighMean;
% 		n0 = d*N0Max;
% 		a = max( exp(-filterOrder/n0), .5*a0);
%
% 	end

% ============================================================
% FIRST-ORDER ################################################
% ============================================================
	function [yk, ykm1] = arFilterKernel1(xk, ykm1, a32)
		% Recursive  filter along third dimension (presumably time)
		
		a = double(a32);
		yk = (1-a)*xk + a*ykm1;
		ykm1 = yk;
		
	end

% ============================================================
% SECOND-ORDER ###############################################
% ============================================================
	function [yk, ykm1, ykm2] = arFilterKernel2(xk, ykm1, ykm2, a32)
		% Recursive  filter along third dimension (presumably time)
		
		a = double(a32);
		yk = (1-a)^2*xk + 2*a*ykm1 - a^2*ykm2;
		ykm2 = ykm1;
		ykm1 = yk;
		
	end


end



