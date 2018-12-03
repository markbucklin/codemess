function bw = applySpatialLut(bw, slut)
[nrow,ncol,nk] = size(bw);
bw2d = reshape( bw, nrow,[],1);
if islogical(slut) || isnumeric(slut)
	bw2d = bwlookup(bw2d, slut);
elseif iscell(slut)
	for kl = 1:numel(slut)
		bw2d = bwlookup(bw2d, slut{kl});
	end
end
bw = reshape( bw2d, nrow,ncol,nk); %addchannels

end