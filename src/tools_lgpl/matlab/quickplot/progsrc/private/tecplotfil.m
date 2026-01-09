function varargout=tecplotfil(FI,domain,field,cmd,varargin)
%TELEMACFIL QP support for Telemac files.
%   Domains                 = XXXFIL(FI,[],'domains')
%   DataProps               = XXXFIL(FI,Domain)
%   Size                    = XXXFIL(FI,Domain,DataFld,'size')
%   Times                   = XXXFIL(FI,Domain,DataFld,'times',T)
%   StNames                 = XXXFIL(FI,Domain,DataFld,'stations')
%   SubFields               = XXXFIL(FI,Domain,DataFld,'subfields')
%   [TZshift   ,TZstr  ]    = XXXFIL(FI,Domain,DataFld,'timezone')
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
%   Copyright (C) 2011-2025 Stichting Deltares.                                     
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
    error('Not enough input arguments')
elseif nargin==2
    varargout={infile(FI,domain)};
    return
elseif ischar(field)
    switch field
        case 'options'
            [varargout{1:2}]=options(FI,cmd,varargin{:});
        case 'domains'
            varargout={domains(FI)};
        case 'dimensions'
            varargout={dimensions(FI)};
        case 'locations'
            varargout={locations(FI)};
        case 'quantities'
            varargout={quantities(FI)};
        case 'getparams'
            varargout={[]};
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
        varargout={getsize(FI,domain,Props)};
        return
    case 'times'
        varargout={readtim(FI,domain,Props,varargin{:})};
        return
    case 'timezone'
        [varargout{1:2}]=gettimezone(FI,domain,Props);
        return
    case 'stations'
        varargout={{}};
        return
    case 'subfields'
        varargout={{}};
        return
    otherwise
        [XYRead,DataRead,DataInCell]=gridcelldata(cmd);
end

DimFlag=Props.DimFlag;
sz=getsize(FI,domain,Props);

% initialize and read indices ...
idx = {[] [] [] [] []};
fidx = find(DimFlag);
idx(fidx(1:length(varargin))) = varargin;
for i = 1:5
    if DimFlag(i) && (isempty(idx{i}) || isequal(idx{i},0))
        idx{i} = 1:sz(i);
    end
end
Zone = FI.Zone(domain);

if strcmpi(Zone.type,'ORDERED')
    spatialIndices = idx(fidx);
    if XYRead
        Ans.X = Zone.data(spatialIndices{:},1);
        Ans.Y = Zone.data(spatialIndices{:},2);
        if length(spatialIndices)==3
            Ans.Z = Zone.data(spatialIndices{:},3);
        end
    end
    if DataRead
        Ans.Val = Zone.data(spatialIndices{:},Props.ival);
    end
else
    switch Zone.elementType
        case 'LINESEG'
            % TODO
        case {'TRIANGLE','QUADRILATERAL','POLYGON'}
            idxM = idx{M_};
            if XYRead
                Ans.X = Zone.data(idxM,1);
                Ans.Y = Zone.data(idxM,2);
                renum = repmat(-1,Zone.nNodes,1);
                renum(idxM) = 1:length(idxM);
                FNC = renum(Zone.topology);
                FNC(any(FNC<=0,2),:) = [];
                Ans.FaceNodeConnect = FNC;
            end
            if DataRead
                Ans.Val = Zone.data(idxM,Props.ival);
                Ans.ValLocation = 'NODE';
            end
        otherwise
            error('Element type "%s" not yet supported.',Zone.elementType)
    end
end

varargout={Ans FI};
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,domain)
T_=1; ST_=2; M_=3; N_=4; K_=5;
Zone = FI.Zone(domain);

PropNames={'Name'                   'Units' 'TemperatureType' 'Geom' 'Coords' 'DimFlag' 'DataInCell' 'NVal' 'SubFld' 'MNK' 'ival' 'UseGrid'};
DataProps={'-------'                ''      ''                ''     ''      [0 0 0 0 0]  0           0      []       0     0      1};
Out=cell2struct(DataProps,PropNames,2);

if strcmpi(Zone.type,'ORDERED')
    if isfield(Zone,'iMax')
        Out.DimFlag(M_) = 1;
    end
    if isfield(Zone,'jMax')
        Out.DimFlag(N_) = 1;
    end
    if isfield(Zone,'kMax')
        Out.DimFlag(K_) = 1;
    end
else
    switch Zone.elementType
        case 'LINESEG'
            Out.Geom = 'UGRID1D-NODE';
            Out.Coords = 'xy';
        case {'TRIANGLE','QUADRILATERAL','POLYGON'}
            Out.Geom = 'UGRID2D-NODE';
            Out.Coords = 'xy';
        case {'POLYHEDRAL','TETRAHEDRON','BRICK'}
            Out.Geom = 'UGRID3D';
            Out.Coords = 'xyz';
            error('3D element type "%s" not yet supported.',Zone.elementType)
        otherwise
            error('Element type "%s" not yet supported.',Zone.elementType)
    end
    Out.DimFlag(M_) = 6;
end
nVar = length(FI.Variables);
Out = repmat(Out,1,nVar);
[Out.Name] = deal(FI.Variables{:});
[Out.NVal] = deal(1);
ival_cell = num2cell(1:nVar);
[Out.ival] = deal(ival_cell{:});


% -----------------------------------------------------------------------------
function sz=getsize(FI,domain,Props)
T_=1; ST_=2; M_=3; N_=4; K_=5;
sz=[0 0 0 0 0];
Zone = FI.Zone(domain);
if strcmpi(Zone.type,'ORDERED')
    if Props.DimFlag(M_)
        sz(M_) = Zone.iMax;
    end
    if Props.DimFlag(N_)
        sz(N_) = Zone.jMax;
    end
    if Props.DimFlag(K_)
        sz(K_) = Zone.kMax;
    end
else
    switch Props.Geom
        case {'UGRID1D-NODE','UGRID2D-NODE','UGRID3D-NODE'}
            sz(M_) = Zone.nNodes;
        case {'UGRID1D-EDGE','UGRID-FACE','UGRID3D-VOLUME'}
            sz(M_) = Zone.nElements;
    end
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function T=readtim(FI,domain,Props,t)
T_=1; ST_=2; M_=3; N_=4; K_=5;

% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function Domains=domains(FI)
if isscalar(FI.Zone) && strcmp(FI.Zone.title,'zone 1')
    Domains = {};
else
    Domains = {FI.Zone.title};
end
% -----------------------------------------------------------------------------
