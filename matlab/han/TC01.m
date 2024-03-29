classdef TC01 < handle
    %TC01 Interface to the National Instruments USB-TC01 single channel Thermometer
    % TC01 provides access to the National Instruments USB-TC01 single
    % channel thermocouple based thermometer.
    %
    % obj = TC01(deviceID,probeType) creates an object OBJ representing the device
    % with the DEVICEID assigned by the National Instruments Measurement
    % and Automation Explorer, with the PROBETYPE of 'J','K','T', etc.
    % representing the type of the thermocouple used.
    %
    % Call the READ method on the object to retrieve the current
    % temperature in Celsius.
    %
    % This requires the Data Acquisition Toolbox and MATLAB R2010b or
    % later.  Note that this object takes exclusive access to the hardware.
    % To release it, clear the variable that the object is assigned to
    %
    % Example:
    % myTemp = TC01('Dev4','J');
    % 
    % read(myTemp)
    % ans =
    %    20.9406
    %
    % % release the hardware
    % clear myTemp
    
    % Copyright 2010, The MathWorks, Inc.
    
    properties(SetAccess = private)
        ThermocoupleType
    end
    
    methods
        function [obj] = TC01(deviceID,probeType)
            if nargin ~= 2
                error('daq:tc01:badParameter','You must provide a valid device identifier, such as ''Dev1'' and thermocouple probe type, such as ''J''.')
            end
            if ~ischar(deviceID)
                error('daq:tc01:badDeviceID','You must provide a valid device identifier, such as ''Dev1''.')
            end
            if ~ischar(probeType)
                error('daq:tc01:badProbeType','You must provide a valid thermocouple probe type, such as ''J''.')
            end
            
            try
                obj.ThermocoupleType = daq.ni.ThermocoupleType.setValue(probeType);
                knownGoodRange = obj.thermocoupleRange(obj.ThermocoupleType,daq.ni.TemperatureUnits.Celsius);
            catch e
                if strcmp(e.identifier,'MATLAB:undefinedVarOrClass')
                    % Check on DAQ not present
                    if ~license('test','data_acq_toolbox')
                        error('daq:tc01:requiresDAQ','This requires the Data Acquisition Toolbox.  For more information, visit the <a href="http://www.mathworks.com/products/daq">Data Acquisition Toolbox web page</a>.')
                    end
                    
                    % Check release -- requires R2010b or later
                    releaseVersion = version('-release');
                    year = str2double(releaseVersion(1:end-1));
                    releaseInYear = releaseVersion(end);
                    if year < 2010 ||...
                            (year == 2010 && strcmpi(releaseInYear,'a'))
                        error('daq:tc01:requiresR2010bOrLater','This requires release R2010b or later.  For more information, visit the <a href="http://www.mathworks.com/products/matlab">MATLAB web page</a>.')
                    end
                end
                throwAsCaller(e)
            end
            
            % Check that the device is a TC-01
            [DevTypeSize,~] = daq.ni.NIDAQmx.DAQmxGetDevProductType(char(deviceID),char(0),uint32(0));
            [~,DevType] = daq.ni.NIDAQmx.DAQmxGetDevProductType(char(deviceID),blanks(DevTypeSize),uint32(DevTypeSize));
            if ~strcmpi(DevType,'USB-TC01')
            	error('daq:tc01:deviceIsNotTC01','Device ''%s'' is not a USB-TC01, it reports that it is a %s.  Only USB-TC01 devices are supported.',deviceID,DevType)
            end
            
            % Create the Task
            [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
            obj.throwOrWarnOnStatus(status);
            obj.Task = taskHandle;

            try
                [status] = daq.ni.NIDAQmx.DAQmxCreateAIThrmcplChan(...
                    taskHandle,...                          % taskHandle
                    sprintf('%s/ai0',deviceID),...          % physicalChannel
                    blanks(0),...                           % nameToAssignToChannel
                    knownGoodRange.Min,...                  % minVal
                    knownGoodRange.Max,...                  % maxVal
                    daq.ni.NIDAQmx.DAQmx_Val_DegC,...       % units
                    obj.DAQToNI(obj.ThermocoupleType),...   % thermocoupleType
                    daq.ni.NIDAQmx.DAQmx_Val_BuiltIn,...    % cjcSource
                    0,...                                   % cjcVal
                    ' ');                                   % cjcChannel
                obj.throwOrWarnOnStatus(status);
            catch e
                [~] = daq.ni.NIDAQmx.DAQmxClearTask(obj.Task);
                obj.Task = [];
                rethrow(e)
            end
            
        end
        
        function [data] = read(obj)
                [status,data,~,~] =...
                    daq.ni.NIDAQmx.DAQmxReadAnalogF64(...
                    obj.Task,...                                                    % taskHandle
                    int32(1),...                                                    % numSampsPerChan
                    1.0,...                                                         % timeout
                    uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber),...          % fillMode
                    zeros(1,1),...                                                  % readArray 
                    uint32(1),...                                                   % arraySizeInSamps
                    int32(0),...                                                    % sampsPerChanRead
                    uint32(0));                                                     % reserved
            obj.throwOrWarnOnStatus(status);
        end
        
        function delete(obj)
            if ~isempty(obj.Task)
                [~] = daq.ni.NIDAQmx.DAQmxClearTask(obj.Task);
                obj.Task = [];
            end
        end
    end
    
    properties(GetAccess = private,SetAccess = private)
        Task = [];
    end
    
    methods(Static, Access = private)
        function throwOrWarnOnStatus( niStatusCode )
            if niStatusCode == daq.ni.NIDAQmx.DAQmxSuccess
                return
            end
            
            % Capture the extended error string
            % First, find out how big it is
            [numberOfBytes,~] = daq.ni.NIDAQmx.DAQmxGetExtendedErrorInfo(' ', uint32(0));
            % Now, get the message
            [~,extMessage] = daq.ni.NIDAQmx.DAQmxGetExtendedErrorInfo(blanks(numberOfBytes), uint32(numberOfBytes));
            
            if niStatusCode < daq.ni.NIDAQmx.DAQmxSuccess
                % Status code is less than 0 -- It is a NI-DAQmx error, throw an error
                errorToThrow = MException(sprintf('daq:ni:err%06d',-1 * niStatusCode),...
                    'NI Error %06d:\n%s', niStatusCode,extMessage);
                throwAsCaller(errorToThrow)
            else
                % It is a NI-DAQmx error, warn
                warning(sprintf('daq:ni:warn%06d',niStatusCode),...
                    'NI Warning %06d:\n%s',niStatusCode,extMessage);
            end
            
        end
        
        function result = thermocoupleRange( thermocoupleType, units )
            switch(thermocoupleType)
                case {daq.ni.ThermocoupleType.Unknown,...
                        daq.ni.ThermocoupleType.J}
                    % Unknown is defined as J for this purpose
                    minDegC = 0;
                    maxDegC = 750;
                case daq.ni.ThermocoupleType.K
                    minDegC = -199.5;
                    maxDegC = 1250;
                case daq.ni.ThermocoupleType.N
                    minDegC = -199.5;
                    maxDegC = 1300;
                case {daq.ni.ThermocoupleType.R,...
                        daq.ni.ThermocoupleType.S}
                    minDegC = 0;
                    maxDegC = 1450;
                case daq.ni.ThermocoupleType.T
                    minDegC = -199.5;
                    maxDegC = 350;
                case daq.ni.ThermocoupleType.B
                    minDegC = 250.5;
                    maxDegC = 1700;
                case daq.ni.ThermocoupleType.E
                    minDegC = -199.5;
                    maxDegC = 900;
            end
            
            result = daq.Range(convertScale(minDegC,units),...
                convertScale(maxDegC,units),...
                char(units));
            
            function result = convertScale(degC,units)
                
                switch units
                    case daq.ni.TemperatureUnits.Celsius
                        % No action required
                        result = degC;
                    case daq.ni.TemperatureUnits.Kelvin
                        % Convert Celsius to Kelvin
                        result = degC + 273;
                    case daq.ni.TemperatureUnits.Fahrenheit
                        % Convert Celsius to Fahrenheit
                        result = degC * 1.8 + 32;
                    case daq.ni.TemperatureUnits.Rankine
                        % Convert Celsius to Fahrenheit
                        result = degC * 1.8 + 32;
                        % Convert Fahrenheit to Rankine
                        result = result + 459.67;
                end
            end
        end
        
        function NIvalue = DAQToNI(DAQvalue)
            %DAQTONI Converts from DAQ enumerations to NI constants
            
            %   Copyright 2010 The MathWorks, Inc.
            
            switch DAQvalue
                    % Thermocouple types
                    % Unknown is used to force user to set a value for the thermocouple
                    % type. It is mapped to J because we need to map to a legal value.
                case daq.ni.ThermocoupleType.Unknown
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_J_Type_TC;
                    
                case daq.ni.ThermocoupleType.J
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_J_Type_TC;
                    
                case daq.ni.ThermocoupleType.K
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_K_Type_TC;
                    
                case daq.ni.ThermocoupleType.N
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_N_Type_TC;
                    
                case daq.ni.ThermocoupleType.R
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_R_Type_TC;
                    
                case daq.ni.ThermocoupleType.S
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_S_Type_TC;
                    
                case daq.ni.ThermocoupleType.T
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_T_Type_TC;
                    
                case daq.ni.ThermocoupleType.B
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_B_Type_TC;
                    
                case daq.ni.ThermocoupleType.E
                    NIvalue = daq.ni.NIDAQmx.DAQmx_Val_E_Type_TC;
                otherwise
                    error('daq:tc01:unknownConversion','Unknown conversion');
            end
        end
    end
end
