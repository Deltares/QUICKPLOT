function Out = mike(cmd,varargin)
%MIKE Read/write DHI Mike files.
%   FILEINFO = MIKE('open',FILENAME) opens a DHI Mike DFS? file or a pair
%   of CT?/DT? files.
%
%   DATA = MIKE('read',FILEINFO,ITEM,TIMESTEP) reads data for the selected
%   ITEM from a Mike file. If no TIMESTEP is specified then the last
%   timestep for the ITEM in the file is returned. If the data files
%   contains just one dataset, the ITEM number is not required.
%
%   DATA = MIKE('read',FILEINFO,ITEM,-1) read the grid from the data file.
%
%   DATA = MIKE(...,SELECTION) where SELECTION equals {M} for 1D, {M N} for
%   2D and {M N K} for 3D returns only the selected m,n,k-indices. The
%   number of indices should match the dimension of the data file.
%
%   See also QPFOPEN, QPREAD.

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

if nargin == 0
    if nargout > 0
        Out = [];
    end
    return
end

switch cmd
    case 'open'
        Out = Local_open_mike(varargin{:});
    case 'read'
        switch lower(varargin{1}.FileType)
            case 'mikectdt'
                Out = Local_read_mike(varargin{:});
            case 'mikedfs'
                Out = Local_read_mike_new(varargin{:});
        end
    otherwise
        error('unknown command: %s',var2str(cmd))
end

function S = Local_open_mike(filename,varargin)
S.Check = 'NotOK';
logid = 0;
if nargin>1
    for i = 1:length(varargin)
        if strcmpi(varargin{i},'debug')
            logid = 1;
        end
    end
end
        

if nargin == 0
    [fn,fp] = uigetfile('*.ct?');
    if ~ischar(fn)
        return
    end
    filename = [fp fn];
end

% Filename: has it an extension?
lastdot = max(strfind(filename,'.'));
lastsep = max(strfind(filename,filesep));
if ~isempty(lastdot) && (isempty(lastsep) || (lastdot > lastsep)) % has extension!
    file_ext = filename(lastdot:end);
    filename = filename(1:(lastdot-1));
else
    error('Missing extension? Could not determine filetype.')
end

S.FileName = filename;
S.FileType = 'MikeCTDT';
S.Format = 'l';
switch file_ext
    case {'.ct2','.dt2'}
        S.Def = '.ct2';
        S.Dat = '.dt2';
    case {'.ct1','.dt1'}
        S.Def = '.ct1';
        S.Dat = '.dt1';
    case {'.ct0','.dt0'}
        S.Def = '.ct0';
        S.Dat = '.dt0';
    otherwise
        fid = fopen([filename file_ext],'r');
        str = fread(fid,20,'*char');
        fclose(fid);
        typ = sscanf(str,'DHI_%[^_]',1);
        if ~isempty(typ)
            S.FileType = ['Mike' typ];
            S.Dat = file_ext;
            S.Def = '';
        else
            error('Invalid filename or unknown MIKE file format.')
        end
end

S.FileName = absfullfile(filename);

if isempty(S.Def)
    S = Local_open_mike_new(S,filename,logid);
    return
end

dat_file = [filename S.Dat];
def_file = [filename S.Def];


% -----------------------------------------------------
% Reading the dat and def files
% -----------------------------------------------------

% Check existence of dat file
if ~exist(dat_file, 'file')
    error('Datafile "%s" does not exist.',dat_file)
end

% Start reading the def file
fidef = fopen(def_file,'r','l');
if fidef < 0
    error('Cannot open definition file: %s.',def_file)
end

BS = fread(fidef,1,'int32'); % 600
if ~isequal(BS,600)
    fclose(fidef);
    fidef = fopen(def_file,'r','b');
    S.Format = 'b';
    BS = fread(fidef,1,'int32'); % 600
    if ~isequal(BS,600)
        S.Format = 'unknown';
        fclose(fidef);
        return
    end
end
X = fread(fidef,[1 600/4],'float32');
BS = fread(fidef,1,'int32'); % 600

