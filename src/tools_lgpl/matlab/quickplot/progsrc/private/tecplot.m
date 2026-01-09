function Out=tecplot(cmd,varargin)
%TECPLOT Read/write for Tecplot files.
%
%   FileInfo=TECPLOT('write',FileName,Data)
%      Writes the matrix Data to a Tecplot file.
%   NewFileInfo=TECPLOT('write',FileName,FileInfo)
%      Writes a Tecplot file based on the information
%      in the FileInfo. FileInfo should be a structure
%      with at least a field Zone having two subfields
%      Title and Data. For example
%        FI.Zone(1).Title='B001';
%        FI.Zone(1).Data=Data1;
%        FI.Zone(2).Title='B002';
%        FI.Zone(2).Data=Data2;
%      Optional fields Title (overall title) and Variables
%      (cell array of variable names) will also be processed.

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


function FI=Local_open_file(filename)
FI.FileName=filename;
FI.FileType='Tecplot';
fid=fopen(filename,'r','l');
if fid<0
    error('Cannot open "%s".',filename)
end
try
    str = fread(fid,[1 8],'*char');
    if strcmp(str(1:5),'#!TDV')
        FI = open_binary(FI,fid,str);
    else
        fseek(fid,0,-1);
        file = init_file(fid);
        FI = open_ascii(FI,file);
    end
    fclose(fid);
catch err
    fclose(fid);
    rethrow(err)
end

function file = init_file(fid)
file.fid = fid;
file.offset = ftell(fid);
file.line = '';

function [keyw,file] = get_keyw(file)
while ischar(file.line)
    [keyw,n,~,nextindex] = sscanf_optional_space(file.line, nonspace_or_equal, 1);
    if n == 0
        file.offset = file.offset + length(file.line);
        file.line = fgets(file.fid);
    else
        break
    end
end
if n == 0
    keyw = '';
else
    file.offset = file.offset + nextindex - 1;
    file.line = file.line(nextindex:end);
end

function [str,file] = get_line(file)
len = length(file.line);
str = strtrim(file.line);
file.offset = file.offset + len;
file.line = '';

function file = skip_line(file)
[~,file] = get_line(file);

function file = check_symbol(file,symbol)
while true
    [keyw,n,~,nextindex] = sscanf_optional_space(file.line, '%1c', 1);
    if n == 0
        error('Symbol "%s" not found.',symbol)
    else
        break
    end
end
%
if isequal(keyw,symbol)
    file.offset = file.offset + nextindex - 1;
    file.line = file.line(nextindex:end);
else
    error('Encountered "%s" while expecting "%s".', keyw, symbol)
end


function [int_value,file] = get_int(file)
[int_value,~,errmsg,nextindex] = sscanf(file.line, ' %u', 1);
if ~isempty(errmsg)
    error(errmsg)
end
file.offset = file.offset + nextindex - 1;
file.line = file.line(nextindex:end);

function [float_value,file] = get_float(file)
[float_value,~,errmsg,nextindex] = sscanf(file.line, ' %f', 1);
if ~isempty(errmsg)
    error(errmsg)
end
file.offset = file.offset + nextindex - 1;
file.line = file.line(nextindex:end);

function str = space_comma_tab_linefeed_carriagereturn
str = [' ,',char(9),newline,char(13)];

function str = skip_space
str = ['%*[',space_comma_tab_linefeed_carriagereturn,']'];

function str = nonspace
str = ['%[^',space_comma_tab_linefeed_carriagereturn,']'];

function str = nonspace_or_equal
str = ['%[^=',space_comma_tab_linefeed_carriagereturn,']'];

function [data,n,errmsg,nextindex] = sscanf_optional_space(str,formatSpec,sizeA)
[data,n,errmsg,nextindex] = sscanf(str, [skip_space,formatSpec],sizeA);
if n == 0 && nextindex == 1
    % no space
    [data,n,errmsg,nextindex] = sscanf(str, formatSpec,sizeA);
end

