classdef (CaseInsensitiveProperties, TruncatedProperties) ...
		FileStream < ignition.dataflow.DataflowBlock
	
	
	
	% CONFIGURATION
	properties
		FileInputObj @ignition.io.FileWrapper
		ParseFrameInfoFcn @function_handle
	end
	
	% CONTROL
	properties
		FirstFrameIdx
		NextFrameIdx
		LastFrameIdx
		NumFramesPerRead		
	end
	
	% STATE
	properties (SetAccess = ?ignition.core.Task)
		CurrentFrameIdx
		StreamFinishedFlag(1,1) logical = false
	end
	
	
	
	
	methods
		function obj = FileStream(varargin)
			
			if nargin
				parseConstructorInput(obj, varargin{:});
			end
			
			
			
		end
	end
	
	
	
	
	
	
	
	
	
	
	
	
	
	
end




