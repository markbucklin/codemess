
% savedChunk = {}; 
% savedOut = struct.empty();
chunkNum = 0;
hStop = msgbox('press to stop','non-modal');

while true
    [out.intensity,out.info,out.mstat,out.frgb,out.srgb] = nextFcn();
    if isempty(out.info.idx) || ~isvalid(hStop)
        break
    end
    chunkNum = chunkNum + 1;
    savedOut(chunkNum) = gatherOrRecurse(out);
%     savedChunk{end+1} = structfun( @gather, out.srgb, 'UniformOutput', false);  
end


function val = gatherOrRecurse(s)
if isstruct(s)
    val = structfun( @gatherOrRecurse, s, 'UniformOutput', false);
else
    val = gather(s);
end

end