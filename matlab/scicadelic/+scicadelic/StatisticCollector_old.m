classdef (CaseInsensitiveProperties = true) StatisticCollector < scicadelic.SciCaDelicSystem
	%
	%			Calculates pixel statistics over time. Skewness and Kurtosis  are "Fisher's
	%			Skewness/Kurtosis" methods
	%
	%			Skewness: assymetry of deviations from the sample mean Kurtosis: "how flat the top of a
	%			symmetric distribution is when compared to a normal distribution with same variance
	%
	% REFERENCES:
	%			Timothy B. Terriberry. Computing Higher-Order Moments Online.
	%			http://www.johndcook.com/blog/skewness_kurtosis/ Philippe P�bay. SANDIA REPORT SAND2008-6212
	%			(2008). Formulas for Robust, One-Pass Parallel Computation of Co- variances and
	%			Arbitrary-Order Statistical Moments.
	%
	
	% ##################################################
	% SETTINGS
	% ##################################################
	properties (Nontunable)
		Precision = 'single'
		Mask
	end
	% OUTPUT SETTINGS
	properties (Nontunable, Logical)
		StatisticOutputPort = false
		CentralMomentOutputPort = false
		DifferentialMomentOutputPort = false
	end
	
	% ##################################################
	% STATISTICS (DEPENDENT ON CENTRAL MOMENTS)
	% ##################################################
	properties (Dependent = true)
		Mean
		StandardDeviation
		Variance
		Skewness
		Kurtosis
		JarqueBera
	end
	% STATISTICS (OTHER)
	properties (SetAccess = protected)
		Min
		Max
		N = 0
	end
	% CENTRAL MOMENTS
	properties (Access = protected, Hidden)
		M0
		M1
		M2
		M3
		M4
	end
	
	% ##################################################
	% PRIVATE
	% ##################################################
	properties (Nontunable, Access = protected, Hidden)
		PrecisionSet = matlab.system.StringSet({'single','double'})
		pPrecision
	end
	
	
	
	
	% ##################################################
	% CONSTRUCTOR
	% ##################################################
	methods
		function obj = StatisticCollector(varargin)
			setProperties(obj,nargin,varargin{:});
			parseConstructorInput(obj,varargin(:));
		end
	end
	
	% ##################################################
	% DEPENDENT STATISTIC GET FUNCTIONS
	% ##################################################
	methods
		function X = get.Mean(obj)
			X = obj.M1;
		end
		function X = get.StandardDeviation(obj)
			if ~isempty(obj.M2) && (obj.N > 1)
				X = sqrt(obj.M2 ./ (obj.N - 1));
			else
				X = obj.M0;
			end
		end
		function X = get.Variance(obj)
			if ~isempty(obj.M2) && (obj.N > 1)
				X = obj.M2 ./ (obj.N - 1);
			else
				X = obj.M0;
			end
		end
		function X = get.Skewness(obj)
			if ~isempty(obj.M2) && (obj.N > 1)
				X = sqrt(obj.N) .* obj.M3 ./ (obj.M2 .^(3/2));
			else
				X = obj.M0;
			end
		end
		function X = get.Kurtosis(obj)
			if ~isempty(obj.M2) && (obj.N > 1)
				X = obj.N .* obj.M4 ./ (obj.M2.^2) - 3;
			else
				X = obj.M0;
			end
		end
		function X = get.JarqueBera(obj)
			if ~isempty(obj.M2) && (obj.N > 1)
				X  = obj.N/6 * (obj.Skewness.^2 + 1/4 *(obj.Kurtosis - 3).^2);
			else
				X = obj.M0;
			end
		end
	end
	
	% ##################################################
	% BASIC INTERNAL SYSTEM METHODS
	% ##################################################
	methods (Access = protected)
		% ============================================================
		% SETUP
		% ============================================================
		function setupImpl(obj, F)
			checkInput(obj, F);
			setPrivateProps(obj)
			sz = size(F);
			fs = sz(1:2);
			fpType = obj.pPrecision;
			obj.FrameSize = fs;
			if isa(F, 'gpuArray')
				obj.InputDataType = classUnderlying(F);
				m0 = gpuArray.zeros(fs,fpType);
			else
				obj.InputDataType = class(F);
				m0 = zeros(fs,fpType);
			end
			obj.OutputDataType = fpType;
			
			% MAX & MIN
			obj.Min = min(F, [], 3);
			obj.Max = max(F, [], 3);
			
			% CENTRAL MOMENTS;
			obj.M0 = 0;
			obj.M1 = m0;
			obj.M2 = m0;
			obj.M3 = m0;
			obj.M4 = m0;
			
			if ~isempty(obj.GpuRetrievedProps)
				pushGpuPropsBack(obj)
			end
		end
		
		% ============================================================
		% STEP
		% ============================================================
		function varargout = stepImpl(obj, F)
			
			% LOCAL VARIABLES
			fpType = obj.pPrecision;
			na = obj.N;
			nb = size(F,3);
			n = na + nb;
			
			if nb>=1
				
				% MAX & MIN
				obj.Min = min(min(F, [],3), obj.Min);
				obj.Max = max(max(F, [],3), obj.Max);
				
				% CENTRAL MOMENTS
				if nb == 1 % Run faster implementation if only updating with 1 frame
					d = cast(F, fpType) - obj.M1;
					dk = d./n;
					dk2 = dk.^2;
					s = d.*dk.*(n-1);
					obj.M1 = obj.M1 + dk;
					m2 = obj.M2;
					m3 = obj.M3;
					obj.M4 = obj.M4 + s.*dk2.*(n^2-3*n+3) + 6*dk2.*m2 - 4.*dk.*m3;
					obj.M3 = m3 + s.*dk.*(n-2) - 3.*dk.*m2;
					obj.M2 = m2 + s;
					
				else	% Not optimized, but easier to follow
					m1a = obj.M1;
					m2a = obj.M2;
					m3a = obj.M3;
					m4a = obj.M4;
					
					m1b = cast(mean(F, 3, 'default'), fpType);
					m2b = moment(cast(F,fpType), 2, 3);
					m3b = moment(cast(F,fpType), 3, 3);
					m4b = moment(cast(F,fpType), 4, 3);
					
					d = bsxfun(@minus, m1b , m1a);
					obj.M1 = m1a  +  d.*(nb/n); % 				dk = d.*(Nb/N);
					obj.M2 = m2a  +  m2b  +  (d.^2).*(na*nb/n); % dk2 = (d.^2).*Na.*Nb./N
					obj.M3 = m3a  +  m3b  +  (d.^3).*(na*nb*(na-nb)/(n^2))  ...
						+  3*(na.*m2b - nb.*m2a).*d./n;
					obj.M4 = m4a  +  m4b  +  (d.^4).*((na*nb*(na-nb)^2)/(n^3))  ...
						+  6*(m2b.*na^2 + m2a.*nb.^2).*((d.^2)./(n^2))  ...
						+  4*(m3b.*na  -  m3a.*nb).*(d./n);
				end
				obj.N = n;
			end
			
			% STATISTIC OUTPUT
			if obj.StatisticOutputPort % TODO: inline statistic calculation from central moments
				statStructure = struct(...
					'Min', obj.Min,...
					'Max', obj.Max,...
					'Mean', obj.Mean,...
					'StandardDeviation', obj.StandardDeviation,...
					'Skewness', obj.Skewness,...
					'Kurtosis', obj.Kurtosis);
			else
				statStructure = [];
			end
			
			% CENTRAL MOMENT OUTPUT
			if obj.CentralMomentOutputPort || obj.DifferentialMomentOutputPort
				centralMomentStructure = struct(...
					'N', n,...
					'M1', obj.M1,...
					'M2', obj.M2,...
					'M3', obj.M3,...
					'M4', obj.M4);
			else
				centralMomentStructure = [];
			end
			
			% DIFFERENTIAL MOMENT OUTPUT (RUN EXTERNAL GPU KERNEL)
			if obj.DifferentialMomentOutputPort
				differentialMomentStructure = differentialMomentGeneratorRunGpuKernel(F, centralMomentStructure);
			else
				differentialMomentStructure = [];
			end
			
			
			% ASSIGN OUTPUT
			if nargout
				availableOutput = {...
					statStructure,...
					centralMomentStructure,...
					differentialMomentStructure};
				specifiedOutput = [...
					obj.StatisticOutputPort,...
					obj.CentralMomentOutputPort,...
					obj.DifferentialMomentOutputPort];
				outputArgs = availableOutput(specifiedOutput);
				varargout = outputArgs(1:nargout);
			end
			
		end
		function numOutputs = getNumOutputsImpl(obj)
			numOutputs = nnz([...
				obj.StatisticOutputPort,...
				obj.CentralMomentOutputPort,...
				obj.DifferentialMomentOutputPort]);
		end
		function resetImpl(obj)
			setPrivateProps(obj)
			sz = size(obj.M1);
			m0 = onGpu(obj, zeros(sz, obj.pPrecision));
			obj.M1 = m0;
			obj.M2 = m0;
			obj.M3 = m0;
			obj.M4 = m0;
			obj.N = 0;
		end
		function releaseImpl(obj)
			fetchPropsFromGpu(obj)
		end
	end
	
	% ##################################################
	% TUNING
	% ##################################################
	methods (Hidden)
		function tuneInteractive(~)
		end
		function tuneAutomated(~)
		end
	end
	
	% ##################################################
	% INITIALIZATION HELPER METHODS
	% ##################################################
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
	
	% ##################################################
	% OUTPUT DISPLAY
	% ##################################################
	methods (Access = public)
		function stat = getStatistics(obj, leaveOnGpu)
			if nargin < 2
				leaveOnGpu = false;
			end
			if leaveOnGpu || ~obj.UseGpu
				stat = struct(...
					'N', obj.N,...
					'Min', obj.Min,...
					'Max', obj.Max,...
					'Mean', obj.Mean,...
					'StandardDeviation', obj.StandardDeviation,...
					'Variance', obj.Variance,...
					'Skewness', obj.Skewness,...
					'Kurtosis', obj.Kurtosis,...
					'JarqueBera', obj.JarqueBera);
			else
				stat = struct(...
					'N', obj.N,...
					'Min', onCpu(obj, obj.Min),...
					'Max', onCpu(obj, obj.Max),...
					'Mean', onCpu(obj, obj.Mean),...
					'StandardDeviation', onCpu(obj, obj.StandardDeviation),...
					'Variance', onCpu(obj, obj.Variance),...
					'Skewness', onCpu(obj, obj.Skewness),...
					'Kurtosis', onCpu(obj, obj.Kurtosis),...
					'JarqueBera', onCpu(obj, obj.JarqueBera));
			end
		end
		function cmom = getCentralMoments(obj)
			
			cmom = struct(...
				'N', obj.N,...
				'M1', obj.M1,...
				'M2', obj.M2,...
				'M3', obj.M3,...
				'M4', obj.M4);
			
		end
		function show(obj)
			
			% REMAP STATS TO RANGE CONDUCIVE TO COMPARATIVE VISUALIZATION
			imMin = normalizeImage(obj.Min);
			imMax = normalizeImage(obj.Max);
			imMean = normalizeImage(obj.Mean);
			imStdev = normalizeImage(obj.StandardDeviation);
			imSkew = normalizeImage(sqrt(abs(obj.Skewness)).*sign(obj.Skewness)); % or log(abs(
			imKurt = normalizeImage(log(obj.Kurtosis+3));
			
			% IMAGE MONTAGE
			imStatCat = cat(2, ...
				cat(1, imMin, imMax), ...
				cat(1, imStdev , imMean), ...
				cat(1, imSkew, imKurt));
			h.im = imagesc(imStatCat);
			
			% TEXT
			[m,n] = size(imStatCat);
			y = m/50;
			dy = m/2;
			x = m/50;
			dx = n/3;
			h.tx(1) = text( x, y, 'Min');
			h.tx(2) = text( x, y+dy, 'Max');
			h.tx(3) = text( x+dx, y, 'Mean');
			h.tx(4) = text( x+dx, y+dy, 'StandardDeviation');
			h.tx(5) = text( x+2*dx, y, 'Skewness');
			h.tx(6) = text( x+2*dx, y+dy, 'Kurtosis');
			set(h.tx, 'FontSize',14)
			% 			'String', idxText,...
			% 				'FontWeight','normal',... 'BackgroundColor',[.1 .1 .1 .3],... 'Color',
			% 				otherColor,... 'FontSize',fontSize,... 'Margin',1,... 'Position',
			% 				infoTextPosition,... 'Parent', h.axCurrent));
			
			
			h.ax = handle(gca);
			h.ax.Position = [0 0 1 1];
			h.ax.DataAspectRatio = [1 1 1];
			axis off
			assignin('base','h',h)
			
			function im = normalizeImage(im)
				if isa(im, 'gpuArray')
					im = gather(im);
				end
				im = double(im);
				
				% 				im = imadjust( (im-min(im(:)))./range(im(:)), stretchlim(im, [.05 .995]));
				
				
				
				
				im = max( im, .5*(mean(min(im,[],1)) + mean(min(im,[],2),1)));
				im = min( im, .5*(mean(max(im,[],1)) + median(max(im,[],2),1)));
				im = imadjust( (im-min(im(:)))./range(im(:)), stretchlim(im, [.10 .9999]));
				im = mcclurenormfcn(im);
				
				function f = mcclurenormfcn(f)
					% Akin to Geman-McClure function
					f = bsxfun(@minus, f, min(min(f,[],1),[],2));
					f = bsxfun(@rdivide, f, max(max(f,[],1),[],2));
					a = .5*(mean(max(f,[],1),2) + mean(max(f,[],2),1));
					f = exp(1) * f.^2 ./ (1 + bsxfun(@rdivide, f.^2 , a.^2));
					
				end
				
			end
		end
	end
	
	
	
	
	
	
	
	
	
	
end