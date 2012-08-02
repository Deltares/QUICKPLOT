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
%   Copyright (C) 2011-2012 Stichting Deltares.
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
                [Ans.X,Ans.Y] = landboundary('read',FileName);
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
            [Ans.X,Ans.Y] = landboundary('read',PRJ.Cases.Data(cse).trackFile);
        case 'distance ticks'
            [x,y] = landboundary('read',PRJ.Cases.Data(cse).trackFile);
            d = pathdistance(x,y);
            doublepoints = find(diff(d)==0)+1;
            x(doublepoints) = [];
            y(doublepoints) = [];
            d(doublepoints) = [];
            dtick = (0:500:max(d))';
            xtick = interp1(d,x,dtick);
            ytick = interp1(d,y,dtick);
            itick = min(length(d)-1,floor(interp1(d,1:length(d),dtick)));
            dx = diff(x);
            dy = diff(y);
            ds = sqrt(dx.^2+dy.^2);
            dx = dx./ds;
            dy = dy./ds;
            width = 100;
            x0 = [xtick-width*dy(itick) xtick+width*dy(itick)];
            y0 = [ytick+width*dx(itick) ytick-width*dx(itick)];
            x0 = x0';
            x0(3,:) = NaN;
            y0 = y0';
            y0(3,:) = NaN;
            Ans.X = x0;
            Ans.Y = y0;
        case 'ship track'
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
        case 'ship'
            ship = PRJ.Cases.Data(cse).shipNr;
            icontour = ustrcmpi('contour',{PRJ.Ships.Data(ship).Props.Quant});
            contour = PRJ.Ships.Data(ship).Props(icontour).Value;
            alf = val1(3)*pi/180;
            Ans.X = contour(:,1)*sin(alf)+contour(:,2)*cos(alf)+val1(1);
            Ans.Y = -contour(:,2)*sin(alf)+contour(:,1)*cos(alf)+val1(2);
        case 'ship at distance ticks'
            ship = PRJ.Cases.Data(cse).shipNr;
            icontour = ustrcmpi('contour',{PRJ.Ships.Data(ship).Props.Quant});
            contour = PRJ.Ships.Data(ship).Props(icontour).Value;
            %
            d = val1(4,:);
            dtick = (0:500:max(d))';
            xtick = interp1(d,val1(1,:),dtick);
            ytick = interp1(d,val1(2,:),dtick);
            itick = interp1(d,1:size(val1,3),dtick);
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
            numS = length(dtick);
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
            Ans.X = val1(3,:)';
            Ans.Val = sqrt(val1(1,:).^2 + val1(2,:).^2)';
        otherwise
            Ans.X = val1(2,:)'; %pathdistance(x,y) rather than distance from file?
            Ans.Val = val1(1,:)';
    end
elseif Props.NVal==4
    switch Props.Name
        case 'distance tick labels'
            [x,y] = landboundary('read',PRJ.Cases.Data(cse).trackFile);
            d = pathdistance(x,y);
            doublepoints = find(diff(d)==0)+1;
            x(doublepoints) = [];
            y(doublepoints) = [];
            d(doublepoints) = [];
            dtick = (0:500:max(d))';
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

if isempty(FI.Project(prj).Cases.Data(cse).TimeSeries)
    shipma = '';
else
    headerLine = FI.Project(prj).Cases.Data(cse).TimeSeries.Header(1,:);
    [shipma,rem] = strtok(headerLine);
    version = strtok(rem);
    shipma = [shipma ' ' version];
end
texts = {'' protectstring(FI.Project(prj).Name) protectstring(FI.Project(prj).Cases.Names{cse}) shipma};
%
texts{1} = 'Track plot and depth';
d3d_qp('newfigure','1 plot - portrait','SHIPMA Fig A',texts)
if d3d_qp('selectfield','depth')
  d3d_qp('colourmap','navdepth')
  d3d_qp('presenttype','contour patches')
  d3d_qp('thresholds',0:5:20)
  d3d_qp('colbarhorz',1)
  d3d_qp('addtoplot')
