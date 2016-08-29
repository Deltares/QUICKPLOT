function [hNew,Thresholds,Param]=qp_plot_polyl(hNew,Parent,Param,data,Ops,Props)
%QP_PLOT_POLYL Plot function of QuickPlot for polyline data sets.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2016 Stichting Deltares.                                     
%                                                                               
%   This library is free software; you can redistribute it and/or                
%   modify it under the terms of the GNU Lesser General Public                   
%   License as published by the Free Software Foundation version 2.1.                         
%                                                                               
%   This library is distributed in the hope that it will be useful,              
%   but WITHOUT ANY WARRANTY; without even the implied warranty of               
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
%   Lesser General Public License for more details.                              
%                                                                               
%   You should have received a copy of the GNU Lesser General Public             
%   License along with this library; if not, see <http://www.gnu.org/licenses/>. 
%                                                                               
%   contact: delft3d.support@deltares.nl                                         
%   Stichting Deltares                                                           
%   P.O. Box 177                                                                 
%   2600 MH Delft, The Netherlands                                               
%                                                                               
%   All indications and logos of, and references to, "Delft3D" and "Deltares"    
%   are registered trademarks of Stichting Deltares, and remain the property of  
%   Stichting Deltares. All rights reserved.                                     
%                                                                               
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL$
%   $Id$

T_=1; ST_=2; M_=3; N_=4; K_=5;

FirstFrame = Param.FirstFrame;
Quant=Param.Quant;
Units=Param.Units;
if ~isempty(Units)
    PName=sprintf('%s (%s)',Quant,Units);
else
    PName=Quant;
end
TStr       = Param.TStr;
Selected   = Param.Selected;
multiple   = Param.multiple;
NVal       = Param.NVal;

DimFlag=Props.DimFlag;
Thresholds=Ops.Thresholds;

switch NVal
    case 0
        if strcmp(Ops.facecolour,'none')
            if ishandle(hNew)
                set(hNew,'xdata',data.X, ...
                         'ydata',data.Y);
            else
                hNew=line(data.X,data.Y, ...
                    'parent',Parent, ...
                    Ops.LineParams{:});
                set(Parent,'layer','top')
            end
        else
            if ~FirstFrame
                delete(hNew)
            end
            vNaN=isnan(data.X);
            if any(vNaN)
                bs=findseries(~vNaN);
            elseif isempty(vNaN)
                bs=zeros(0,2);
            else
                bs=[1 length(vNaN)];
            end
            hNew = plot_polygons([data.X data.Y],bs,[],Parent,Ops);
            %
            set(Parent,'layer','top')
        end
        qp_title(Parent,TStr,'quantity',Quant,'unit',Units,'time',TStr)
    case 1
        if ~FirstFrame
            delete(hNew)
        end
        vNaN=isnan(data.Val);
        if any(vNaN)
            bs=findseries(~vNaN);
        elseif isempty(vNaN)
            bs=zeros(0,2);
        else
            bs=[1 length(vNaN)];
        end
        hNew = plot_polygons([data.X data.Y],bs,data.Val(bs(:,1)),Parent,Ops);
        %
        set(Parent,'layer','top')
        if strcmp(Ops.colourbar,'none')
            qp_title(Parent,{PName,TStr},'quantity',Quant,'unit',Units,'time',TStr)
        else
            qp_title(Parent,{TStr},'quantity',Quant,'unit',Units,'time',TStr)
        end
    case {2,3}
        if multiple(M_) % network
        else % point
        end
    case 4
        switch Ops.presentationtype
            case {'markers'}
                if isfield(data,'XY')
                    hNew=genmarkers(hNew,Ops,Parent,[],data.XY(:,1),data.XY(:,2));
                else
                    hNew=genmarkers(hNew,Ops,Parent,[],data.X,data.Y);
                end
            case {'labels'}
                if isfield(data,'XY')
                    hNew=genmarkers(hNew,Ops,Parent,[],data.XY(:,1),data.XY(:,2));
                else
                    hNew=gentextfld(hNew,Ops,Parent,data.Val,data.X,data.Y);
                end
        end
end


function hNew = plot_polygons(XY,bs,val,Parent,Ops)
if ~isempty(val)
    uval = unique(val);
    nval = length(uval);
    for i = nval:-1:1
        hNew{i} = plot_polygons_one_value(XY,bs(val==uval(i),:),uval(i),Parent,Ops);
    end
    hNew = cat(1,hNew{:});
else
    hNew = plot_polygons_one_value(XY,bs,[],Parent,Ops);
end


function hNew = plot_polygons_one_value(XY,bs,val,Parent,Ops)
nseg = size(bs,1);
ln = bs(:,2)-bs(:,1)+1;
%
polygons = false(nseg,1);
for i = 1:nseg
    if all(XY(bs(i,1),:)==XY(bs(i,2),:))
        % this is a polyGON
        polygons(i) = true;
    end
end
% one NaN separator needed per contour except for the last one
ln_polygons  = max(0,sum(ln(polygons)+1)-1);
ln_polylines = max(0,sum(ln(~polygons)+1)-1);
%
xy_polygons  = NaN(ln_polygons,2);
xy_polylines = NaN(ln_polylines,2);
ofgon = 0;
oflin = 0;
%
for i = 1:nseg
    xy = XY(bs(i,1):bs(i,2),:);
    if polygons(i)
        xy_polygons(ofgon+(1:ln(i)),:)  = xy;
        ofgon = ofgon + ln(i) + 1;
    else
        xy_polylines(oflin+(1:ln(i)),:) = xy;
        oflin = oflin + ln(i) + 1;
    end
