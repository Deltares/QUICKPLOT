function S = shyfemmesh(cmd,FileName)
%SHYFEMMESH Read a SHYFEM mesh topology file.
%   MESH = SHYFEMMESH('open',FILENAME) reads a ISMAR-CNR SHYFEM mesh
%   topology file and returns a structure containing all mesh information.
%   The returned structure contains fields 
%    * NodeCoor: NNODES x 3 array with XYZ coordinates of NNODES mesh
%                nodes.
%    * Faces:    NELM x MAXNODE array with the indices of nodes for each of
%                the NELM elements. The number of nodes per element is at
%                most MAXNODE but may be smaller in which case the last
%                node indices are 0.
%
%    See also: ADCIRCMESH, NODELEMESH, MIKEMESH

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2014 Stichting Deltares.                                     
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

function S = local_open(FileName)
S.FileName = FileName;
S.FileType = 'SHYFEM mesh';
fid = fopen(FileName,'r');
try
    Line = fgetl(fid);
    X=sscanf(Line,'%i');
    if length(X)~=4
        error('The first line should contain 4 integers:\n%s',Line)
    end
    nNodes=X(1);
    nElm=X(3);
    nNodePerElm=3;
    Elm = fscanf(fid,'%i',[nNodePerElm nElm]);
    if numel(Elm)~=nNodePerElm*nElm
        error('Unable to read element table.')
    end
    for i = 1:nNodes
        nNeighb = fscanf(fid,'%i',1);
        N = fscanf(fid,'%i',nNeighb+1);
        if length(N)~=nNeighb+1
            error('Unable to read neighbours of node: %i',i)
        end
    end
    Coords=fscanf(fid,'%f',[5 nNodes]);
    if ~isequal(Coords(1,:),1:nNodes)
        error('Node numbers in file don''t match 1:%i',nNodes)
    end
    S.NodeCoor = Coords(2:4,:)';
    S.NodeType = Coords(5,:)';
    S.Faces = Elm';
    fclose(fid);
catch
    fclose(fid);
    error(lasterr)
end