end
if d3d_qp('selectfield','fairway contour')
    d3d_qp('linestyle','-')
    d3d_qp('colour',[ 0 0 0 ])
    d3d_qp('fillpolygons',1)
    d3d_qp('facecolour',[ 1 1 0.2 ])
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','desired ship track')
    d3d_qp('addtoplot')
    a=d3d_qp('loaddata'); % get ship track for auto zoom limits
else
    a=[];
end
if d3d_qp('selectfield','ship at distance ticks')
    d3d_qp('facecolour',[ 1 0 0 ])
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','distance ticks')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','distance tick labels')
    d3d_qp('presenttype','labels')
    d3d_qp('fontsize',6)
    d3d_qp('addtoplot')
end
d3d_qp('axesboxed',1)
if ~isempty(a)
    xrange = [min(a.X) max(a.X)];
    xrange = xrange + [-1 1]*0.1*diff(xrange);
    yrange = [min(a.Y) max(a.Y)];
    yrange = yrange + [-1 1]*0.1*diff(yrange);
    fac = 1.25;
    yrange = mean(yrange)+[-1 1]*max(diff(xrange)*fac,diff(yrange))/2;
    xrange = mean(xrange)+[-1 1]*diff(yrange)/fac/2;
    d3d_qp('axeslimits',xrange,yrange)
end
%--------
texts{1} = 'Track plot and currents';
d3d_qp('newfigure','1 plot - portrait','SHIPMA Fig B',texts)
if d3d_qp('selectfield','current')
    d3d_qp('component','magnitude')
    d3d_qp('presenttype','contour patches')
    d3d_qp('thresholds',0:0.05:0.25)
    d3d_qp('colourmap','revhot')
    d3d_qp('addtoplot')
    d3d_qp('component','vector')
    d3d_qp('colourvectors',0)
    d3d_qp('colour',[ 0 0 1 ])
    d3d_qp('thinfld','distance')
    d3d_qp('thindist',diff(xrange)/100)
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','fairway contour')
    d3d_qp('colour',[ 0 0 0 ])
    d3d_qp('facecolour',[ 1 1 0.2 ])
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','desired ship track')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','ship at distance ticks')
    d3d_qp('facecolour',[ 1 0 0 ])
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','distance ticks')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','distance tick labels')
    d3d_qp('presenttype','labels')
    d3d_qp('fontsize',6)
    d3d_qp('addtoplot')
end
d3d_qp('axesboxed',1)
if ~isempty(a)
    d3d_qp('axeslimits',xrange,yrange)
end
%--------
texts{1} = 'Speed and ruddle angle plots';
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
%--------
texts{1} = 'Swept path and depth along track';
d3d_qp('newfigure','2 plots, vertical - portrait','SHIPMA Fig D',texts)
%--
set(qpsa('upper plot'),'ydir','reverse')
if d3d_qp('selectfield','swept path port side')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','swept path starboard side')
    d3d_qp('linestyle','--')
    d3d_qp('addtoplot')
end
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--
qpsa('lower plot')
if d3d_qp('selectfield','water depth')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--------
texts{1} = 'External forces plots';
d3d_qp('newfigure','3 plots, vertical - portrait','SHIPMA Fig E',texts)
%--
qpsa('upper plot')
if d3d_qp('selectfield','longitudinal wind force')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','longitudinal wave force')
    d3d_qp('linestyle','--')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','longitudinal swell force')
    d3d_qp('linestyle','-.')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','longitudinal bank suction force')
    d3d_qp('linestyle',':')
    d3d_qp('addtoplot')
end
%xlabel(qpsa,'longitudinal forces (unit?)')
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--
qpsa('middle plot')
if d3d_qp('selectfield','transverse wind force')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','transverse wave force')
    d3d_qp('linestyle','--')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','transverse swell force')
    d3d_qp('linestyle','-.')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','transverse bank suction force')
    d3d_qp('linestyle',':')
    d3d_qp('addtoplot')
end
%xlabel(qpsa,'transverse forces (unit?)')
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--
qpsa('lower plot')
if d3d_qp('selectfield','wind moment on ship')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','wave moment')
    d3d_qp('linestyle','--')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','swell moment')
    d3d_qp('linestyle','-.')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','moment due to bank suction')
    d3d_qp('linestyle',':')
    d3d_qp('addtoplot')
