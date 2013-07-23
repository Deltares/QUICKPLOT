function varargout=shipmafil(FI,domain,field,cmd,varargin)
%SHIPMAFIL QP support for Shipma project files.
%   Domains                 = XXXFIL(FI,[],'domains')
%   DataProps               = XXXFIL(FI,Domain)
%   Size                    = XXXFIL(FI,Domain,DataFld,'size')
%   Times                   = XXXFIL(FI,Domain,DataFld,'times',T)
%   StNames                 = XXXFIL(FI,Domain,DataFld,'stations')
%   SubFields               = XXXFIL(FI,Domain,DataFld,'subfields')
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'data',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'celldata',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'griddata',subf,t,station,m,n,k)
%   [Data      ,NewFI]      = XXXFIL(FI,Domain,DataFld,'gridcelldata',subf,t,station,m,n,k)
%                             XXXFIL(FI,[],'options',OptionsFigure,'initialize')
%   [NewFI     ,cmdargs]    = XXXFIL(FI,[],'options',OptionsFigure,OptionsCommand, ...)
%
%   The DataFld can only be either an element of the DataProps structure.

%----- LGPL --------------------------------------------------------------------
%
%   Copyright (C) 2011-2013 Stichting Deltares.
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
%   All values and logos of, and references to, "Delft3D" and "Deltares"
%   are registered trademarks of Stichting Deltares, and remain the property of
%   Stichting Deltares. All rights reserved.
%
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL$
%   $Id$

%========================= GENERAL CODE =======================================

T_=1; ST_=2; M_=3; N_=4; K_=5;

if nargin<2
    error('Not enough input arguments');
elseif nargin==2
    varargout={infile(FI,domain)};
    return
elseif ischar(field)
    switch field
        case 'options'
            [varargout{1:2}]=options(FI,cmd,varargin{:});
        case 'optionstransfer'
            varargout{1}=optionstransfer(FI,cmd);
        case 'domains'
            varargout={domains(FI)};
        case 'dimensions'
            varargout={dimensions(FI)};
        case 'locations'
            varargout={locations(FI)};
        case 'quantities'
            varargout={quantities(FI)};
        case 'data'
            [varargout{1:2}]=getdata(FI,cmd,varargin{:});
    end
    return
else
    Props=field;
end

cmd=lower(cmd);
switch cmd
    case 'size'
        varargout={getsize(FI,Props)};
        return;
    case 'times'
        varargout={readtim(FI,Props,varargin{:})};
        return
    case 'stations'
        varargout={{}};
        return
    case 'subfields'
        varargout={{}};
        return
    case 'plot'
        selfplot(FI,Props);
        varargout={[] FI};
        return
    otherwise
        [XYRead,DataRead,DataInCell]=gridcelldata(cmd);
end

DimFlag=Props.DimFlag;

% initialize and read indices ...
idx={[] [] 0 0 0};
fidx=find(DimFlag);
idx(fidx(1:length(varargin)))=varargin;

sz=getsize(FI,Props);
if DimFlag(T_)
    if isempty(idx{T_})
        idx{T_}=sz(T_);
    end
elseif all(Props.Var>=0)
    idx{T_}=0;
end

prj = Props.Project;
PRJ = FI.Project(prj);
cse = Props.Case;

switch Props.Name
    case 'ship snapshots'
        step = qp_settings('shipma_timestep');
        Series = PRJ.Cases.Data(cse).TimeSeries;
        times = delwaq('read',Series,1,1,0)*3600*24;
        timereq = 0:step:times(end)+1;
        for i=1:length(timereq)
            [mn,timereq(i)]=min(abs(times-timereq(i)));
        end
        idx{1}=timereq;
end

% read data ...
if all(Props.Var>=0)
    [T,val1] = delwaq('read',PRJ.Cases.Data(cse).TimeSeries,Props.Var,1,idx{1});
else
    T=[];
end

% generate output ...
if Props.NVal==0
    switch Props.Name
        case 'fairway contour'
            FileName = PRJ.Sceneries.Data(PRJ.Cases.Data(cse).sceneryNr).fairwayContourFile;
            if exist(FileName)
                [Ans.X,Ans.Y] = landboundary('read',FileName,'autocorrect');
            else
                Ans.X=[];
                Ans.Y=[];
            end
        case 'bank suction lines'
            bsFI = tekal('open',PRJ.Sceneries.Data(PRJ.Cases.Data(cse).sceneryNr).banksuctionFile,'nskipdatalines',1);
            XY = tekal('read',bsFI,1:2);
            Ans.X = [XY{1}(:,1);NaN;XY{2}(:,1)];
            Ans.Y = [XY{1}(:,2);NaN;XY{2}(:,2)];
        case 'desired ship track'
            [Ans.X,Ans.Y] = landboundary('read',PRJ.Cases.Data(cse).trackFile,'autocorrect');
        case 'distance ticks'
            step = qp_settings('shipma_spacestep');
            width = qp_settings('shipma_tickwidth');
            if qp_settings('shipma_distance_along_desired_track')
                [x,y] = landboundary('read',PRJ.Cases.Data(cse).trackFile,'autocorrect');
            else
                x = squeeze(val1(1,1,:));
                y = squeeze(val1(2,1,:));
            end
            d = pathdistance(x,y);
            doublepoints = find(diff(d)==0)+1;
            x(doublepoints) = [];
            y(doublepoints) = [];
            d(doublepoints) = [];
            dtick = (0:step:max(d))';
            xtick = interp1(d,x,dtick);
            ytick = interp1(d,y,dtick);
            itick = min(length(d)-1,floor(interp1(d,1:length(d),dtick)));
            dx = diff(x);
            dy = diff(y);
            ds = sqrt(dx.^2+dy.^2);
            dx = dx./ds;
            dy = dy./ds;
            hwidth = width/2;
            x0 = [xtick-hwidth*dy(itick) xtick+hwidth*dy(itick)];
            y0 = [ytick+hwidth*dx(itick) ytick-hwidth*dx(itick)];
            x0 = x0';
            x0(3,:) = NaN;
            y0 = y0';
            y0(3,:) = NaN;
            Ans.X = x0;
            Ans.Y = y0;
        case 'realized ship track'
            Ans.X = squeeze(val1(1,1,:));
            Ans.Y = squeeze(val1(2,1,:));
        case 'swept path'
            val1 = squeeze(val1)';
            x = val1(:,1);
            y = val1(:,2);
            alf = val1(:,3)*pi/180;
            lat_offset = val1(:,4);
            swept_port = val1(:,5) - lat_offset;
            swept_star = val1(:,6) - lat_offset;
            sppx = x + cos(alf).*swept_port;
            sppy = y - sin(alf).*swept_port;
            spsx = x + cos(alf).*swept_star;
            spsy = y - sin(alf).*swept_star;
            Ans.X = [sppx;spsx(end-1:-1:1); sppx(1)];
            Ans.Y = [sppy;spsy(end-1:-1:1); sppy(1)];
        case {'ship','ship snapshots'} 
            ship = PRJ.Cases.Data(cse).shipNr;
            icontour = ustrcmpi('contour',{PRJ.Ships.Data(ship).Props.Quant});
            contour = PRJ.Ships.Data(ship).Props(icontour).Value;
            %
            lenC = size(contour,1);
            numS = size(val1,3);
            Ans.X = repmat(NaN,(lenC+1)*numS-1,1);
            Ans.Y = Ans.X;
            for i = 1:numS
                alf = val1(3,1,i)*pi/180;
                Ans.X((i-1)*(lenC+1)+(1:lenC)) = contour(:,1)*sin(alf)+contour(:,2)*cos(alf)+val1(1,1,i);
                Ans.Y((i-1)*(lenC+1)+(1:lenC)) = -contour(:,2)*sin(alf)+contour(:,1)*cos(alf)+val1(2,1,i);
            end
        case 'ship at distance ticks'
            ship = PRJ.Cases.Data(cse).shipNr;
            icontour = ustrcmpi('contour',{PRJ.Ships.Data(ship).Props.Quant});
            contour = PRJ.Ships.Data(ship).Props(icontour).Value;
            %
            step = qp_settings('shipma_spacestep');
            if qp_settings('shipma_distance_along_desired_track')
                d = val1(4,:);
            else
                d = pathdistance(val1(1,:),val1(2,:));
            end
            dtick = (0:step:max(d))';
            itick = crossings(d,dtick);
            i = 1:size(val1,3);
            xtick = interp1(i,val1(1,:),itick);
            ytick = interp1(i,val1(2,:),itick);
            atick = val1(3,floor(itick));
            atic2 = val1(3,ceil(itick));
            for i = 1:length(itick)
                f = itick(i)-floor(itick(i));
                if atick(i)>270 && atic2(i)<90
                    atick(i) = (atick(i)-360)*(1-f) + atick(i)*f;
                    if atick(i)<0
                        atick(i) = atick(i)+360;
                    end
                elseif atick(i)<90 && atic2(i)>270
                    atick(i) = atick(i)*(1-f) + (atick(i)-360)*f;
                    if atick(i)<0
                        atick(i) = atick(i)+360;
                    end
                else
                    atick(i) = atick(i)*(1-f) + atick(i)*f;
                end
            end
            %
            lenC = size(contour,1);
            numS = length(xtick);
            Ans.X = repmat(NaN,(lenC+1)*numS-1,1);
            Ans.Y = Ans.X;
            for i = 1:numS
                alf = atick(i)*pi/180;
                Ans.X((i-1)*(lenC+1)+(1:lenC)) = contour(:,1)*sin(alf)+contour(:,2)*cos(alf)+xtick(i);
                Ans.Y((i-1)*(lenC+1)+(1:lenC)) = -contour(:,2)*sin(alf)+contour(:,1)*cos(alf)+ytick(i);
            end
    end
