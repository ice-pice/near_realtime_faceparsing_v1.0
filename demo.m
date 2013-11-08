function demo(global_trflag, in_dir, in_file_list)

addpath('src/');
addpath('dramanan_files/');

face_det(global_trflag, in_dir, in_file_list);
disp('Done!');

end
