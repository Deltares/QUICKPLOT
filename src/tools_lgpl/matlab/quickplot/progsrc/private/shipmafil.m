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
[T,val1] = delwaq('read',FI.Cases.Data(domain).TimeSeries,Props.Var,1,idx{1});

% generate output ...
if Props.NVal==0
    switch Props.Name
        case 'ship track'
            Ans.X = squeeze(val1(1,1,:));
            Ans.Y = squeeze(val1(2,1,:));
        case 'ship'
            ship = FI.Cases.Data(domain).ShipNr;
            icontour = ustrcmpi('contour',{FI.Ships(ship).Data.Props.Quant});
            contour = FI.Ships(ship).Data.Props(icontour).Value;
            alf = val1(3)*pi/180;
            Ans.X = contour(:,1)*sin(alf)+contour(:,2)*cos(alf)+val1(1);
            Ans.Y = -contour(:,2)*sin(alf)+contour(:,1)*cos(alf)+val1(2);
    end
    Ans.XUnits = 'm';
    Ans.YUnits = 'm';
    Ans.Time = T;
elseif Props.NVal==1
    Ans.Val=val1;
else
    Ans.XComp=val1;
    Ans.YComp=val2;
end
Ans.Time=T;

varargout={Ans FI};
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function selfplot(FI,Props)
d3d_qp('newfigure','3 plots, vertical - portrait','3 plots, vertical - portrait')
qpsa('upper plot')
d3d_qp('selectfield','n1')
d3d_qp('linestyle','-')
d3d_qp('addtoplot')
qpsa('lower plot')
d3d_qp('selectfield','rudder1')
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
    '-------'                   ''      [0 0 0 0 0] 0             0     ''       ''       0            domain   0       
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
    Out(startVal+i).Name = deblank(var(1:uStart-1));
    Out(startVal+i).Units = var(uStart+1:end-1);
    Out(startVal+i).Var = i;
end
%
[dummy,iCoords,reordered]=intersect(hisvars,{'x [m]','y [m]'});
Out(3).Var = iCoords;
[dummy,iCoords,reordered]=intersect(hisvars,{'x [m]','y [m]','Heading [deg]'});
[dummy,i]=sort(reordered);
Out(4).Var = iCoords(i);
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
