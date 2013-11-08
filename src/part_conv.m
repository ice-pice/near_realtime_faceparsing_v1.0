function [resp_out, parts_out] =  part_conv(numparts,parts,rlvl,model,resp,pyrmd,filters,st,en,components,bs,check,xpand,face_bb,final_part_box)

padx  = pyrmd.padx;
pady  = pyrmd.pady;

factor = 0.3;

for part_num = 1:numparts
    % ???
    f = parts(part_num).filterid;
    level = rlvl-parts(part_num).scale*model.interval;
    %Check if for this level convolution has already been        %done or not
    if isempty(resp{level})
        scale = pyrmd.scale(level);
        % ?? Which boxes are these
        bbs = -1*ones(4,length(filters));
        for cmpn_in = st:en
            parts_in = components{cmpn_in};
            numparts_in = length(parts_in);
            for part_num_in = 1:numparts_in
                % ?? If else
                if check ~= -1 && size(bs.xy,1) == numparts_in
                    x1 = floor(((bs.xy(part_num_in,1) - 1)/scale) + 1 + padx);
                    y1 = floor(((bs.xy(part_num_in,2) - 1)/scale) + 1 + pady);
                    x2 = ceil(((bs.xy(part_num_in,3) - 1)/scale) + 1 + padx);
                    y2 = ceil(((bs.xy(part_num_in,4) - 1)/scale) + 1 + pady);
                else
                    bs.xy = final_part_box{cmpn_in};
                    bs.xy(:,1) = max(1,floor(bs.xy(:,1)*xpand(1)));
                    bs.xy(:,2) = max(1,floor(bs.xy(:,2)*xpand(2)));
                    bs.xy(:,3) = ceil(bs.xy(:,3)*xpand(1));
                    bs.xy(:,4) = ceil(bs.xy(:,4)*xpand(2));
%                   
                    x1 = floor(((bs.xy(part_num_in,1) - 1)/scale) + 1 + padx); %+ face_bb(1);
                    y1 = floor(((bs.xy(part_num_in,2) - 1)/scale) + 1 + pady);% + face_bb(2);
                    x2 = ceil(((bs.xy(part_num_in,3) - 1)/scale) + 1 + padx);% + face_bb(1);
                    y2 = ceil(((bs.xy(part_num_in,4) - 1)/scale) + 1 + pady);% + face_bb(2);
                    
                    wd = x2 - x1;
                    ht = y2 - y1;
                    
                    x1 = max(3,round(x1-factor*wd));
                    y1 = max(3,round(y1-factor*ht));
                    x2 = min(size(pyrmd.feat{level},2)-2,round(x2+factor*wd));
                    y2 = min(size(pyrmd.feat{level},1)-2,round(y2+factor*ht));
                    
%                     x1 = 3;
%                     y1 = 3;
%                     x2 = size(pyrmd.feat{level},2)-2;
%                     y2 = size(pyrmd.feat{level},1)-2;
%                     fprintf('%d vs %d\n%d vs %d\n%d vs %d\n%d vs %d\n',x1,x1_2,y1,y1_2,x2,x2_2,y2,y2_2);
                end;
                f_in  = parts_in(part_num_in).filterid;
                bbs(:,f_in) = [x1-1 y1-1 x2-1 y2-1];
            end;
        end;
        resp{level} = fconv(pyrmd.feat{level},filters,1, length(filters),bbs);
    end;
    
    parts(part_num).score = resp{level}{f};
    parts(part_num).level = level;
    
end;
resp_out = resp;
parts_out = parts;
