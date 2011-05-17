function varargout=netcdffil(FI,domain,field,cmd,varargin)
%NETCDFFIL QP support for netCDF files.
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
        varargout={getsubfields(FI,Props,varargin{:})};
        return
    otherwise
        [XYRead,DataRead,DataInCell]=gridcelldata(cmd);
end

DimFlag=Props.DimFlag;

% initialize and read indices ...
idx={[] [] 0 0 0};
fidx=find(DimFlag);

[subf,rec]=getsubfields(FI,Props);
if isempty(subf)
    % initialize and read indices ...
    Props.SubFld=rec;
    idx(fidx(1:length(varargin)))=varargin;
else
    % initialize and read indices ...
    rec.Val = rec.Val(varargin{1},:);
    Props.SubFld=rec;
    idx(fidx(1:(length(varargin)-1)))=varargin(2:end);
end

% select appropriate dimensions ...
sz=getsize(FI,Props);
for d_ = [T_ ST_ M_ N_ K_]
    if DimFlag(d_)
        %
        % Rule: if time not specified, use last time
        %
        if d_==T_ && isempty(idx{T_})
            idx{T_}=sz(T_);
        end
        %
        % Rule: if specified 0, the use all
        %
        if isequal(idx{d_},0)
            idx{d_}=1:sz(d_);
        end
    end
end

% expand SubFld into higher order dimensions
if ~isempty(Props.SubFld)
    Props.Dimension = cat(2,Props.Dimension,Props.SubFld.Fld);
    for i=1:length(Props.SubFld.Fld)
        idx{end+1} = Props.SubFld.Val(i);
    end
end
% read data ...
Info=FI.Dataset(Props.varid(1)+1);
%
if isfield(Info.Attribute,'Name')
    Attribs = {Info.Attribute.Name};
else
    Attribs = {};
end
%
removeTime = 0;
for ii=1:length(Props.varid)
    [data, status] = netcdf_get(FI,Props.varid(ii),Props.Dimension,idx);
    szData = size(data);
    %
    if Props.DimFlag(T_) && length(idx{T_})==1
        szV = [size(data) 1];
        data = reshape(data,szV(2:end));
        removeTime = 1;
    end
    %
    %positive = strmatch('positive',Attribs,'exact');
    %if ~isempty(positive)
    %   if isequal(lower(Info.Attribute(positive).Value),'down')
    %      data = -data;
    %   end
    %end
    %
    if ii==1
        if length(Props.varid)==1
            Ans.Val = data;
        else
            Ans.XComp = data;
        end
    elseif ii==2
        Ans.YComp = data;
    else
        Ans.ZComp = data;
    end
end
%
if isfield(Props,'VectorDef') && Props.VectorDef==2
    Ang = Ans.YComp*pi/180;
    Mag = Ans.XComp;
    Ans.XComp = Mag.*sin(Ang);
    Ans.YComp = Mag.*cos(Ang);
end
%
activeloaded = 0;
hdim = 1-cellfun('isempty',Props.Dimension);
hdim(M_) = hdim(M_)*2;
hdim(N_) = hdim(N_)*2;
hdim(hdim==0)=[];
hdim = hdim==2;
%
% Read coordinates
%
if Props.hasCoords
    coordname={'X','Y'};
else
    coordname={};