elseif Props.NVal==1
    switch Props.Name
        case 'depth'
            btFI = samples('read',PRJ.Cases.Data(cse).bottomFile);
            Ans.XYZ = reshape(btFI.XYZ,[1 size(btFI.XYZ,1) 1 3]);
            Ans.TRI = delaunay(btFI.XYZ(:,1),btFI.XYZ(:,2));
            Ans.Val = btFI.XYZ(:,3);
        case 'speed'
            Ans.X   = val1(3,:)';
            Ans.Val = sqrt(val1(1,:).^2 + val1(2,:).^2)';
            if ~qp_settings('shipma_distance_along_desired_track')
                Ans.X = realized_track_distance(PRJ,cse,idx);
            end
        otherwise
            Ans.X   = val1(2,:)';
            Ans.Val = val1(1,:)';
            if ~qp_settings('shipma_distance_along_desired_track')
                Ans.X = realized_track_distance(PRJ,cse,idx);
            end
    end
elseif Props.NVal==4
    switch Props.Name
        case 'distance value at ticks'
            step = qp_settings('shipma_spacestep');
            if qp_settings('shipma_distance_along_desired_track')
                [x,y] = landboundary('read',PRJ.Cases.Data(cse).trackFile,'autocorrect');
            else
                x = squeeze(val1(1,1,:));
                y = squeeze(val1(2,1,:));
            end
            d = pathdistance(x,y);
            doublepoints = find(diff(d)==0)+1;
            x(doublepoints) = [];
            y(doublepoints) = [];
            d(doublepoints) = [];
            dtick = (0:step:max(d))';
            Ans.X = interp1(d,x,dtick);
            Ans.Y = interp1(d,y,dtick);
            Ans.Val = cell(size(dtick));
            for i = 1:length(dtick)
                Ans.Val{i} = sprintf('%i',dtick(i));
            end
    end
elseif Props.NVal==2
    switch Props.Name
        case 'speed'
            Ans.X = val1(3,:)';
            Ans.XComp = val1(1,:)';
            Ans.YComp = val1(2,:)';
        case 'wind'
            wFI = shipma('openpar',PRJ.Environments.Winds.Data(PRJ.Cases.Data(cse).windNr).file,'wind');
            Ans.XYZ = reshape(wFI.XY,[1 size(wFI.XY,1) 1 2]);
            Ans.TRI = delaunay(wFI.XY(:,1),wFI.XY(:,2));
            toDir = wFI.WindFromDir*pi/180-pi;
            Ans.XComp = wFI.WindMagnitude.*sin(toDir);
            Ans.YComp = wFI.WindMagnitude.*cos(toDir);
        case 'waves'
            wFI = shipma('openpar',PRJ.Environments.Waves.Data(PRJ.Cases.Data(cse).wavesNr).file,'waves');
            Ans.XYZ = reshape(wFI.XY,[1 size(wFI.XY,1) 1 2]);
            Ans.TRI = delaunay(wFI.XY(:,1),wFI.XY(:,2));
            toDir = wFI.WaveToDir*pi/180;
            Ans.XComp = wFI.WaveHeight.*sin(toDir);
            Ans.YComp = wFI.WaveHeight.*cos(toDir);
        case 'current'
            wFI = shipma('openpar',PRJ.Environments.Currents.Data(PRJ.Cases.Data(cse).currentNr).file,'current');
            Ans.XYZ = reshape(wFI.XY,[1 size(wFI.XY,1) 1 2]);
            Ans.TRI = delaunay(wFI.XY(:,1),wFI.XY(:,2));
            toDir = wFI.CurrentToDir*pi/180;
            Ans.XComp = wFI.CurrentMagnitude.*sin(toDir);
            Ans.YComp = wFI.CurrentMagnitude.*cos(toDir);
        otherwise
            Ans.XComp = val1;
            Ans.YComp = val2;
    end
end
if isfield(Ans,'X') || isfield(Ans,'XYZ')
    Ans.XUnits = 'm';
end
if isfield(Ans,'Y') || isfield(Ans,'XYZ')
    Ans.YUnits = 'm';
end
if ~isempty(T)
    Ans.Time = T;
end

varargout={Ans FI};
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function selfplot(FI,Props)
persistent inSelfPlot
%
% use persistent variable to prevent the selfplot command from recursively
% calling itself if one of the selected variables does not exist.
%
if isequal(inSelfPlot,1)
    return
end
inSelfPlot = 1; %#ok<NASGU>

prj = Props.Project;
cse = Props.Case;
cartoyellow = [254 197 68]/255;

if isempty(FI.Project(prj).Cases.Data(cse).TimeSeries)
    shipma = '';
else
    headerLine = FI.Project(prj).Cases.Data(cse).TimeSeries.Header(1,:);
    [shipma,rem] = strtok(headerLine);
    version = strtok(rem);
    shipma = [shipma ' ' version];
end
texts_template = get_shipma_bordertexts;
texts_template = local_strrep(texts_template,'%organization%',protectstring(qp_settings('organizationname')));
texts_template = local_strrep(texts_template,'%project%',protectstring(FI.Project(prj).Name));
texts_template = local_strrep(texts_template,'%case%',protectstring(FI.Project(prj).Cases.Names{cse}));
texts_template = local_strrep(texts_template,'%ship%',protectstring(FI.Project(prj).Cases.Data(cse).shipId));
texts_template = local_strrep(texts_template,'%shipma%',shipma);
%
if d3d_qp('selectfield','desired ship track')
    a=d3d_qp('loaddata'); % get ship track for auto zoom limits
    xrange = [min(a.X) max(a.X)];
    xrange = xrange + [-1 1]*0.1*diff(xrange);
    yrange = [min(a.Y) max(a.Y)];
    yrange = yrange + [-1 1]*0.1*diff(yrange);
    fac = 1.25;
    yrange = mean(yrange)+[-1 1]*max(diff(xrange)*fac,diff(yrange))/2;
    xrange = mean(xrange)+[-1 1]*diff(yrange)/fac/2;
else
    a=[];
