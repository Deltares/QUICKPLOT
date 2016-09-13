function varargout=d3d_simfil(FI,idom,field,cmd,varargin)
%D3D_SIMFIL QP support for Delft3D simulation configuration files.
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

%========================= GENERAL CODE =======================================
T_=1; ST_=2; M_=3; N_=4; K_=5;

if nargin<2
    error('Not enough input arguments')
end

OrigFI = FI;

if nargin==2
    varargout={infile(FI,idom)};
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
        varargout={getsize(FI,idom,Props)};
        return
    case 'times'
        varargout={readtim(FI,idom,Props,varargin{:})};
        return
    case 'timezone'
        [varargout{1:2}]=gettimezone(FI,idom,Props);
        return
    case 'stations'
        varargout={readsts(FI,Props,0)};
        return
    case 'subfields'
        varargout={getsubfields(FI,Props,varargin{:})};
        return
    otherwise
        [XYRead,DataRead,DataInCell]=gridcelldata(cmd);
end

DimFlag=Props.DimFlag;

% initialize and read indices ...
idx={[] [] 0 0 0};
fidx=find(DimFlag);
subf=getsubfields(FI,Props);
if isempty(subf)    
    idx_subf = [];
    idx(fidx(1:length(varargin))) = varargin;
else
    idx_subf = varargin{1};
    idx(fidx(1:(length(varargin)-1))) = varargin(2:end);
end

sz = getsize(FI,idom,Props);
allidx=zeros(size(sz));
for i=1:length(sz)
    if DimFlag(i)
        if isempty(idx{i}) || isequal(idx{i},0) || isequal(idx{i},1:sz(i))
            idx{i}=1:sz(i);
            allidx(i)=1;
        end
    end
end

Name = [FI.FileType(9:end) ':' Props.Name];
if strcmp(Name,'D-Flow1D:water level boundary points') || ...
        strcmp(Name,'D-Flow1D:discharge boundary points') || ...
        strncmp(Name,'D-Flow1D:boundary points',24)
    Name = 'D-Flow1D:boundary points';
elseif strncmp(Name,'D-Flow1D:structure points',25)
    Name = 'D-Flow1D:structure points';
