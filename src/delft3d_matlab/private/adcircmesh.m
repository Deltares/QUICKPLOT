function S = adcircmesh(cmd,FileName)
%ADCIRCMESH Read an Adcirc fort.14 mesh topology file.
%   MESH = ADCIRCMESH('open',FILENAME) reads an Adcirc fort.14 mesh
%   topology file and returns a structure containing all mesh information.
%   The returned structure contains fields
%    * NodeCoor: NNODES x 3 array with XYZ coordinates of NNODES mesh
%                nodes.
%    * Faces:    NELM x MAXNODE array with the indices of nodes for each of
%                the NELM elements. The number of nodes per element is at
%                most MAXNODE but may be smaller in which case the last
%                node indices are 0.
%
%    See also: NODELEMESH, MIKEMESH

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

switch cmd
    case {'open','read'}
        S = local_open(FileName);
    otherwise
        error('Unknown command argument: %s',cmd)
end

function A = readmat(fid,nValPerLine,nLines,VarName)
offset = 0;
while 1
    [Apart,count]=fscanf(fid,'%f',[nValPerLine nLines]);
    nLinesRead = count/nValPerLine;
    if nLinesRead<nLines
        Line = fgetl(fid);
        if ~ischar(Line)
            error('End-of-file reached while reading %s',VarName)
        elseif round(nLinesRead) ~= nLinesRead
            VarName(1) = upper(VarName(1));
            error('%s data line interrupted by comment "%s"',VarName,Line)
        end
    end
    %
    if offset==0
        A = Apart;
        if nLinesRead<nLines
            A(nValPerLine,nLines) = 0;
        end
    else
        A(:,offset+(1:nLinesRead)) = Apart;
    end
    nLines = nLines-nLinesRead;
    if nLines==0
        fgetl(fid);
        return
    end
    offset = offset+nLinesRead;
end

function A = readelm(fid,nElm)
A = zeros(4,nElm);
for elm = 1:nElm
    Line = fgetl(fid);
    [Elm,count]=sscanf(Line,'%i');
    if count<2 || count<2+Elm(2)
        if isempty(Line)
            error('End-of-file reached while reading element node table')
        else
            error('Error reading node indices for element %i from line "%s"',elm,Line)
        end
    end
    A(1:2+Elm(2),elm) = Elm;
end

function S = local_open(FileName)
S.FileName = FileName;
S.FileType = 'Adcirc 14 mesh';
[fid,msg] = fopen(FileName,'r','n','US-ASCII');
if fid<0
    error('%s: %s',FileName,msg)
