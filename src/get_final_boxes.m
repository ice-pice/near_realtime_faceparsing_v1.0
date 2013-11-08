function [true_det_out true_cnt_out] = get_final_boxes(boxes,face_bb,part_xy,true_det,true_cnt,max_x,max_y,check)

box_len = length(boxes);
for bi = 1:box_len
    if check == -1
        boxes(bi).xy(:,1) = boxes(bi).xy(:,1) + face_bb(1);
        boxes(bi).xy(:,2) = boxes(bi).xy(:,2) + face_bb(3);
        boxes(bi).xy(:,3) = boxes(bi).xy(:,3) + face_bb(1);
        boxes(bi).xy(:,4) = boxes(bi).xy(:,4) + face_bb(3);
    else
        boxes(bi).xy(:,1) = boxes(bi).xy(:,1) + part_xy(1);
        boxes(bi).xy(:,2) = boxes(bi).xy(:,2) + part_xy(2);
        boxes(bi).xy(:,3) = boxes(bi).xy(:,3) + part_xy(1);
        boxes(bi).xy(:,4) = boxes(bi).xy(:,4) + part_xy(2);
    end;
    ww = boxes(bi).xy(:,3) - boxes(bi).xy(:,1) + 1;
    hh = boxes(bi).xy(:,4) - boxes(bi).xy(:,2) + 1;
    
    boxes(bi).xy(:,1) = boxes(bi).xy(:,1) - 1*ww;
    boxes(bi).xy(:,2) = boxes(bi).xy(:,2) - 1*hh;
    boxes(bi).xy(:,3) = boxes(bi).xy(:,3) + 1*ww;
    boxes(bi).xy(:,4) = boxes(bi).xy(:,4) + 1*hh;
    
    ppx1 = min(boxes(bi).xy(:,1));
    ppy1 = min(boxes(bi).xy(:,2));
    ppx2 = max(boxes(bi).xy(:,3));
    ppy2 = max(boxes(bi).xy(:,4));
    w = ppx2-ppx1+1;
    h = ppy2-ppy1+1;
    ppx1 = round(ppx1 - 0.15*w);
    ppx2 = round(ppx2 + 0.15*w);
    ppy1 = round(ppy1 - 0.45*h);
    ppy2 = round(ppy2 + 0.20*h);
    if ppx1 < 1
        ppx1 = 1;
    end
    if ppy1 < 1
        ppy1 = 1;
    end
    if ppx2 > max_x
        ppx2 = max_x;
    end
    if ppy2 > max_y
        ppy2 = max_y;
    end
    boxes(bi).coords = [ppx1 ppy1 ppx2 ppy2];
    
    true_det(true_cnt) = boxes(bi);
    true_cnt = true_cnt + 1;
end;
true_det_out = true_det;
true_cnt_out = true_cnt;
end
