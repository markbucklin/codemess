function success = writeCompressedHighQualityMP4(filename,data,opts)

success = false;

if nargin<3
    opts={};
end
    

success = false;

filename = string(filename);
ext = "mp4";
vprofile = "MPEG-4";

if ~filename.endsWith(ext)
    filename = filename.append(".",ext);
end

try        
    writer = VideoWriter( filename, vprofile );
    if ~isempty(opts)
        set(writer, opts{:})
    end
    open(writer)
    writer.writeVideo(data);
    close(writer);
    success = true;
catch me
    success = false;
end

