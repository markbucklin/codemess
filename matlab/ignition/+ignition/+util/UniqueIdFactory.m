%UniqueIdFactory
% A helper class that generates unique IDs using a combination of tempname
% and a local ID count.
%
% This will generate string IDs.

% Copyright 2015 The MathWorks, Inc.

classdef (Sealed) UniqueIdFactory < handle
    properties (SetAccess = immutable)
        % The name to attach to all generated IDs.
        Name;
    end
    
    properties (SetAccess = private)
        % The number of IDs generated by this object.
        NumIds = 0;
    end
    
    methods
        % The main constructor.
        function obj = UniqueIdFactory(name)
					
            [~, randomString] = fileparts(tempname);
            obj.Name = sprintf('%s_%s', name, randomString);
        end
        
        % Generate a new ID.
        function id = nextId(obj)
            obj.NumIds = obj.NumIds + 1;
            id = sprintf('%s_%i', obj.Name, obj.NumIds);
        end
    end
end



% NEW (DataflowBlock)
% 	% INITIALIZE WITH DEFAULT NAME
% 			persistent class_id_factory_store
% 			
% 			if isempty(class_id_factory_store)
% 				class_id_factory_store = containers.Map;
% 			end
% 			className = ignition.util.getClassName(obj);
% 			if ~isKey(class_id_factory_store, className)
% 				uidGenerator = ignition.util.UniqueIdFactory(className);				
% 			else
% 				uidGenerator = class_id_factory_store(className);
% 			end
% 			
% 			% SET NAME & UNIQUE ID
% 			obj.Name = className;
% 			obj.ID = uidGenerator.nextId();




% OLD
%class_id_factory_store(className) = classCount;
%obj.Name = sprintf('%s_%d',className,classCount);