function [str,file] = get_string(file, readFromCurrentLineOnly)
while true
    [~,n,~,nextindex] = sscanf_optional_space(file.line, '%["]', 1);
    if n == 0
        % without quotes, no spaces or commas allowed
        hasQuotes = false;
        nextindex = 0;
        [str,n,~,nextindex2] = sscanf_optional_space(file.line, nonspace, 1);
    else
        % with quotes
        hasQuotes = true;
        [keyw,n,~,nextindex2] = sscanf(file.line(nextindex:end), '%[^"]%["]', 2);
        % todo check for escaped quotes \"
    end

    if n == 0 
        if readFromCurrentLineOnly
            error('Unable to locate string.')
        else
            file.offset = file.offset + length(file.line);
            file.line = fgets(file.fid);
        end
    else
        if hasQuotes
            str = keyw(1:end-1);
        end
        break
    end
end
file.offset = file.offset + nextindex + nextindex2 - 1;
file.line = file.line(nextindex+nextindex2:end);

function [color,file] = get_color(file)
[color,file] = get_string(file);
switch upper(color)
    case {'BLACK', 'RED', 'GREEN', 'BLUE', 'CYAN', 'YELLOW', 'PURPLE', 'WHITE'}
        % standard colours
    case {'CUST1', 'CUST2', 'CUST3', 'CUST4', 'CUST5', 'CUST6', 'CUST7', 'CUST8'}
        % custom colours
    otherwise
        error('Unsupported color %s.',color)
end

function [str,file] = get_string_list(file,nStrings)
str = cell(1,nStrings);
i = 0;
if nStrings == 0
    readFromCurrentLineOnly = true;
else
    readFromCurrentLineOnly = false;
end
while i < nStrings || readFromCurrentLineOnly
    i = i+1;
    try
        [str{i},file] = get_string(file, readFromCurrentLineOnly);
    catch err
        if readFromCurrentLineOnly
            break
        end
    end
end

