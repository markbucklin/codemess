classdef (CaseInsensitiveProperties, TruncatedProperties) ...
		TaskData ...
		< ignition.core.tasks.TaskIO




	% TASK I/O
	properties (SetAccess = immutable)
		PropertyList ignition.core.TaskProperty
		PropertyMap containers.Map
	end



	methods
		function obj = TaskData( taskUpdate, taskSrc, names, vals)

			obj = obj@ignition.core.tasks.TaskIO( taskUpdate );
			% todo -> create mutual listener task that updates Data

			assert(iscellstr(names))
			if nargin < 3
				vals = cell(1,numel(names));
			end

			propMap = containers.Map;

			k = 0;
			while k < numel(names)
				k = k + 1;
				name = names{k};
				val = vals{k};
				propLink = ignition.core.TaskProperty( taskUpdate, taskSrc, name, val);

				% ADD TO ARRAY OF TASK-PROPERTY OBJECTS
				obj.PropertyList(k) = propLink;

				% ADD TO HASH-MAP
				if ~isKey(propMap, name)
					propMap(name) = propLink;
				else
					propMap(name) = [propMap(name) ; propLink];
				end

			end
			obj.PropertyMap = propMap;

			% INITIALIZE DATA
			obj.Data = cell2struct( vals(:), names(:));

		end
	end


	methods (Static)
		function taskDataObj = buildFromPropTag( propSrc, tag, updateTask)

			controlStruct = getStructFromPropGroup(propSrc, tag);
			fprintf('Building TaskData object using property tag: <strong>%s</strong>\n',tag)
			names = fields(controlStruct);
			vals = struct2cell(controlStruct);
			fprintf('\t%s\n',names{:});
			taskDataObj = ignition.core.TaskData( updateTask, propSrc, names, vals );

		end
	end









end