S.RefDate = X(1)+694020+X(5)/(24*3600);
S.StartTimeStep = X(2);
S.NumTimeSteps = X(4);
%if S.NumTimeSteps > 0,
S.TimeStep = X(6)/(60*60*24);
%end
S.NumItems = X(7);
%S.DataDim = X(20:21);
%S.Origin = X(24:25); % latitude, longitude in degrees
%S.GridCell = X(28:29); % in meters
S.NumCoords = X(8); % 0 t/m 4
if S.NumCoords == 0
    S.DataDim = 0; % 1 added while reading!
else
    S.DataDim = X(19+(1:S.NumCoords)); % 1 added while reading!
    S.Origin = X(23+(1:S.NumCoords));
    S.GridCell = X(27+(1:S.NumCoords));
    if S.NumCoords == 2
        S.Orientation = X(144); % in degrees
        S.Land = X(147);
    end
end

S.Item = [];
for i = 1:S.NumItems
    Min = X(31+7*(i-1)+1);
    Max = X(31+7*(i-1)+2);
    %if Min > Max, break; end
    S.Item(i).Min = Min;
    S.Item(i).Max = Max;
    S.Item(i).Mean = X(31+7*(i-1)+3);
    %  S.Item(i).X = X(31+7*(i-1)+4);
end
%S.NumItems = length(S.Item)
S.DataField(1).Data = X;

BS = fread(fidef,1,'int32'); % 436
X = fread(fidef,[1 436],'*char');
BS = fread(fidef,1,'int32'); % 436

S.Description = deblank(X(1:40));
if any(S.Description == 0)
    S.Description = S.Description(1:min(find(S.Description == 0))-1);
end
S.DataField(1).Description = X;
fclose(fidef);

for i = 1:S.NumItems
    S.Item(i).Name = X(96+20*(i-1)+(1:20));
    if any(S.Item(i).Name == 0)
        S.Item(i).Name = S.Item(i).Name(1:min(find(S.Item(i).Name == 0))-1);
    end
end

S.Check = 'OK';

function S = Local_open_mike_new(Sin,filename,logid)
S = Sin;
file = [filename S.Dat];

% Check existence of file
if ~exist(file, 'file')
    error('File "%s" does not exist.',file)
end

% Start reading the file
fid = fopen(file,'r','l');
if fid < 0
    error('Cannot open file: %s.',file)
end

X = fread(fid,[1 64],'*char');
if ~strcmp(X,['DHI_' S.FileType(5:7) '_ MIKE Zero - this file contains binary data, do not edit'])
    error('Invalid start of MIKE Zero file.')
end

if strcmp(S.FileType,'MikeDFS')
    X = fread(fid,[1 17],'*char'); %  FOpenFileCreate
end

X = fread(fid,1,'uchar'); %<end of text>

V = fread(fid,[1 6],'int16'); % FileCreationDate
S.Date = datenum(V(1),V(2),V(3),V(4),V(5),V(6));

X = fread(fid,2,'int32'); %104, 206

V = fread(fid,[1 6],'int16'); % FileCreationDate

X = fread(fid,4,'int32'); %104, 206, 0, 0

S.Data = {};
switch lower(S.Dat)
    case {'.dfs0','.dfs1','.dfs2','.dfs3'}
        n = lower(S.Dat(end));
        S.NumCoords = n-'0';
        S.DataType = 'structured';
    case {'.dfsu'}
        S.NumCoords = 'u';
        S.DataType = 'unstructured';
    case { '.xns11'}
        S.NumCoords = 'x';
        S.DataType = 'crosssections';
    otherwise
        S.NumCoords = 0;
        S.DataType = 'unknown';
end

S.SparseStorage = 0;
S = read_info(fid,S,0,logid,'');
if strcmp(S.DataType,'unstructured')
    fm = strmatch('MIKE_FM',S.Attrib.Name,'exact');
    S.NumCoords = S.Attrib(fm).Data(3);
    S.NumLayers = max(1,S.Attrib(fm).Data(4));
    if S.NumCoords == 3
        S.NumNodes = S.Attrib(fm).Data(1)/(S.NumLayers+1);
    else
        S.NumNodes = S.Attrib(fm).Data(1);
    end
    S.NumCells = S.Attrib(fm).Data(2)/max(1,S.NumLayers);
