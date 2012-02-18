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

% read data ...
if all(Props.Var>=0)
    [T,val1] = delwaq('read',FI.Cases.Data(domain).TimeSeries,Props.Var,1,idx{1});
else
    T=[];
end

% generate output ...
if Props.NVal==0
    switch Props.Name
        case 'fairway contour'
            [Ans.X,Ans.Y] = landboundary('read',FI.Sceneries.Data(FI.Cases.Data.sceneryNr).fairwayContourFile);
        case 'bank suction lines'
            bsFI = tekal('open',FI.Sceneries.Data(FI.Cases.Data.sceneryNr).banksuctionFile,'nskipdatalines',1);
            XY = tekal('read',bsFI,1:2);
            Ans.X = [XY{1}(:,1);NaN;XY{2}(:,1)];
            Ans.Y = [XY{1}(:,2);NaN;XY{2}(:,2)];
        case 'ship track'
            Ans.X = squeeze(val1(1,1,:));
            Ans.Y = squeeze(val1(2,1,:));
        case 'ship'
            ship = FI.Cases.Data(domain).shipNr;
            icontour = ustrcmpi('contour',{FI.Ships(ship).Data.Props.Quant});
            contour = FI.Ships(ship).Data.Props(icontour).Value;
            alf = val1(3)*pi/180;
            Ans.X = contour(:,1)*sin(alf)+contour(:,2)*cos(alf)+val1(1);
            Ans.Y = -contour(:,2)*sin(alf)+contour(:,1)*cos(alf)+val1(2);
    end
    Ans.XUnits = 'm';
    Ans.YUnits = 'm';
elseif Props.NVal==1
    switch Props.Name
        case 'depth'
            btFI = samples('read',FI.Sceneries.Data(FI.Cases.Data.sceneryNr).bottomFile);
            Ans.XYZ = reshape(btFI.XYZ,[1 size(btFI.XYZ,1) 1 3]);
            Ans.TRI = delaunay(btFI.XYZ(:,1),btFI.XYZ(:,2));
            Ans.Val = btFI.XYZ(:,3);
        case 'speed'
            Ans.Val = sqrt(val1(1,:).^2 + val1(2,:).^2)';
        otherwise
            Ans.Val = val1;
    end
else
    switch Props.Name
        case 'wind'
            wFI = shipma('openpar',FI.Environments.Winds(FI.Cases.Data.windNr).Data.file,'wind');
            Ans.XYZ = reshape(wFI.XY,[1 size(wFI.XY,1) 1 2]);
            Ans.TRI = delaunay(wFI.XY(:,1),wFI.XY(:,2));
            toDir = wFI.WindFromDir*pi/180-pi;
            Ans.XComp = wFI.WindMagnitude.*sin(toDir);
            Ans.YComp = wFI.WindMagnitude.*cos(toDir);
        case 'waves'
            wFI = shipma('openpar',FI.Environments.Waves(FI.Cases.Data.wavesNr).Data.file,'waves');
            Ans.XYZ = reshape(wFI.XY,[1 size(wFI.XY,1) 1 2]);
            Ans.TRI = delaunay(wFI.XY(:,1),wFI.XY(:,2));
            toDir = wFI.WaveToDir*pi/180;
            Ans.XComp = wFI.WaveHeight.*sin(toDir);
            Ans.YComp = wFI.WaveHeight.*cos(toDir);
        case 'current'
            wFI = shipma('openpar',FI.Environments.Currents(FI.Cases.Data.currentNr).Data.file,'current');
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
if ~isempty(T)
    Ans.Time = T;
end

