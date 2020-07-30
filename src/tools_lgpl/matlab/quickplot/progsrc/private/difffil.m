function varargout=difffil(FI,domain,field,cmd,varargin)
%DIFFFIL QP support for file differences.
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
%   Copyright (C) 2011-2020 Stichting Deltares.                                     
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

if ~isfield(FI,'Files')
    FIo = FI;
    FI = [];
    FI.Files = FIo;
    FI.DiffType = 'index';
end

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
        varargout={readsts(FI,domain,Props,varargin{:})};
        return
    case 'subfields'
        varargout={getsubfields(FI,domain,Props,varargin{:})};
        return
    otherwise
        [XYRead,DataRead,DataInCell]=gridcelldata(cmd);
end

checkgrids = strcmp(FI.DiffType,'renum');
if Props.NVal>0 && checkgrids
    [success,Grid1,FI.Files(1)] = qp_getdata(FI.Files(1),domain,Props.Q1,'grid');
    [success,Grid2,FI.Files(2)] = qp_getdata(FI.Files(2),domain,Props.Q2,'grid');
    if isfield(Grid1,'ValLocation')
        switch Grid1.ValLocation
            case 'NODE'
                X1 = Grid1.X;
                Y1 = Grid1.Y;
                %
                X2 = Grid2.X;
                Y2 = Grid2.Y;
            case 'EDGE'
                X1 = mean(Grid1.X(Grid1.EdgeNodeConnect),2);
                Y1 = mean(Grid1.Y(Grid1.EdgeNodeConnect),2);
                %
                X2 = mean(Grid2.X(Grid2.EdgeNodeConnect),2);
                Y2 = mean(Grid2.Y(Grid2.EdgeNodeConnect),2);
            case 'FACE'
                FNC = Grid1.FaceNodeConnect;
                Mask = isnan(FNC);
                N = sum(~Mask,2);
                FNC(Mask) = 1;
                X1 = Grid1.X(FNC); X1(Mask) = 0; X1 = sum(X1,2)./N;
                Y1 = Grid1.Y(FNC); Y1(Mask) = 0; Y1 = sum(Y1,2)./N;
                %
                FNC = Grid2.FaceNodeConnect;
                Mask = isnan(FNC);
                N = sum(~Mask,2);
                FNC(Mask) = 1;
                X2 = Grid2.X(FNC); X2(Mask) = 0; X2 = sum(X2,2)./N;
                Y2 = Grid2.Y(FNC); Y2(Mask) = 0; Y2 = sum(Y2,2)./N;
        end
        [~,I1] = sort(Y1);
        [~,I2] = sort(X1(I1));
        I = I1(I2);
        [~,RI] = sort(I);
        %
        [~,J1] = sort(Y2);
        [~,J2] = sort(X2(J1));
        J = J1(J2);
        %
        if isequal(X1(I),X2(J)) && isequal(Y1(I),Y2(J))
            JRI = J(RI);
        else
            error('The %s coordinates are not equal after sorting.',lower(Grid1.ValLocation))
        end
    end
end

[success,Ans,FI.Files(1)] = qp_getdata(FI.Files(1),domain,Props.Q1,cmd,varargin{:});
if ~success
    error(lasterr)
end

if Props.NVal>0
    cmd = strrep(cmd,'grid','');
    args = varargin;
    if checkgrids
        i = sum(Props.DimFlag(1:M_)~=0);
        if isequal(args{i},0)
            args{i} = JRI;
        else
            args{i} = JRI(args{i});
        end
    end
    [success,Data2,FI.Files(2)] = qp_getdata(FI.Files(2),domain,Props.Q2,cmd,args{:});
    if ~success
        error(lasterr)
    end
    %
    cflds = {'Val','XComp','YComp','ZComp','XDamVal','YDamVal'};
    for cfld = cflds
        fld = cfld{1};
        if isfield(Data2,fld)
            v1 = Ans.(fld);
            v2 = Data2.(fld);
            v1 = v1 - v2;
            Ans.(fld) = v1;
        end
    end
    %
    % temperature units are always relative or unspecified
    %
    if isfield(Ans,'AbsoluteUnits')
        Ans = rmfield(Ans,'AbsoluteUnits');
        Ans.TemperatureType = 'relative';
    elseif isfield(Ans,'TemperatureType')
        % The difference of two temperature quantities will always be relative
        % however only if the base quantities are simple temperatures and not
        % if the quantity is e.g. a temperature flux or square of temperature
        % So, keep TemperatureType unspecified unchanged.
        if ~strcmp(Ans.TemperatureType,'unspecified')
            Ans.TemperatureType = 'relative';
        end
    end
end

varargout={Ans FI};
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Domains=domains(FI)
[success,D1] = qp_getdata(FI.Files(1),'domains');
[success,D2] = qp_getdata(FI.Files(2),'domains');
if isempty(D1) && isempty(D2)
    Domains = {};
elseif isequal(D1,D2)
    Domains = D1;