end
fclose(fid);


function Info = read_info(fid,Info,loaddata,logid,indent)
it = 0;
att = 0;
crs = 0;
static = 0;
fld = 0;
while 1
    Typ = fread(fid,1,'uchar');
    if isempty(Typ) % End of File
        break
    end
    switch Typ
        case 1
            % data block floating point single precision
            N = fread(fid,1,'uint32');
            logger(logid,indent,'%d single precision numbers: ',N)
            if loaddata == 1
                data = fread(fid,[1 N],'float32');
                arraylogger(logid,data)
                Info.Data{end+1} = data;
            else
                it = it+1;
                while Info.Item(it).Static
                    it = it+1;
                end
                Info.Item(it).Data(fld) = ftell(fid);
                data = fread(fid,[1 N],'float32');
                arraylogger(logid,data)
            end
        case 2
            % data block floating point double precision
            N = fread(fid,1,'uint32');
            logger(logid,indent,'%d double precision numbers: ',N)
            data = fread(fid,[1 N],'float64');
            arraylogger(logid,data)
            Info.Data{end+1} = data;
        case 3
            % data block characters / string
            N = fread(fid,1,'uint32');
            logger(logid,indent,'%d characters: ',N)
            str = fread(fid,[1 N],'*char');
            logger(logid,indent,'"%s"\n',str)
            Info.Data{end+1} = str;
        case 4
            % data block signed 4-byte integers
            N = fread(fid,1,'uint32');
            logger(logid,indent,'%d signed 4-byte integers: ',N)
            data = fread(fid,[1 N],'int32');
            arraylogger(logid,data)
            Info.Data{end+1} = data;
        case 5
            % data block unsigned 4-byte integers
            N = fread(fid,1,'uint32');
            logger(logid,indent,'%d unsigned 4-byte integers: ',N)
            data = fread(fid,[1 N],'uint32');
            arraylogger(logid,data)
            Info.Data{end+1} = data;
        case 6
            % data block signed 2-byte integers
            N = fread(fid,1,'uint32');
            logger(logid,indent,'%d signed 2-byte integers: ',N)
            data = fread(fid,[1 N],'int16');
            arraylogger(logid,data)
            Info.Data{end+1} = data;
        case 7
            % data block unsigned 2-byte integers
            N = fread(fid,1,'uint32');
            logger(logid,indent,'%d unsigned 2-byte integers: ',N)
            data = fread(fid,[1 N],'uint16');
            arraylogger(logid,data)
            Info.Data{end+1} = data;
        case 254
            % meta data block
            Opt = fread(fid,1,'uchar');
            X = fread(fid,1,'uchar');
            i2.Data = {};
            logger(logid,indent,'\n')
            logger(logid,indent,'--> Block %d with X = %d\n',Opt,X)
            i2 = read_info(fid,i2,1,logid,[indent '  ']);
            switch Opt
                case 1
                    % cross section information
                    % 'JOTIJA'    [         0]    'CURRENT'    '3'    
                    crs = crs+1;
                    Info.CrossSection.Name{crs}    = deblank(i2.Data{4});
                    Info.CrossSection.Branch{crs}  = deblank(i2.Data{1});
                    Info.CrossSection.Offset(crs)  = i2.Data{2};
                    Info.CrossSection.Version{crs} = deblank(i2.Data{3});
                case 2
                    % cross section flags
                    % 25 int32  : 0 2 1 ? ? 0 0 0 0 1 50 0 0 0 0 0 ? 0 0 0 0 0 0 0 0
                    %                   1 2            3           4
                    % 1: unknown range 4-17
                    % 2: NPnts in cross section (size in block 3)
                    % 3: NLevels in tables (size in block 5)
                    % 4: 2 (if block 6 present)
                    % 23 float64: 0 0 0 0 0 ? ? ? ? 0 1 1 1 1 1 0.001 1 1 1 1 1 1 1
                    Info.CrossSection.Integers(crs,:) = i2.Data{1};
                    Info.CrossSection.Reals(crs,:)    = i2.Data{2};
                    Info.CrossSection.NPnts(crs)      = i2.Data{1}(5);
                case 3
                    % cross section coordinates
                    % 6 * NPnts float64
                    % Y, Z, 1, 0, 0, 0
                    Info.CrossSection.YZ{crs} = cat(1,i2.Data{1:2});
                    %Info.CrossSection.ones(crs,:) = i2.Data{3};
                    %Info.CrossSection.zeros(crs,:) = i2.Data{4/5/6};
                case 5
                    % cross section elevation, area, radius, perimeter
                    % 6 * 50 float64
                    % Z, Area(Z), Hydraulic Radius(Z), Wetted Perimeter(Z), 0, 1
                    Info.CrossSection.ZARP{crs} = cat(1,i2.Data{1:4});
                case 6
                    % cross section georeferenced coordinates
                    % N * 
                    Info.CrossSection.GeoLine{crs} = cat(1,i2.Data{:});
                case 16
                    % X = 39  {}
                case 17
                    % File title; user defined title of the file.
                    % X = 39
                    Info.FileTitle = deblank(i2.Data{1});
                case 18
                    % Application title; title of the application that created the file.
                    % X = 39
                    Info.CreatingProgram = deblank(i2.Data{1});
                case 19
                    % Application version number; version of the application that created the file.
                    % X = 39
                    %  [0], [1], [100]
                case 20
                    % Data type; used to tag the file as a special DFS file type, see (1) below.
                    %
                    % The data type tag is a user specified integer. The
                    % data type tag is used as an identification tag for
                    % the type of DFS file at hand. The user should tag
                    % bathymetries, result files, input files etc. matching
                    % those tags required for the DFS file type at hand. A
                    % wrong data type tag in some contexts is an error. Not
                    % all DFS files and tools handling DFS use the tag.
                    %
                    % In Appendix G there is a list of data type tags
                    % currently used within the DHI model complex. A
                    % programmer writing a new type of DFS file should
                    % choose the tag carefully, such that it does not
                    % interfere with existing DFS file types.
                    % X = 39
                    %  [1]
                case 21
                    % Type of DFS file storing format, see (2) below.
                    %
                    % The storing format specifies whether all items are
                    % stored in all time steps, and if a time-varying
                    % spatial axes is used. Currently the DFS file system
                    % only supports files with all items in all time steps
                    % and not any of the time-varying spatial axes. Thus
                    % this is not used, and is not presently planned to be
                    % explored.
                    % X = 39
                    %  [1], [2] --> It seems 2 correlates with the occurence of a 51/117 record
                case 22
                    % Delete values, see (3) below.
                    %
                    % A delete value represents a not-defined value. If a
                    % value is not available, or if it does not make sense
                    % to set a value, setting the delete value indicates
                    % that there is no value. There is a delete value for
                    % data of type float, double, integer (32 bit),
                    % unsigned integer and byte (8 bit).
                    % X = 39
                    Info.Clipping = i2.Data{1};
                case 23
                    % X = 39
                    %  [-1.0000e-030], [-1.0000e-077], [-1.0000e-255]
                case 24
                    % X = 39
                    %  ' '
                case 25
                    % minimum value?
                    % X = 39
                    %  [-9876789], [2.1475e+009]
                case 26
                    % maximum value?
                    % X = 39
                    %  [9876789], [2.1475e+009]
                case 27
                    % Geographic map projection information.
                    % X = 39
                    Info.ProjectionName = deblank(i2.Data{1});
                    Info.ProjectionData = i2.Data{2};
                case 28
                    % X = 39
                    Info.NumItems = i2.Data{1}+1;
                case 29
                    % X = 39
                    Info.SparseStorage = i2.Data{1};
                case 32
                    % X = 78  {}
                case 48
                    % X = 117 {}
                case 49
                    % number of time dependent quantities
                    Info.NumTimDepItems = i2.Data{1};
                case 51
                    % per item
                    % X = 117: {[10.0085 10 3.6116e+003 3.6132e+004 3.6032e+004 10.0084 361 360 0]}
                    % X = 117: {[4611 -12364.1 -121720 1.59038e+09 1.52705e+09 -6156.77 21 20 0]}                    
                    % 10.0085 10 = Max & Min of Item
                    % 10.0084 = last value
                    % 361 = NumTimeSteps
                    %Info.Item(it).NumTimeSteps = i2.Data{1}(7);
                    %fprintf('%g %g %g %g %g %g %g %g %g\n',i2.Data{1});
                case 53
                    % quantity description
                    %  1          2                                 3      4    5                                 6        7
                    % {[100000]  'P(25,10): H Water Depth m '      [1000] [1]  [10.0085 10.0000 0]               [0 0 0]  [0 0 0]}
                    % {[999]     'P(0,10)-P(50,10): Component 1 '  [0]    [1]  [4.5768 -2.3594e-005 1083]        [0 0 0]  [0 0 0]}
                    % {[100000]  'naam '                           [1000] [1]  [-1.0000e-255 -1.0000e-255 30000] [0 0 0]  [0 0 0]}
                    % {[999]     'Static item '                    [0]    [1]  [0 0 0]                           [0 0 0]  [0 0 0]}
                    % {[999]     'Dummy '                          [0]    [1]  [0 0 1589]                        [0 0 0]  [0 0 0]}
                    % {[999]     'E-coli '                         [0]    [1]  [0 0 1589]                        [0 0 0]  [0 0 0]}
                    it = it+1;
                    Info.Item(it).Name = deblank(i2.Data{2});
                    Info.Item(it).Static = static;
                    Info.Item(it).Max = i2.Data{5}(1);
                    Info.Item(it).Min = i2.Data{5}(2);
                    Info.Item(it).NumClip = i2.Data{5}(3);
                    if ~static
                        Info.Item(it).Data = repmat(-1,1,Info.NumTimeSteps);
                    end
                    Info.Item(it).MatrixSize = 1;
                    Info.Item(it).CellSize = 0;
                case 54
                    % X = 117
                    % per item
                    % [0], [1]
                    %fprintf('54/117 -> %i\n',i2.Data{1});
                case 64
                    % X+156
                    static = 1;
                case 65
                    % per item
                    % X = 156
                    sz = [Info.Item(it).MatrixSize 1];
                    Info.Item(it).Data = reshape(i2.Data{1},sz);
                case 75
                    % per item
                case {76,79,82}
                    % per item
                    % X = 121
                    % 0: -
                    % 1: 76: {[1000 51]  [0 100]}
                    % 2: 79: {[1000 44 78]  [0 0 150 150]}
                    % 3: 82: {[1000 10 20 5]  [0 0 0 10 10 1]}
                    NDim = length(i2.Data{1})-1;
                    Info.Item(it).MatrixSize = i2.Data{1}(2:end);
                    %Info.Item(it).Offset = i2.Data{2}(1:NDim);
                    Info.Item(it).CellSize = i2.Data{2}((NDim+1):end);
                case 80
                    % start time dependent data
                    % X = 195
                    % {}
                    it = 0;
                case 81
                    % markers between time dependent datasets - time step
                    % X = 195
                    % {} : EQuidistant times
                    % {0} : Non-EQuidistant times
                    % {2280}
                    % {4200}
                    fld = fld+1;
                    if strcmp(Info.TimeType,'NEQ')
                        Info.Times(fld) = i2.Data{1} * Info.TimeUnit;
                    end
                    it = 0;
                case {85,86} % reference date, so type: calendar
                    % X = 78
                    % {'1990-01-01 '  '12:00:00 '  [1400]  [0 20]  [361 0]}
                    % {'1990-01-01 '  '12:00:00 '  [1400]  [0 20]  [361 0]}
                    % {'1990-01-01 '  '12:00:00 '  [1400]  [0 1800]  [1 0]}
                    % {'1990-01-01 '  '00:00:00 '  [1400]  [0 30]  [30 0]}
                    % {'2009-10-13 '  '07:02:00 '  [1400]  [0 39840]  [21 0]}
                    V = sscanf([i2.Data{1}(1:end-1),' ',i2.Data{2}],'%d-%d-%d %d:%d:%d');
                    Info.RefDate = datenum(V(1),V(2),V(3),V(4),V(5),V(6));
                    % i2.Data{3} i.e. 1400 = time unit flag?
                    Info.TimeUnit = 1/(3600*24);
                    Info.NumTimeSteps = i2.Data{5}(1);
                    switch Opt
                        case 85
                            Info.TimeType = 'EQ'; % equidistant
                            Info.TimeOffset = i2.Data{4}(1) * Info.TimeUnit; % assumption ...
                            Info.TimeStep = i2.Data{4}(2) * Info.TimeUnit;
                            Info.Times = Info.TimeOffset + (0:Info.NumTimeSteps-1) * Info.TimeStep;
                        case 86
                            Info.TimeType = 'NEQ'; % non-equidistant
                            % i2.Data{4}(1) first time
                            % i2.Data{4}(2) last time
                            Info.Times = zeros(1,Info.NumTimeSteps);
                    end
                case 96
                    % X = 234
                    % {'M21_Misc '  [327.8968 0.2000 -900 5 71 93 40]}
                    % 327.8968 = ProjectionData(3)
                    %
                    % {'MIKE_FM '  [3192 4578 3 7]}
                    att = att+1;
                    Info.Attrib(att).Name = deblank(i2.Data{1});
                    Info.Attrib(att).Data = i2.Data{2};
                otherwise
                    % Opt = 75, X = 121: {[0]}
                    Fld = sprintf('Fld%i_%i',Opt,X);
                    if isfield(Info,Fld)
                        Fld1 = Fld;
                        i = 1;
                        while isfield(Info,Fld1)
                            i = i+1;
                            Fld1 = sprintf('%s_%i',Fld,i);
                        end
                        Fld = Fld1;
                    end
                    %fprintf('%s\nGeneral Field: %s\n\n',fopen(fid),Fld);
                    Info = setfield(Info,Fld,i2);
            end
        case 255
            logger(logid,indent(1:end-2),'<--\n')
            return
        otherwise
            error('Unknown type %i',Typ)
    end