end
switch Name
    case 'D-Flow1D:network'
        G = inifile('geti',FI.ntw,'Branch','geometry');
        G = G(idx{M_});
        for i = length(G):-1:1
            XY{i} = geom2xy(G{i});
        end
        Ans.XY = XY;
    case 'D-Flow1D:nodes'
        X = inifile('geti',FI.ntw,'Node','x');
        Y = inifile('geti',FI.ntw,'Node','y');
        Ans.X = [X{idx{M_}}];
        Ans.Y = [Y{idx{M_}}];
        Ans.Val = inifile('geti',FI.ntw,'Node','id');
    case 'D-Flow1D:cross section locations'
        cId = inifile('geti',FI.crsLoc,'CrossSection','id');
        bId = inifile('geti',FI.crsLoc,'CrossSection','branchid');
        bCh = inifile('geti',FI.crsLoc,'CrossSection','chainage');
        %
        bId = bId(idx{M_});
        bCh = bCh(idx{M_});
        [Ans.X,Ans.Y] = branch_idchain2xy(FI.ntw,bId,bCh);
        Ans.Val = cId(idx{M_});
    case 'D-Flow1D:grid points'
        gpCnt = inifile('geti',FI.ntw,'Branch','gridPointsCount');
        gpX = inifile('geti',FI.ntw,'Branch','gridPointX');
        gpY = inifile('geti',FI.ntw,'Branch','gridPointY');
        gpI = inifile('geti',FI.ntw,'Branch','gridPointIds');
        gpCnt = [gpCnt{:}];
        Ans.X   = zeros(length(idx{M_}),1);
        Ans.Y   = zeros(length(idx{M_}),1);
        Ans.Val = cell(length(idx{M_}),1);
        oM = 0;
        oAns = 0;
        for i = 1:length(gpCnt)
            iM = oM + (1:gpCnt(i));
            oM = oM + gpCnt(i);
            isub = find(ismember(iM,idx{M_}));
            %
            if any(isub)
                im = find(isub);
                %
                nPnt = length(im);
                iAns = oAns + (1:nPnt);
                oAns = oAns + nPnt;
                %
                gpx = gpX{i};
                gpy = gpY{i};
                gpi = multiline(gpI{i},';','cell');
                Ans.X(iAns)   = gpx(im)';
                Ans.Y(iAns)   = gpy(im)';
                Ans.Val(iAns) = gpi(im);
            end
        end
    case 'D-Flow1D:boundary points'
        F=inifile('geti',FI.bndLoc,'Boundary','type');
        BT = [F{:}];
        BT = find(BT==Props.varid);
        %
        F=inifile('geti',FI.bndLoc,'Boundary','nodeId');
        BI = F(BT(idx{M_}));
        %
        NI = inifile('geti',FI.ntw,'Node','id');
        ni = find(ismember(NI,BI));
        ni = ni(idx{M_});
        x = inifile('geti',FI.ntw,'Node','x');
        y = inifile('geti',FI.ntw,'Node','y');
        Ans.X   = [x{ni}]';
        Ans.Y   = [y{ni}]';
        Ans.Val = NI(ni);
    case 'D-Flow1D:structure points'
        ST = inifile('geti',FI.struct,'Structure','type');
        ST = find(strcmp(ST,Props.varid));
        %
        sId = inifile('geti',FI.struct,'Structure','id');
        bId = inifile('geti',FI.struct,'Structure','branchid');
        bCh = inifile('geti',FI.struct,'Structure','chainage');
        %
        iM = ST(idx{M_});
        bId = bId(iM);
        bCh = bCh(iM);
        [Ans.X,Ans.Y] = branch_idchain2xy(FI.ntw,bId,bCh);
        Ans.Val = sId(iM);
    case 'D-Flow2D3D:grid'
        nM = length(idx{M_});
        nN = length(idx{N_});
        Ans.X = NaN(nM,nN);
        Ans.Y = NaN(nM,nN);
        if idx{M_}(end)==sz(M_)
            idx{M_}(end) = [];
            nM = nM-1;
        end
        if idx{N_}(end)==sz(N_)
            idx{N_}(end) = [];
            nN = nN-1;
        end
        Ans.X(1:nM,1:nN) = FI.grd.X(idx{M_},idx{N_});
        Ans.Y(1:nM,1:nN) = FI.grd.Y(idx{M_},idx{N_});
    case 'D-Flow FM:mesh'
        Ans = netcdffil(FI.mesh.nc_file,idom,FI.mesh.quant,'grid',idx{M_});
    case 'D-Wave:grid'
        Ans.X = FI.domain(idom).grd.X(idx{M_},idx{N_});
        Ans.Y = FI.domain(idom).grd.Y(idx{M_},idx{N_});
    otherwise
        Ans = [];
end

varargout={Ans OrigFI};
% -----------------------------------------------------------------------------


function XY = geom2xy(G)
p = strfind(G,'(');
GeomType = G(1:p-1);
if strcmp(GeomType,'LINESTRING')
    xy = sscanf(G(p+1:end),'%f');
    switch length(xy)
        case 2
            XY = sscanf(G(p+1:end),'%f %f,',[2 inf]);
            XY = XY';
        case 3
            XY = sscanf(G(p+1:end),'%f %f %f,',[3 inf]);
            XY = XY(1:2,:)';
    end
else
    error('Geometry type "%s" not yet supported.',GeomType)
end

