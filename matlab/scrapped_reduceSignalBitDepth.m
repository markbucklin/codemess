function out = reduceSignalBitDepth(signal, numBits)
	
	if nargin < 2
		numBits = 8;
	end
    [numFrames, numChannels] = size(signal);
	if numel(numBits)>1
		numBits = reshape(numBits,1,1,[]);
	end
	
	%% Get Range to Stretch To
	sigMax = max(signal,[],1);
	sigMin = min(signal,[],1);
	sigRange = sigMax - sigMin;
	outMax = 2.^(numBits) - 1;
	outMin = 0;
	
	%% Stretch Signal to Fit Range
	stretchSignal = ...
		bsxfun(@rdivide,...
		bsxfun(@minus,...
		double(signal), double(sigMin) ),...
		double(sigRange));
	
	
	switch ceil((numBits-1)/8)
		case 0
			intCastFcn = @logical
		case 1
			intCastFcn = @uint8;
		case 2
			
		otherwise
			
	end		
	
	
    %% Binary pattern distribution and Network entropy
    traceOutBin = (traceOut >= thresh);
    traceOutValid = uint8(traceOut - thresh)+thresh;
    
    Psingle = nnz(traceOutBin) / numel(traceOutBin);
    hasActivity = any(traceOutBin, 2);
    Pgroup = nnz(hasActivity) / numFrames;
    allObservedActivitySamples = traceOutBin(hasActivity,:);
    [observedPatterns, firstFrameIdx, patternIdx] = unique(...
        allObservedActivitySamples,'rows');
    
    subplot(2,1,1), spy(observedPatterns')
    patternProbability = histcounts(int32(patternIdx),...
        'Normalization', 'probability', 'BinMethod', 'integers');
    subplot(2,1,2), bar(patternProbability)
    pause(1)
    
    idvEntropy = zeros(1,size(patternProbability,2));
    for i = 1:size(patternProbability,2);
        idvEntropy(i) = patternProbability(i).*log2(patternProbability(i));
    end
    NetworkEntropy(count) = -sum(idvEntropy(1,:));

    %% Individual cell firing probability
    fcn = binaryStatisticFunctions();
    BlueFiringProb(count,:) = feval(fcn.P_X, traceOutBlue >= thresh);
    
    %% Save binary and 8-bit data from each ROI
    B = traceOutBin;
    
%     out.packed = bwpack(B(:,k));
%         Valid{k} = traceOutValid(:,k);
    end
    