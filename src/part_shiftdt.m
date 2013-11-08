function parts = part_shiftdt(numparts,parts,rlvl,check,bs,padx,pady,pyrmd,model,final_part_box,cmpn_num,xpand)

if check == -1 || isempty(bs)
    bs.xy = final_part_box{cmpn_num};
    bs.xy(:,1) = max(1,floor(bs.xy(:,1)*xpand(1)));
    bs.xy(:,2) = max(1,floor(bs.xy(:,2)*xpand(2)));
    bs.xy(:,3) = ceil(bs.xy(:,3)*xpand(1));
    bs.xy(:,4) = ceil(bs.xy(:,4)*xpand(2));
end;

for k=numparts:-1:2
    child = parts(k);
    par   = child.parent;
    [Ny,Nx] = size(parts(par).score);
    level = rlvl-parts(k).scale*model.interval;
    scale = pyrmd.scale(level);
    
    % why this condition??
    if check == 1 && size(bs.xy,1) == numparts
        ccx1 = floor(((bs.xy(k,1) - 1)/scale) + 1 );%+ padx);
        ccy1 = floor(((bs.xy(k,2) - 1)/scale) + 1 );%+ pady);
        ccx2 = floor(((bs.xy(k,3) - 1)/scale) + 1 );
        ccy2 = floor(((bs.xy(k,4) - 1)/scale) + 1 );
        
        ppx1 = floor(((bs.xy(par,1) - 1)/scale) + 1 );%+ padx);
        ppy1 = floor(((bs.xy(par,2) - 1)/scale) + 1 );%+ pady);
        ppx2 = floor(((bs.xy(par,3) - 1)/scale) + 1 );
        ppy2 = floor(((bs.xy(par,4) - 1)/scale) + 1 );
    else
        %         wd = x2 - x1;
        %         ht = y2 - y1;
        %
        %         x1 = max(3,round(x1-0.1*wd));
        %         y1 = max(3,round(y1-0.1*ht));
        %         x2 = min(size(pyrmd.feat{level},2)-2,round(x2+0.1*wd));
        %         y2 = min(size(pyrmd.feat{level},1)-2,round(y2+0.1*ht));
        
        ccx1 = floor(((bs.xy(k,1) - 1)/scale) + 1 );%+ padx);
        ccy1 = floor(((bs.xy(k,2) - 1)/scale) + 1 );%+ pady);
        ccx2 = floor(((bs.xy(k,3) - 1)/scale) + 1 );%+ padx);
        ccy2 = floor(((bs.xy(k,4) - 1)/scale) + 1 );%+ pady);
        
        ppx1 = floor(((bs.xy(par,1) - 1)/scale) + 1 );%+ padx);
        ppy1 = floor(((bs.xy(par,2) - 1)/scale) + 1 );%+ pady);
        ppx2 = floor(((bs.xy(par,3) - 1)/scale) + 1 );%(+ padx);
        ppy2 = floor(((bs.xy(par,4) - 1)/scale) + 1 );%+ pady);
        
        factor = 0.3;
        ccwd = ccx2 - ccx1;
        ccht = ccy2 - ccy1;
        
        ccx1 = max(1,round(ccx1-factor*ccwd));
        ccy1 = max(1,round(ccy1-factor*ccht));
        ccx2 = min(size(child.score,2),round(ccx2+factor*ccwd));
        ccy2 = min(size(child.score,1),round(ccy2+factor*ccht));
        
        ppwd = ppx2 - ppx1;
        ppht = ppy2 - ppy1;
        
        ppx1 = max(1,round(ppx1-factor*ppwd));
        ppy1 = max(1,round(ppy1-factor*ppht));
        ppx2 = min(Nx,round(ppx2+factor*ppwd));
        ppy2 = min(Ny,round(ppy2+factor*ppht));
%                 ccx1 = 1;
%                 ccx2 = size(child.score,2);
%                 ccy1 = 1;
%                 ccy2 = size(child.score,1);
%         
%                 ppx1 = 1;
%                 ppx2 = Nx;
%                 ppy1 = 1;
%                 ppy2 = Ny;
    end;
    %    fprintf('\n%d %d %d %d %d %d %d %d\n',ccx1,ccy1,ccx2,ccy2,ppx1,ppy1,ppx2,ppy2);
    %    fprintf('%d %d %d %d %d %d %d %d\n\n',ccx1_2,ccy1_2,ccx2_2,ccy2_2,ppx1_2,ppy1_2,ppx2_2,ppy2_2);
    [msg,parts(k).Ix,parts(k).Iy] = shiftdt2(child.score, child.w(1),child.w(2),child.w(3),child.w(4), ...
        child.startx, child.starty, Nx, Ny, child.step, ...
        ppx1, ppy1, ppx2, ppy2, ccx1, ccy1, ccx2, ccy2);
    
    tmpmsg = msg;
    msg = -1000*ones(size(tmpmsg));
    msg(ppy1:ppy2,ppx1:ppx2) = tmpmsg(ppy1:ppy2,ppx1:ppx2);
    parts(par).score = parts(par).score + msg;
end;
