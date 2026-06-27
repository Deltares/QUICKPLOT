function varargout=flexmeshfil(FI,domain,field,cmd,varargin)
%FLEXMESHFIL QP support for various unstructured mesh files.
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
        varargout={getsize(FI,Props)};
        return
    case 'times'
        varargout={readtim(FI,Props,varargin{:})};
        return
    case 'timezone'
        [varargout{1:2}]=gettimezone(FI,domain,Props);
        return
    case 'stations'
        varargout={{}};
        return
    case 'subfields'
        varargout={getsubfields(FI,Props,varargin{:})};
        return
    otherwise
        [XYRead,DataRead,DataInCell]=gridcelldata(cmd);
end

DimFlag=Props.DimFlag;

% initialize and read indices ...
idx={[] [] 0 [] []};
fidx=find(DimFlag);

idx(fidx(1:length(varargin)))=varargin;

if strcmp(FI.FileType,'Gmsh')
    NodeCoor = FI.Node.Coords';
else
    NodeCoor = FI.NodeCoor;
end

switch Props.Geom
    case 'POLYL'
        bndTypes = {FI.Bnd.Type};
        iBnd = find(strcmp(bndTypes,Props.Name(1:end-11)));
        if ~isequal(idx{M_},0)
            iBnd = iBnd(idx{M_});
        end
        nBnd = length(iBnd);
        if isfield(FI.Bnd,'Nodes2') && ~isempty(FI.Bnd(iBnd(1)).Nodes2)
            has_Nodes2 = true;
            ipoly = 2*nBnd;
        else
            has_Nodes2 = false;
            ipoly = nBnd;
        end
        for b = nBnd:-1:1
            if has_Nodes2
                nodes = FI.Bnd(iBnd(b)).Nodes2;
                Ans.XY{ipoly} = NodeCoor(nodes,1:2);
                ipoly = ipoly-1;
            end
            nodes = FI.Bnd(iBnd(b)).Nodes;
            Ans.XY{ipoly} = NodeCoor(nodes,1:2);
            ipoly = ipoly-1;
        end
        %
        varargout={Ans FI};
end

if strcmp(FI.FileType,'Gmsh')
    Faces = FI.Element.Nodes';
else
    if isfield(Props,'ElmLayer')
        Faces = FI.Faces(FI.ElmLyr==Props.ElmLayer,:);
    else
        Faces = FI.Faces;
    end
end
iFaces = [];
lFaces = [];
if ~isequal(idx{M_},0)
    switch Props.Geom
        case 'UGRID2D-NODE'
            lFaces = all(ismember(Faces,idx{M_}) | Faces<=0,2);
            Faces = Faces(lFaces,:);
            %NodeCoor = NodeCoor(idx{M_},:); % will be updated below since
            %Faces only contains a subset of the Node indices.
        case 'UGRID2D-FACE'
            iFaces = idx{M_};
            Faces = Faces(iFaces,:);
    end
end
i = Faces>0;
[iNodes,~,renumFaces] = unique(Faces(i));
Faces(i) = renumFaces;
NodeCoor = NodeCoor(iNodes,:);
%
switch Props.Geom
    case 'TRI'
        Ans.TRI = Faces;
        sz = size(NodeCoor);
        Ans.XYZ = reshape(NodeCoor,[1 sz(1) 1 sz(2)]);
        Ans.Val = NodeCoor(:,3);
    case {'UGRID2D-NODE','UGRID2D-FACE'}
        Faces(Faces==0) = NaN;
        Ans.FaceNodeConnect = Faces;
        faceMask = all(isnan(Ans.FaceNodeConnect),2);
        Ans.FaceNodeConnect(faceMask,:) = [];
        Ans.X = NodeCoor(:,1);
        Ans.Y = NodeCoor(:,2);
        switch Props.Name
            case 'mesh - node indices'
                Ans.Val = iNodes;
            case 'mesh - face indices'
                if ~isempty(lFaces)
                    Ans.Val = find(lFaces);
                elseif ~isempty(iFaces)
                    Ans.Val = iFaces;
                else
                    Ans.Val = 1:size(Faces,1);
                end
                Ans.Val(faceMask) = [];
            case 'value'
                Ans.Val = NodeCoor(:,3);
        end
        Ans.ValLocation = Props.Geom(9:end);
end
%
varargout={Ans FI};
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,domain)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE =======================================
PropNames={'Name'                   'Units' 'Geom'       'Coords' 'DimFlag' 'DataInCell' 'NVal' 'SubFld' 'ClosedPoly' 'UseGrid'};
DataProps={'mesh'                   ''      'UGRID2D-NODE' 'xy'    [0 0 6 0 0]  0            0      []         0            1
           'mesh - node indices'    ''      'UGRID2D-NODE' 'xy'    [0 0 6 0 0]  0            1      []         0            1
           'mesh - face indices'    ''      'UGRID2D-FACE' 'xy'    [0 0 6 0 0]  1            1      []         0            1
           'value'                  ''      'UGRID2D-NODE' 'xy'    [0 0 6 0 0]  0            1      []         0            1};
if strcmp(FI.FileType,'Gmsh')
    Out=cell2struct(DataProps,PropNames,2);
else
    if size(FI.NodeCoor,2)<3
        DataProps(4,:) = [];
    end
    Out=cell2struct(DataProps,PropNames,2);
    if isfield(FI,'ElmLyr') && domain<=length(FI.Layers)
        [Out.ElmLayer] = deal(FI.Layers(domain));
    end
end
if isfield(FI,'Bnd') && ~isempty(FI.Bnd)
    Out(end+1) = Out(end);
    Out(end).Name = '-------';
    bndTypes = unique({FI.Bnd.Type});
    for b = 1:length(bndTypes)
        Out(end+1) = Out(end);
        Out(end).Name = [bndTypes{b}, ' boundaries'];
        Out(end).Geom = 'POLYL';
        Out(end).NVal = 0; % maybe the values ...
    end
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function sz=getsize(FI,Props)
T_=1; ST_=2; M_=3; N_=4; K_=5;
sz=[0 0 0 0 0];
switch Props.Geom
    case 'UGRID2D-NODE'
        if strcmp(FI.FileType,'Gmsh')
            sz(M_) = size(FI.Node.Coords,2);
        else
            sz(M_) = size(FI.NodeCoor,1);
        end
    case 'UGRID2D-FACE'
        if strcmp(FI.FileType,'Gmsh')
            sz(M_) = size(FI.Element.Nodes,2);
        elseif isfield(Props,'ElmLayer')
            sz(M_) = sum(FI.ElmLyr==Props.ElmLayer);
        else
            sz(M_) = size(FI.Faces,1);
        end
    case 'POLYL'
        bndTypes = {FI.Bnd.Type};
        iBnd = strcmp(bndTypes,Props.Name(1:end-11));
        sz(M_) = sum(iBnd);
end
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
function Domains=domains(FI)
if isfield(FI,'ElmLyr')
    nLyr = length(FI.Layers);
    Domains = cell(1,nLyr+1);
    for i = 1:nLyr
        Domains{i} = sprintf('%i',FI.Layers(i));
    end
    Domains{end} = 'All';
else
    Domains = {};
end
% -----------------------------------------------------------------------------
