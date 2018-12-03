function lickdata = importLickDataDevalue(filename)

% FIND FILE
if nargin < 1
   d = dir('*lick*');
   if ~isempty(d)
	  filename = d(1).name;
   else
	  [fname, fdir] = uigetfile(...
		  {'*.*','All Files (*.*)'},...
		  'Please select a LICK file');
	  filename = fullfile(fdir,fname);
   end
end

% Initialize variables.
delimiter = '\t';
   startRow = 1;
   endRow = inf;

% Format string for each line of text:
%   column1: double (%f)
%	column3: double (%f)
%   column4: double (%f)
%	column5: double (%f)
%   column6: double (%f)
%	column8: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%*s%f%f%f%f%*s%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this code. If an error occurs for a different
% file, try regenerating the code from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
   frewind(fileID);
   dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
   for col=1:length(dataArray)
	  dataArray{col} = [dataArray{col};dataArrayBlock{col}];
   end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post processing code is included. To generate
% code which works for unimportable data, select unimportable cells in a file and regenerate the script.

%% Create output variable
lickdata = table(dataArray{1:end-1}, 'VariableNames', {'tlick','trialnumber','duringsound','duringwindow','duringiti','stim'});