function FI=open_ascii(FI,file)
zone_found = false;
in_record = 'HEADER';
z = 0;
t = 0;
while ischar(file.line)
    loc = file.offset;
    [keyw,file] = get_keyw(file);
    if isempty(keyw)
        break
    elseif keyw(1) == '#'
        % comment line ... these we can skip for sure ...
        file = skip_line(file);
        continue
    end
    switch upper(keyw)
        case 'TITLE'
            if ~zone_found
                file = check_symbol(file,'=');
                [FI.Title,file] = get_string(file);
                FI.FileContent = 'FULL';
                FI.Variables = {};
            end
        case 'FILETYPE'
            if ~zone_found
                file = check_symbol(file,'=');
                [filetype,file] = get_string(file);
                if ~ismember(upper(filetype),{'FULL','GRID','SOLUTION'})
                    error('Unsupported filetype "%s" found in file %s.',filetype,FI.FileName)
                end
                FI.FileContent = upper(filetype);
            end
        case 'VARIABLES'
            if ~zone_found
                file = check_symbol(file,'=');
                [FI.Variables,file] = get_string_list(file,0);
            end
        case 'ZONE'
            in_record = 'ZONE';
            zone_found = true;
            z = z+1;
            FI.Zone(z).title = sprintf('zone %i',z);
            FI.Zone(z).type = 'ORDERED';
        case 'T'
            file = check_symbol(file,'=');
            switch in_record
                case 'ZONE' % zone title
                    [FI.Zone(z).title,file] = get_string(file);
                case 'TEXT' % text label (may be multi-line by including \\n)
                    [FI.Text(t).label,file] = get_string(file);
            end
        case 'ZONETYPE'
            file = check_symbol(file,'=');
            [FI.Zone(z).type,file] = get_string(file);
            switch upper(FI.Zone(z).type)
                case 'ORDERED'
                case {'FELINESEG','FETRIANGLE','FEQUADRILATERAL','FEPOLYGON','FEPOLYHEDRAL','FETETRAHEDRON','FEBRICK'}
                    FI.Zone(z).elementType = FI.Zone(z).type(3:end);
                    FI.Zone(z).elementSize = element_size(FI.Zone(z).elementType);
            end
        case 'C'
            file = check_symbol(file,'=');
            [FI.Zone(z).Color,file] = get_color(file);
        case 'D'
            file = check_symbol(file,'=');
            file = check_symbol(file,'(');
            [FI.Zone(z).duplicateList,file] = get_int_list(file,0); % all < length(variables)
            file = check_symbol(file,')');
        case {'E','ELEMENTS'}
            file = check_symbol(file,'=');
            [FI.Zone(z).nElements,file] = get_int(file);
        case 'ET'
            file = check_symbol(file,'=');
            [FI.Zone(z).elementType,file] = get_string(file);
            FI.Zone(z).type = ['FE',FI.Zone(z).elementType];
            FI.Zone(z).elementSize = element_size(FI.Zone(z).elementType);
            if FI.Zone(z).elementSize <= 0
                error('Unsupported element type %s for zone %i.',FI.Zone(z).elementType,z)
            end
        case 'F'
            file = check_symbol(file,'=');
            switch in_record
                case 'ZONE'
                    [FI.Zone(z).dataFormat,file] = get_string(file);
                    switch upper(FI.Zone(z).dataFormat)
                        case {'BLOCK','FEBLOCK'}
                            % all values of one variable together
                            FI.Zone(z).dataFormat = 'BLOCK';
                        case {'POINT','FEPOINT'}
                            % all values of one point/node together
                             FI.Zone(z).dataFormat = 'POINT';
                       otherwise
                            error('Unsupported data format %s for zone %i.',FI.Zone(z).dataFormat,z)
                    end
                case 'TEXT'
                    [FI.Text(t).Font,file] = get_string(file);
            end
        case 'FACES'
            file = check_symbol(file,'=');
            [FI.Zone(z).nFaces,file] = get_int(file);
        case 'I'
            file = check_symbol(file,'=');
            [FI.Zone(z).iMax,file] = get_int(file);
        case 'J'
            file = check_symbol(file,'=');
            [FI.Zone(z).jMax,file] = get_int(file);
        case 'K'
            file = check_symbol(file,'=');
            [FI.Zone(z).kMax,file] = get_int(file);
        case {'N','NODES'}
            file = check_symbol(file,'=');
            [FI.Zone(z).nNodes,file] = get_int(file);
        case 'TOTALNUMFACENODES'
            file = check_symbol(file,'=');
            [FI.Zone(z).totalNumFaceNodes,file] = get_int(file);
        case 'NUMCONNECTEDBOUNDARYFACES'
            file = check_symbol(file,'=');
            [FI.Zone(z).numConnectedBoundaryFaces,file] = get_int(file);
        case 'TOTALNUMBOUNDARYCONNECTIONS'
            file = check_symbol(file,'=');
            [FI.Zone(z).totalNumBoundaryConnections,file] = get_int(file);
        case 'FACENEIGHBORMODE'
            file = check_symbol(file,'=');
            [FI.Zone(z).faceNeighborMode,file] = get_string(file);
            switch upper(FI.Zone(z).faceNeighborMode)
                case {'LOCALONETOONE','LOCALONETOMANY','GLOBALONETOONE','GLOBALONETOMANY'}
                    % known options
                otherwise
                    error('Unsupported face neighbor mode %s for zone %i.',FI.Zone(z).faceNeighborMode,z)
            end
        case 'FACENEIGHBORCONNECTIONS'
            file = check_symbol(file,'=');
            [FI.Zone(z).faceNeighborConnections,file] = get_int(file);
        case 'DT'
            file = check_symbol(file,'=');
            file = check_symbol(file,'(');
            [FI.Zone(z).dataTypes,file] = get_string_list(file,length(FI.Variables));
            file = check_symbol(file,')');
            for i = 1:length(FI.Zone(z).dataTypes)
                switch upper(FI.Zone(z).dataTypes{i})
                    case {'SINGLE','DOUBLE','LONGINT','SHORTINT','BYTE','BIT'}
                    otherwise
                        error('Unsupported data type %s for variable %s.',FI.Zone(z).dataTypes{i},FI.Variables{i})
                end
            end
        case 'DATAPACKING'
            file = check_symbol(file,'=');
            [FI.Zone(z).dataPacking,file] = get_string(file);
            switch upper(FI.Zone(z).dataPacking)
                case {'BLOCK','POINT'}
                otherwise
                    error('Unsupported data packing %s for zone %i.',FI.Zone(z).dataPacking,z)
            end
        case 'VARLOCATION'
            % example syntax: VARLOCATION = ([3,4]=CELLCENTERED)
            % two options: NODAL (default) and CELLCENTERED
            file = check_symbol(file,'=');
            file = check_symbol(file,'(');
            error('Reading VARLOCATION keyword not yet implemented.')
        case 'VARSHARELIST'
            % example syntax: VARSHARELIST=([4-6,11]=3, [20-23]=1, [13,15])
            % unspecified zone number: previous zone z-1
            file = check_symbol(file,'=');
            file = check_symbol(file,'(');
            error('Reading VARSHARELIST keyword not yet implemented.')
        case 'NV' % node value
            file = check_symbol(file,'=');
            [FI.Zone(z).nodeValue,file] = get_int(file); % < length(variables)
        case 'CONNECTIVITYSHAREZONE'
            file = check_symbol(file,'=');
            [FI.Zone(z).connectivityShareZone,file] = get_int(file); % < length(zones)
        case 'STRANDID'
            file = check_symbol(file,'=');
            [FI.Zone(z).strandID,file] = get_int(file);
        case 'SOLUTIONTIME'
            file = check_symbol(file,'=');
            [FI.Zone(z).solutionTime,file] = get_float(file);
        case 'PASSIVEVARLIST'
            % example syntax: [4-5,20]
            file = check_symbol(file,'=');
        case 'AUXDATA'
            % example syntax: AUXDATA EXPERIMENTDATE ="October 13, 2007, 8 A.M."
            error('Reading AUXDATA keyword not yet implemented.')
        case 'TEXT'
            in_record = 'TEXT';
            t = t+1;
        case 'X'
            file = check_symbol(file,'=');
            [FI.Text(t).xCoord,file] = get_float(file);
        case 'Y'
            file = check_symbol(file,'=');
            [FI.Text(t).yCoord,file] = get_float(file);
        case 'CS' % coordinate system
            file = check_symbol(file,'=');
            [FI.Text(t).coordinateSystem,file] = get_string(file);
            switch upper(FI.Text(t).coordinateSystem)
                case {'FRAME','GRID','GRID3D'}
                otherwise
                    error('Unsupported coordinate system %s.',FI.Text(t).coordinateSystem)
            end
        case 'AN' % anchor
            file = check_symbol(file,'=');
            [FI.Text(t).anchor,file] = get_string(file);
            switch upper(FI.Text(t).anchor)
                case {'HEADLEFT','MIDLEFT','LEFT','HEADCENTER','MIDCENTER','CENTER','HEADRIGHT','MIDRIGHT','RIGHT'}
                otherwise
                    error('Unsupported anchor %s.',FI.Text(t).anchor)
            end
        case 'HU' % height unit
            file = check_symbol(file,'=');
            [FI.Text(t).heightUnit,file] = get_string(file);
            switch upper(FI.Text(t).heightUnit)
                case {'FRAME','POINT','GRID'}
                otherwise
                    error('Unsupported anchor %s.',FI.Text(t).heightUnit)
            end
        case 'H' % height
            file = check_symbol(file,'=');
            [FI.Text(t).height,file] = get_floa(file);
        case 'LS' % line spacing (default: 1)
            file = check_symbol(file,'=');
            [FI.Text(t).lineSpacing,file] = get_float(file);
        case 'BX' % box type: HOLLOW, FILLED, NOBOX
            file = check_symbol(file,'=');
            [FI.Text(t).boxType,file] = get_string(file);
            switch upper(FI.Text(t).boxType)
                case {'HOLLOW','FILLED','NOBOX'}
                otherwise
                    error('Unsupported anchor %s.',FI.Text(t).boxType)
            end
        case 'BXF' % box fill color
            file = check_symbol(file,'=');
            [FI.Time(t).boxFillColor,file] = get_color(file);
        case 'BXO' % box outline color
            file = check_symbol(file,'=');
            [FI.Time(t).boxOutlineColor,file] = get_color(file);
        case 'BXM' % box margin
            file = check_symbol(file,'=');
            [FI.Text(t).boxMargin,file] = get_float(file);
        case 'LT' % line thickness
            file = check_symbol(file,'=');
            [FI.Text(t).lineThickness,file] = get_float(file);
        case 'R' % radius for polar plots (see also THETA)
            file = check_symbol(file,'=');
            [FI.Text(t).rCoord,file] = get_float(file);
        case 'THETA' % theta for polar plots (see also R)
            file = check_symbol(file,'=');
            [FI.Text(t).thetaCoord,file] = get_float(file);
        case 'MFC'
            file = check_symbol(file,'=');
            [FI.Text(t).macroFunction,file] = get_string(file);
        case 'CLIPPING'
            file = check_symbol(file,'=');
            [FI.Text(t).clipping,file] = get_string(file);
            switch upper(FI.Text(t).clipping)
                case {'CLIPTOVIEWPORT','CLIPTOFRAME'}
                otherwise
                    error('Unsupported clipping %s.',FI.Text(t).clipping)
            end
        case 'S' % scope
            file = check_symbol(file,'=');
            [FI.Text(t).scope,file] = get_string(file);
            switch upper(FI.Text(t).scope)
                case {'GLOBAL','LOCAL'}
                otherwise
                    error('Unsupported scope %s.',FI.Text(t).scope)
            end
        otherwise
            if isnan(str2double(keyw))
                error('Unsupported keyword %s encountered while reading %s.',keyw,FI.FileName)
            else
                % reached data block
                FI.Zone(z).dataStart = loc;
                fseek(file.fid,loc,-1);
                Zone = FI.Zone(z);
                nVar =  length(FI.Variables);
                %
                if strcmpi(Zone.type,'ORDERED')
                    if isfield(Zone,'kMax') % 3D
                        blockSize = [Zone.iMax Zone.jMax Zone.kMax];
                    elseif isfield(Zone,'jMax') % 2D
                        blockSize = [Zone.iMax Zone.jMax];
                    else % 1D
                        blockSize = Zone.iMax;
                    end
                else % unstructured elements
                    blockSize = Zone.nNodes;
                end
                %
                switch Zone.dataFormat
                    case 'BLOCK'
                        % all values of one variable together
                        % following implementation assumes all variables
                        % NODAL and not shared.
                        data = data_read(file.fid,prod(blockSize)*nVar);
                        data = reshape(data,[prod(blockSize) nVar]);
                    case 'POINT'
                        % all values of one point/node together
                        % FI.Variables may not be set ...
                        if nVar == 0
                            % if so derive from number of values on line 1.
                            % TODO
                        end
                        data = data_read(file.fid,prod(blockSize)*nVar);
                        data = reshape(data,[nVar prod(blockSize)]).';
                end
                data = reshape(data,[blockSize nVar]);
                FI.Zone(z).data = data;
                %
                if ~strcmpi(Zone.type,'ORDERED')
                    if isfield(Zone,'elementSize') && ~isempty(Zone.elementSize)
                        blockSize = [Zone.elementSize FI.Zone(z).nElements];
                        [topo,nRead] = fscanf(file.fid,'%i',prod(blockSize));
                        if nRead < prod(blockSize)
                            error('Error while reading element-node connectivity.')
                        end
                        topo = reshape(topo,blockSize);
                    else
                        topo = [];
                    end
                    %
                    FI.Zone(z).data = data;
                    FI.Zone(z).topology = topo.';
                end
                file = init_file(file.fid);
            end
    end