varargout={Ans FI};
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function selfplot(FI,Props)
d3d_qp('newfigure','1 plot - portrait','1 plot - portrait')
d3d_qp('selectfield','depth')
d3d_qp('colourmap','navdepth')
d3d_qp('presenttype','patches')
d3d_qp('colbarhorz',1)
d3d_qp('climmode','manual')
d3d_qp('climmax',20)
d3d_qp('addtoplot')
d3d_qp('selectfield','fairway contour')
d3d_qp('linestyle','-')
d3d_qp('colour',[ 0 0 0 ])
d3d_qp('fillpolygons',1)
d3d_qp('facecolour',[ 1 1 0.2 ])
d3d_qp('addtoplot')
d3d_qp('selectfield','ship track')
d3d_qp('allt',1)
d3d_qp('addtoplot')
a=d3d_qp('loaddata');
d3d_qp('selectfield','ship')
d3d_qp('allt',0)
d3d_qp('editt',1)
d3d_qp('facecolour',[ 1 0 0 ])
d3d_qp('addtoplot')
xrange = [min(a.X) max(a.X)];
xrange = xrange + [-1 1]*0.1*diff(xrange);
yrange = [min(a.Y) max(a.Y)];
yrange = yrange + [-1 1]*0.1*diff(yrange);
fac = 1.25;
yrange = mean(yrange)+[-1 1]*max(diff(xrange)*fac,diff(yrange))/2;
xrange = mean(xrange)+[-1 1]*diff(yrange)/fac/2;
set(qpsa,'xlim',xrange,'ylim',yrange)
set(qpsa,'drawmode','fast')
set(qpsf,'renderer','painters')
%--------
d3d_qp('newfigure','1 plot - portrait','1 plot - portrait')
d3d_qp('selectfield','current')
d3d_qp('component','magnitude')
d3d_qp('climmode','automatic')
d3d_qp('colourmap','revhot')
d3d_qp('addtoplot')
d3d_qp('component','vector')
d3d_qp('colourvectors',0)
d3d_qp('thinfld','distance')
d3d_qp('thindist',diff(xrange)/100)
d3d_qp('addtoplot')
d3d_qp('selectfield','fairway contour')
d3d_qp('facecolour',[ 1 1 0.2 ])
d3d_qp('addtoplot')
d3d_qp('selectfield','ship')
d3d_qp('facecolour',[ 1 0 0 ])
d3d_qp('allt',0)
d3d_qp('addtoplot')
set(qpsa,'xlim',xrange,'ylim',yrange)
set(qpsa,'drawmode','fast')
set(qpsf,'renderer','painters')
%--------
d3d_qp('newfigure','3 plots, vertical - portrait','3 plots, vertical - portrait')
qpsa('upper plot')
d3d_qp('allt',1)
d3d_qp('selectfield','propeller speed')
d3d_qp('linestyle','-')
d3d_qp('addtoplot')
qpsa('middle plot')
d3d_qp('selectfield','speed')
d3d_qp('addtoplot')
qpsa('lower plot')
d3d_qp('selectfield','rudder angle')
d3d_qp('addtoplot')
%--------
d3d_qp('newfigure','2 plots, vertical - portrait','2 plots, vertical - portrait')
set(qpsa('upper plot'),'ydir','reverse')
d3d_qp('selectfield','swept path port')
d3d_qp('linestyle','-')
d3d_qp('addtoplot')
d3d_qp('selectfield','swept path stb.')
d3d_qp('linestyle','--')
d3d_qp('addtoplot')
%--------
d3d_qp('selectfield','default figures')
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=domains(FI)
Out=FI.Cases.Names;
if ~iscell(Out)
    Out = {Out};
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,domain)