end
%
for c = {'a' 'a1'}
    if qp_settings(['shipma_fig' c{1}])
        caption = 'Overview plot of track';
        if isequal(c,{'a1'})
            caption = 'Zoomed plot of track';
            zoombox = qp_settings('shipma_figa1_zoombox');
            if any(isnan(zoombox))
                ui_message('error','Skipping Fig A1 because zoombox coordinates are incomplete')
                continue
            end
        end
        if qp_settings('shipma_figa_depth')
            caption = [caption ' and depth'];
        end
        cstep = qp_settings('shipma_figa_contourstep');
        cmax  = qp_settings('shipma_figa_contourmax');
        texts = local_strrep(texts_template,'%caption%',caption);
        d3d_qp('newfigure','1 plot - portrait',['SHIPMA Fig ' upper(c{1})],texts)
        if qp_settings('shipma_figa_depth') && d3d_qp('selectfield','depth')
            d3d_qp('colourmap','navdepth')
            d3d_qp('presenttype','contour patches')
            d3d_qp('thresholds',[-inf 0:cstep:cmax])
            d3d_qp('colbarhorz',1)
            d3d_qp('addtoplot')
        end
        if qp_settings('shipma_figa_fairway') && d3d_qp('selectfield','fairway contour')
            d3d_qp('linestyle','-')
            d3d_qp('colour',[ 0 0 0 ])
            d3d_qp('fillpolygons',1)
            d3d_qp('facecolour',cartoyellow)
            d3d_qp('addtoplot')
        end
        if qp_settings('shipma_figa_banksuction') && d3d_qp('selectfield','bank suction lines')
            d3d_qp('linestyle','--')
            d3d_qp('colour',[ 0 0 0 ])
            d3d_qp('fillpolygons',0)
            d3d_qp('addtoplot')
        end
        if d3d_qp('selectfield','desired ship track')
            d3d_qp('linestyle','-')
            d3d_qp('colour',[ 0 0 0 ])
            d3d_qp('addtoplot')
        end
        if d3d_qp('selectfield','ship snapshots')
            d3d_qp('linestyle','-')
            d3d_qp('colour',[ 0 0 0 ])
            d3d_qp('fillpolygons',1)
            d3d_qp('facecolour',[ 1 0 0 ])
            d3d_qp('addtoplot')
        end
        if d3d_qp('selectfield','distance ticks')
            d3d_qp('colour',[ 0 0 0 ])
            d3d_qp('addtoplot')
        end
        if d3d_qp('selectfield','distance value at ticks')
            d3d_qp('colour',[ 0 0 0 ])
            d3d_qp('presenttype','labels')
            d3d_qp('fontsize',6)
            d3d_qp('addtoplot')
        end
        d3d_qp('axesboxed',1)
        if isequal(c,{'a1'})
            d3d_qp('axeslimits',zoombox(1:2),zoombox(3:4))
        else
            if ~isempty(a)
                d3d_qp('axeslimits',xrange,yrange)
            end
        end
    end
end
%--------
if qp_settings('shipma_figb')
    quant = qp_settings('shipma_figb_quantity');
    cstep = qp_settings('shipma_figb_contourstep');
    cmax  = qp_settings('shipma_figb_contourmax');
    %
    switch quant
        case {'wind','waves'}
            caption = ['Track plot and ' quant];
        case {'current'}
            caption = ['Track plot and ' quant 's'];
    end
    texts = local_strrep(texts_template,'%caption%',caption);
    d3d_qp('newfigure','1 plot - portrait','SHIPMA Fig B',texts)
    if d3d_qp('selectfield',quant)
        d3d_qp('component','magnitude')
        d3d_qp('presenttype','contour patches')
        d3d_qp('thresholds',0:cstep:cmax)
        d3d_qp('colourmap','revhot')
        d3d_qp('addtoplot')
        d3d_qp('component','vector')
        d3d_qp('colourvectors',0)
        d3d_qp('colour',[ 0 0 1 ])
        d3d_qp('thinfld','distance')
        d3d_qp('thindist',diff(xrange)/100)
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_figa_fairway') && d3d_qp('selectfield','fairway contour')
        d3d_qp('linestyle','-')
        d3d_qp('colour',[ 0 0 0 ])
        d3d_qp('fillpolygons',1)
        d3d_qp('facecolour',cartoyellow)
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_figa_banksuction') && d3d_qp('selectfield','bank suction lines')
        d3d_qp('linestyle','--')
        d3d_qp('colour',[ 0 0 0 ])
        d3d_qp('fillpolygons',0)
        d3d_qp('addtoplot')
    end
    if d3d_qp('selectfield','desired ship track')
        d3d_qp('colour',[ 0 0 0 ])
        d3d_qp('addtoplot')
    end
    if d3d_qp('selectfield','ship snapshots')
        d3d_qp('colour',[ 0 0 0 ])
        d3d_qp('facecolour',[ 1 0 0 ])
        d3d_qp('addtoplot')
    end
    if d3d_qp('selectfield','distance ticks')
        d3d_qp('colour',[ 0 0 0 ])
        d3d_qp('addtoplot')
    end
    if d3d_qp('selectfield','distance value at ticks')
        d3d_qp('colour',[ 0 0 0 ])
        d3d_qp('presenttype','labels')
        d3d_qp('fontsize',6)
        d3d_qp('addtoplot')
    end
    d3d_qp('axesboxed',1)
    if qp_settings('shipma_figa1')
        d3d_qp('axeslimits',zoombox(1:2),zoombox(3:4))
    else
        if ~isempty(a)
            d3d_qp('axeslimits',xrange,yrange)
        end
    end
end
%--------
if qp_settings('shipma_figc')
    caption = 'Speed and ruddle angle plots';
    texts = local_strrep(texts_template,'%caption%',caption);
    d3d_qp('newfigure','3 plots, vertical - portrait','SHIPMA Fig C',texts)
    %--
    qpsa('upper plot')
    d3d_qp('allt',1)
    if d3d_qp('selectfield','propeller speed')
        d3d_qp('axestype','Distance-Val')
        d3d_qp('linestyle','-')
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    %--
    qpsa('middle plot')
    if d3d_qp('selectfield','speed')
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    %--
    qpsa('lower plot')
    if d3d_qp('selectfield','rudder angle')
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
end
%--------
if qp_settings('shipma_figd')
    caption = {'Swept path and depth along track','Starboard side (dashed) port side (solid)'};
    texts = local_strrep(texts_template,'%caption%',caption);
    d3d_qp('newfigure','2 plots, vertical - portrait','SHIPMA Fig D',texts)
    %--
    set(qpsa('upper plot'),'ydir','reverse')
    if d3d_qp('selectfield','swept path port side')
        d3d_qp('axestype','Distance-Val')
        d3d_qp('linestyle','-')
        d3d_qp('addtoplot')
    end
    if d3d_qp('selectfield','swept path starboard side')
        d3d_qp('linestyle','--')
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    newylabel(qpsa,'swept path',0)
    %--
    qpsa('lower plot')
    if d3d_qp('selectfield','water depth')
        d3d_qp('linestyle','-')
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
end
%--------
lstyle = {'-','--','-.',':'};
lstylename = {'solid','dashed','dash-dotted','dotted'};
i=0;
if qp_settings('shipma_fige')
    lines = {'' '' '' ''};
    quants = {};
    if qp_settings('shipma_fige_wind')
        i=i+1;
        lines{1} = lstyle{i};
        quants{i} = sprintf('wind (%s)',lstylename{i});
    end
    if qp_settings('shipma_fige_waves')
        i=i+1;
        lines{2} = lstyle{i};
        quants{i} = sprintf('waves (%s)',lstylename{i});
    end
    if qp_settings('shipma_fige_swell')
        i=i+1;
        lines{3} = lstyle{i};
        quants{i} = sprintf('swell (%s)',lstylename{i});
    end
    if qp_settings('shipma_fige_banksuction')
        i=i+1;
        lines{4} = lstyle{i};
        quants{i} = sprintf('bank suction (%s)',lstylename{i});
    end
    if ~isempty(quants)
        quantstr = sprintf('%s, ',quants{:});
        quantstr(1) = upper(quantstr(1));
        quantstr = quantstr(1:end-2);
        commas = strfind(quantstr,',');
        if ~isempty(commas)
            quantstr = [quantstr(1:commas(end)-1) ' and' quantstr(commas(end)+1:end)];
        end
        caption = {'External forces plots' quantstr};
    else
        caption = 'External forces plots';
    end
    texts = local_strrep(texts_template,'%caption%',caption);
    d3d_qp('newfigure','3 plots, vertical - portrait','SHIPMA Fig E',texts)
    %--
    qpsa('upper plot')
    if qp_settings('shipma_fige_wind') && d3d_qp('selectfield','longitudinal wind force')
        d3d_qp('axestype','Distance-Val')
        d3d_qp('linestyle',lines{1})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_waves') && d3d_qp('selectfield','longitudinal wave force')
        d3d_qp('linestyle',lines{2})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_swell') && d3d_qp('selectfield','longitudinal swell force')
        d3d_qp('linestyle',lines{3})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_banksuction') && d3d_qp('selectfield','longitudinal bank suction force')
        d3d_qp('linestyle',lines{4})
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    newylabel(qpsa,'longitudinal forces',1)
    %--
    qpsa('middle plot')
    if qp_settings('shipma_fige_wind') && d3d_qp('selectfield','transverse wind force')
        d3d_qp('linestyle',lines{1})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_waves') && d3d_qp('selectfield','transverse wave force')
        d3d_qp('linestyle',lines{2})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_swell') && d3d_qp('selectfield','transverse swell force')
        d3d_qp('linestyle',lines{3})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_banksuction') && d3d_qp('selectfield','transverse bank suction force')
        d3d_qp('linestyle',lines{4})
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    newylabel(qpsa,'transverse forces',1)
    %--
    qpsa('lower plot')
    if qp_settings('shipma_fige_wind') && d3d_qp('selectfield','wind moment on ship')
        d3d_qp('linestyle',lines{1})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_waves') && d3d_qp('selectfield','wave moment')
        d3d_qp('linestyle',lines{2})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_swell') && d3d_qp('selectfield','swell moment')
        d3d_qp('linestyle',lines{3})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_fige_banksuction') && d3d_qp('selectfield','moment due to bank suction')
        d3d_qp('linestyle',lines{4})
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    newylabel(qpsa,'moment',1)
end
%--------
if qp_settings('shipma_figf')
    if qp_settings('shipma_figf_tugs')
        if qp_settings('shipma_figf_thrusters')
            caption = {'Tug and thrusters forces plots','Tug forces (solid) and thruster forces (dashed)'};
            lines = {'-' '--'};
        else
            caption = 'Tug forces plots';
            lines = {'-' ''};
        end
    elseif qp_settings('shipma_figf_thrusters')
        caption = 'Tug forces plots';
        lines = {'' '-'};
    else
        caption = '';
    end
    texts = local_strrep(texts_template,'%caption%',caption);
    d3d_qp('newfigure','3 plots, vertical - portrait','SHIPMA Fig F',texts)
    %--
    qpsa('upper plot')
    if qp_settings('shipma_figf_tugs') && d3d_qp('selectfield','longitudinal total tug force')
        d3d_qp('axestype','Distance-Val')
        d3d_qp('linestyle',lines{1})
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    newylabel(qpsa,'longitudinal force',1)
    %--
    qpsa('middle plot')
    if qp_settings('shipma_figf_tugs') && d3d_qp('selectfield','transverse total tug force')
        d3d_qp('linestyle',lines{1})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_figf_thrusters') && d3d_qp('selectfield','transverse thruster force')
        d3d_qp('linestyle',lines{2})
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    newylabel(qpsa,'transverse force',1)
    %--
    qpsa('lower plot')
    if qp_settings('shipma_figf_tugs') && d3d_qp('selectfield','total tug moment')
        d3d_qp('linestyle',lines{1})
        d3d_qp('addtoplot')
    end
    if qp_settings('shipma_figf_thrusters') && d3d_qp('selectfield','moment due to thrusters')
        d3d_qp('linestyle',lines{2})
        d3d_qp('addtoplot')
    end
    d3d_qp('axesgrid',1,1)
    d3d_qp('axesboxed',1)
    newylabel(qpsa,'moment',1)