end

function elsize = element_size(eltype)
switch upper(eltype)
    case 'BRICK'
        elsize = 8;
    case 'LINESEG'
        elsize = 2;
    case 'POLYGON'
        elsize = NaN;
    case 'POLYHEDRAL'
        elsize = NaN;
    case 'QUADRILATERAL'
        elsize = 4;
    case 'TETRAHEDRON'
        elsize = 4;
    case 'TRIANGLE'
        elsize = 3;
    otherwise
        elsize = -1;
end



function data = data_read(fid,numValues)
nTotalRead = 0;
data = zeros(numValues,1);
while nTotalRead < numValues
    [newData,nRead] = fscanf(fid,[skip_space,'%f'],numValues-nTotalRead);
    symbol = fread(fid,1,'uint8=>char');
    fseek(fid,-1,0);
    switch symbol
        case {'+','-'}
            % FORTRAN default exp format drops "e" for exponents larger
            % than 99 or smaller than -99
            exponent = fscanf(fid,'%i',1);
            newData(end) = newData(end) * 10^exponent;

        case {'*'}
            % shorthand for repeated value
            value = fscanf(fid,'%f',1);
            % could be for FORTRAN special case as well ...
            symbol = fread(fid,1,'uint8=>char');
            fseek(fid,-1,0);
            if isequal(symbol,'+') || isequal(symbol,'-')
                exponent = fscanf(fid,'%i',1);
                value = value * 10^exponent;
            end
            newData = cat(1,newData(1:end-1),repmat(value,newData(end),1));

        otherwise
            if nTotalRead+nRead < numValues
                fseek(fid,-20,0);
                txt = fscanf(fid,'%40c',1);
                linefeed = find(txt==10 | txt==13);
                if any(linefeed>20)
                    first_linefeed = min(linefeed(linefeed>20));
                    txt = txt(1:first_linefeed-1);
                end
                errloc = 20;
                if any(linefeed<20)
                    last_linefeed = max(linefeed(linefeed<20));
                    txt = txt(last_linefeed+1:end);
                    errloc = errloc - last_linefeed;
                end
                txt(txt==9) = ' ';
                error('Error while reading data values:\n%s\n%s^',txt,repmat(' ',1,errloc))
            end
    end
    data(nTotalRead+1:nTotalRead+nRead) = newData;
    nTotalRead = nTotalRead + nRead;
