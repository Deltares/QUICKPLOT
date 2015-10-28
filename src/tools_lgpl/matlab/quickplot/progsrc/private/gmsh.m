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
    Line = fgetl(fid);
    if ~ischar(Line)
        error('A GMSH file cannot be empty.')
    end
    % $MeshFormat
    FI.VersionNumber = 2.2;
    Line = deblank(Line);
    switch Line
        case '$MeshFormat'
            % A modern file
        case '$NOD'
            FI.VersionNumber = 1.0;
        case '$PostFormat'
            FI.VersionNumber = 1.4;
        otherwise
            error('Line 1 should read $MeshFormat (or $NOD or $PostFormat) but received: %s',Line)
    end
    if FI.VersionNumber==1
        % 1.0
        isbinary = false;
        Line = fgetl(fid);
        NumNodes = sscanf(Line,'%i',1);
        Nodes = fscanf(fid,'%i %f %f %f',[4 NumNodes]);
        FI.Nodes.Nr = Nodes(1,:);
        FI.Nodes.XYZ  = Nodes(2:end,:);
        fgetl(fid);
        parsecheck(fid,'$ENDNOD')
    else
        % 1.4 or 2.0
        % version-number file-type data-size
        Line = fgetl(fid);
        Values = sscanf(Line,'%f %i %i');
        FI.VersionNumber = Values(1);
        FI.FileType = Values(2);
        FI.DataSize = Values(3);
        if FI.VersionNumber~=1.4 && FI.VersionNumber~=2.2
            error('GMSH file version %g is not supported; only versions 1.4 and 2.2 are supported.')
        elseif FI.FileType~=0 && FI.FileType~=1
            error('GMSH file type %i is not supported; only 0 (ASCII) and 1 (BINARY) are supported.')
        elseif FI.DataSize~=8
            error('GMSH data size %i is not supported; only sizeof(double)=8 is supported.')
        elseif FI.FileType==0
            FI.FileType = 'ASCII';
            isbinary = false;
        else % FI.FileType==1
            FI.FileType = 'BINARY';
            isbinary = true;
            if FI.VersionNumber==2.2
                ONE = fread(fid,1,'int32',0,'l');
                if isequal(ONE,1)
                    FI.ByteOrder = 'l';
                elseif isequal(ONE,2)
                    FI.ByteOrder = 'b';
                else
                    error('Unable to identify GMSH byte order; reading %i but expecting 1.',ONE)
                end
            else
                FI.ByteOrder = 'n'; % unknown, so assume native
            end
        end
        if FI.VersionNumber==1.4
            parsecheck(fid,'$EndPostFormat')
        else
            % $EndMeshFormat
            parsecheck(fid,'$EndMeshFormat')
        end
    end
    %
    while ~feof(fid)
        Line = deblank(fgetl(fid));
        switch Line
            case '$Nodes'
                Line = fgetl(fid);
                NumNodes = sscanf(Line,'%i',1);
                if isbinary
                    Nodes = zeros(4,NumNodes);
                    for i = 1:NumNodes
                        Nodes(1,i) = fread(fid,1,'int32',0,FI.ByteOrder);
                        Nodes(2:4,i) = fread(fid,3,'float64',0,FI.ByteOrder);
                    end
                else
                    Nodes = fscanf(fid,'%i %f %f %f',[4 NumNodes]);
                end
                FI.Nodes.Nr = Nodes(1,:);
                FI.Nodes.XYZ  = Nodes(2:end,:);
                fgetl(fid);
                parsecheck(fid,'$EndNodes')
            case {'$Elements','$ELM'}
                NumElms = fscanf(fid,'%i \n',1);
                FI.Element.Nr   = zeros(1,NumElms);
                FI.Element.Type = zeros(1,NumElms);
                FI.Element.Tags = zeros(0,NumElms);
                FI.Element.Node = zeros(0,NumElms);
                i = 0;
                while i<NumElms
                    i = i+1;
                    if isbinary
                        Values = fread(fid,3,'int32',0,FI.ByteOrder);
                        FI.Element.Type(i) = Values(1);
                        NrElm = Values(2);
                        NrTag = Values(3);
                        %
                        [NrNod,ElmNm] = element(FI.Element.Type(i));
                        %
                        for j = i:i+NrElm-1
                            Values = fread(fid,1+NrTag+NrNod,'int32',0,FI.ByteOrder);
                            FI.Element.Nr(j)   = Values(1);
                            if NrTag>0
                                FI.Element.Tags(1:NrTag,j) = Values(1+(1:NrTag))';
                            end
                            FI.Element.Node(1:NrNod,j) = Values(1+NrTag+(1:NrNod))';
                        end
                        i = i+NrElm-1;
                    else
                        Line = fgetl(fid);
                        Values = sscanf(Line,'%f');
                        FI.Element.Nr(i)   = Values(1);
                        FI.Element.Type(i) = Values(2);
                        if FI.VersionNumber==1.0
                            offset = 2;
                            NrTag = 3;
                            FI.Element.Tags(1:2,i) = Values(3:4)';
                            NrNod = Values(5);
                        else
                            offset = 3;
                            NrTag = Values(3); % tag 1: physical entity; tag 2: elementary geometrical entity; tag 3: mesh partition; following: partition ids (negative: ghost cell)
                            %
                            [NrNod,ElmNm] = element(FI.Element.Type(i));
                            %
                            if NrTag>0
                                FI.Element.Tags(1:NrTag,i) = Values(offset+(1:NrTag))';
                            end
                        end
                        FI.Element.Node(1:NrNod,i) = Values(offset+NrTag+(1:NrNod))';
                    end
                end
                parsecheck(fid,'$EndElements')
            %case '$PhysicalName'
            %case '$Periodic'
            %case '$View'
            case {'$NodeData','$ElementData','$ElementNodeData'}
                DataField = Line(2:end);
                Field.Strings             = {};
                Field.Reals               = {};
                Field.Integers            = {};
                %
                Field.ViewName            = '';
                Field.InterpolationScheme = '';
                Field.Time                = 0;
                Field.TimeIndex           = 0;
                Field.NumFields           = 0;
                Field.NumEntity           = 0;
                Field.Partition           = 0;
                %
                Field.Data                = [];
                %
                NumTags = fscanf(fid,'%i \n',1); % strings
                strings = cell(NumTags,1);
                for i = 1:NumTags,
                    strings{i} = deblank(fgetl(fid));
                    if strings{i}(1)=='"' && strings{i}(end)=='"'
                        strings{i} = strings{i}(2:end-1);
                    end
                end
                Field.Strings = strings;
                % string 1: name of the post-processing view
                % string 2: name of the interpolation scheme
                if NumTags>0, Field.ViewName = strings{1}; end
                if NumTags>1, Field.InterpolationScheme = strings{2}; end
                %
                NumTags = fscanf(fid,'%i \n',1);
                Field.Reals = fscanf(fid,'%f \n',NumTags);
                % real 1: time value associated with the dataset
                if NumTags>0, Field.Time = Field.Reals(1); end
                %
                NumTags = fscanf(fid,'%i \n',1);
                Field.Integers = fscanf(fid,'%i \n',NumTags);
                % integer 1: time step index (starting at 0)
                % integer 2: number of field components of the data in the view (1, 3 or 9)
                % integer 3: number of entities (nodes or elements) in the view
                % integer 4: partition index for the view data (0 for no partition)
                if NumTags>0, Field.TimeIndex = Field.Integers(1); end
                if NumTags>1, Field.NumFields = Field.Integers(2); end
                if NumTags>2, Field.NumEntity = Field.Integers(3); end
                if NumTags>3, Field.Partition = Field.Integers(4); end
                %
                if isbinary
                    Field.Data = zeros(1+Field.NumFields,Field.NumEntity);
                    for i = 1:Field.NumEntity
                        Field.Data(1,i) = fread(fid,1,'int32',0,FI.ByteOrder);
                        Field.Data(2:end,i) = fread(fid,Field.NumFields,'float64',0,FI.ByteOrder);
                    end
                else
                    Field.Data = fscanf(fid,'%f',[1+Field.NumFields Field.NumEntity]);
                end
                fgetl(fid);
                %
                FI.(DataField) = Field;
                parsecheck(fid,['$End' DataField])
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