end
Info.Check = 'OK';


function Data = Local_read_mike(S,varargin)
Data = [];

IN = varargin;
if ~isempty(IN) && iscell(IN{end})
    subscr = IN{end};
    if length(subscr) ~= S.NumCoords,
        error('Invalid number of indices.');
    end
    IN = IN(1:end-1);
else
    subscr = {};
end

switch length(IN)
    case 0
        if S.NumItems == 1
            Item = 1;
            TimeStep = max(1,S.NumTimeSteps);
        else
            error('No item specified.')
        end
    case 1 % TimeStep or Item
        if S.NumItems == 1
            Item = 1;
            TimeStep = IN{1};
        else
            Item = IN{1};
            if ischar(Item)
                Item = ustrcmpi(Item,{S.Item.Name});
                if isempty(Item)
                    error('Invalid item name')
                end
            end
            TimeStep = max(1,S.NumTimeSteps);
        end
    case 2
        Item = IN{1};
        if ischar(Item)
            Item = ustrcmpi(Item,{S.Item.Name});
            if isempty(Item)
                error('Invalid item name')
            end
        end
        TimeStep = IN{2};
    otherwise
        error('Too many input arguments.')
end

if isempty(subscr)
    Size = S.DataDim+1;
else
    Size = zeros(1,S.NumCoords);
    for i = 1:S.NumCoords
        if isequal(subscr{i},0)
            subscr{i} = 1:(S.DataDim(i)+1);
            Size(i) = S.DataDim(i)+1;
        else
            Size(i) = length(subscr{i});
        end
    end