end


function FI=open_binary(FI,fid,str)
filename = FI.FileName;
version = sscanf(str(6:8),'%i');
switch version
    case 75
        FI.Version = 9;
    case 102
        FI.Version = 10;
    case 112
        FI.Version = 11;
    otherwise
        error('Version %i of Tecplot file "%s" not supported.',version,filename)
end
fread(fid,1,'int32'); % 1
fread(fid,1,'int32'); % 1
FI.Title = freadstring(fid);
nV = fread(fid,1,'int32');
Var = cell(1,nV);
for i = 1:nV
    Var{i} = freadstring(fid);
end
FI.Variables = Var;
%
fread(fid,[1 4],'uchar'); %00 80 95 43
%
z = 1;
FI.Zone(z).Title = freadstring(fid);
switch FI.Version
    case 9
        ZoneType = fread(fid,1,'int32'); % 0=BLOCK, 1=POINT, 2=FEBLOCK, 3=FEPOINT order
        FI.Zone(z).Color = fread(fid,1,'int32'); % ColorNumber
    case {10,11}
        FI.Zone(z).Color = fread(fid,1,'int32'); % ColorNumber
        ZoneType = fread(fid,1,'int32'); % 0=ORDERED, 1=FELINESEG, 2=FETRIANGULAR, 3=FEQUADRILATERAL, 4=FETETRAHEDRON, 5=FEBRICK
        BlockPnt = fread(fid,1,'int32'); % 0=BLOCK, 1=POINT
        DataLoc  = fread(fid,1,'int32'); % NODAL or CELLCENTERED data - if 1, followed by flag array of length nV: 0=NODAL, 1=CELLCENTERED
        fread(fid,1,'int32'); % ???
    otherwise
        error('Unsupported Tecplot binary data file version %u.',FI.Version)