end
%
if ln_polylines + ln_polygons > 0
    % ... && (~strcmp(Ops.linestyle,'none') || ~strcmp(Ops.marker,'none'))
    % outline using a NaN separated line for multiple parts and
    % holes
    if isempty(val)
        hNewL = line([xy_polygons(:,1);NaN;xy_polylines(:,1)], ...
            [xy_polygons(:,2);NaN;xy_polylines(:,2)], ...
            'parent',Parent, ...
            Ops.LineParams{:});
    else
        hNewL = patch([xy_polygons(:,1);NaN;xy_polylines(:,1);NaN], ...
            [xy_polygons(:,2);NaN;xy_polylines(:,2);NaN], ...
            repmat(val,ln_polylines + ln_polygons + 2,1), ...
            'edgecolor','flat', ...
            'facecolor','none', ...
            'linestyle',Ops.linestyle, ...
            'linewidth',Ops.linewidth, ...
            'marker',Ops.marker, ...
            'markersize',Ops.markersize, ...
            'markeredgecolor',Ops.markercolour, ...
            'markerfacecolor',Ops.markerfillcolour, ...
            'parent',Parent);
    end
else
    hNewL = [];
end
hNewP = [];
if ln_polygons>0
    % the patch command doesn't support
    % * multiple parts, and
    % * holes
    % using NaN separated arrays. It is possible to create holes by
    % connecting the outer contour with the contour of the hole and
    % returning back to the outer contour along the same line. One can do
    % the same for polygons with multiple parts but this doesn't work that
    % well; sometimes a thin connecting line remains (even without coloring
    % the contours). So, we first need to identify which contour marks an
    % outer contour and which contour represents a hole.
    %
    nansep = find(isnan(xy_polygons(:,1)));
    BP = [[0;nansep] [nansep;size(xy_polygons,1)+1]];
    BPln = BP(:,2)-BP(:,1)-1;
    np = size(BP,1);
    inside = false(np);
    inside_check = 'sequential';
    switch inside_check
        case 'never'
            % default matrix inside is valid
        case 'sequential'
            % check only for polygons inside the previous ones back to the
            % latest outer one
            i1 = 1; % latest outer
            for j = 2:np
                is_inside = false;
                for i = i1:j-1
                    inside(j,i) = all(inpolygon(xy_polygons(BP(j,1)+1:BP(j,2)-1,1),xy_polygons(BP(j,1)+1:BP(j,2)-1,2),xy_polygons(BP(i,1)+1:BP(i,2)-1,1),xy_polygons(BP(i,1)+1:BP(i,2)-1,2)));
                    is_inside = is_inside | inside(j,i);
                end
                if ~is_inside
                    i1 = j;
                end
            end
        case 'always'
            % check any combination
            for i = 1:np
                for j = i+1:np
                    inside(i,j) = all(inpolygon(xy_polygons(BP(i,1)+1:BP(i,2)-1,1),xy_polygons(BP(i,1)+1:BP(i,2)-1,2),xy_polygons(BP(j,1)+1:BP(j,2)-1,1),xy_polygons(BP(j,1)+1:BP(j,2)-1,2)));
                    inside(j,i) = all(inpolygon(xy_polygons(BP(j,1)+1:BP(j,2)-1,1),xy_polygons(BP(j,1)+1:BP(j,2)-1,2),xy_polygons(BP(i,1)+1:BP(i,2)-1,1),xy_polygons(BP(i,1)+1:BP(i,2)-1,2)));
                end
            end
    end
    %
    % determine contour type: 0 = outer contour, 1 = inner contour (hole)
    type = mod(sum(inside,2),2);
    hNewP = zeros(np,1);
    for ip = 1:np
        % skip inner contours
        if type(ip)==1
            continue
        end
        %
        inrank = sum(inside(ip,:));
        inhere = find(inside(:,ip));
        ipx = [ip;inhere(sum(inside(inhere,:),2)==inrank+1)];
        %
        xyr = NaN(sum(BPln(ipx)+1)-1,2);
        or = 0;
        for i = ipx'
            xyr(or+(1:BPln(i)),:) = xy_polygons(BP(i,1)+1:BP(i,2)-1,:);
            or = or + BPln(i)+1;
        end
        bp = cumsum(BPln(ipx)+1);
        %
        for i = 1:length(bp)-1
            % find the shortest distance between the first contour
            % and the second one.
            d1min = inf;
            for i2 = bp(i)+1:bp(i+1)-1
                [d1,i1] = min( (xyr(1:bp(i)-1,1)-xyr(i2,1)).^2 + (xyr(1:bp(i)-1,2)-xyr(i2,2)).^2);
                if d1<d1min
                    d1min = d1;
                    i1min = i1;
                    i2min = i2;
                end
            end
            % merge the first and second contour along the line
            % between the two points with shortest distance.
            xyr(1:bp(i+1)-1,:) = xyr([i1min:bp(i)-1 2:i1min i2min:bp(i+1)-1 bp(i)+2:i2min i1min],:);
            % the merged contour is now contour one, continue to
            % merge it with the contour of the next hole.
        end
        %
        % if the color is given then this patch should not influence color
        % scaling. However, the default "1" cdata will do so; we need to set it
        % to []. Unfortunately, we cannot set the cdata to [] immediately since
        % this will result in an error since the facecolor is flat by default.
        % so, we change it after having set facecolor to something else.
        facecolor = Ops.facecolour;
        if strcmp(facecolor,'yes')
            facecolor = 'flat';
        end
        hNewP(i) = patch(xyr(:,1), ...
            xyr(:,2), ...
            1, ...
            'edgecolor','k', ...
            'facecolor',facecolor, ...
            'linestyle','none', ...
            'marker','none', ...
            'cdata',val, ...
            'parent',Parent);
    end
    hNewP(hNewP==0,:) = [];
end
hNew = [hNewL;hNewP];