%======================== SPECIFIC CODE =======================================
PropNames={'Name'               'Units' 'DimFlag'   'DataInCell' 'NVal' 'Geom'   'Coords' 'ClosedPoly' 'Domain' 'Var'   };
DataProps={'default figures'    ''      [0 0 0 0 0] 0            -2     ''       ''       0            domain   0       
    '-------'                   ''      [0 0 0 0 0] 0             0     ''       ''       0            domain   0       
    'ship track'                ''      [1 0 0 0 0] 0             0     'PNT'    'xy'     0            domain   0       
    'ship'                      ''      [1 0 0 0 0] 0             0     'POLYG'  'xy'     1            domain   0       
    'fairway contour'           ''      [0 0 1 0 0] 0             0     'POLYG'  'xy'     1            domain   -1       
    'bank suction lines'        ''      [0 0 1 0 0] 0             0     'POLYL'  'xy'     0            domain   -1       
    '-------'                   ''      [0 0 0 0 0] 0             0     ''       ''       0            domain   0       
    'wind'                      'm/s'   [0 0 1 0 0] 0             2     'TRI'    'xy'     0            domain   -1       
    'waves'                     'm'     [0 0 1 0 0] 0             2     'TRI'    'xy'     0            domain   -1       
    'swell'                     'm'     [0 0 1 0 0] 0             1     'TRI'    'xy'     0            domain   -1       
    'current'                   'm/s'   [0 0 1 0 0] 0             2     'TRI'    'xy'     0            domain   -1       
    'depth'                     'm'     [0 0 1 0 0] 0             1     'TRI'    'xy'     0            domain   -1       
    '-------'                   ''      [0 0 0 0 0] 0             0     ''       ''       0            domain   0       
    'speed'                     'm/s'   [1 0 0 0 0] 0             1     ''       ''       0            domain   0
    'his-data'                  ''      [1 0 0 0 0] 0             1     ''       ''       0            domain   0       };
Out=cell2struct(DataProps,PropNames,2);
%======================== SPECIFIC CODE DIMENSIONS ============================
hisvars = FI.Cases.Data(domain).TimeSeries.SubsName;
startVal = length(Out)-1;
nVal = length(hisvars);
Out = cat(1,Out(1:startVal),repmat(Out(end),nVal,1));
for i=1:nVal
    var = hisvars{i};
    uStart = strfind(var,'[');
    name = translate(deblank(var(1:uStart-1)));
    unit = var(uStart+1:end-1);
    %
    hisvars{i} = name;
    Out(startVal+i).Name = name;
    Out(startVal+i).Units = unit;
    Out(startVal+i).Var = i;
end
%
for i = length(Out):-1:1
    switch Out(i).Name
        case 'x'
            Out(i)=[];
        case 'y'
            Out(i)=[];
        case 'wind'
            if FI.Cases.Data(domain).windNr<0
                Out(i)=[];
            elseif ~FI.Environments.Winds(FI.Cases.Data(domain).windNr).Data.fileSelected
                Out(i)=[];
            end
        case 'waves'
            if FI.Cases.Data(domain).wavesNr<0
                Out(i)=[];
            elseif ~FI.Environments.Waves(FI.Cases.Data(domain).wavesNr).Data.fileSelected
                Out(i)=[];
            end
        case 'swell'
            if FI.Cases.Data(domain).swellNr<0
                Out(i)=[];
            elseif ~FI.Environments.Swells(FI.Cases.Data(domain).swellNr).Data.fileSelected
                Out(i)=[];
            end
        case 'current'
            if FI.Cases.Data(domain).currentNr<0
                Out(i)=[];
            elseif ~FI.Environments.Currents(FI.Cases.Data(domain).currentNr).Data.fileSelected
                Out(i)=[];
            end
        case 'speed'
            u = find(strcmpi('u',hisvars));
            v = find(strcmpi('v',hisvars));
            Out(i).Var = [u v];
        case 'ship track'
            x = find(strcmpi('x',hisvars));
            y = find(strcmpi('y',hisvars));
            Out(i).Var = [x y];
        case 'ship'
            x = find(strcmpi('x',hisvars));
            y = find(strcmpi('y',hisvars));
            dir = find(strcmpi('Heading',hisvars));
            Out(i).Var = [x y dir];
    end
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function sz=getsize(FI,Props)
T_=1; ST_=2; M_=3; N_=4; K_=5;
sz=[0 0 0 0 0];

%======================== SPECIFIC CODE =======================================
if Props.DimFlag(T_)
    sz(T_) = FI.Cases.Data(Props.Domain).TimeSeries.NTimes;
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function T=readtim(FI,Props,t)
%======================== SPECIFIC CODE =======================================
if t==0
    t=':';
end
T=[];
% -----------------------------------------------------------------------------


function s2 = translate(s1)
table = {'n1' 'propeller speed'
    'rudder1' 'rudder angle'};
is1 = strcmpi(s1,table(:,1));
if ~any(is1)
    s2 = s1;
else
    s2 = table{is1,2};
end