end

if isequal(TimeStep,-1)
    if S.DataDim == 0 % 0D
        Data = [];
    else
        sz = S.DataDim+1;
        switch length(sz)
            case 1
                Data.X = (0:sz(1))*S.GridCell(1);
                if ~isempty(subscr)
                    Data.X = Data.X(subscr{:});
                end
            case 2
                Data.X = repmat(transpose(0:sz(1))*S.GridCell(1), ...
                    1,sz(2)+1);
                Data.Y = repmat((0:sz(2))*S.GridCell(2), ...
                    sz(1)+1,1);
                if ~isempty(subscr)
                    Data.X = Data.X(subscr{:});
                end
                if ~isempty(subscr)
                    Data.Y = Data.Y(subscr{:});
                end
            case 3
                Data.X = repmat(transpose(0:sz(1))*S.GridCell(1), ...
                    [1,sz(2)+1,sz(3)+1]);
                Data.Y = repmat((0:sz(2))*S.GridCell(2), ...
                    [sz(1)+1,1,sz(3)+1]);
                Data.Z = repmat(reshape((0:sz(3))*S.GridCell(3), ...
                    [1 1 sz(3)+1]), ...
                    [sz(1)+1,sz(2)+1,1]);
                if ~isempty(subscr)
                    Data.X = Data.X(subscr{:});
                end
                if ~isempty(subscr)
                    Data.Y = Data.Y(subscr{:});
                end
                if ~isempty(subscr)
                    Data.Z = Data.Z(subscr{:});
                end
        end
    end
    return
