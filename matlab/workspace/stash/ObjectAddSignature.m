function Data = ObjectAddSignature(Data,Signature)
%  Helps to keep track of what kind of processing was performed on the Data.
%
% Receives:
%   Data                -   struct          -   Structure initially created with Object create
%   Signature   -     string         -   (optional)  The name of the function wich processes the Data. Default: eval('caller','mfilename')
%                               cell array of strings   -   list of signatures
% Returns:
%   Data                -   struct          -   Structure initially created with Object create%
%
% See Also:
%   CreateObject
%
%
% Example:
%   
%   
%   
%

narginchk(1,2);
nargoutchk(0,1);

if ~exist('Signature','var')
    Signature = evalin('caller','mfilename');
end
if ~isfield(Data,'Signature')
    Data.Signature = {};
end   
if ischar(Signature)
    Data.Signature{end+1} = Signature;
elseif iscell(Signature)
    Data.Signature = [Data.Signature Signature];
end
    