end
%--------
d3d_qp('selectfield','default figures')
inSelfPlot=[];
% -----------------------------------------------------------------------------

function newylabel(ax,val,arrow)
hy=get(ax,'ylabel');
yu=getappdata(ax,'yunit');
if ~isempty(yu)
    yu = [' (' yu ')'];
end
if arrow
    arrowstr = ' \rightarrow';
else
    arrowstr = '';
end
set(hy,'string',[val yu arrowstr])


% -----------------------------------------------------------------------------
function Out=domains(FI)
Out=FI.Case.Name;
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,domain)
if domain > length(FI.Case.Project)
    prj='';
    cse='';
else
    prj=FI.Case.Project(domain);
    cse=FI.Case.Case(domain);
end
%
V=inf; % unknown/variable number of points indicated by infinity
PropNames={'Name'                   'Units' 'DimFlag'   'DataInCell' 'NVal' 'Geom'   'Coords' 'ClosedPoly' 'Project' 'Case' 'Var'   };
DataProps={'default figures'        ''      [0 0 0 0 0] 0            -2     ''       ''       0            prj       cse     0
    '-------'                       ''      [0 0 0 0 0] 0             0     ''       ''       0            prj       cse     0
    'desired ship track'            ''      [0 0 0 0 0] 0             0     'POLYL'  'xy'     0            prj       cse     -1
    'realized ship track'           ''      [9 0 0 0 0] 0             0     'PNT'    'xy'     0            prj       cse     0
    'distance ticks'                ''      [0 0 0 0 0] 0             0     'POLYL'  'xy'     0            prj       cse     0
    'distance value at ticks'       ''      [0 0 0 0 0] 0             4     'sQUAD'  'xy'     0            prj       cse     0
    'ship at distance ticks'        ''      [0 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     0
    'ship snapshots'                ''      [0 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     0
    'ship'                          ''      [9 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     0
    'swept path'                    ''      [0 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     0
    'fairway contour'               ''      [0 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     -1
    'bank suction lines'            ''      [0 0 0 0 0] 0             0     'POLYL'  'xy'     0            prj       cse     -1
    '-------'                       ''      [0 0 0 0 0] 0             0     ''       ''       0            prj       cse     0
    'wind'                          'm/s'   [0 0 V 0 0] 0             2     'TRI'    'xy'     0            prj       cse     -1
    'waves'                         'm'     [0 0 V 0 0] 0             2     'TRI'    'xy'     0            prj       cse     -1
    'swell'                         'm'     [0 0 V 0 0] 0             1     'TRI'    'xy'     0            prj       cse     -1
    'current'                       'm/s'   [0 0 V 0 0] 0             2     'TRI'    'xy'     0            prj       cse     -1
    'depth'                         'm'     [0 0 V 0 0] 0             1     'TRI'    'xy'     0            prj       cse     -1
    '-------'                       ''      [0 0 0 0 0] 0             0     ''       ''       0            prj       cse     0
    'speed'                         'm/s'   [9 0 0 0 0] 0             1     'PNT'    'd'      0            prj       cse     0
    'his-data'                      ''      [9 0 0 0 0] 0             1     'PNT'    'd'      0            prj       cse     0       };
Out=cell2struct(DataProps,PropNames,2);
%
if domain > length(FI.Case.Project)
    Out(1:end,:)=[];
    return
end
%
Proj = FI.Project(prj);
if isempty(Proj.Cases.Data(cse).TimeSeries)
    hisvars={};
else
    hisvars = Proj.Cases.Data(cse).TimeSeries.SubsName;
end
startVal = length(Out)-1;
nVal = length(hisvars);
Out = cat(1,Out(1:startVal),repmat(Out(end),nVal,1));
track = find(strcmpi('track [m]',hisvars));
for i=1:nVal
    var = hisvars{i};
    uStart = strfind(var,'[');
    name = translate(deblank(var(1:uStart-1)));
    unit = var(uStart+1:end-1);
    %
    hisvars{i} = name;
    Out(startVal+i).Name = name;
    Out(startVal+i).Units = unit;
    Out(startVal+i).Var = [i track];
end
%
for i = length(Out):-1:1
    switch Out(i).Name
        case 'x'
            Out(i)=[];
        case 'y'
            Out(i)=[];
        case 'wind'
            if ~Proj.Cases.Data(cse).windIsSelected || Proj.Cases.Data(cse).windNr<0
                Out(i)=[];
            elseif ~Proj.Environments.Winds.Data(Proj.Cases.Data(cse).windNr).fileSelected
                Out(i)=[];
            elseif isempty(Proj.Environments.Winds.Data(Proj.Cases.Data(cse).windNr).file)
                Out(i)=[];
            end
        case 'waves'
            if ~Proj.Cases.Data(cse).wavesIsSelected || Proj.Cases.Data(cse).wavesNr<0
                Out(i)=[];
            elseif ~Proj.Environments.Waves.Data(Proj.Cases.Data(cse).wavesNr).fileSelected
                Out(i)=[];
            elseif isempty(Proj.Environments.Waves.Data(Proj.Cases.Data(cse).wavesNr).file)
                Out(i)=[];
            end
        case 'swell'
            if ~Proj.Cases.Data(cse).swellIsSelected || Proj.Cases.Data(cse).swellNr<0
                Out(i)=[];
            elseif ~Proj.Environments.Swells.Data(Proj.Cases.Data(cse).swellNr).fileSelected
                Out(i)=[];
            elseif isempty(Proj.Environments.Swells.Data(Proj.Cases.Data(cse).swellNr).file)
                Out(i)=[];
            end
        case 'current'
            if ~Proj.Cases.Data(cse).currentIsSelected || Proj.Cases.Data(cse).currentNr<0
                Out(i)=[];
            elseif ~Proj.Environments.Currents.Data(Proj.Cases.Data(cse).currentNr).fileSelected
                Out(i)=[];
            elseif isempty(Proj.Environments.Currents.Data(Proj.Cases.Data(cse).currentNr).file)
                Out(i)=[];
            end
        case 'speed'
            u = find(strcmpi('longitudinal vessel speed',hisvars));
            v = find(strcmpi('transverse vessel speed',hisvars));
            if isempty(u) || isempty(v) || isempty(track)
                Out(i)=[];
            else
                Out(i).Var = [u v track];
            end
        case {'realized ship track','distance ticks','distance value at ticks'}
            x = find(strcmpi('x',hisvars));
            y = find(strcmpi('y',hisvars));
            if isempty(x) || isempty(y)
                Out(i)=[];
            else
                Out(i).Var = [x y];
            end
        case 'fairway contour'
            if ~Proj.Cases.Data(cse).sceneryIsSelected || ~exist(Proj.Sceneries.Data(Proj.Cases.Data(cse).sceneryNr).fairwayContourFile)
                Out(i)=[];
            end
        case 'bank suction lines'
            if ~Proj.Cases.Data(cse).sceneryIsSelected || ~exist(Proj.Sceneries.Data(Proj.Cases.Data(cse).sceneryNr).banksuctionFile)
                Out(i)=[];
            end
        case 'desired ship track'
            if ~exist(Proj.Cases.Data(cse).trackFile)
                Out(i)=[];
            end
        case {'ship','ship snapshots','ship at distance ticks','swept path'}
            x = find(strcmpi('x',hisvars));
            y = find(strcmpi('y',hisvars));
            dir = find(strcmpi('heading',hisvars));
            Out(i).Var = [x y dir];
            %
            ship = Proj.Cases.Data(cse).shipNr;
            icontour = ustrcmpi('contour',{Proj.Ships.Data(ship).Props.Quant});
            contour = Proj.Ships.Data(ship).Props(icontour).Value;
            %
            if isempty(x) || isempty(y) || isempty(dir)
                Out(i)=[];
            else
                switch Out(i).Name
                    case 'ship'
                        if isempty(contour)
                            Out(i) = [];
                        end
                    case {'ship at distance ticks','ship snapshots'}
                        Out(i).Var(4) = track;
                        if isempty(contour)
                            Out(i) = [];
                        end
                    case 'swept path'
                        loff = find(strcmpi('lateral offset (from desired track)',hisvars));
                        spp = find(strcmpi('swept path port side',hisvars));
                        sps = find(strcmpi('swept path starboard side',hisvars));
                        Out(i).Var(1,4:6) = [loff spp sps];
                end
            end
    end
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function sz=getsize(FI,Props)
T_=1; ST_=2; M_=3; N_=4; K_=5;
sz=[0 0 0 0 0];
%======================== SPECIFIC CODE =======================================
prj = Props.Project;
cse = Props.Case;
if Props.DimFlag(T_)
    sz(T_) = FI.Project(prj).Cases.Data(cse).TimeSeries.NTimes;
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function T=readtim(FI,Props,t)
prj = Props.Project;
cse = Props.Case;
%======================== SPECIFIC CODE =======================================
T = delwaq('read',FI.Project(prj).Cases.Data(cse).TimeSeries,1,1,t);
% -----------------------------------------------------------------------------

% -------------------------------------------------------------------------
function [NewFI,cmdargs]=options(FI,mfig,cmd,varargin)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE ===================================
Inactive=get(0,'defaultuicontrolbackground');
Active=[1 1 1];
NewFI=FI;
cmd=lower(cmd);
cmdargs={};
switch cmd
    case 'initialize'
        optfig(mfig);
        %
        h=findobj(mfig,'tag','spacestepval');
        step=qp_settings('shipma_spacestep');
        set(h,'string',step)
        %
        h=findobj(mfig,'tag','timestepval');
        step=qp_settings('shipma_timestep');
        set(h,'string',step)
        %
        h=findobj(mfig,'tag','shipma_distance_along_desired_trackval');
        step=qp_settings('shipma_distance_along_desired_track');
        set(h,'value',1+step)
        %
        zb = qp_settings('shipma_figa1_zoombox');
        for cellchari = {'a' 'a1' 'b' 'c' 'd' 'e' 'f'}
            chari = cellchari{1};
            h=findobj(mfig,'tag',['fig' chari]);
            v=qp_settings(['shipma_fig' chari]);
            set(h,'value',v)
            %
            switch chari
                case {'b','e','f'}
                    switch chari
                        case 'b'
                            taglist = {'figa_fairway','figa_banksuction','figa_depth', ...
                                'figa_contourstep','figa_contourstepval', ...
                                'figa_contourmax','figa_contourmaxval', ...
                                'figa1_xmin','figa1_xminval','figa1_xmax','figa1_xmaxval', ...
                                'figa1_ymin','figa1_yminval','figa1_ymax','figa1_ymaxval', 'figa1_zoombox', ...
                                'figb_list','figb_contourstep','figb_contourstepval', ...
                                'figb_contourmax','figb_contourmaxval'};
                            if get(findobj(mfig,'tag','figa1'),'value')
                                set(h,'string','Fig B, as Fig A1 replacing depth by')
                            else
                                set(h,'string','Fig B, as Fig A replacing depth by')
                            end
                        case 'e'
                            taglist = {'fige_wind','fige_waves','fige_swell','fige_banksuction'};
                        case 'f'
                            taglist = {'figf_tugs','figf_thrusters'};
                    end
                    for tg = taglist
                        h = findobj(mfig,'tag',tg{1});
                        opt = {};
                        vloc = v;
                        switch tg{1}
                            case {'figa_fairway','figa_banksuction'}
                                vloc = get(findobj(mfig,'tag','figa'),'value') || ...
                                    get(findobj(mfig,'tag','figa1'),'value') || ...
                                    v;
                                v2=qp_settings(['shipma_' tg{1}]);
                                opt = {'value',v2};
                            case 'figa_depth'
                                vloc = get(findobj(mfig,'tag','figa'),'value') || ...
                                    get(findobj(mfig,'tag','figa1'),'value');
                                v2=qp_settings(['shipma_' tg{1}]);
                                opt = {'value',v2};
                            case {'figa_contourstep','figa_contourmax'}
                                vloc = (get(findobj(mfig,'tag','figa'),'value') || ...
                                    get(findobj(mfig,'tag','figa1'),'value')) && ...
                                    get(findobj(mfig,'tag','figa_depth'),'value');
                            case {'figa_contourstepval','figa_contourmaxval'}
                                vloc = (get(findobj(mfig,'tag','figa'),'value') || ...
                                    get(findobj(mfig,'tag','figa1'),'value')) && ...
                                    get(findobj(mfig,'tag','figa_depth'),'value');
                                opt = {'string',qp_settings(['shipma_' tg{1}(1:end-3)])};
                            case {'figa1_xmin','figa1_xmax','figa1_ymin','figa1_ymax', ...
                                    'figa1_zoombox'}
                                vloc = get(findobj(mfig,'tag','figa1'),'value');
                            case {'figa1_xminval','figa1_xmaxval','figa1_yminval','figa1_ymaxval'}
                                switch tg{1}
                                    case 'figa1_xminval'
                                        iz=1;
                                    case 'figa1_xmaxval'
                                        iz=2;
                                    case 'figa1_yminval'
                                        iz=3;
                                    case 'figa1_ymaxval'
                                        iz=4;
                                end
                                vloc = get(findobj(mfig,'tag','figa1'),'value');
                                if ~isnan(zb(iz))
                                    opt = {'string',zb(iz)};
                                end
                            case {'figb_list','figb_contourstep','figb_contourmax'}
                            case {'figb_contourstepval','figb_contourmaxval'}
                                opt = {'string',qp_settings(['shipma_' tg{1}(1:end-3)])};
                            otherwise
                                v2=qp_settings(['shipma_' tg{1}]);
                                opt = {'value',v2};
                        end
                        if vloc
                            set(h,'enable','on',opt{:})
                            if strcmp(get(h,'style'),'popupmenu')
                                set(h,'backgroundcolor',Active)
                            end
                        else
                            set(h,'enable','off',opt{:})
                            if strcmp(get(h,'style'),'popupmenu')
                                set(h,'backgroundcolor',Inactive)
                            end
                        end
                    end
            end
        end
        %
        h=findobj(mfig,'tag','figb_list');
        quant=qp_settings('shipma_figb_quantity');
        str=get(h,'string');
        i=ustrcmpi(quant,str);
        if i>0
            set(h,'value',i)
        end
    case {'shipma_spacestep','shipma_timestep','shipma_figa_contourstep','shipma_figb_contourstep'}
        h = findobj(mfig,'tag',[cmd(8:end) 'val']);
        if isempty(varargin)
            step = get(h,'string');
        else
            step = varargin{1};
        end
        if ischar(step)
            step = str2double(step);
        end
        set(h,'string',sprintf('%g',step))
        qp_settings(cmd,step)
        cmdargs={cmd,step};
        
    case 'shipma_distance_along_desired_track'
        h = findobj(mfig,'tag',[cmd(8:end) 'val']);
        if isempty(varargin)
            val = get(h,'value')-1;
        else
            val = varargin{1};
        end
        if ischar(val)
            val = str2double(val);
        end
        set(h,'value',1+val)
        qp_settings(cmd,val)
        cmdargs={cmd,val};
        
    case 'shipma_figa1_zoombox'
        if isempty(varargin)
            % get from Fig A1 if exists, otherwise from Fig A if exists
            fg = 'A1';
            Figs = findall(0,'type','figure','name','QuickPlot: SHIPMA Fig A1');
            if isempty(Figs)
                fg = 'A';
                Figs = findall(0,'type','figure','name','QuickPlot: SHIPMA Fig A');
            end
            if length(Figs)>1
                ui_message('error','Multiple Fig %s open. Don''t know which one to use.',fg)
                return
            elseif isempty(Figs)
                ui_message('error','No Fig A or A1 open to get zoombox coordinates from.')
                return
            end
            Ax = findall(Figs,'type','axes','tag','plot area');
            if length(Ax)~=1
                ui_message('error','Invalid Fig %s found.',fg)
                return
            end
            xrange = get(Ax,'xlim');
            yrange = get(Ax,'ylim');
            val = [xrange yrange];
        else
            val = varargin{1};
            if ischar(val)
                val = str2vec(val);
            end
            if ~isequal(size(val),[1 4])
                error('Invalid zoombox specified; should be 1x4 array.')
            end
        end
        cmds = {'shipma_figa1_xmin','shipma_figa1_xmax','shipma_figa1_ymin','shipma_figa1_ymax'};
        for i = 1:4
            options(FI,mfig,cmds{i},val(i))
        end
        cmdargs={cmd,val};
        
    case {'shipma_figa1_xmin','shipma_figa1_xmax','shipma_figa1_ymin','shipma_figa1_ymax'}
        zb = qp_settings('shipma_figa1_zoombox');
        h = findobj(mfig,'tag',[cmd(8:end) 'val']);
        if isempty(varargin)
            val = get(h,'string');
        else
            val = varargin{1};
        end
        if ischar(val)
            val = str2double(val);
        end
        if isnan(val)
            set(h,'string','')
        else
            set(h,'string',sprintf('%g',val))
        end
        switch cmd
            case 'shipma_figa1_xmin'
                iz = 1;
            case 'shipma_figa1_xmax'
                iz = 2;
            case 'shipma_figa1_ymin'
                iz = 3;
            case 'shipma_figa1_ymax'
                iz = 4;
        end
        zb(iz) = val;
        qp_settings('shipma_figa1_zoombox',zb)
        cmdargs={cmd,val};
        
    case {'shipma_figa','shipma_figa1','shipma_figb','shipma_figc','shipma_figd','shipma_fige', ...
            'shipma_figa_fairway','shipma_figa_banksuction','shipma_figa_depth', ...
            'shipma_fige_wind','shipma_fige_waves','shipma_fige_swell','shipma_fige_banksuction', ...
            'shipma_figf','shipma_figf_tugs','shipma_figf_thrusters'}
        h = findobj(mfig,'tag',cmd(8:end));
        if isempty(varargin)
            v = get(h,'value');
        else
            v = varargin{1};
        end
        if ischar(v)
            v = str2double(v);
        end
        set(h,'value',v)
        qp_settings(cmd,v)
        %
        adjustv = 0;
        vloc = v;
        %
        if strcmp(cmd,'shipma_figa1') || strcmp(cmd,'shipma_figb')
            if get(findobj(mfig,'tag','figa1'),'value')
                set(findobj(mfig,'tag','figb'),'string','Fig B, as Fig A1 replacing depth by')
            else
                set(findobj(mfig,'tag','figb'),'string','Fig B, as Fig A replacing depth by')
            end
        end
        switch cmd
            case {'shipma_figa','shipma_figa1','shipma_figb'}
                taglist = {'figa_fairway','figa_banksuction','figa_depth', ...
                    'figa_contourstep','figa_contourstepval', ...
                    'figa_contourmax','figa_contourmaxval', ...
                    'figa1_xmin','figa1_xminval','figa1_xmax','figa1_xmaxval', ...
                    'figa1_ymin','figa1_yminval','figa1_ymax','figa1_ymaxval', ...
                    'figa1_zoombox', ...
                    'figb_list','figb_contourstep','figb_contourstepval', ...
                    'figb_contourmax','figb_contourmaxval'};
                adjustv = 1;
            case 'shipma_figa_depth'
                taglist = {'figa_contourstep','figa_contourstepval', ...
                    'figa_contourmax','figa_contourmaxval'};
            case 'shipma_fige'
                taglist = {'fige_wind','fige_waves','fige_swell','fige_banksuction'};
            case 'shipma_figf'
                taglist = {'figf_tugs','figf_thrusters'};
            otherwise
                taglist = {};
        end
        for tg = taglist
            h = findobj(mfig,'tag',tg{1});
            if adjustv
                switch tg{1}
                    case {'figa_fairway','figa_banksuction'}
                        vloc = get(findobj(mfig,'tag','figa'),'value') || ...
                            get(findobj(mfig,'tag','figa1'),'value') || ...
                            get(findobj(mfig,'tag','figb'),'value');
                    case {'figa_depth'}
                        vloc = get(findobj(mfig,'tag','figa'),'value') || ...
                            get(findobj(mfig,'tag','figa1'),'value');
                    case {'figa_contourstep','figa_contourstepval','figa_contourmax','figa_contourmaxval'}
                        vloc = (get(findobj(mfig,'tag','figa'),'value') || ...
                            get(findobj(mfig,'tag','figa1'),'value')) && ...
                            get(findobj(mfig,'tag','figa_depth'),'value');
                    case {'figa1_xmin','figa1_xminval','figa1_xmax','figa1_xmaxval', ...
                            'figa1_ymin','figa1_yminval','figa1_ymax','figa1_ymaxval', ...
                            'figa1_zoombox'}
                        vloc = get(findobj(mfig,'tag','figa1'),'value');
                    case {'figb_list','figb_contourstep','figb_contourstepval','figb_contourmax','figb_contourmaxval'}
                        vloc = get(findobj(mfig,'tag','figb'),'value');
                    otherwise
                        vloc = 0;
                end
            end
            if vloc
                set(h,'enable','on')
                if strcmp(get(h,'style'),'popupmenu')
                    set(h,'backgroundcolor',Active)
                end
            else
                set(h,'enable','off')
                if strcmp(get(h,'style'),'popupmenu')
                    set(h,'backgroundcolor',Inactive)
                end
            end
        end
        cmdargs={cmd,v};
    case {'shipma_figb_quantity'}
        h = findobj(mfig,'tag','figb_list');
        str = get(h,'string');
        if isempty(varargin)
            i = get(h,'value');
            v = str{i};
        else
            v = varargin{1};
        end
        i = ustrcmpi(v,str);
        if i>0
            set(h,'value',i)
            qp_settings(cmd,str{i})
            cmdargs={cmd,str{i}};
        end
    case 'editborder'
        fg=figure('visible','off', ...
            'integerhandle','off', ...
            'numbertitle','off', ...
            'name','SHIPMA');
        hBorder=md_paper(fg,'no edit','a4p','7box',get_shipma_bordertexts);
        md_paper('editmodal',hBorder)
        for i=1:7
            h = findall(hBorder,'tag',sprintf('plottext%i',i));
            str = get(h,'string');
            if ischar(str) && size(str,1)>1
                str = cellstr(str);
            end
            if iscell(str)
                str = str';
                str(2,:)={'\n{}'};
                str(2,end)={''};
                str = strcat(str{:});
            end
            qp_settings(sprintf('shipma_bordertext%i_string',i),str)
        end
        delete(fg)
    otherwise
        error(['Unknown option command: ',cmd])
end
% -------------------------------------------------------------------------


function c = get_shipma_bordertexts
c = cell(1,7);
for i = 1:7
    str = qp_settings(sprintf('shipma_bordertext%i_string',i));
    str = strrep(str,'\n{}',char(13));
    str = splitcellstr(str,char(13));
    c{i} = str;
end

function d = local_strrep(c,key,val)
lkey = lower(key);
lenkey = length(key);
%
d = cell(size(c));
if iscell(val)
    val = val(:)';
    val(2,:)={char(13)};
    val(2,end)={''};
    val = [val{:}];
    breakapart = 1;
else
    breakapart = 0;
end
for i = 1:length(c)
    found = 0;
    for j = 1:length(c{i})
        k = strfind(lower(c{i}{j}),lkey);
        for ik = 1:length(k)
            found = 1;
            c{i}{j}(k(ik)+(0:lenkey-1)) = lkey;
        end
    end
    d{i} = strrep(c{i},lkey,val);
    if found && breakapart
        cstr = d{i}(:)';
        cstr(2,:)={char(13)};
        cstr(2,end)={''};
        cstr = [cstr{:}];
        d{i} = splitcellstr(cstr,char(13));
    end
end

% -------------------------------------------------------------------------
function OK=optfig(h0)
Inactive=qp_settings('UIInActiveColor');
Active=qp_settings('UIActiveColor');
FigPos=get(h0,'position');
FigPos(3) = 680;
set(h0,'position',FigPos)
voffset=FigPos(4)-30;
textwidth=340-80-30; %FigPos(3)-80-30
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[11 voffset textwidth 18], ...
    'String','Space Step for Distance Ticks (m)', ...
    'Enable','on', ...
    'Tag','spacestep');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_spacestep', ...
    'Position',[21+textwidth voffset 80 20], ...
    'Enable','on', ...
    'Tag','spacestepval');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[11 voffset textwidth-50 18], ...
    'String','Distance Measured Along', ...
    'Enable','on', ...
    'Tag','distance_along_desired_track');
uicontrol('Parent',h0, ...
    'Style','popupmenu', ...
    'String',{'Realized Track','Desired Track'}, ...
    'Value',2, ...
    'HorizontalAlignment','left', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_distance_along_desired_track', ...
    'Position',[21+textwidth-50 voffset 80+50 20], ...
    'Enable','on', ...
    'Tag','distance_along_desired_trackval');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[11 voffset textwidth 18], ...
    'String','Time Step for Ship Snapshots (s)', ...
    'Enable','on', ...
    'Tag','timestep');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_timestep', ...
    'Position',[21+textwidth voffset 80 20], ...
    'Enable','on', ...
    'Tag','timestepval');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[11 voffset textwidth-50 18], ...
    'String','Default Figures:', ...
    'Enable','on');