end

dat_file = [S.FileName S.Dat];
fidat = fopen(dat_file,'r',S.Format);
if isequal(TimeStep,0)
    TimeStep = 1:max(1,S.NumTimeSteps);
end
if length(TimeStep) ~= 1
    Data = zeros([length(TimeStep) Size]);
    for i = 1:length(TimeStep)
        fseek(fidat,(S.NumItems*(TimeStep(i)-1)+Item-1)*prod(S.DataDim+1)*4,-1);
        Tmp = fread(fidat,[1 prod(S.DataDim+1)],'float32');
        if ~isempty(subscr)
            Tmp = Tmp(1,subscr{:});
        end
        Data(i,:) = Tmp;
    end
else
    fseek(fidat,(S.NumItems*(TimeStep-1)+Item-1)*prod(S.DataDim+1)*4,-1);
    Data = fread(fidat,[1 prod(S.DataDim+1)],'float32');
    Data = reshape(Data,[S.DataDim+1 1]);
    if ~isempty(subscr)
        Data = Data(subscr{:});
    end
end

fclose(fidat);


function Data = Local_read_mike_new(S,varargin)
Data = [];

IN = varargin;
if iscell(IN{end})
    subscr = IN{end};
    if length(subscr) ~= S.NumCoords
        error('Invalid number of indices.')
    end
    IN = IN(1:end-1);
