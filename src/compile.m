% addpath('/home/diggy/FaceProject/near_realtime_faceparsing_v1.0/dramanan_files');
% addpath([pwd '/../dramanan_files/']);

mex -O dramanan_files/resize.cc -outdir src/
mex -O dramanan_files/reduce.cc -outdir src/
mex -O dramanan_files/shiftdt2.cc -outdir src/
mex -O dramanan_files/features.cc -outdir src/

% use one of the following depending on your setup.
% 1 is fastest, 3 is slowest.
% If you are using a Windows machine, please use 3. 

% 1) multithreaded convolution using blas
% mex -O dramanan_files/fconvblas.cc -lmwblas -o fconv
% 2) mulththreaded convolution without blas
% mex -O dramanan_files/fconvMT.cc -o fconv
% 3) basic convolution, very compatible
mex -O dramanan_files/fconv.cc -outdir src/