uicontrol('Parent',h0, ...
    'Style','pushbutton', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[21+textwidth-50 voffset 80+50 20], ...
    'String','Edit Border Text', ...
    'Callback','d3d_qp fileoptions editborder', ...
    'Enable','on', ...
    'Tag','editborder');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[21 voffset textwidth-10 18], ...
    'String','Fig A, overview plot', ...
    'Callback','d3d_qp fileoptions shipma_figa', ...
    'Enable','on', ...
    'Tag','figa');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[41 voffset 80 18], ...
    'String','fairway', ...
    'Callback','d3d_qp fileoptions shipma_figa_fairway', ...
    'Enable','on', ...
    'Tag','figa_fairway');
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[131 voffset 80 18], ...
    'String','bank suction', ...
    'Callback','d3d_qp fileoptions shipma_figa_banksuction', ...
    'Enable','on', ...
    'Tag','figa_banksuction');
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[221 voffset 80 18], ...
    'String','depth', ...
    'Callback','d3d_qp fileoptions shipma_figa_depth', ...
    'Enable','on', ...
    'Tag','figa_depth');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[41 voffset 80 18], ...
    'String','Contour step', ...
    'Enable','on', ...
    'Tag','figa_contourstep');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figa_contourstep', ...
    'Position',[131 voffset 60 20], ...
    'Enable','on', ...
    'Tag','figa_contourstepval');
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[201 voffset 40 18], ...
    'String','Max', ...
    'Enable','on', ...
    'Tag','figa_contourmax');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figa_contourmax', ...
    'Position',[251 voffset 80 20], ...
    'Enable','on', ...
    'Tag','figa_contourmaxval');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[21 voffset textwidth-10 18], ...
    'String','Fig A1, zoomed version of Fig A', ...
    'Callback','d3d_qp fileoptions shipma_figa1', ...
    'Enable','on', ...
    'Tag','figa1');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[41 voffset 40 18], ...
    'String','X Min', ...
    'Enable','on', ...
    'Tag','figa1_xmin');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figa1_xmin', ...
    'Position',[81 voffset 75 20], ...
    'Enable','on', ...
    'Tag','figa1_xminval');
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[161 voffset 40 18], ...
    'String','X Max', ...
    'Enable','on', ...
    'Tag','figa1_xmax');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figa1_xmax', ...
    'Position',[201 voffset 75 20], ...
    'Enable','on', ...
    'Tag','figa1_xmaxval');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[41 voffset 40 18], ...
    'String','Y Min', ...
    'Enable','on', ...
    'Tag','figa1_ymin');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figa1_ymin', ...
    'Position',[81 voffset 75 20], ...
    'Enable','on', ...
    'Tag','figa1_yminval');
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[161 voffset 40 18], ...
    'String','Y Max', ...
    'Enable','on', ...
    'Tag','figa1_ymax');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figa1_ymax', ...
    'Position',[201 voffset 75 20], ...
    'Enable','on', ...
    'Tag','figa1_ymaxval');