else
    subscr = {};
end

switch length(IN)
    case 0
        if S.NumItems == 1
            Item = 1;
            Info = S.Item(Item);
            if Info.Static
                TimeStep = 1;
            else
                TimeStep = S.NumTimeSteps;
                if TimeStep == 0 % Doesn't mean all timesteps. Well, it would give the same result since there are none.
                    TimeStep = [];
                end
            end
        else
            error('No item specified.')
        end
    case 1 % TimeStep or Item
        if S.NumItems == 1
            Item = 1;
            Info = S.Item(Item);
            TimeStep = IN{1};
        else
            Item = IN{1};
            if ischar(Item)
                Item = ustrcmpi(Item,{S.Item.Name});
                if isempty(Item)
                    error('Invalid item name')
                end
            end
            Info = S.Item(Item);
            if Info.Static
                TimeStep = 1;
            else
                TimeStep = S.NumTimeSteps;
                if TimeStep == 0 % Doesn't mean all timesteps. Well, it would give the same result since there are none.
                    TimeStep = [];
                end
            end
        end
    case 2
        Item = IN{1};
        if ischar(Item)
            Item = ustrcmpi(Item,{S.Item.Name});
            if isempty(Item)
                error('Invalid item name')
            end
        end
        Info = S.Item(Item);
        TimeStep = IN{2};
    otherwise
        error('Too many input arguments.')
end

if isempty(subscr)
    Size = Info.MatrixSize;
else
    Size = zeros(1,S.NumCoords);
    for i = 1:S.NumCoords
        if isequal(subscr{i},0)
            subscr{i} = 1:Info.MatrixSize(i);
            Size(i) = Info.MatrixSize(i);
        else
            Size(i) = length(subscr{i});
        end
    end