% -----------------------------------------------------------------------------
function Out=domains(FI)
switch FI.FileType
    case 'Delft3D D-Wave'
        Out = {FI.domain.name};
    otherwise
        Out = {};
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,idom)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE =======================================
PropNames={'Name'                   'Units' 'Geom' 'Coords' 'DimFlag' 'DataInCell' 'NVal' 'SubFld' 'MNK' 'varid'  'DimName' 'hasCoords' 'VectorDef' 'ClosedPoly' 'UseGrid'};
DataProps={'dummy field'            ''      ''     ''      [0 0 0 0 0]  0           0      []       0     []          {}          0         0          0          0};
Out=cell2struct(DataProps,PropNames,2);
switch FI.FileType
    case 'Delft3D D-Flow1D'
        Out(1).Name = 'network';
        Out(1).Geom = 'POLYL';
        Out(1).Coords = 'xy';
        Out(1).DimFlag(M_) = 1;
        %
        F=inifile('geti',FI.bndLoc,'Boundary','type');
        BT=[F{:}];
        uBT=unique(BT);
        nBT=length(uBT);
        %
        ST=inifile('geti',FI.struct,'Structure','type');
        uST=unique(ST);
        nST=length(uST);
        %
        Out(2:4+nBT+nST) = Out(1);
        Out(2).Name = 'nodes';
        Out(2).Geom = 'PNT';
        Out(2).NVal = 4;
        %
        Out(3).Name = 'grid points';
        Out(3).Geom = 'PNT';
        Out(3).NVal = 4;
        %
        Out(4).Name = 'cross section locations';
        Out(4).Geom = 'PNT';
        Out(4).NVal = 4;
        %
        for i = 1:nBT
            switch uBT(i)
                case 1
                    Name = 'water level boundary points';
                case 2
                    Name = 'discharge boundary points';
                otherwise
                    Name = sprintf('boundary points - type %i',uBT(i));
            end
            Out(4+i).Name = Name;
            Out(4+i).Geom = 'PNT';
            Out(4+i).NVal = 4;
            Out(4+i).varid = uBT(i);
        end
        %
        for i = 1:nST
            switch uST{i}
                case 'universalWeir'
                    Name = 'universal weir';
                otherwise
                    Name = uST{i};
            end
            Out(4+nBT+i).Name = ['structure points - ' Name];
            Out(4+nBT+i).Geom = 'PNT';
            Out(4+nBT+i).NVal = 4;
            Out(4+nBT+i).varid = uST{i};
        end
    case 'Delft3D D-Flow2D3D'
        Out(1).Name = 'grid';
        Out(1).Geom = 'sQUAD';
        Out(1).Coords = 'xy';
        Out(1).DimFlag([M_ N_]) = 1;
    case 'Delft3D D-Flow FM'
        Out(1).Name = 'mesh';
        Out(1).Geom = 'UGRID-NODE';
        Out(1).Coords = 'xy';
        Out(1).DimFlag(M_) = 6;
    case 'Delft3D D-Wave'
        Out(1).Name = 'grid';
        Out(1).Geom = 'sQUAD';
        Out(1).Coords = 'xy';
        Out(1).DimFlag([M_ N_]) = 1;
    otherwise
        Out(:,1) = [];
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function sz=getsize(FI,idom,Props)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE =======================================
ndims = length(Props.DimFlag);
sz = zeros(1,ndims);
switch FI.FileType
    case 'Delft3D D-Flow1D'
        switch Props.Name
            case 'network'
                F=inifile('chapters',FI.ntw);
                sz(M_) = sum(strcmp(F,'Branch'));
            case 'nodes'
                F=inifile('chapters',FI.ntw);
                sz(M_) = sum(strcmp(F,'Node'));
            case 'grid points'
                F=inifile('geti',FI.ntw,'Branch','gridPointsCount');
                sz(M_) = sum([F{:}]);
            case 'cross section locations'
                F=inifile('geti',FI.crsLoc,'CrossSection','branchid');
                sz(M_) = length(F);
            otherwise
                if ~isempty(strfind(Props.Name,'boundary points'))
                    F=inifile('geti',FI.bndLoc,'Boundary','type');
                    BT = [F{:}];
                    sz(M_) = sum(BT==Props.varid);
                elseif strncmp(Props.Name,'structure points',16)
                    ST=inifile('geti',FI.struct,'Structure','type');
                    sz(M_)=sum(strcmp(Props.varid,ST));
                end
        end
    case 'Delft3D D-Flow2D3D'
        MNK = inifile('geti',FI.mdf,'*','MNKmax');
        sz([M_ N_]) = MNK(1:2);
    case 'Delft3D D-Flow FM'
        grdSz = netcdffil(FI.mesh.nc_file,idom,FI.mesh.quant,'size');
        sz(M_) = grdSz(M_);
    case 'Delft3D D-Wave'
        grdSz = size(FI.domain(idom).grd.X);
        sz([M_ N_]) = grdSz;
    otherwise
        % no generic default dimension code
end
% -----------------------------------------------------------------------------


function [x,y] = branch_idchain2xy(NTWini,bId,bCh)
nPnt = length(bId);
x = NaN(nPnt,1);
y = NaN(nPnt,1);
%
[uBId,ia,ic] = unique(bId);
G = inifile('geti',NTWini,'Branch','geometry');
GId = inifile('geti',NTWini,'Branch','id');
for i = 1:length(uBId)
    Branch = uBId(i);
    iBranch = ustrcmpi(Branch,GId);
    if iBranch>0
        XY   = geom2xy(G{iBranch});
        d    = pathdistance(XY(:,1),XY(:,2));
        iOut = ic==i;
        cCS  = [bCh{iOut}];
        xyCS = interp1(d,XY,cCS);
        x(iOut) = xyCS(:,1);
        y(iOut) = xyCS(:,2);
    end
end