end


function FI=Local_write_file(filename,FileInfo)
if ~isstruct(FileInfo)
    FI.Zone.Title='';
    FI.Zone.Data=FileInfo;
else
    FI=FileInfo;
end
FI.Check='NotOK';
if isfield(FI,'FileType')
    ASCII=isequal(FI.FileType,'TecplotASCII');
else
    [p,f,e]=fileparts(filename);
    if isequal(lower(e),'.dat')
        ASCII=1;
    elseif isequal(lower(e),'.plt')
        ASCII=0;
    else
        ASCII=1;
    end
end
FI.FileName=filename;
if ~isfield(FI.Zone,'Color')
    [FI.Zone(:).Color]=deal('');
end
if ~isfield(FI.Zone,'Color')
    [FI.Zone(:).DataPacking]=deal('BLOCK');
end
if ~isfield(FI.Zone,'AuxData')
    FI.Zone(1).AuxData=[];
end
if ASCII
    FI.FileType='TecplotASCII';
    if ~isfield(FI,'Version')
        FI.Version=9;
    end
else
    FI.FileType='TecplotBINARY';
    if ~isfield(FI,'Version')
        FI.Version=10;
    end
end

%
% --- Check consistency of number of variables ...
%
nV=[];
for i=1:length(FI.Zone)
    nDi=ndims(FI.Zone(i).Data);
    if nDi>4
        error('The data array should be at most 4 dimensional.')
    end
    nVi=size(FI.Zone(i).Data,nDi);
    if ~isempty(nV)
        if nV~=nVi
            error('Number of variables should not vary.')
        end
    else
        nV=nVi;
    end
