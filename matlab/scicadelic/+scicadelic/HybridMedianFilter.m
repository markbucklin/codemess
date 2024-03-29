classdef (CaseInsensitiveProperties = true) HybridMedianFilter < scicadelic.SciCaDelicSystem
	% HybridMedianFilter
	% Set ForceUseCustomHybridFcn to true to use 3D capable function that avoids edge-artifact
	
	
	
	
	
	% USER SETTINGS
	properties (Nontunable)		
		FilterSize = 3
	end
	properties (Nontunable, Logical)		
	end
	
	% STATES
	properties (DiscreteState)
	end
	properties (SetAccess = protected, Logical)
	end
	
	% PRIVATE VARIABLES
	properties (SetAccess = protected, Hidden, Nontunable)		
		pFilterSize
		MedianFilterFcn		
	end
	
	
	
	
	
	
	
	
	% CONSTRUCTOR
	methods
		function obj = HybridMedianFilter(varargin)
			setProperties(obj,nargin,varargin{:});
			obj.CanUseInteractive = true;
		end		
	end
	
	% BASIC INTERNAL SYSTEM METHODS	
	methods (Access = protected)
		function setupImpl(obj, F)			
			
			% INITIALIZE
			fillDefaults(obj)
			checkInput(obj, F);
			obj.TuningImageDataSet = [];
			setPrivateProps(obj)
			if ~isempty(obj.GpuRetrievedProps)
				pushGpuPropsBack(obj)
			end
			
			if obj.UseGpu
				% GPU -> HYBRID MEDIAN FILTER (currently only filter size is 3)				
				filterSize = 3;
				obj.MedianFilterFcn = @applyHybridMedianFilter;
				
				
			else
				% CPU -> BUILTIN MEDFILT2
				filterSize = obj.FilterSize;
				if (numel(filterSize) == 1)
					filterSize = [filterSize filterSize];
				else
					filterSize = filterSize(1:2);
				end
				obj.MedianFilterFcn = @applyMatlabMedianFilter;
			end
			
			% UPDATE FILTER SIZE
			obj.FilterSize = filterSize;
			setPrivateProps(obj);
			
		end		
		function F = stepImpl(obj,F)
			
			try
				F = obj.MedianFilterFcn(obj, F);
			catch
				if obj.pUseGpu
					F = hybridMedianFilterRunGpuKernel(F);
				else
					F = applyMatlabMedianFilter(obj, F);
				end
			end
			
			% 			F = feval(obj.MedianFilterFcn, F);
			% 			F = applyMedianFilter(obj, F);
			
		end
		function resetImpl(obj)
			dStates = obj.getDiscreteState;
			fn = fields(dStates);
			for m = 1:numel(fn)
				dStates.(fn{m}) = 0;
			end
		end
		function releaseImpl(obj)
			fetchPropsFromGpu(obj)
		end
	end
	
	% RUN-TIME HELPER FUNCTIONS
	methods (Access = protected, Hidden)
		function F = applyMatlabMedianFilter(obj, F, filterSize)
			% WILL CALL BUILT-IN MATLAB FUNCTION -> MEDFILT2 (FOR GPU OR CPU)
			
			if nargin < 3
				filterSize = obj.pFilterSize;
			end
			if isscalar(filterSize)
				filterSize = [filterSize filterSize];
			end
			[numRows, numCols, numFrames] = size(F);
			
			% RESHAPE TO 2D MATRIX, APPLY, THEN FOLD BACK (SOME EDGE ARTIFACTS)
			F = reshape( ...
				medfilt2( ...
				reshape( F, [numRows, numCols*numFrames]), ...
				filterSize), ...
				[numRows, numCols, numFrames]);
			
			% TODO: PAD SYMMETRIC IF ON GPU, OTHERWISE SPECIFY SYMMETRIC PADDING (NOT ZEROS)
			
		end
		function F = applyHybridMedianFilter(obj, F)
			% Runs a small external (normal matlab) function that constructs/calls a custom element-wise kernel
			
			% CALL ELEMENT-WISE MATLAB FUNCTION THAT RUNS ON GPU
			F = hybridMedianFilterRunGpuKernel(F);
			
		end
	end
	
% TUNING
methods (Hidden)
		function tuneInteractive(obj)			
			
			
			% STEP 1: MEDIAN FILTER
			k = 1;
			obj.TuningStep(k).ParameterName = 'FilterSize';
			x = obj.FilterSize;			
			obj.TuningStep(k).ParameterDomain = 3:2:15;
			obj.TuningStep(k).ParameterIdx = 1;
			obj.TuningStep(k).Function = @applyMatlabMedianFilter;
			obj.TuningStep(k).CompleteStep = true;
			
			% SET UP TUNING WINDOW
			createTuningFigure(obj);			%TODO: can also use for automated tuning?
			
		end			
		function tuneAutomated(obj)
			constructDomainTransferFunctions(obj)			
			constructLocalLowPassFilter(obj)
			tuneScalarBaseline(obj, obj.TuningImageDataSet);
			lockLimits(obj)
			obj.TuningImageDataSet = [];
		end		
end

% INITIALIZATION HELPER METHODS
	methods (Access = protected, Hidden)
		function setPrivateProps(obj)
			oMeta = metaclass(obj);
			oProps = oMeta.PropertyList(:);
			for k=1:numel(oProps)
				prop = oProps(k);
				if prop.Name(1) == 'p'
					pname = prop.Name(2:end);
					try
						pval = obj.(pname);
						obj.(prop.Name) = pval;
					catch me
						getReport(me)
					end
				end
			end
		end		
		function fetchPropsFromGpu(obj)
			oMeta = metaclass(obj);
			oProps = oMeta.PropertyList(:);
			propSettable = ~[oProps.Dependent] & ~[oProps.Constant];			
			for k=1:length(propSettable)
				if propSettable(k)
					pn = oProps(k).Name;
					try
						if isa(obj.(pn), 'gpuArray') && existsOnGPU(obj.(pn))
							obj.(pn) = gather(obj.(pn));
							obj.GpuRetrievedProps.(pn) = obj.(pn);			
						end
					catch me
						getReport(me)
					end
				end
			end
		end
		function pushGpuPropsBack(obj)
			fn = fields(obj.GpuRetrievedProps);
			for kf = 1:numel(fn)
				pn = fn{kf};
				if isprop(obj, pn)
					if obj.UseGpu
						obj.(pn) = gpuArray(obj.GpuRetrievedProps.(pn));
					else
						obj.(pn) = obj.GpuRetrievedProps.(pn);
					end
				end
			end
		end
	end	
	
	
	
	
	
	
end





















