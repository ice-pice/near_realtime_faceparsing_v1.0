% global_trflag stands for global track flag which is set if the input is a
% video so that tracking can be done. Otherwise, if it is just a bunch of
% random images, there is no need of tracking.

function face_det(global_trflag, in_dir, in_file_list)

compile;

% addpath([pwd '/../dramanan_files/']);

%Load images
fileID = fopen(in_file_list);
imgs = textscan(fileID,'%s');
imgs = imgs{1};
fclose(fileID);
%imgs = dir('data_dir/*jpg');

%Load model
load face_p146_small.mat;
model.interval = 5;
model.thresh = min(-1, model.thresh);
thresh = model.thresh;

% define the mapping from view-specific mixture id to viewpoint
if length(model.components)==13
    posemap = 90:-15:-90;
elseif length(model.components)==18
    posemap = [90:-15:15 0 0 0 0 0 0 -15:-15:-90];
else
    error('Can not recognize this model');
end

%Make a strucuture for previous detections that can be used for tracking
track_prev.s  = 0;
track_prev.c  = 0;
track_prev.xy = 0;
track_prev.level = 0;
track_prev.coords = [-1 -1 -1 -1];

[components,filters]  = modelcomponents(model);

load final_parts_box.mat;

for i=1:numel(imgs)
    %Load image
    im_path = [in_dir imgs{i}];
    fprintf('%d out of %d\n',i,numel(imgs));
    im = imread(im_path);
    
    
    %Get viola-jones bounding box
    [n det] = runFacedet(in_dir,imgs{i});
    
    % No detection
    if n == 0
        %No face has been detected by viola-jones
        track_prev.s  = 0;
        track_prev.c  = 0;
        track_prev.xy = 0;
        track_prev.level = 0;
        track_prev.coords = [-1 -1 -1 -1];
        continue;
    end;
    
    BOXCACHESIZE = 10;
    true_det.s  = 0;
    true_det.c  = 0;
    true_det.xy = 0;
    true_det.level = 0;
    true_det.coords = [-1 -1 -1 -1];
    true_det(BOXCACHESIZE) = true_det;
    true_cnt = 1;
    
    %     keyboard;
    %For all the viola-jones detections, check if there is any overlap
    %with the previous detection. If not there is no tracking.
    for ii = 1:n
%         ii
        
        st = 1;
        en = length(components);
        
        [check track_num] = check_overlap([det(ii,1),det(ii,3),det(ii,2),det(ii,4)],track_prev);
        if global_trflag == 0
            check = -1;
        end;
        
        %Face_track
        if global_trflag == 1 && i ~= 1 && check ~= -1% && track_prev(track_num).xy ~= 0
            %Checking for overlap between the current vj detection and tracked.
            
            
            bs = track_prev(track_num);
            part_xy = bs.coords;
            face_bb = part_xy;
            face_box = im(part_xy(2):part_xy(4),part_xy(1):part_xy(3),:);
            bs.xy(:,1) = bs.xy(:,1) - part_xy(1);
            bs.xy(:,2) = bs.xy(:,2) - part_xy(2);
            bs.xy(:,3) = bs.xy(:,3) - part_xy(1);
            bs.xy(:,4) = bs.xy(:,4) - part_xy(2);
            
            st = max(1,bs.c- 1);
            en = min(13,bs.c+1);
            
%             disp('tracking');
            xpand = [1,1];
        else
            %Pass empty set to Face_detect.
            bs = [];
            ww = det(ii,2) - det(ii,1) + 1;
            hh = det(ii,4) - det(ii,3) + 1;
            face_bb = [1,size(im,2),1,size(im,1)];
            face_bb(1) = max(face_bb(1),(round(det(ii,1)-0.3*ww)));
            face_bb(2) = min(face_bb(2),(round(det(ii,2)+0.3*ww)));
            face_bb(3) = max(face_bb(3),(round(det(ii,3)-0.3*hh)));
            face_bb(4) = min(face_bb(4),(round(det(ii,4)+0.3*hh)));
            part_xy = [];
            face_box = im(face_bb(3):face_bb(4),face_bb(1):face_bb(2),:);
            