end

%
% --- Open file ... always in PC style ...
%
fid=fopen(filename,'w','l');
if fid<0
    error('Cannot open requested output file.')
end

%
% --- Start writing file and title ...
%
if ~ASCII
    switch FI.Version
        case 9
            fwrite(fid,'#!TDV75 ','uchar');
        case 10
            fwrite(fid,'#!TDV102','uchar');
    end
end
if ASCII
    if isfield(FI,'Title') && ~isempty(FI.Title)
        fprintf(fid,'TITLE= "%s"\n',FI.Title);
    end
else
    fwrite(fid,1,'int32');
    if isfield(FI,'Title') && ~isempty(FI.Title)
        fwritestring(fid,FI.Title)
    else
        fwritestring(fid,'')
    end
end

%
% --- Use or generate variable names ...
%
for i=nV:-1:1
    Vars{i}=sprintf('V%i',i);
end
if isfield(FI,'Variables')
    nVnames=min(nV,length(FI.Variables));
    Vars(1:nVnames)=FI.Variables(1:nVnames);
end
FI.Variables=Vars;
if ASCII
    fprintf(fid,'VARIABLES=');
    fprintf(fid,' "%s"',Vars{:});
    fprintf(fid,'\n');
else
    fwrite(fid,nV,'int32');
    for i=1:nV
        fwritestring(fid,Vars{i})
    end
end

Clrs={'', 'BLACK', 'RED', 'GREEN', 'BLUE', 'CYAN', 'YELLOW', 'PURPLE', 'WHITE', ...
    'CUST1', 'CUST2', 'CUST3', 'CUST4', 'CUST5', 'CUST6', 'CUST7', 'CUST8'};

