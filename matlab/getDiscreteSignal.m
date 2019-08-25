function B = getDiscreteSignal(X, numBins)

%%
if nargin < 2
	numBins = 2.^(1:8);
end

%%
for kBin = 1:numel(numBins)
	% Discretize Input Multi-Channel Signals
	M = numBins(kBin);
	[xDiscrete, xEdge] = discretize(X,M);
	Xm = uint8(xDiscrete);
	
	% Find all Unique Combinations of all Signal State
	[Xu,xmIdx,xuIdx] = unique(Xm,'rows');
	Sm = uint16(xuIdx);
	sCount = accumarray( Sm, 1, size(xmIdx), @sum);
	Ps = double(sCount) ./ sum(sCount(:));
	
	% Consider All Channels (pixel-values) Independently
	B(kBin).xm = xDiscrete;
	B(kBin).xleft = xEdge(1:end-1);
	B(kBin).xright = xEdge(2:end);
	
	% Consider All Channels (pixel-values) Jointly		
	B(kBin).Sm = Sm;
	B(kBin).stateset = Xu;
	B(kBin).numstates = size(Xu,1);
	B(kBin).P = Ps;
	B(kBin).H = entropy(Sm);
end


% %%
% [numFrames, numChannels] = size(X);
% binMethod = {'auto','scott','fd','sturges','sqrt'};
% for k=1:numel(binMethod)
% 	name = binMethod{k};
% 	for kpx = numChannels:-1:1
% 		
% 		
% 		
% 		[p,edges,bin] = histcounts(X(:,kpx),numBins,...
% 			'Normalization', 'probability',...
% 			'BinMethod',name);
% 		hc(kpx).p = p;
% 		hc(kpx).edges = edges;
% 		hc(kpx).bin = bin;
% 	end
% 	B.(name) = hc;
% end
