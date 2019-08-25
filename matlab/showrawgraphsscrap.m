

jsonSession = jsonencode(session);
% fid = fopen(sprintf('session_info_output_%s.json',datestr(now,'YYYYmmmDD-HHMM')),'wt');
% fwrite(fid,jsonSession)
% fclose(fid)
clipboard('copy',jsonSession);
!chrome "http://app.rawgraphs.io/"