%
% --- Write zones ...
%
for i=1:length(FI.Zone)
    Di=FI.Zone(i).Data;
    nDi=ndims(Di);
    szDi=size(Di);
    nIJK=prod(szDi(1:(nDi-1)));
    ijk=repmat({':'},1,nDi-1);
    %
    % --- Set colorname and colornumber
    %
    Color=FI.Zone(i).Color;
    if isequal(Color,'') || isequal(Color,-1)
        ColorNumber=-1;
    elseif ischar(Color)
        ColorNumber=strmatch(Color,Clrs,'exact')-2;
    else
        ColorNumber=Color;
    end
    ColorName=Clrs{ColorNumber+2};
    %
    % --- Start new zone ...
    %
    if ASCII
        %
        % Start ZONE ...
        %
        fprintf(fid,'ZONE');
        %
        % Size of ordered block ...
        %
        fprintf(fid,' I=%i',szDi(1));
        if nDi>=3, fprintf(fid,' J=%i',szDi(2)); end
        if nDi==4, fprintf(fid,' K=%i',szDi(3)); end
        %
        % BLOCK ordering of the data ...
        %
        switch FI.Version
            case 9
                fprintf(fid,' F=BLOCK');
            case 10
                %fprintf(fid,' ZONETYPE=ORDERED');
                fprintf(fid,' DATAPACKING=BLOCK');
        end
        %
        % Colour ...
        %
        if ColorNumber>=0
            fprintf(fid,' C=%s',ColorName);
        end
        %
        % Zone title ...
        %
        if isfield(FI.Zone,'Title') && ~isempty(FI.Zone(i).Title)
            fprintf(fid,' T="%s"\n',FI.Zone(i).Title);
        else
            fprintf(fid,'\n');
        end
    else
        %
        fwrite(fid,[0 128 149 67],'uchar'); %00 80 95 43
        %
        % Zone title ...
        %
        if isfield(FI.Zone,'Title') && ~isempty(FI.Zone(i).Title)
            fwritestring(fid,FI.Zone(i).Title);
        else
            fwritestring(fid,sprintf('ZONE %3.3i',i));
        end
        %
        switch FI.Version
            case 9
                %
                % 0=BLOCK, 1=POINT, 2=FEBLOCK, 3=FEPOINT order
                %
                fwrite(fid,0,'int32');
                %
                % Colour ...
                %
                fwrite(fid,ColorNumber,'int32');
                %
            case 10
                %
                % Colour ...
                %
                fwrite(fid,ColorNumber,'int32');
                %
                % 0=ORDERED, 1=FELINESEG, 2=FETRIANGULAR, 3=FEQUADRILATERAL, 4=FETETRAHEDRON, 5=FEBRICK
                %
                fwrite(fid,0,'int32');
                %
                % 0=BLOCK, 1=POINT
                %
                fwrite(fid,0,'int32');
                %
                % NODAL or CELLCENTERED data
                % if 1, followed by flag array of length nV: 0=NODAL, 1=CELLCENTERED
                %
                fwrite(fid,0,'int32');
                %
                % ???
                %
                fwrite(fid,0,'int32');
                %
        end
        %
        % I,J,K     or    FI.Version=9  N,E,F
        %                                  F: 1=TRIANGLE, 2=QUADRILATERAL, 3=TETRAHEDRON, 4=BRICK
        %           or    FI.Version=10 N,E and some other values ...
        %
        szWrite = szDi(1:end-1);
        if length(szWrite)<3
            szWrite(3)=1;
        end
        fwrite(fid,szWrite,'int32');
        %
        switch FI.Version
            case 10
                %
                AuxData=FI.Zone(i).AuxData;
                if ~isempty(AuxData)
                    for ad=1:size(AuxData,1)
                        %
                        % indicate auxdata entry
                        %
                        fwrite(fid,1,'int32');
                        %
                        % auxdata namestring="valuestring"
                        %
                        fwritestring(fid,AuxData{ad,1});
                        fwrite(fid,0,'int32');
                        fwritestring(fid,AuxData{ad,2});
                    end
                end
                %
                % finish auxdata block
                %
                fwrite(fid,0,'int32');
                %
        end
    end

    %
    % --- Write zone data ...
    %
    if ASCII
        nvalPerLine=20;
        Format=[repmat(' %12g',1,nvalPerLine) '\n'];
        for v=1:size(Di,nDi)
            fprintf(fid,Format,Di(ijk{:},v));
            if mod(nIJK,nvalPerLine)~=0
                fprintf(fid,'\n');
            end
        end
    end
end

%
% --- Write zone data ...
%
if ~ASCII
    %
    % 00 80 B2 43
    %
    fwrite(fid,[0 128 178 67],'uchar');
    %
    for i=1:length(FI.Zone)
        Di=FI.Zone(i).Data;
        %
        % --- Write zone data ...
        %
        % 00 80 95 43
        %
        fwrite(fid,[0 128 149 67],'uchar');
        %
        switch FI.Version
            case 9
                %
                % length of duplist followed by duplist
                %
                fwrite(fid,0,'int32');
                %fwrite(fid,duplist,'int32');
                %
        end
        %
        % 1=(SINGLE), 2=(DOUBLE), 3=(LONGINT), 4=(SHORTINT), 5=(BYTE), 6=(BIT)
        %
        fwrite(fid,ones(1,nV),'int32');
        %
        switch FI.Version
            case 10
                %
                % if 1, followed by VARSHARELIST (length=nV) of ZONE NUMBERS= value+1
                %
                fwrite(fid,0,'int32');
                %
                % if >=0, CONNECTIVITYSHAREZONE= value+1
                %
                fwrite(fid,-1,'int32');
                %
        end
        %
        % DATA in block format
        % FEDATA value data, 0, elementconnectivity
        %                    1 (in case of FECONNECT)
        %
        fwrite(fid,Di,'float32');
    end
end
FI.Check='OK';
fclose(fid);

function Str = freadstring(fid)
Loc = ftell(fid);
Str = fread(fid,[1 1024],'int32=>char');
Len = min(find(Str==0));
Str = Str(1:Len-1);
fseek(fid,Loc+4*Len,-1);

function fwritestring(fid,Str)
fwrite(fid,Str,'int32');
fwrite(fid,0,'int32');
