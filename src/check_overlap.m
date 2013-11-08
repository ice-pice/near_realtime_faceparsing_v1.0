function [check val] = check_overlap(detected,boxes)

len = length(boxes);

check = -1;
val = -1;

for i=1:len
    if isempty(boxes(i).s)
        continue;
    end;
    det_x1 = detected(1);
    det_y1 = detected(2);
    det_x2 = detected(3);
    det_y2 = detected(4);
    
    box_x1 = boxes(i).coords(1);
    box_y1 = boxes(i).coords(2);
    box_x2 = boxes(i).coords(3);
    box_y2 = boxes(i).coords(4);
    
    int_x1 = max(det_x1,box_x1);
    int_y1 = max(det_y1,box_y1);
    int_x2 = min(det_x2,box_x2);
    int_y2 = min(det_y2,box_y2);
    
    if int_x2 < int_x1 || int_y2 < int_y1
        continue;
    else
        int_area = (int_x2 - int_x1 + 1)*(int_y2 - int_y1 + 1);
        box_area = (box_x2 - box_x1 + 1)*(box_y2 - box_y1 + 1);
        det_area = (det_x2 - det_x1 + 1)*(det_y2 - det_y1 + 1);
        
        un_area = box_area + det_area - int_area;
        
        iou = int_area/un_area;
        
        if iou >= 0.20
            check = 1;
            val = i;
        end
    end
end
end
