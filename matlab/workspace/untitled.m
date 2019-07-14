
Frgb = readbinary('*.uint8');
F = readBinary('*.single');

frgb_max32 = maxk(Frgb(:,:,:,100:end),32,4);
imrgbplay(frgb_max32)