end
try
    Line = fgetl(fid);
    Excl = strfind(Line,'!');
    if ~isempty(Excl)
        Line = Line(1:Excl(1));
    end
    S.GridName = Line;
    %
    Line = fgetl(fid);
    Values = sscanf(Line,'%i',2);
    nElm = Values(1);
    nNodes = Values(2);
    if nNodes==0
       error('Invalid mesh: number of nodes = 0')
    elseif nElm==0
       error('Invalid mesh: number of elements = 0')
    end
    %
    Coords = readmat(fid,4,nNodes,'node coordinates');
    if ~isequal(Coords(1,:),1:nNodes)
        error('Node numbers in file don''t match 1:%i',nNodes)
    end
    S.NodeCoor = Coords(2:4,:)';
    %
    Elm = readelm(fid,nElm);
    if ~isequal(Elm(1,:),1:nElm)
        error('Element numbers in file don''t match 1:%i',nElm)
    end
    S.Faces = Elm(3:end,:)';
    %
    Line = fgetl(fid);
    if ischar(Line)
        nWaterlevelBndSeg = sscanf(Line,'%i',1);
        fgetl(fid); % line contains total number of open boundary nodes
        for seg = 1:nWaterlevelBndSeg
            Line = fgetl(fid);
            nBndSegNod = sscanf(Line,'%i',1);
            S.Bnd(seg).Type = 'waterlevel';
            S.Bnd(seg).Nodes = readmat(fid,1,nBndSegNod,sprintf('open boundary segment %i',seg));
        end
        %
        Line = fgetl(fid);
        if ischar(Line)
            nDischargeBndSeg = sscanf(Line,'%i',1);
            fgetl(fid); % line contains total number of land boundary nodes
            for seg = 1:nDischargeBndSeg
                Line = fgetl(fid);
                N = sscanf(Line,'%i',2);
                if isscalar(N)
                    N(2) = -999;
                end
                switch N(2)
                    case {0,1,2,10,11,12,20,21,22,30}
                        NVal = 1;
                        Values = {'ndx'};
                    case {3,13,23}
                        NVal = 3;
                        Values = {'ndx','barrier height','barrier supercritical flow coefficient'};
                    case {4,24}
                        NVal = 5;
                        Values = {'ndx','ndx2','barrier height','barrier subcritical flow coefficient','barrier supercritical flow coefficient'};
                    case {5,25}
                        % NODE NO.,IBCONN,BARINHT,BARINCFSB,BARINCFSP,PIPEHT,PIPECOEF,PIPEDIAM
                        NVal = 8;
                        Values = {'ndx','ndx2','barrier height','barrier subcritical flow coefficient','barrier supercritical flow coefficient','pipe height','pipe friction factor','pipe diameter'};
                    otherwise
                        % auto detect the number of values per boundary node ...
                        here = ftell(fid);
                        Line = fgetl(fid);
                        [~,NVal] = sscanf(Line,'%f');
                        fseek(fid,here,-1);
                        Values = {'ndx'};
                        for n = NVal:-1:2
                            Values{n} = sprintf('boundary parameter %d',n-1);
                        end
                end
                % interpret boundary index
                switch N(2)
                    case 0
                        BndType = 'external closed, free slip';
                    case 1
                        BndType = 'island closed, free slip';
                    case 2
                        BndType = 'external discharge, free slip';
                    case 3
                        BndType = 'external barrier, free slip';
                    case 4
                        BndType = 'internal barrier, free slip';
                    case 5
                        BndType = 'internal barrier with pipes, free slip';
                    case 10
                        BndType = 'external closed, no slip';
                    case 11
                        BndType = 'island closed, no slip';
                    case 12
                        BndType = 'external discharge, no slip';
                    case 13
                        BndType = 'external barrier, no slip';
                    case 20
                        BndType = 'external closed, weak formulation, free slip';
                    case 21
                        BndType = 'island closed, weak formulation, free slip';
                    case 22
                        BndType = 'external discharge, weak formulation, free slip';
                    case 23
                        BndType = 'external barrier, weak formulation, free slip';
                    case 24
                        BndType = 'internal barrier, weak formulation, free slip';
                    case 25
                        BndType = 'internal barrier with pipes, weak formulation, free slip';
                    case 30
                        BndType = 'Sommerfield radiation';
                    case 32
                        BndType = 'combined discharge and Sommerfield radiation';
                    case 40
                        BndType = 'zero normal velocity gradient, internal point method';
                    case 41
                        BndType = 'zero normal velocity gradient, Galerkin method';
                    case 52
                        BndType = 'periodic boundary, free slip';
                    case 102
                        BndType = 'external discharge, baroclinic, free slip';
                    case 112
                        BndType = 'external discharge, baroclinic, no slip';
                    case 122
                        BndType = 'external discharge, weak formulation, baroclinic, free slip';
                    otherwise
                        BndType = sprintf('unknown boundary type %d',N(2));
                end
                S.Bnd(nWaterlevelBndSeg+seg).Type = BndType;
                Data = readmat(fid,NVal,N(1),sprintf('land boundary segment %i',seg));
                S.Bnd(nWaterlevelBndSeg+seg).Nodes = Data(1,:);
                if length(Values)>1 && strcmp(Values{2},'ndx2')
                    S.Bnd(nWaterlevelBndSeg+seg).Nodes2 = Data(2,:);
                    ndx=2;
                else
                    ndx=1;
                end
                S.Bnd(nWaterlevelBndSeg+seg).Data = Data(ndx+1:end,:);
                S.Bnd(nWaterlevelBndSeg+seg).Values = Values(ndx+1:end);
            end
        end
    end
    fclose(fid);
catch
    fclose(fid);
    error(lasterr)
end