uicontrol('Parent',h0, ...
    'Style','pushbutton', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Inactive, ...
    'Callback','d3d_qp fileoptions shipma_figa1_zoombox', ...
    'Position',[286 voffset 45 45], ...
    'Max',2, ...
    'CData',qp_icon('getaxesdims','nan'), ...
    'Enable','on', ...
    'Tooltip','Get zoombox from Fig A1 or A', ...
    'Tag','figa1_zoombox');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[21 voffset textwidth 18], ...
    'String','Fig B, as Fig A1 replacing depth by', ...
    'Callback','d3d_qp fileoptions shipma_figb', ...
    'Enable','on', ...
    'Tag','figb');
uicontrol('Parent',h0, ...
    'Style','popupmenu', ...
    'BackgroundColor',Active, ...
    'Horizontalalignment','left', ...
    'Position',[21+textwidth voffset 80 20], ...
    'String',{'wind','waves','current'}, ...
    'Callback','d3d_qp fileoptions shipma_figb_quantity', ...
    'Enable','on', ...
    'Tag','figb_list');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[41 voffset 80 18], ...
    'String','Contour step', ...
    'Enable','on', ...
    'Tag','figb_contourstep');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figb_contourstep', ...
    'Position',[131 voffset 60 20], ...
    'Enable','on', ...
    'Tag','figb_contourstepval');