end
%xlabel(qpsa,'moment on ship (unit?)')
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--------
texts{1} = 'Tug and thrusters forces plots';
d3d_qp('newfigure','3 plots, vertical - portrait','SHIPMA Fig F',texts)
%--
qpsa('upper plot')
if d3d_qp('selectfield','longitudinal total tug force')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--
qpsa('middle plot')
if d3d_qp('selectfield','transverse total tug force')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','transverse thruster force')
    d3d_qp('linestyle','--')
    d3d_qp('addtoplot')
end
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--
qpsa('lower plot')
if d3d_qp('selectfield','total tug moment')
    d3d_qp('linestyle','-')
    d3d_qp('addtoplot')
end
if d3d_qp('selectfield','moment due to thrusters')
    d3d_qp('linestyle','--')
    d3d_qp('addtoplot')
end
d3d_qp('axesgrid',1,1)
d3d_qp('axesboxed',1)
%--------
d3d_qp('selectfield','default figures')
inSelfPlot=[];
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=domains(FI)
Out=FI.Case.Name;
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,domain)
prj=FI.Case.Project(domain);
cse=FI.Case.Case(domain);
%======================== SPECIFIC CODE =======================================
V=inf; % unknown/variable number of points indicated by infinity
PropNames={'Name'               'Units' 'DimFlag'   'DataInCell' 'NVal' 'Geom'   'Coords' 'ClosedPoly' 'Project' 'Case' 'Var'   };
DataProps={'default figures'    ''      [0 0 0 0 0] 0            -2     ''       ''       0            prj       cse     0
    '-------'                   ''      [0 0 0 0 0] 0             0     ''       ''       0            prj       cse     0
    'desired ship track'        ''      [0 0 0 0 0] 0             0     'POLYL'  'xy'     0            prj       cse     -1
    'distance ticks'            ''      [0 0 0 0 0] 0             0     'POLYL'  'xy'     0            prj       cse     -1
    'distance tick labels'      ''      [0 0 0 0 0] 0             4     'sQUAD'  'xy'     0            prj       cse     -1
    'ship at distance ticks'    ''      [0 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     0
    'ship track'                ''      [9 0 0 0 0] 0             0     'PNT'    'xy'     0            prj       cse     0
    'ship'                      ''      [9 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     0
    'swept path'                ''      [0 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     0
    'fairway contour'           ''      [0 0 0 0 0] 0             0     'POLYG'  'xy'     1            prj       cse     -1
    'bank suction lines'        ''      [0 0 0 0 0] 0             0     'POLYL'  'xy'     0            prj       cse     -1
    '-------'                   ''      [0 0 0 0 0] 0             0     ''       ''       0            prj       cse     0
    'wind'                      'm/s'   [0 0 V 0 0] 0             2     'TRI'    'xy'     0            prj       cse     -1
    'waves'                     'm'     [0 0 V 0 0] 0             2     'TRI'    'xy'     0            prj       cse     -1
    'swell'                     'm'     [0 0 V 0 0] 0             1     'TRI'    'xy'     0            prj       cse     -1
    'current'                   'm/s'   [0 0 V 0 0] 0             2     'TRI'    'xy'     0            prj       cse     -1
    'depth'                     'm'     [0 0 V 0 0] 0             1     'TRI'    'xy'     0            prj       cse     -1
    '-------'                   ''      [0 0 0 0 0] 0             0     ''       ''       0            prj       cse     0
    'speed'                     'm/s'   [9 0 0 0 0] 0             1     'PNT'    'd'      0            prj       cse     0
    'his-data'                  ''      [9 0 0 0 0] 0             1     'PNT'    'd'      0            prj       cse     0       };
Out=cell2struct(DataProps,PropNames,2);
%======================== SPECIFIC CODE DIMENSIONS ============================
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
        case 'ship track'
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
        case {'desired ship track','distance ticks','distance tick labels'}
            if ~exist(Proj.Cases.Data(cse).trackFile)
                Out(i)=[];
            end
        case {'ship','ship at distance ticks','swept path'}
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
                    case 'ship at distance ticks'
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