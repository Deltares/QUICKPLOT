function setaxesprops(Parent,FullAxesType,dimension1,dimension2,dimension3)
%SETAXESPROPS Set appropriate axes properties.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C)  Stichting Deltares, 2011.                                     
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

AxesType=full2basic_axestype(FullAxesType);
if ~ishandle(Parent)
else
    if isappdata(Parent,'AxesType')
        if ~isequal(getappdata(Parent,'AxesType'),FullAxesType)
            warning(sprintf('AxesType mismatch: %s (set) vs. %s (new).',getappdata(Parent,'AxesType'),FullAxesType))
            FullAxesType = getappdata(Parent,'AxesType');
            AxesType = full2basic_axestype(FullAxesType);
        end
    end
    if nargin<3
        dimension1 = 'quantity (?)';
    end
    if nargin<4
        dimension2 = 'quantity (?)';
    end
    if nargin<5
        dimension3 = 'quantity (?)';
    end
    %
    set(Parent,'layer','top')
    %
    % Get label handles. If the label is not empty, let the handle be empty
    % such that the label contents will not be overwritten.
    %
    xlab=get(Parent,'xlabel');
    if ~isempty(get(xlab,'string')) & isempty(get(xlab,'userdata'))
        xlab=[];
    end
    ylab=get(Parent,'ylabel');
    if ~isempty(get(ylab,'string')) & isempty(get(ylab,'userdata'))
        ylab=[];
    end
    zlab=get(Parent,'zlabel');
    if ~isempty(get(zlab,'string')) & isempty(get(zlab,'userdata'))
        zlab=[];
    end
    %
    ra = ' \rightarrow';
    switch AxesType
        %
        %----------------------------------------------------------------
        %
        case '<blocking>'
        case 'Time-Val'
            tick(Parent,'x','autodate');
            set(xlab,'string','time \rightarrow')
            set(ylab,'string',[dimension3 ra])
        case 'Time-Z'
            tick(Parent,'x','autodate');
            set(xlab,'string','time \rightarrow')
            set(ylab,'string',[dimension3 ra])
        case 'X-Time-Val'
            tick(Parent,'y','autodate');
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string','time \rightarrow')
            set(zlab,'string',[dimension3 ra])
        case 'X-Time-Z'
            tick(Parent,'y','autodate');
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string','time \rightarrow')
            set(zlab,'string',[dimension3 ra])
            %
            %-------------------------------------------------------------
            %
        case 'Val-Val'
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string',[dimension3 ra])
        case 'X-Val'
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string',[dimension3 ra])
        case 'Val-Z'
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string',[dimension3 ra])
        case 'X-Y-Val'
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string',[dimension2 ra])
            set(zlab,'string',[dimension3 ra])
        case 'Lon-Lat-Val'
            lat=mean(get(Parent,'ylim'));
            sethscale(Parent,cos(lat*pi/180))
            tick(Parent,'x','longitude');
            tick(Parent,'y','latitude');
            set(xlab,'string','longitude (deg) \rightarrow')
            set(ylab,'string','latitude (deg) \rightarrow')
            set(zlab,'string',[dimension3 ra])
            %
            %-------------------------------------------------------------
            %
        case 'X-Y'
            sethscale(Parent,1)
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string',[dimension2 ra])
        case 'X-Z'
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string',[dimension3 ra])
        case 'X-Y-Z'
            sethscale(Parent,1)
            set(xlab,'string',[dimension1 ra])
            set(ylab,'string',[dimension2 ra])
            set(zlab,'string',[dimension3 ra])
        case 'Lon-Lat'
            ylimv=get(Parent,'ylim');
            if ylimv(1)<-90
                ylimv(1)=-90;
                if ylimv(2)<=ylimv(1)
                    ylimv(2)=-89;
                end
            end
            if ylimv(2)>90
                ylimv(2)=90;
                if ylimv(1)>=ylimv(2)
                    ylimv(1)=89;
                end
            end
            lat=mean(ylimv);
            lat=min(max(lat,-89),89);
            sethscale(Parent,cos(lat*pi/180))
            set(Parent,'ylim',ylimv)
            tick(Parent,'x','longitude');
            tick(Parent,'y','latitude');
            set(xlab,'string','longitude (deg) \rightarrow')
            set(ylab,'string','latitude (deg) \rightarrow')
        case 'Lon-Lat-Z'
            lat=mean(get(Parent,'ylim'));
            sethscale(Parent,cos(lat*pi/180))
            tick(Parent,'x','longitude');
            tick(Parent,'y','latitude');
            set(xlab,'string','longitude (deg) \rightarrow')
            set(ylab,'string','latitude (deg) \rightarrow')
            set(zlab,'string',[dimension3 ra])
            %
            %-------------------------------------------------------------
            %
        otherwise
            AxisQuant = multiline(AxesType,'-','cell');
            for i = 1:length(AxisQuant)
                if i == 1
                    ilab = xlab;
                    idimension = dimension1;
                elseif i == 2
                    ilab = ylab;
                    idimension = dimension2;
                else
                    ilab = zlab;
                    idimension = dimension3;
                end
                if isequal(AxisQuant{i},'Val')
                    idimension = dimension3;
                end
                set(ilab,'string',[idimension ra])
            end
    end
    %
    set(xlab,'userdata','autolabel')
    set(ylab,'userdata','autolabel')
    set(zlab,'userdata','autolabel')
    %
    setappdata(Parent,'AxesType',FullAxesType)
end


function distanceticks(ax,x)
unitQ=[0     1  1000];
unitS={'mm' 'm' 'km'};
dx=diff(get(ax,[x 'lim']));
scale=max(find(dx>unitQ*0.1));
set(ax,[x 'ticklabelmode'],'auto',[x 'tickmode'],'auto');
tick(ax,x,'%g',1/unitQ(scale))
set(get(ax,[x 'label']),'string',sprintf('distance (%s) \\rightarrow',unitS{scale}))


function sethscale(Parent,ratio)
if strcmp(get(Parent,'dataaspectratiomode'),'auto')
    set(Parent,'dataaspectratio',[1 ratio 1/30])
else
    da = get(Parent,'dataaspectratio');
    da(2) = da(1)*ratio;
    set(Parent,'dataaspectratio',da)
end


function axestype = full2basic_axestype(axestype)
unitsloc=strfind(axestype,' [');
for i=length(unitsloc):-1:1
    unitsclose=strfind(axestype(unitsloc(i):end),']');
    if ~isempty(unitsclose)
        axestype(:,unitsloc(i)+(0:max(unitsclose)-1))=[];
    end
end