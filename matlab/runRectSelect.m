rs = simpleRectSelection();

rd(1).rect = rs.getRect();
rd(1).vid = rs.getVid();

selectedRect = findobj(rd.rect, 'Selected', 1)
bw = createMask(selectedRect(1), 1024, 1024);
for sr = selectedRect, disp(sr), end
bw = false(1024,1024); for n=1:numel(selectedRect)
bw = bw | createMask(selectedRect(n), 1024, 1024);
end



for n=1:numel(selectedRect), roi(n).mask = createMask(selectedRect(n), 1024,1024); end

for m = 1:numel(roi)
roi(m).frame(k).data = rd.vid.frame(k).Data(roi(m).mask);
end

for m=1:numel(roi)
    roi(m).vdata = reshape(cat(2,roi(m).frame.data), 64, 64, []); 
end
imscplay(cat(1, roi.vdata))