uicontrol('Parent',h0, ...
    'Style','text', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[201 voffset 40 18], ...
    'String','Max', ...
    'Enable','on', ...
    'Tag','figb_contourmax');
uicontrol('Parent',h0, ...
    'Style','edit', ...
    'HorizontalAlignment','right', ...
    'BackgroundColor',Active, ...
    'Callback','d3d_qp fileoptions shipma_figb_contourmax', ...
    'Position',[251 voffset 80 20], ...
    'Enable','on', ...
    'Tag','figb_contourmaxval');
voffset=FigPos(4)-130;
hoffset=340;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+21 voffset textwidth-10 18], ...
    'String','Fig C, speed and rudder angle plots', ...
    'Callback','d3d_qp fileoptions shipma_figc', ...
    'Enable','on', ...
    'Tag','figc');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+21 voffset textwidth-10 18], ...
    'String','Fig D, swept path and depth plots', ...
    'Callback','d3d_qp fileoptions shipma_figd', ...
    'Enable','on', ...
    'Tag','figd');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+21 voffset textwidth-10 18], ...
    'String','Fig E, external forces plots', ...
    'Callback','d3d_qp fileoptions shipma_fige', ...
    'Enable','on', ...
    'Tag','fige');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+41 voffset 80 18], ...
    'String','wind', ...
    'Callback','d3d_qp fileoptions shipma_fige_wind', ...
    'Enable','on', ...
    'Tag','fige_wind');
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+131 voffset 80 18], ...
    'String','waves', ...
    'Callback','d3d_qp fileoptions shipma_fige_waves', ...
    'Enable','on', ...
    'Tag','fige_waves');
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+221 voffset 80 18], ...
    'String','swell', ...
    'Callback','d3d_qp fileoptions shipma_fige_swell', ...
    'Enable','on', ...
    'Tag','fige_swell');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+41 voffset 80 18], ...
    'String','bank suction', ...
    'Callback','d3d_qp fileoptions shipma_fige_banksuction', ...
    'Enable','on', ...
    'Tag','fige_banksuction');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+21 voffset textwidth-10 18], ...
    'String','Fig F, tugs and thrusters plots', ...
    'Callback','d3d_qp fileoptions shipma_figf', ...
    'Enable','on', ...
    'Tag','figf');