%             disp('no tracking'); 
            xpand = [abs(face_bb(2)-face_bb(1)),abs(face_bb(4)-face_bb(3))];
        end;
        
        
        % Face_detect part
        BOXCACHESIZE = 100000;
        cnt = 0;
        boxes.s  = 0;
        boxes.c  = 0;
        boxes.xy = 0;
        boxes.level = 0;
        boxes.coords = [-1 -1 -1 -1];
        boxes(BOXCACHESIZE) = boxes;
        
        %Get pyramid level
        if check == -1 
            lvl = max(7,ceil(((log(size(face_box,1)/(34*4))/(log(2)))*5)+6));
        else
            lvl = max(7,bs.level);
        end;
        
        %Compute feature pyramid
        pyrmd = featpyramid(face_box,model,lvl);
        resp = cell(length(pyrmd.feat),1);
        
        padx  = pyrmd.padx;
        pady  = pyrmd.pady;
        
        %For components
        for cmpn_num = st:en
            %On pyramid levels
            % TODO

            for rlvl = lvl-1:lvl+1
                parts    = components{cmpn_num};
                numparts = length(parts);
                
                % Convolution for each part
                [resp, parts] = part_conv(numparts,parts,rlvl,model,resp,pyrmd,filters,st,en,components,bs,check,xpand,face_bb,final_part_box);
                
               
                % Shift distance transform
                %                 keyboard;
                parts = part_shiftdt(numparts,parts,rlvl,check,bs,padx,pady,pyrmd,model,final_part_box,cmpn_num,xpand);
               
                
                % Add bias to root score
                rscore = parts(1).score + parts(1).w;
                [Y,X] = find(rscore >= thresh);
                if ~isempty(X)
                    XY = backtrack( X, Y, parts, pyrmd);
                end;
                
                % Walk back down tree following pointers
                for k = 1:length(X)
                    x = X(k);
                    y = Y(k);
                    
                    if cnt == BOXCACHESIZE
                        b0 = nms_face(boxes,0.3);
                        clear boxes;
                        boxes.s  = 0;
                        boxes.c  = 0;
                        boxes.xy = 0;
                        boxes.level = 0;
                        boxes(BOXCACHESIZE) = boxes;
                        cnt = length(b0);
                        boxes(1:cnt) = b0;
                    end
                    
                    cnt = cnt + 1;
                    boxes(cnt).c = cmpn_num;
                    boxes(cnt).s = rscore(y,x);
                    boxes(cnt).level = rlvl;
                    boxes(cnt).xy = XY(:,:,k);
                end
            end;
        end;
        
        
        % change the boxes coordinates back to originals. TODO.
%         fprintf('Count is %d\n',cnt);
        boxes = boxes(1:cnt);
        boxes = clipboxes(face_box, boxes);
        boxes = nms_face(boxes,0.3);
        
        if ~isempty(boxes)
            [true_det] = get_final_boxes(boxes,face_bb,part_xy,true_det,true_cnt,size(im,2),size(im,1),check);  
        end;
        
        
        clear boxes;
    end;
    if ~isempty(true_det)
%        showboxes(im, true_det,posemap,['out_dir/' imgs{i}]);
    end;
    track_prev = true_det;
    clear true_det;
end;


% Backtrack through dynamic programming messages to estimate part locations
% and the associated feature vector
function box = backtrack(x,y,parts,pyra)
numparts = length(parts);
ptr = zeros(numparts,2,length(x));
box = zeros(numparts,4,length(x));
k   = 1;
p   = parts(k);
ptr(k,1,:) = x;
ptr(k,2,:) = y;
% image coordinates of root
scale = pyra.scale(p.level);
padx  = pyra.padx;
pady  = pyra.pady;
box(k,1,:) = (x-1-padx)*scale + 1;
box(k,2,:) = (y-1-pady)*scale + 1;
box(k,3,:) = box(k,1,:) + p.sizx*scale - 1;
box(k,4,:) = box(k,2,:) + p.sizy*scale - 1;

for k = 2:numparts,
    p   = parts(k);
    par = p.parent;
    x   = ptr(par,1,:);
    y   = ptr(par,2,:);
    inds = sub2ind(size(p.Ix), y, x);
    ptr(k,1,:) = p.Ix(inds);
    ptr(k,2,:) = p.Iy(inds);
    % image coordinates of part k
    scale = pyra.scale(p.level);
    box(k,1,:) = (ptr(k,1,:)-1-padx)*scale + 1;
    box(k,2,:) = (ptr(k,2,:)-1-pady)*scale + 1;
    box(k,3,:) = box(k,1,:) + p.sizx*scale - 1;
    box(k,4,:) = box(k,2,:) + p.sizy*scale - 1;
end

% Cache various statistics from the model data structure for later use
function [components,filters] = modelcomponents(model)
components = cell(length(model.components),1);
padx = max(model.maxsize(2)-1-1,0);
pady = max(model.maxsize(1)-1-1,0);
for c = 1:length(model.components),
    for k = 1:length(model.components{c}),
        p = model.components{c}(k);
        x = model.filters(p.filterid);
        [p.sizy p.sizx foo] = size(x.w);
        p.filterI = x.i;
        x = model.defs(p.defid);
        p.defI = x.i;
        p.w    = x.w;
        
        % store the scale of each part relative to the component root
        par = p.parent;
        assert(par < k);
        ax  = x.anchor(1);
        ay  = x.anchor(2);
        ds  = x.anchor(3);
        if par > 0,
            p.scale = ds + components{c}(par).scale;
        else
            assert(k == 1);
            p.scale = 0;
        end
        % amount of (virtual) padding to hallucinate
        step     = 2^ds;
        virtpady = (step-1)*pady;
        virtpadx = (step-1)*padx;
        % starting points (simulates additional padding at finer scales)
        p.starty = ay-virtpady;
        p.startx = ax-virtpadx;
        p.step   = step;
        p.level  = 0;
        p.score  = 0;
        p.Ix     = 0;
        p.Iy     = 0;
        components{c}(k) = p;
    end
end

% resp    = cell(length(pyra.feat),1);
filters = cell(length(model.filters),1);
for i = 1:length(filters),
    filters{i} = model.filters(i).w;
end
