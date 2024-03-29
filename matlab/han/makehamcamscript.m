obj =  Camera(...
  'camAdaptor', 'hamamatsu',...
  'videoFormat',  'MONO16_BIN2x2_1024x1024_FastMode',...
  'triggerConfiguration', 'manual')
setup(obj)
start(obj)
vidfile = VideoFile()
vidfile.experimentName = 'TSPL'
stopsavefcn = @(~,~)addFrame
t = timer(...
  'ExecutionMode', 'singleShot',...
  'startFcn',@(~,~)trigger(obj),...
  'StartDelay', 5,...
  'TimerFcn', @(~,~)stop(obj),...
  'TasksToExecute', 1,...
  'StopFcn', 
  'Period',obj.autoRangeTimerPeriod,...
	 

nFrames = obj.videoInputObj.FramesAvailable
[data,tstamp,meta] = getdata(obj.