voffset=voffset-25;
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+41 voffset 80 18], ...
    'String','tugs', ...
    'Callback','d3d_qp fileoptions shipma_figf_tugs', ...
    'Enable','on', ...
    'Tag','figf_tugs');
uicontrol('Parent',h0, ...
    'Style','checkbox', ...
    'BackgroundColor',Inactive, ...
    'Horizontalalignment','left', ...
    'Position',[hoffset+131 voffset 80 18], ...
    'String','thrusters', ...
    'Callback','d3d_qp fileoptions shipma_figf_thrusters', ...
    'Enable','on', ...
    'Tag','figf_thrusters');
OK=1;
% -------------------------------------------------------------------------


function s2 = translate(s1)
table = {'track' 'track distance'
    'psi' 'course (earth-fixed coords)'
    'Heading' 'heading'
    'dy' 'lateral offset (from desired track)'
    'dpsi' 'course deviation'
    'u' 'longitudinal vessel speed'
    'v' 'transverse vessel speed'
    'r' 'rate of turn'
    'rudder1' 'rudder angle'
    'n1' 'propeller speed'
    'h' 'water depth'
    'Vwind' 'wind speed'
    'phiwind' 'wind direction (earth-fixed coords)'
    'Xwind' 'longitudinal wind force'
    'Ywind' 'transverse wind force'
    'Nwind' 'wind moment on ship'
    'Hwave' 'Hs sea waves'
    'phiwave' 'direction sea waves (earth-fixed coords)'
    'Xwave' 'longitudinal wave force'
    'Ywave' 'transverse wave force'
    'Nwave' 'wave moment'
    'Hswl' 'Hs swell waves'
    'phiswl' 'direction swell waves (earth-fixed coords)'
    'Xswl' 'longitudinal swell force'
    'Yswl' 'transverse swell force'
    'Nswl' 'swell moment'
    'uc' 'longitudinal current velocity over ground'
    'vc' 'transverse current velocity over ground'
    'rc' 'rotational current velocity'
    'Xtugs' 'longitudinal total tug force'
    'Ytugs' 'transverse total tug force'
    'Ntugs' 'total tug moment'
    'YThrusters' 'transverse thruster force'
    'NThrusters' 'moment due to thrusters'
    'Xbank' 'longitudinal bank suction force'
    'Ybank' 'transverse bank suction force'
    'Nbank' 'moment due to bank suction'
    'Xhull' 'longitudinal hydrodynamic hull forces'
    'Yhull' 'transverse hydrodynamic hull forces'
    'Nhull' 'moment due to hydrodynamic hull forces'
    'Xrudprop' 'longitudinal control forces'
    'Yrudprop' 'latereal control forces'
    'Nrudprop' 'moment from control forces'
    'dp1' 'rate of rudder change'
    'up' 'ship acceleration in longitudinal direction'
    'vp' 'ship acceleration in transverse direction'
    'rp' 'yaw acceleration'
    'ucp' 'acceleration of current in longitudinal direction'
    'vcp' 'acceleration of current in transverse direction'
    'rcp' 'acceleration of rotational current'
    'Xtug1' 'first tug force in ship''s longitudinal direction'
    'Ytug1' 'first tug force in ship''s transverse direction'
    'Ntug1' 'moment due to first tug forces'
    'Towforce tug1' 'total tow force of first tug'
    'Towdir. tug1' 'tow direction of first tug (rel. to ship)'
    'Xtug2' 'second tug force in ship''s longitudinal direction'
    'Ytug2' 'second tug force in ship''s transverse direction'
    'Ntug2' 'moment due to second tug forces'
    'Towforce tug2' 'total tow force of second tug'
    'Towdir. tug2' 'tow direction of second tug (rel. to ship)'
    'Xtug3' 'third tug force in ship''s longitudinal direction'
    'Ytug3' 'third tug force in ship''s transverse direction'
    'Ntug3' 'moment due to third tug forces'
    'Towforce tug3' 'total tow force of third tug'
    'Towdir. tug3' 'tow direction of third tug (rel. to ship)'
    'Xtug4' 'fourth tug force in ship''s longitudinal direction'
    'Ytug4' 'fourth tug force in ship''s transverse direction'
    'Ntug4' 'moment due to fourth tug forces'
    'Towforce tug4' 'total tow force of fourth tug'
    'Towdir. tug4' 'tow direction of fourth tug (rel. to ship)'
    'Xtug5' 'fifth tug force in ship''s longitudinal direction'
    'Ytug5' 'fifth tug force in ship''s transverse direction'
    'Ntug5' 'moment due to fifth tug forces'
    'Towforce tug5' 'total tow force of fifth tug'
    'Towdir. tug5' 'tow direction of fifth tug (rel. to ship)'
    'Xtug6' 'sixth tug force in ship''s longitudinal direction'
    'Ytug6' 'sixth tug force in ship''s transverse direction'
    'Ntug6' 'moment due to sixth tug forces'
    'Towforce tug6' 'total tow force of sixth tug'
    'Towdir. tug6' 'tow direction of sixth tug (rel. to ship)'
    'Xtug7' 'seventh tug force in ship''s longitudinal direction'
    'Ytug7' 'seventh tug force in ship''s transverse direction'
    'Ntug7' 'moment due to seventh tug forces'
    'Towforce tug7' 'total tow force of seventh tug'
    'Towdir. tug7' 'tow direction of seventh tug (rel. to ship)'
    'Xtug8' 'eighth tug force in ship''s longitudinal direction'
    'Ytug8' 'eighth tug force in ship''s transverse direction'
    'Ntug8' 'moment due to eighth tug forces'
    'Towforce tug8' 'total tow force of eighth tug'
    'Towdir. tug8' 'tow direction of eighth tug (rel. to ship)'
    'swept path port' 'swept path port side'
    'swept path stb.' 'swept path starboard side'};
is1 = strcmpi(s1,table(:,1));
if ~any(is1)
    s2 = s1;
else
    s2 = table{is1,2};
end

function d = realized_track_distance(PRJ,cse,idx)
hisvars = PRJ.Cases.Data(cse).TimeSeries.SubsName;
x = find(strcmpi('x [m]',hisvars));
y = find(strcmpi('y [m]',hisvars));
[T,val1] = delwaq('read',PRJ.Cases.Data(cse).TimeSeries,[x y],1,0);
d = pathdistance(val1(1,:),val1(2,:))';
if ~isequal(idx{1},0)
    d = Ans.X(idx{1});
end


function dc = classify(d,dtick)
if ~isequal(dtick,sort(dtick))
    error('Ticks must be sorted.')
end
dc = zeros(size(d));
for i = 1:length(dtick)
   dc = dc + (d>dtick(i));
end


function id = crossings(d,dtick)
dc = classify(d,dtick); % determine class for each data value
idc = find(diff(dc)); % find class transitions
id = zeros(1,length(idc)*length(dtick)); % a class transition may go through multiple class boundaries
k = 0;
for j = 1:length(idc) % for each class transition
    d1 = d(idc(j));
    c1 = dc(idc(j));
    d2 = d(idc(j)+1);
    c2 = dc(idc(j)+1);
    if c1<c2 % going to higher class
        range = c1+1:c2;
    else % going to lower class
        range = c1:-1:c2+1;
    end
    for c = range
        k = k+1;
        id(k) = idc(j) + (dtick(c)-d1)/(d2-d1);
    end
end
id(:,k+1:end) = [];