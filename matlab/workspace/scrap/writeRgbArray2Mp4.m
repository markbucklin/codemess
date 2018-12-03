function writeRgbArray2Mp4(rgbArray,varargin)
warning('writeRgbArray2Mp4.m being called from scrap directory: Z:\Files\MATLAB\toolbox\ignition\scrap')

fps = 20;

% N = numel(vid)
% rgbArray(:,:,1,:) = uint8( cat(4, bwvid.bwRisingEdge));
% rgbArray(:,:,3,:) = uint8( cat(4, bwvid.bwFallingEdge));
% rgbArray = rgbArray*180;
% rgbArray(:,:,2,:) = cat(4, vid(:).cdata);


if nargin > 1
   filename = varargin{1};
else
   [filename, filedir] = uiputfile('*.mp4');
   filename = fullfile(filedir,filename);
end
profile = 'MPEG-4';
writerObj = VideoWriter(filename,profile);
writerObj.FrameRate = fps;
writerObj.Quality = 80;
open(writerObj)
writeVideo(writerObj, rgbArray)
close(writerObj)