elseif length(D1)<=1 && length(D2)<=1
    if length(D1)==1 && isempty(D2)
        Domains = D1;
    elseif isempty(D1) && length(D2)==1
        Domains = D2;
    else % length(D1)==1 && length(D2)==1
        Domains = { sprintf('%s/%s',D1{1},D2{1}) };
    end
else
    error('Multiple different domains not supported.')
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function Out=infile(FI,domain)
[success,Q1] = qp_getdata(FI.Files(1),domain);
if ~success
    error(lasterr)
end
[success,Q2] = qp_getdata(FI.Files(2),domain);
if ~success
    error(lasterr)
end
%
Out = cell2struct(cell(12,length(Q1)),{'Name','Units','Geom','Coords','DimFlag','DataInCell','NVal','Q1','Q2','Size','SubFld','ClosedPoly'});
q2 = {Q2.Name};
j = 0;
for i=1:length(Q1)
    if strcmp(Q1(i).Name,'-------')
        j=j+1;
        Out(j).Name = Q1(i).Name;
        Out(j).Units = '';
        Out(j).Geom = '';
        Out(j).Coords = '';
        Out(j).DimFlag = [0 0 0 0 0];
        Out(j).DataInCell = 0;
        Out(j).NVal = 0;
        Out(j).Q1 = [];
        Out(j).Q2 = [];
        Out(j).Size = [];
        Out(j).SubFld = {};
        Out(j).ClosedPoly = 0;
        continue
    end
    if Q1(i).NVal<0
        % cannot diff dedicated plots
        continue
    end
    i2 = strmatch(Q1(i).Name,q2,'exact');
    if isempty(i2)
        % no match found
        continue
    end
    [success,sz] = qp_getdata(FI.Files(1),domain,Q1(i),'size');
    if ~success
        error(lasterr)
    end
    [success,sf] = qp_getdata(FI.Files(1),domain,Q1(i),'subfields');
    if ~success
        error(lasterr)
    end
    for k=length(i2):-1:1
        if ~isequal(Q1(i).NVal,Q2(i2(k)).NVal)
            % cannot take difference of scalar and vector or similar
            % mismatches.
            i2(k)=[];
        elseif ~isequal(Q1(i).DimFlag,Q2(i2(k)).DimFlag)
            % the dimension should match, although a mismatch in time
            % dependence and stations might be acceptable in the future.
            i2(k)=[];
        else
            [success,sz2] = qp_getdata(FI.Files(2),domain,Q2(i2(k)),'size');
            if ~success
                error(lasterr)
            end
            if ~isequal(sz,sz2)
                % allow for different number of time steps, stations in the
                % future?
                i2(k)=[];
            else
                [success,sf2] = qp_getdata(FI.Files(2),domain,Q2(i2(k)),'subfields');
                if ~success
                    error(lasterr)
                end
                if ~isequal(sf,sf2)
                    % might be acceptable in the future to select matching
                    % subfields, e.g. corresponding sediment fractions.
                    i2(k)=[];
                end
            end
        end
    end
    if length(i2)~=1
        % unable to uniquely identify the corresponding quantity
        continue
    end
    %
    NewFld.Name = Q1(i).Name;
    NewFld.Units = Q1(i).Units;
    if isfield(Q1,'Geom')
        NewFld.Geom = Q1(i).Geom;
    else
        NewFld.Geom = '';
    end
    if isfield(Q1,'Coords')
        NewFld.Coords = Q1(i).Coords;
    else
        NewFld.Coords = '';
    end
    if ~isequal(NewFld.Units,Q2(i2).Units)
        % might be able to relax this to compatible units later.
        continue
    end
    NewFld.DimFlag = Q1(i).DimFlag;
    NewFld.DataInCell = Q1(i).DataInCell;
    if ~isequal(NewFld.DataInCell,Q2(i2).DataInCell)
        % should not be too restrictive
        continue
    end
    NewFld.NVal = Q1(i).NVal;
    if NewFld.NVal~=0
        NewFld.Name = [NewFld.Name ' difference'];
    end
    NewFld.Q1 = Q1(i);
    NewFld.Q2 = Q2(i2);
    NewFld.Size = sz;
    NewFld.SubFld = sf;
    if isfield(Q1,'ClosedPoly')
        NewFld.ClosedPoly = Q1(i).ClosedPoly;
    else
        NewFld.ClosedPoly = 0;
    end
    %
    j = j+1;
    Out(j) = NewFld;
end
Out(j+1:end)=[];
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function subf=getsubfields(FI,domain,Props,f)
subf = Props.SubFld;
if nargin>3
    subf = subf(f);
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function sz=getsize(FI,domain,Props)
sz = Props.Size;
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function T=readtim(FI,domain,Props,t)
TimeNr = {};
if nargin>3
    TimeNr = {t};
end
[success,T] = qp_getdata(FI.Files(1),domain,Props.Q1,'times',TimeNr{:});
if ~success
    error(lasterr)
end
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
function S=readsts(FI,domain,Props,t)
StationNr = {};
if nargin>3
    StationNr = {t};
end
[success,S] = qp_getdata(FI.Files(1),domain,Props.Q1,'stations',StationNr{:});
if ~success
    error(lasterr)
end
% -----------------------------------------------------------------------------
