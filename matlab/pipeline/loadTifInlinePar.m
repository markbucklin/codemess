
function [data, varargout] = loadTifInline(varargin)

% PROCESS ARGUMENTS (fileName) OR ASK TO PICK FILE
if nargin
  fname = varargin{1};
  switch class(fname)
	 case 'char'
		fileName = cellstr(fname);
	 case 'cell'
		for n = 1:numel(fname)
		  fileName{n} = which(fname{n});
		end
  end
else
  [fname,fdir] = uigetfile('*.tif','MultiSelect','on');
  switch class(fname)
	 case 'char'
		fileName{1} = [fdir,fname];
	 case 'cell'
		for n = 1:numel(fname)
		  fileName{n} = [fdir,fname{n}];
		end
  end
end

% GET INFO FROM EACH TIF FILE
nFiles = numel(fileName);
tifFile = struct(...
  'fileName',fileName(:),...
  'tiffTags',repmat({struct.empty(0,1)},nFiles,1),...
  'nFrames',repmat({0},nFiles,1),...
  'frameSize',repmat({[1024 1024]},nFiles,1));
parfor n = 1:numel(fileName)
  tifFile(n).fileName = fileName{n};
  tifFile(n).tiffTags = imfinfo(fileName{n});
  tifFile(n).nFrames = numel(tifFile(n).tiffTags);
  tifFile(n).frameSize = [tifFile(n).tiffTags(1).Height tifFile(n).tiffTags(1).Width];
end
nTotalFrames = sum([tifFile(:).nFrames]);
fileFrameIdx.last = cumsum([tifFile(:).nFrames]);
fileFrameIdx.first = [0 fileFrameIdx.last(1:end-1)]+1;
[tifFile.firstIdx] = deal(fileFrameIdx.first);
[tifFile.lastIdx] = deal(fileFrameIdx.last);

% PREINSTANTIATE STRUCTURE ARRAY FOR IMAGE DATA
blankFrame = zeros(tifFile(1).frameSize, 'uint16');
% data = repmat(blankFrame, [1 1 nTotalFrames]);

info = struct(...
  'frame',repmat({0},nTotalFrames,1),...
  'subframe',repmat({0},nTotalFrames,1),...
  'tiffTag',repmat({tifFile(1).tiffTags(1)},nTotalFrames,1),...
  't',NaN,...
  'timestamp',struct('hours',NaN,'minutes',NaN,'seconds',NaN));

% FILL INFO STRUCTURE
for n=1:numel(tifFile)
  firstFrame = fileFrameIdx.first(n);
  lastFrame = fileFrameIdx.last(n);
  tifInfo = tifFile(n).tiffTags;
  subk = 1;
  for k = firstFrame:lastFrame
	 info(k).frame = k;
	 info(k).subframe = subk;
	 info(k).tiffTag = tifInfo(subk);
	 info(k).timestamp = getHcTimeStamp(info(k).tiffTag);
	 info(k).t = info(k).timestamp.seconds;
	 subk = subk + 1;
  end
end
allData = cell(numel(tifFile),1);

%SHOW WAITBAR
[fp,~] = fileparts(tifFile(1).fileName);
[~,fp] = fileparts(fp);
fprintf('Loading %s from %i files (%i frames)\n', fp, nFiles, nTotalFrames);
% wbString = sprintf('Loading %s from %i files (%i frames)', fp, nFiles, nTotalFrames);
% multiWaitBar(wbString,0)

% INLINE TIF LOAD
parfor n = 1:numel(tifFile)
  warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning')
  warning off MATLAB:tifflib:TIFFReadDirectory:libraryWarning
  tiffFileName = tifFile(n).fileName;
  InfoImage = tifFile(n).tiffTags;
  
  %   tifObj = Tiff(tiffFileName,'r');
  firstFrame = fileFrameIdx.first(n);
  lastFrame = fileFrameIdx.last(n);
  nSubFrames = tifFile(n).nFrames;
  tifData = repmat(blankFrame, [1 1 nSubFrames]);
  fprintf('Loading frames %g to %g from %s\n',firstFrame,lastFrame,tifFile(n).fileName);
  
  mImage = InfoImage(1).Width;
  nImage = InfoImage(1).Height;
  FileID = tifflib('open',tiffFileName,'r');
  rps = tifflib('getField',FileID,Tiff.TagID.RowsPerStrip);
  
  for ksf = 1:nSubFrames
% 	 multiWaitBar(wbString, 'Increment', 1/nTotalFrames);
	 tifflib('setDirectory',FileID,ksf - 1);
	 % 	 kFrame = fileFrameIdx.first(n) + ksf - 1;
	 % Go through each strip of data.
	 rps = min(rps,nImage);
	 for r = 1:rps:nImage
		try
		  row_inds = r:min(nImage,r+rps-1);
		  stripNum = tifflib('computeStrip', FileID, r) - 1;
		  tifData(row_inds,:,ksf) = tifflib('readEncodedStrip',FileID,stripNum);
		catch me
		  showError(me)		  
		end
	 end
  end
  tifflib('close',FileID);
  allData{n} = tifData;
end
data = cat(3, allData{:});

% multiWaitBar(wbString, 'Close')
if nargout > 1
  varargout{1} = info;
  if nargout > 2
	 varargout{2} = tifFile;
  end
end
end











