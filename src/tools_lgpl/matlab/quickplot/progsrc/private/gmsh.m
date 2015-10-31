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


function element = getElementDefinition
element = cell(2,93);
%
i = [1 8 26 27 28];
element(1,i) = {'edge'};
element(2,i) = {2 3 4 5 6};
i = [2 9 20 21 22 23 24 25];
element(1,i) = {'triangle'};
element(2,i) = {3 6 9 10 12 15 15 21};
i = [3 10 16];
element(1,i) = {'quadrangle'};
element(2,i) = {4 9 8};
i = [4 11 29 30 31];
element(1,i) = {'tetrahedron'};
element(2,i) = {4 10 20 35 56};
i = [5 12 17 92 93];
element(1,i) = {'hexahedron'};
element(2,i) = {8 27 20 64 125};
i = [6 13 18];
element(1,i) = {'prism'};
element(2,i) = {6 18 15};
i = [7 14 19];
element(1,i) = {'pyramid'};
element(2,i) = {5 14 13};
i = 15;
element(1,i) = {'point'};
element(2,i) = {1};


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
    %
    element = getElementDefinition;
    %
    % $MeshFormat
    FI.VersionNumber = 2.2;
    FI.FileType = 'ASCII';
    FI.DataSize = 8;
    FI.ByteOrder = 'N/A';
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
        if FI.VersionNumber~=1.4 && FI.VersionNumber~=2.2 && FI.VersionNumber~=3
            error('GMSH file version %g is not supported; only versions 1.4, 2.2 and 3 are supported.',FI.VersionNumber)
        elseif FI.FileType~=0 && FI.FileType~=1
            error('GMSH file type %i is not supported; only 0 (ASCII) and 1 (BINARY) are supported.',FI.FileType)
        elseif FI.DataSize~=8
            error('GMSH data size %i is not supported; only sizeof(double)=8 is supported.',FI.DataSize)
        elseif FI.FileType==0
            FI.FileType = 'ASCII';
            isbinary = false;
        else % FI.FileType==1
            FI.FileType = 'BINARY';
            isbinary = true;
            if FI.VersionNumber==1.4
                FI.ByteOrder = 'n'; % unknown, so assume native
            else
                ONE = fread(fid,1,'int32',0,'l');
                if isequal(ONE,1)
                    FI.ByteOrder = 'l';
                elseif isequal(ONE,2)
                    FI.ByteOrder = 'b';
                else
                    error('Unable to identify GMSH byte order; reading %i but expecting 1.',ONE)
                end
                fgetl(fid); % skip rest of line
            end
        end
        if FI.VersionNumber==3
            warning('GMSH file version 3 support is incomplete.')
        end
        if FI.VersionNumber==1.4
            parsecheck(fid,'$EndPostFormat')
        else
            % $EndMeshFormat
            parsecheck(fid,'$EndMeshFormat')
        end
    end
    %
    if FI.VersionNumber<3
        nNodeVal = 3;
        nodeParser = '%i %f %f %f';
    else
        nNodeVal = 4;
        nodeParser = '%i %f %f %f %i';
    end
    %
    while ~feof(fid)
        Section = deblank(fgetl(fid));
        switch Section
            case '$Nodes'
                Line = fgetl(fid);
                NumNodes = sscanf(Line,'%i',1);
                if isbinary
                    Nodes = zeros(1+nNodeVal,NumNodes);
                    for i = 1:NumNodes
                        Nodes(1,i) = fread(fid,1,'int32',0,FI.ByteOrder);
                        Nodes(2:4,i) = fread(fid,3,'float64',0,FI.ByteOrder);
                        if nNodeVal>3
                            Nodes(5,i) = fread(fid,1,'int32',0,FI.ByteOrder);
                        end
                    end
                else
                    Nodes = fscanf(fid,nodeParser,[1+nNodeVal NumNodes]);
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
                        eType = Values(1);
                        NrElm = Values(2);
                        NrTag = Values(3);
                        %
                        if eType>size(element,2) || isempty(element(2,eType))
                            error('Invalid element type %i encountered.',eType)
                        end
                        %ElmNm = element{1,eType};
                        NrNod = element{2,eType};
                        %
                        FI.Element.Type(i) = eType;
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
                        eType              = Values(2);
                        FI.Element.Type(i) = eType;
                        if FI.VersionNumber==1.0
                            offset = 2;
                            NrTag = 3;
                            FI.Element.Tags(1:2,i) = Values(3:4)';
                            NrNod = Values(5);
                        else
                            offset = 3;
                            NrTag = Values(3); % tag 1: physical entity; tag 2: elementary geometrical entity; tag 3: mesh partition; following: partition ids (negative: ghost cell)
                            %
                            if eType>size(element,2) || isempty(element(2,eType))
                                error('Invalid element type %i encountered.',eType)
                            end
                            %ElmNm = element{1,eType};
                            NrNod = element{2,eType};
                            %
                            if NrTag>0
                                FI.Element.Tags(1:NrTag,i) = Values(offset+(1:NrTag))';
                            end
                        end
                        FI.Element.Node(1:NrNod,i) = Values(offset+NrTag+(1:NrNod))';
                    end
                end
                if isbinary
                    fgetl(fid); % skip rest of line
                end
                switch Section
                    case '$Elements'
                        parsecheck(fid,'$EndElements')
                    case '$ELM'
                        parsecheck(fid,'$ENDELM')
                end
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
                if Section(1)~='$' || any(isspace(Section))
                    error('Section header "%s" not supported.',Section)
                else % well formatted unrecognized section ... skip it
                    EndSection = [Section(1) 'End' Section(2:end)];
                    fprintf('Skipping lines from %s until %s\n',Section,EndSection);
                    Line = '';
                    while ~strcmp(Line,EndSection)
                        Line = fgetl(fid);
                        if ~ischar(Line)
                            error('End of line while searching for "%s".',EndSection)
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