end

if isequal(TimeStep,-1)
    if Info.CellSize(1) == 0 % 0D
        Data = [];
    else
        switch length(Info.MatrixSize)
            case 1
                Data.X = (0:Info.MatrixSize(1))*Info.CellSize(1);
                if ~isempty(subscr)
                    Data.X = Data.X(subscr{:});
                end
            case 2
                Data.X = repmat(transpose(0:Info.MatrixSize(1))*Info.CellSize(1), ...
                    1,Info.MatrixSize(2)+1);
                Data.Y = repmat((0:Info.MatrixSize(2))*Info.CellSize(2), ...
                    Info.MatrixSize(1)+1,1);
                if ~isempty(subscr)
                    Data.X = Data.X(subscr{:});
                end
                if ~isempty(subscr)
                    Data.Y = Data.Y(subscr{:});
                end
            case 3
                Data.X = repmat(transpose(0:Info.MatrixSize(1))*Info.CellSize(1), ...
                    [1,Info.MatrixSize(2)+1,Info.MatrixSize(3)+1]);
                Data.Y = repmat((0:Info.MatrixSize(2))*Info.CellSize(2), ...
                    [Info.MatrixSize(1)+1,1,Info.MatrixSize(3)+1]);
                Data.Z = repmat(reshape((0:Info.MatrixSize(3))*Info.CellSize(3), ...
                    [1 1 Info.MatrixSize(3)+1]), ...
                    [Info.MatrixSize(1)+1,Info.MatrixSize(2)+1,1]);
                if ~isempty(subscr)
                    Data.X = Data.X(subscr{:});
                end
                if ~isempty(subscr)
                    Data.Y = Data.Y(subscr{:});
                end
                if ~isempty(subscr)
                    Data.Z = Data.Z(subscr{:});
                end
        end
    end
    return
end

if S.SparseStorage
    ix = strmatch('X-Encoding Key',{S.Item.Name},'exact');
    IX = S.Item(ix).Data;
    iy = strmatch('Y-Encoding Key',{S.Item.Name},'exact');
    IY = S.Item(iy).Data;
    iz = strmatch('Z-Encoding Key',{S.Item.Name},'exact');
    IZ = S.Item(iz).Data;
end
if Info.Static
    Data = S.Item(Item).Data;
    if ~isempty(subscr)
        Data = Data(subscr{:});
    end
else
    dat_file = [S.FileName S.Dat];
    fidat = fopen(dat_file,'r',S.Format);
    if isequal(TimeStep,0)
        TimeStep = 1:S.NumTimeSteps;
    end
    if length(TimeStep) ~= 1
        Data = zeros([length(TimeStep) Size]);
        for i = 1:length(TimeStep)
            fseek(fidat,Info.Data(TimeStep(i)),-1);
            Tmp = fread(fidat,[1 prod(Info.MatrixSize)],'float32');
            if ~isempty(subscr)
                Tmp = Tmp(1,subscr{:});
            end
            Data(i,:) = Tmp;
        end
    else
        fseek(fidat,Info.Data(TimeStep),-1);
        if S.SparseStorage
            Vals = fread(fidat,length(IX),'float32');
            Data = repmat(NaN,[Info.MatrixSize 1]);
            Data(sub2ind(size(Data),IX+1,IY+1,IZ+1)) = Vals;
        else
            Data = fread(fidat,prod(Info.MatrixSize),'float32');
            Data = reshape(Data,[Info.MatrixSize 1]);
        end
        if ~isempty(subscr)
            Data = Data(subscr{:});
        end
    end
    fclose(fidat);
end
Data(Data == S.Clipping) = NaN;


function logger(logid,indent,varargin)
if logid > 0
    fprintf(logid,[indent varargin{1}],varargin{2:end});
end


function arraylogger(logid,data)
if logid>0
    str = sprintf('%g ',data(1:min(length(data),10)));
    if length(data) > 10
        fprintf(logid,'%s...\n',str);
    else
        fprintf('%s\n', str);
    end
end