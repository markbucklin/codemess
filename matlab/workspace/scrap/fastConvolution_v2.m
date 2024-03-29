function y = fastConvolution_v2(data,filter)
warning('fastConvolution_v2.m being called from scrap directory: Z:\Files\MATLAB\toolbox\ignition\scrap')
m = size(data,1);
% Zero-pad filter to the length of data, and transform
filter_f = fft(filter,m);
% Transform each column of the input
af = fft(data);
% Multiply each column by filter and compute inverse transform
y = ifft(bsxfun(@times,af,filter_f));
end