end
for iCoord = 1:length(coordname)
    vdim = getfield(Info,coordname{iCoord});
    if isempty(vdim)
        continue
    end
    CoordInfo = FI.Dataset(vdim);
    CoordAttribs = {CoordInfo.Attribute.Name};
    [Coord, status] = netcdf_get(FI,CoordInfo,Props.Dimension,idx);
    Coord = expand_hdim(Coord,szData,hdim);
    %
    %--------------------------------------------------------------------
    % Delft3D special
    %
    active_id = strmatch('active',CoordAttribs,'exact');
    if ~isempty(active_id)
        activevar = CoordInfo.Attribute(active_id).Value;
        [Active, status] = netcdf_get(FI,activevar,Props.Dimension,idx);
        Coord(Active~=1)=NaN; % Active~=1 excludes boundary points, Active==0 includes boundary points
    end
    %--------------------------------------------------------------------
    %
    %--------------------------------------------------------------------
    % ROMS special
    %
    if ~isnan(CoordInfo.TSMNK(3))
        xcoord = FI.Dimension(CoordInfo.TSMNK(3)+1).Name;
        underscore = strfind(xcoord,'_');
        if activeloaded==0
            activeloaded = -1;
            if ~isempty(underscore)
                location = xcoord(underscore+1:end);
                maskvar = ['mask_' location];
                actvarid = strmatch(maskvar,{FI.Dataset.Name}');
                ActiveInfo = FI.Dataset(actvarid);
                if ~isempty(ActiveInfo)
                    [Active, status] = netcdf_get(FI,ActiveInfo,Props.Dimension,idx);
                    activeloaded = 1;
                end
            end
        end
    end
    if activeloaded>0 && isequal(ActiveInfo.Dimension,CoordInfo.Dimension)
        Coord(~Active)=NaN;
    end
    %--------------------------------------------------------------------
    %
    if removeTime
        szCoord = size(Coord);
        Coord = reshape(Coord,[szCoord(2:end) 1]);
    end
    %
    Ans = setfield(Ans,coordname{iCoord},Coord);
    if ~isempty(CoordInfo.Attribute)
        Attribs = {CoordInfo.Attribute.Name};
        j = strmatch('units',Attribs,'exact');
        if ~isempty(j)
            unit = CoordInfo.Attribute(j).Value;
            units = {'degrees_east','degree_east','degreesE','degreeE', ...
                'degrees_north','degree_north','degreesN','degreeN'};
            if ismember(unit,units)
                unit = 'deg';
            end
            Ans = setfield(Ans,[ coordname{iCoord} 'Units'],unit);
        end
    end
end
%
if ~isempty(Info.Z) && Props.hasCoords
    vdimid = Info.Z;
    CoordInfo = FI.Dataset(vdimid);
    %
    Attribs = {CoordInfo.Attribute.Name};
    j=strmatch('formula_terms',Attribs,'exact');
    if ~isempty(j)
        formula = CoordInfo.Attribute(j).Value;
        FormulaTerms = multiline(formula,' ','cell');
        i = 1;
        while i<=length(FormulaTerms)
           if isempty(FormulaTerms{i})
              FormulaTerms(i,:)=[];
           else
              i=i+1;
           end
        end
        FormulaTerms = reshape(FormulaTerms,2,length(FormulaTerms)/2)';
    end
    %
    j=strmatch('standard_name',Attribs,'exact');
    if ~isempty(j)
        standard_name = CoordInfo.Attribute(j).Value;
        switch standard_name
            case 'atmosphere_sigma_coordinate'
                [sigma  , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                [ps     , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                [ptop   , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                Z = zeros(szData);
                for t=1:size(Z,1)
                    for k=1:length(sigma)
                        Z(t,:,:,k) = ptop+sigma(k)*(ps(t,:,:)-ptop);
                    end
                end
            case 'atmosphere_hybrid_sigma_pressure_coordinate'
                if isequal(FormulaTerms{1,1},'a:')
                    [a      , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                    [b      , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                    [ps     , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                    [p0     , status] = netcdf_get(FI,FormulaTerms{4,2},Props.Dimension,idx);
                    Z = zeros(szData);
                    for t=1:size(Z,1)
                        for k=1:length(a)
                            Z(t,:,:,k) = a(k)*p0+b(k)*ps(t,:,:);
                        end
                    end
                else
                    [ap     , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                    [b      , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                    [ps     , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                    Z = zeros(szData);
                    for t=1:size(Z,1)
                        for k=1:length(ap)
                            Z(t,:,:,k) = ap(k)+b(k)*ps(t,:,:);
                        end
                    end
                end
            case 'atmosphere_hybrid_height_coordinate'
                [tau     , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                [eta     , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                [ztop    , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                [zsurface, status] = netcdf_get(FI,FormulaTerms{4,2},Props.Dimension,idx);
                Z = zeros(szData);
                for t=1:size(Z,1)
                    for k=1:length(tau)
                        Z(t,:,:,k) = tau(k)*zsurface(t,:,:)+eta(k)*ztop;
                    end
                end
            case 'atmosphere_sleve_coordinate'
                [a       , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                [b1      , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                [b2      , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                [ztop    , status] = netcdf_get(FI,FormulaTerms{4,2},Props.Dimension,idx);
                [zsurf1  , status] = netcdf_get(FI,FormulaTerms{5,2},Props.Dimension,idx);
                [zsurf2  , status] = netcdf_get(FI,FormulaTerms{6,2},Props.Dimension,idx);
                Z = zeros(szData);
                for t=1:size(Z,1)
                    for k=1:length(a)
                        Z(t,:,:,k) = a(k)*ztop+b1(k)*zsurf1(t,:,:)+b2(k)*zsurf2(t,:,:);
                    end
                end
            case 'ocean_sigma_coordinate'
                [sigma  , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                [eta    , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                [depth  , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                Z = zeros(szData);
                for t=1:size(Z,1)
                    for k=1:length(sigma)
                        Z(t,:,:,k) = eta(t,:,:)+(depth+eta(t,:,:))*sigma(k);
                    end
                end
            case 'ocean_s_coordinate'
                [s      , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                [eta    , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                [depth  , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                [a      , status] = netcdf_get(FI,FormulaTerms{4,2},Props.Dimension,idx);
                [b      , status] = netcdf_get(FI,FormulaTerms{5,2},Props.Dimension,idx);
                [depth_c, status] = netcdf_get(FI,FormulaTerms{6,2},Props.Dimension,idx);
                C = (1-b)*sinh(a*s)/sinh(a) + b*(tanh(a*(s+0.5))/(2*tanh(0.5*a))-0.5);
                Z = zeros(szData);
                for t=1:size(Z,1)
                    for k=1:length(s)
                        Z(t,:,:,k) = eta(t,:,:)*(1+s(k))+depth_c*s(k)+(depth-depth_c)*C(k);
                    end
                end
            case 'ocean_sigma_z_coordinate'
                [sigma  , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                [eta    , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                [depth  , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                [depth_c, status] = netcdf_get(FI,FormulaTerms{4,2},Props.Dimension,idx);
                [nsigma , status] = netcdf_get(FI,FormulaTerms{5,2},Props.Dimension,idx);
                [zlev   , status] = netcdf_get(FI,FormulaTerms{6,2},Props.Dimension,idx);
                K=idx{K_};
                Z = zeros(szData);
                for t=1:size(Z,1)
                    for k=1:length(s)
                        if K(k)<=nsigma
                            Z(t,:,:,k) = eta(t,:,:) + sigma(k)*(min(depth_c,depth)+eta(t,:,:));
                        else
                            Z(t,:,:,k) = zlev(k);
                        end
                    end
                end
            case 'ocean_double_sigma_coordinate'
                [sigma  , status] = netcdf_get(FI,FormulaTerms{1,2},Props.Dimension,idx);
                [depth  , status] = netcdf_get(FI,FormulaTerms{2,2},Props.Dimension,idx);
                [z1     , status] = netcdf_get(FI,FormulaTerms{3,2},Props.Dimension,idx);
                [z2     , status] = netcdf_get(FI,FormulaTerms{4,2},Props.Dimension,idx);
                [a      , status] = netcdf_get(FI,FormulaTerms{5,2},Props.Dimension,idx);
                [href   , status] = netcdf_get(FI,FormulaTerms{6,2},Props.Dimension,idx);
                [k_c    , status] = netcdf_get(FI,FormulaTerms{7,2},Props.Dimension,idx);
                K=idx{K_};
                Z = zeros(szData);
                for t=1:size(Z,1)
                    for k=1:length(s)
                        f = 0.5*(z1+z2) + 0.5*(z1-z2)*tanh(2*a/(z1-z2)*(depth-href));
                        if K(k)<=k_c
                            Z(t,:,:,k) = sigma(k)*f;
                        else
                            Z(t,:,:,k) = f + (sigma(k)-1)*(depth-f);
                        end
                    end
                end
            otherwise
                error(sprintf('%s not yet implemented',standard_name))
        end
    else
        [Z, status] = netcdf_get(FI,CoordInfo,Props.Dimension,idx);
        Z = expand_hdim(Z,szData,hdim);
    end
    %--------------------------------------------------------------------
    %
    if removeTime
        szCoord = size(Z);
        Z = reshape(Z,[szCoord(2:end) 1]);
    end
    %--------------------------------------------------------------------
    Ans.Z = Z;
    %
    szZ = size(Z);
    szX = ones(size(szZ));
    szX(1:ndims(Ans.X)) = size(Ans.X);
    rep = szZ./szX;
    Ans.X = repmat(Ans.X,rep);
    Ans.Y = repmat(Ans.Y,rep);
    %
end
%
if ~Props.hasCoords
    %
    % Grid regular grid
    %
    Ans.X = repmat(idx{M_}(:),1,length(idx{N_}));
    Ans.Y = repmat(idx{N_}(:)',length(idx{M_}),1);
    if Props.DimFlag(T_) && length(idx{T_})>1
        Ans.X = reshape(Ans.X,[1 size(Ans.X)]);
        Ans.Y = reshape(Ans.Y,[1 size(Ans.Y)]);
    end
    if Props.DimFlag(K_)
        Ans.Z = idx{K_};
    end
end

% read time ...
T=[];
if Props.DimFlag(T_)
    T=readtim(FI,Props,idx{T_});
end
Ans.Time=T;

varargout={Ans FI};
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,domain)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE =======================================
PropNames={'Name'                   'Units' 'Geom' 'Coords' 'DimFlag' 'DataInCell' 'NVal' 'SubFld' 'MNK' 'varid'  'Dimension' 'hasCoords' 'VectorDef'};
DataProps={'dummy field'            ''      ''     ''      [0 0 0 0 0]  0           0      []       0     []          {}          0         0};
Out=cell2struct(DataProps,PropNames,2);
%Out.MName='M';
%Out.NName='N';
%Out.KName='K';
% -----------------------------------------------------------------------------
ndims = length(FI.Dimension);
nvars = length(FI.Dataset);
ngatts = length(FI.Attribute);
%
Dummy = Out;
Dummy.Name='-------';
%
% Following lines are a hack to detect vector quantities for XBeach netcdf files
% NOTE: also [min(x-component) min(y-component)] is incorrectly detected as vector quantity
%
% for i=1:length(FI.Dataset)
%     for j=1:length(FI.Dataset(i).Attribute)
%         if strcmp(FI.Dataset(i).Attribute(j).Name,'long_name')
%             nm=FI.Dataset(i).Attribute(j).Value;
%             if strfind(nm,'x-')
%                 nm=strrep(nm,'x-','');
%                 nm=[nm ', x-component'];
%             elseif strfind(nm,'y-')
%                 nm=strrep(nm,'y-','');
%                 nm=[nm ', y-component'];
%             end
%             FI.Dataset(i).Attribute(j).Value=nm;
%         end
%     end
% end
%
if nvars==0
    Out = Out([]);
else
    %
    % Process variables and add them to the list
    %
    for ivar=1:nvars
        Insert=Out(1);
        Info = FI.Dataset(ivar);
        if isfield(Info.Attribute,'Name')
            Attribs = {Info.Attribute.Name};
        else
            Attribs = {};
        end
        %
        j = strmatch('long_name',Attribs,'exact');
        if ~isempty(j)
            Insert.Name = Info.Attribute(j).Value;
        else
            j = strmatch('standard_name',Attribs,'exact');
            if ~isempty(j)
                Insert.Name = Info.Attribute(j).Value;
            else
                Insert.Name = Info.Name;
            end
        end
        %
        j = strmatch('units',Attribs,'exact');
        if ~isempty(j)
            Insert.Units = Info.Attribute(j).Value;
        else
            Insert.Units = '';
        end
        %
        Insert.NVal = 1;
        Insert.Dimension = cell(1,5);
        %
        for i=1:5
            if ~isnan(Info.TSMNK(i))
                Insert.DimFlag(i)=1;
                Insert.Dimension{i}=FI.Dimension(Info.TSMNK(i)+1).Name;
            end
        end
        %
        if ~isempty(Info.SubFieldDim)
            %Insert.Name = [Insert.Name ' (incomplete assignment)'];
            Insert.SubFld={};
            for d = Info.SubFieldDim+1
                Insert.SubFld(end+1,1:2) = {FI.Dimension(d).Name FI.Dimension(d).Length};
            end
        end
        %
        if ~isempty(Info.X) && ~isempty(Info.Y)
            Insert.hasCoords=1;
            if ~Insert.DimFlag(N_) % 1D data set
                if Insert.DimFlag(K_)
                    Insert.Geom = 'PNT+';
                    Insert.Coords = 'xy+z';
                else
                    Insert.Geom = 'PNT';
                    Insert.Coords = 'xy';
                end
            end
        end
        %
        Insert.varid = Info.Varid;
        %
        Out(end+1)=Insert;
    end
    Out(1)=[];
end

%
% detect vector quantities
%
% VecStdNameTable: component_1 component_2 quickplot_combined_name
VecStdNameTable = {
    'sea_water_speed','direction_of_sea_water_velocity',2,'sea_water_velocity'
    'sea_ice_speed','direction_of_sea_ice_speed',2,'sea_water_velocity'
    'wind_speed','wind_to_direction',2,'air_velocity'
    'eastward_sea_water_velocity','northward_sea_water_velocity',1,'velocity'
    'eastward_sea_ice_velocity','northward_sea_ice_velocity',1,'sea_ice_velocity'
    'eastward_wind_shear','northward_wind_shear',1,'wind_shear'
    'surface_downward_eastward_wind','surface_downward_northward_wind',1,'surface_downward_wind'
    'eastward_wind','northward_wind',1,'air_velocity'};
nVecStdNames = size(VecStdNameTable,1);

i=1;
while i<length(Out)
    stdname = FI.Dataset(Out(i).varid+1).StdName;
    j = strmatch(stdname,VecStdNameTable(:,1:2),'exact');
    y=[];
    if ~isempty(j)
        % standard name matches known standard name of a vector component
        if j<=nVecStdNames
            j2 = j+nVecStdNames;
            Name = VecStdNameTable{j,4};
            VectorDef = VecStdNameTable{j,3};
        else
            j2 = j-nVecStdNames;
            Name = VecStdNameTable{j2,4};
            VectorDef = VecStdNameTable{j2,3};
        end
        Ystr = VecStdNameTable{j2};
        for i2=i+1:length(Out)
            stdname = FI.Dataset(Out(i2).varid+1).StdName;
            if strcmp(stdname,Ystr)
                y=i2;
                break
            end
        end
    elseif length(Out(i).Name)>12 && strcmp(Out(i).Name(end-12:end),', x-component')
        Ystr = Out(i).Name; Ystr(end-10)='y';
        Name = Out(i).Name(1:end-13);
        j=1; j2=2;
        VectorDef = 1;
        for i2=1:length(Out)
            if strcmp(Out(i2).Name,Ystr)
                y=i2;
                break
            end
        end
    end
    if ~isempty(y)
        Out(i).NVal=2;
        Out(i).Name = Name;
        Out(i).VectorDef = VectorDef;
        if j<j2
            Out(i).varid=[Out(i).varid Out(y).varid];
        else
            Out(i).varid=[Out(y).varid Out(i).varid];
        end
        Out(y)=[];
        if y<i
            i=i-1;
        end
    end
    i=i+1;
end

hasCoords = [Out.hasCoords]==1;
OutNoCoords = Out(~hasCoords);
Out = Out(hasCoords);
%
matchDims = 1:length(Out);
for i = 1:length(Out)
    for j = 1:i-1
        if isequal(Out(i).Dimension,Out(j).Dimension)
            matchDims(i) = j;
            break
        end
    end
end
%
OutCoords = [];
for m = unique(matchDims)
    OutCoords = [OutCoords Out(matchDims==m) Dummy];
end
Out = [OutCoords OutNoCoords];
%
for i = length(OutCoords)+(1:length(OutNoCoords))
    if Out(i).DimFlag(M_)
        Out(i).MName = Out(i).Dimension{M_};
        [V,cnt,err] = sscanf(Out(i).MName,'%f',2);
        if cnt == 1 && isempty(err)
            Out(i).MName = 'M';
        end
    end
    if Out(i).DimFlag(N_)
        Out(i).NName = Out(i).Dimension{N_};
        [V,cnt,err] = sscanf(Out(i).NName,'%f',2);
        if cnt == 1 && isempty(err)
            Out(i).NName = 'N';
        end
    end
    if Out(i).DimFlag(K_)
        Out(i).KName = Out(i).Dimension{K_};
        [V,cnt,err] = sscanf(Out(i).KName,'%f',2);
        if cnt == 1 && isempty(err)
            Out(i).KName = 'K';
        end
    end
end
%
for i = 1:length(Out)
    if ~isempty(Out(i).varid)
        Info = FI.Dataset(Out(i).varid(1)+1);
        for j = 1:length(Info.Attribute)
            if strcmp(Info.Attribute(j).Name,'cell_methods')
                Out(i).Name = [Out(i).Name ' - ' Info.Attribute(j).Value];
            end
        end
    end
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function [subf,rec]=getsubfields(FI,Props,f)
if isempty(Props.SubFld)
    subf={};
    rec.Fld={};
    rec.Val=[];
else
    subf={''};
    Fld=Props.SubFld(:,1)';
    Val=zeros(1,0);
    for d = 1:length(Fld)
        nval = Props.SubFld{d,2};
        newsubf = {};
        newVal = [];
        for f = 1:length(subf)
            subf_f = subf{f};
            Val_f = Val(f,:);
            if ~isempty(subf_f)
                subf_f = [subf_f ', '];
            end
            for v=1:Props.SubFld{d,2}
                if nval>1
                    newsubf{end+1}=sprintf('%s%s=%i',subf_f,Fld{d},v);
                else
                    newsubf{end+1}=subf_f;
                end
                newVal(end+1,1:d)=[Val_f v];
            end
        end
        subf = newsubf;
        Val = newVal;
    end
    if isequal(subf,{''})
        subf={};
    end
    rec.Fld=Fld;
    rec.Val=Val;
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function sz=getsize(FI,Props)
T_=1; ST_=2; M_=3; N_=4; K_=5;
sz=[0 0 0 0 0];
if ~isempty(Props.varid)
    Info=FI.Dataset(Props.varid(1)+1);
    for d_ = [T_ ST_ M_ N_ K_]
        if Props.DimFlag(d_)
            sz(d_) = FI.Dimension(Info.TSMNK(d_)+1).Length;
        end
    end
end
%======================== SPECIFIC CODE =======================================

% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function T=readtim(FI,Props,t)
T_=1; ST_=2; M_=3; N_=4; K_=5;
%======================== SPECIFIC CODE =======================================
tvar = FI.Dataset(Props.varid(1)+1).Time;
tinfo = FI.Dataset(tvar).Info;
T = double(nc_varget(FI.FileName,FI.Dataset(tvar).Name));
if ischar(tinfo.RefDate)
    switch tinfo.RefDate
        case 'day as %Y%m%d.%f'
            Y = floor(T/10000);
            T = T - Y*10000;
            M = floor(T/100);
            T = T - M*100;
            D = floor(T);
            T = T - D;
            T = datenum(Y,M,D) + T;
        otherwise
            T = tinfo.DT * T;
    end
elseif ~isempty(tinfo.RefDate)
    T = tinfo.RefDate + tinfo.DT * T;
else
    T = tinfo.DT * T;
end
if t~=0
    T=T(t);
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Dimension = matchdims(CoordDims,VarDims)
Dimension = zeros(1,length(VarDims));
%
for i = 1:length(CoordDims)
    idim = strmatch(CoordDims{i},VarDims,'exact');
    if ~isempty(idim)
        Dimension(idim) = i;
    else
        error(sprintf('Coordinate dimension ''%s'' not matched by variable dimension.',CoordDims{i}))
    end
end
%
for i = 1:length(VarDims)
    if Dimension(i) == 0
        Dimension(i) = max(Dimension)+1;
    end
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function [Data, errmsg] = netcdf_get(FI,var,RequestDims,RequestedSubset)
errmsg='';
%
if isempty(var)
    errmsg='Variable name is empty.';
    error(errmsg)
elseif ischar(var)
    var = strmatch(var,{FI.Dataset.Name},'exact')-1;
elseif isstruct(var)
    var = var.Varid;
end
Info = FI.Dataset(var+1);
varid = Info.Varid;
if isempty(Info)
    errmsg=sprintf('Variable ''%s'' not found in file.',Info.Name);
    error(errmsg)
end
%
rank=Info.Rank;
N=length(RequestDims);
permuted=zeros(1,N);
for d=1:N
    DName=RequestDims{d};
    if ~isempty(DName)
        d_netcdf=strmatch(DName,Info.Dimension,'exact');
        if isempty(d_netcdf)
            %
            % requested dimension does not occur in NetCDF source
            % use higher dimensions to fill in these dimensions.
            %
            rank=rank+1;
            permuted(d)=rank;
        else
            %
            % requested dimension occurs in NetCDF source
            %
            permuted(d)=d_netcdf;
        end
    end
end
%
for d=1:Info.Rank
    if all(permuted~=d)
        errmsg=sprintf('Dimension ''%s'' of ''%s'' could not be matched to any of the requested dimensions: ',Info.Dimension{d},Info.Name);
        errmsg=cat(2,errmsg,sprintf('''%s'', ',RequestDims{permuted~=0}));
        errmsg(end-1:end)=[];
        error(errmsg)
    end
end
%
fliporder = ~getpref('SNCTOOLS','PRESERVE_FVD',false);
if fliporder
   reverse=Info.Rank:-1:1;
else
   reverse=1:Info.Rank;
end
%
loadtype = 'double';
if Info.Nctype == nc_char
    loadtype = 'text';
end
if isempty(Info.Dimid)
    Data = nc_varget(FI.FileName,FI.Dataset(varid+1).Name);
elseif nargin==3
    Data = nc_varget(FI.FileName,FI.Dataset(varid+1).Name);
else
    %
    % Convert data subset in QP dimension order to NetCDF dimension order
    %
    RS_netcdf=cell(1,Info.Rank);
    start_coord=zeros(1,Info.Rank);
    count_coord=zeros(1,Info.Rank);
    %
    % The following block selection procedure is inefficient if a relatively
    % limited number of values is requested compared to full range of
    % indices, e.g. [1 2 100]
    %
    for d=1:N
        p=permuted(d);
        if p>0 && p<=Info.Rank
            RS_netcdf(p)=RequestedSubset(d);
            start_coord(p)=min(RS_netcdf{p})-1;
            count_coord(p)=max(RS_netcdf{p})-start_coord(p);
            RS_netcdf{p}=RS_netcdf{p}-start_coord(p);
        end
    end
    %
    if fliporder
        start_coord = fliplr(start_coord);
        count_coord = fliplr(count_coord);
    end
    %
    Data = nc_varget(FI.FileName,FI.Dataset(varid+1).Name,start_coord,count_coord);
    if length(count_coord)>1
        Data = reshape(Data,count_coord);
    end
    Data=Data(RS_netcdf{reverse});
end
%
reverse=[reverse Info.Rank+1:5];
permuted(permuted==0)=[];
if length(permuted)>1
    Data=permute(Data,reverse(permuted));
end
%
if ~isempty(Info.Attribute)
    Attribs = {Info.Attribute.Name};
    %
    missval = strmatch('missing_value',Attribs,'exact');
    if ~isempty(missval)
        missval = Info.Attribute(missval).Value;
        Data(Data==missval)=NaN;
    end
    %
    missval = strmatch('valid_min',Attribs,'exact');
    if ~isempty(missval)
        missval = Info.Attribute(missval).Value;
        Data(Data<missval)=NaN;
    end
    %
    missval = strmatch('valid_max',Attribs,'exact');
    if ~isempty(missval)
        missval = Info.Attribute(missval).Value;
        Data(Data>missval)=NaN;
    end
    %
    missval = strmatch('valid_range',Attribs,'exact');
    if ~isempty(missval)
        missval = Info.Attribute(missval).Value;
        Data(Data<missval(1) | Data>missval(2))=NaN;
    end
    %
    missval = strmatch('_FillValue',Attribs,'exact');
    if ~isempty(missval)
        missval = Info.Attribute(missval).Value;
        Data(Data==missval)=NaN;
    else
        % NCL standard or general standard?
        % The following are the default settings for _FillValue by type: 
        %
        % logical   : -1
        % byte      : 0xff (hex), 0377 (octal)
        % short     : -99
        % integer   : -999
        % long      : -9999
        % float     : -999
        % double    : -9999
        % graphic   : -9999
        % file      : -9999
        % character : 0 or '\0' for those who know C
        % string    : "missing"
    end
end


function Coord = expand_hdim(Coord,szData,hdim)
szC = size(Coord);
if length(szC)<length(hdim)
    szC(end+1:length(hdim))=1;
end
if length(szData)<length(hdim)
    szData(end+1:length(hdim))=1;
end
if ~isequal(szC(hdim),szData(hdim))
    repC = szData./szC;
    repC(~hdim)=1;
    Coord = repmat(Coord,repC);
end
