function Out=gmsh(cmd,varargin)
%GMSH Read/write for GMSH grid files.
%
%   FileInfo=GMSH('open',FileName)
%   NewFileInfo=GMSH('write',FileName,FileInfo)

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2015 Stichting Deltares.                                     
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

if nargin==0
    if nargout>0
        Out=[];
    end
    return
end
switch cmd
    case 'open'
        Out=Local_open_file(varargin{:});
    case 'write'
        Out=Local_write_file(varargin{:});
    otherwise
        uiwait(msgbox('unknown command','modal'));
end


function parsecheck(fid,str)
Line = fgetl(fid);
if ~ischar(Line)
    error('End of file encountered while trying to read "%s"',str)
end
Line = deblank(Line);
if ~strcmp(Line,str)
    error('Reading "%s" but expecting "%s"',Line,str)
end


function [NrNodes,ElmName] = element(Elm)
switch Elm
    case {1,8,26,27,28}
        NrNodes = [1 2;8 3;26 4;27 5;28 6];
        ElmName = 'edge';
    case {2,9,20,21,22,23,24,25}
        NrNodes = [2 3; 9 6;20 9;21 10;22 12;23 15;24 15;25 21];
        ElmName = 'triangle';
    case {3,10,16}
        NrNodes = [3 4; 10 9;16 8];
        ElmName = 'quandrangle';
    case {4,11,29,30,31}
        NrNodes = [4 4;11 10;29 20;30 35;31 56];
        ElmName = 'tetrahedron';
    case {5,12,17,92,93}
        NrNodes = [5 8;12 27;17 20;92 64;93 125];
        ElmName = 'hexahedron';
    case {6,13,18}
        NrNodes = [6 6;13 18;18 15];
        ElmName = 'prism';
    case {7,14,19}
        NrNodes = [7 5;14 14;19 13];
        ElmName = 'pyramid';
    case 15
        NrNodes = [15 1];
        ElmName = 'point';
end
NrNodes = NrNodes(NrNodes(:,1)==Elm,2);


function FI=Local_open_file(filename)
FI.FileName=filename;
fid=fopen(filename,'r');
if fid<0
    error('Cannot open "%s".',filename)
end
try
    % $MeshFormat
    parsecheck(fid,'$MeshFormat')
    % version-number file-type data-size
    % 2.2 0 8
    Line = fgetl(fid);
    Values = sscanf(Line,'%f %i %i');
    FI.VersionNumber = Values(1);
    FI.FileType = Values(2);
    FI.DataSize = Values(3);
    if FI.VersionNumber~=2.2
        error('GMSH file version %g is not supported; only version 2.2 is supported.')
    elseif FI.FileType~=0 && FI.FileType~=1
        error('GMSH file type %i is not supported; only 0 (ASCII) and 1 (BINARY) are supported.')
    elseif FI.DataSize~=8
        error('GMSH data size %i is not supported; only sizeof(double)=8 is supported.')
    elseif FI.FileType==0
        FI.FileType = 'ASCII';
    else % FI.FileType==1
        FI.FileType = 'BINARY';
        ONE = fread(fid,1,'int32',0,'l');
        if isequal(ONE,1)
            FI.ByteOrder = 'l';
        elseif isequal(ONE,2)
            FI.ByteOrder = 'b';
        else
            error('Unable to identify GMSH byte order; reading %i but expecting 1.',ONE)
        end
    end
    % $EndMeshFormat
    parsecheck(fid,'$EndMeshFormat')
    %
    while ~feof(fid)
        Line = deblank(fgetl(fid));
        switch Line
            case '$Nodes'
                NumNodes = fscanf(fid,'%i',1);
                Nodes = fscanf(fid,'%i %f %f %f',[4 NumNodes]);
                FI.Nodes.Nr = Nodes(1,:);
                FI.Nodes.XYZ  = Nodes(2:end,:);
                fgetl(fid);
                parsecheck(fid,'$EndNodes')
            case '$Elements'
                NumElms = fscanf(fid,'%i \n',1);
                FI.Element.Nr   = zeros(1,NumElms);
                FI.Element.Type = zeros(1,NumElms);
                FI.Element.Tags = zeros(0,NumElms);
                FI.Elememt.Node = zeros(0,NumElms);
                for i = 1:NumElms
                    Line = fgetl(fid);
                    Values = sscanf(Line,'%f');
                    FI.Element.Nr(i)   = Values(1);
                    FI.Element.Type(i) = Values(2);
                    NrTag = Values(3); % tag 1: physical entity; tag 2: elementary geometrical entity; tag 3: mesh partition; following: partition ids (negative: ghost cell)
                    [NrNod,ElmNm] = element(FI.Element.Type(i));
                    if NrTag>0
                        FI.Element.Tags(1:NrTag,i) = Values(3+(1:NrTag))';
                    end
                    FI.Element.Node(1:NrNod,i) = Values(3+NrTag+(1:NrNod))';
                end
                parsecheck(fid,'$EndElements')
            %case '$PhysicalName'
            %case '$Periodic'
            %case {'$NodeData','$ElementData','$ElementNodeData'}
            otherwise
                if Line(1)~='$' || any(isspace(Line))
                    error('Section header "%s" not supported.',Line)
                else % well formatted unrecognized section ... skip it
                    EndLine = [Line(1) 'End' Line(2:end)];
                    fprintf('Skipping lines from %s until %s\n',Line,EndLine);
                    while ~strcmp(Line,EndLine)
                        Line = fgetl(fid);
                        if ~ischar(Line)
                            error('End of line while searching for "%s".',EndLine)
                        end
                    end
                end
        end
    end
    %
    fclose(fid);
catch err
    fclose(fid);
    rethrow(err)
end
