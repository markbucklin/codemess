function success = writeUncompressedAVI(filename,data)

success = false;

filename = string(filename);
ext = "avi";
vprofile = "Uncompressed AVI";

if ~filename.endsWith(ext)
    filename = filename.append(".",ext);
end

try
    writer = VideoWriter( filename, vprofile);
    open(writer)
    writer.writeVideo(data);
    close(writer);
    success = true;
catch me
    success = false;
end
