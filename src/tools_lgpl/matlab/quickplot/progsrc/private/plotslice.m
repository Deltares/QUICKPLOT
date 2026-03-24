function hNew = plotslice(hNew,Parent,data,Ops,Props,Thresholds)
%PLOTSLICE

%----- LGPL --------------------------------------------------------------------
%
%   Copyright (C) 2011-2026 Stichting Deltares.
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

x = squeeze(data.X);
z = squeeze(data.Z);
if isfield(data,'Y')
    y = squeeze(data.Y);
else
    y = [];
end
val = squeeze(data.Val);
%
if size(z,2)>1
    if size(x,2)==1
        x = repmat(x,[1 size(z,2)]);
    end
    if size(y,2)==1
        y = repmat(y,[1 size(z,2)]);
    end
    %
    Mask = repmat(min(z,[],2) == max(z,[],2), [1 size(z,2)]);
    if isequal(size(Mask),size(x))
        x(Mask) = NaN;
    end
    if isequal(size(Mask),size(y))
        y(Mask) = NaN;
    end
end
%
set(Parent,'NextPlot','add');
switch Ops.presentationtype
    case {'patches','patches with lines','grid'}
        if isfield(Props,'ThreeD')
            hNew = genfaces(hNew,Ops,Parent,val,x,y,z);
        else
            hNew = genfaces(hNew,Ops,Parent,val,x,z);
        end
        
    case 'old grid'
        if isempty(hNew)
            hNew = surface(x,z,zeros(size(x)), ...
                'cdata',[], ...
                'parent',Parent, ...
                'edgecolor',Ops.colour, ...
                'linewidth',Ops.linewidth, ...
                'linestyle',Ops.linestyle, ...
                'marker',Ops.marker, ...
                'markersize',Ops.markersize, ...
                'markeredgecolor',Ops.markercolour, ...
                'markerfacecolor',Ops.markerfillcolour, ...
                'facecolor','none');
        else
            set(hNew,'xdata',x,'ydata',z,'zdata',zeros(size(x)))
        end

    case 'values'
        I = ~isnan(val);
        hNew=gentextfld(hNew,Ops,Parent,val(I),x(I),z(I));
        
    case 'continuous shades'
        [val,x,z] = resize2data(val,x,z,Ops);
        hNew=gensurface(hNew,Ops,Parent,val,x,z,val);
        
    case 'markers'
        [val,x,z] = resize2data(val,x,z,Ops);
        hNew=genmarkers(hNew,Ops,Parent,val,x,z);
        
    case {'contour lines','coloured contour lines','contour patches','contour patches with lines'}
        [val,x,z] = resize2data(val,x,z,Ops);
        val(isnan(x) | isnan(z))=NaN;
        ms = max(x(:));
        mz = max(z(:));
        x(isnan(x)) = ms;
        z(isnan(z)) = mz;
        hNew = gencontour(hNew,Ops,Parent,x,z,val,Thresholds);
        
end