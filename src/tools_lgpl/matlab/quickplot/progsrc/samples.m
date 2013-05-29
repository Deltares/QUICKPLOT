function [x,y,z]=samples(cmd,varargin)
%SAMPLES Read/write sample data from file.
%     XYZ = SAMPLES('read',FILENAME) read the specified file and return the
%     data contained in it. In the classic case of a simple plain Delft3D
%     samples file contain three data columns, the function returns an Nx3
%     array with the data. Due to the algorithm used, the file may contain
%     any number of comments in MATLAB style, i.e. starting with %. As a
%     generalization beyond the classic samples file, the number of columns
%     may differ from 3.
%
%     [X,Y,Z] = SAMPLES('read',FILENAME) read the specified file and return
%     the samples in three separate Nx1 arrays.
%
%     SAMPLES('write',FILENAME,XYZ) write samples given in a Nx3 (or 3xN)
%     array to a samples file. Because of the automatic transpose option,
%     this function does not support any other number of data columns.
%
%     SAMPLES('write',FILENAME,X,Y,Z) write samples given in three Nx1 (or
%     1xN) arrays to a samples file. Because of the automatic transpose
%     option, this function does not support any other number of data
%     columns.

%----- LGPL --------------------------------------------------------------------
%
%   Copyright (C) 2011-2013 Stichting Deltares.
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

switch lower(cmd)
    case 'read'
        xyz=Local_read_samples(varargin{:});
        if nargout>1
            x=xyz(:,1);
            y=xyz(:,2);
            z=xyz(:,3);
        else
            x=xyz;
        end
    case 'write'
        if ~ischar(varargin{1})
            Local_write_samples('?',varargin{:});
        else
            Local_write_samples(varargin{:});
        end
    otherwise
        error('Unknown command: %s',var2str(cmd)) 
end

function xyz=Local_read_samples(filename,opt)
if (nargin==0) || strcmp(filename,'?')
    [fname,fpath]=uigetfile('*.xyz','Select sample file');
    if ~ischar(fname)
        xyz=zeros(0,3);
        return
    end
    filename=[fpath,fname];
end

readtype='default';
if nargin>1
    opt = lower(opt);
    switch opt
        case {'simple','struct'}
            readtype = opt;
        otherwise
            error('Invalid samples read option: %s',opt)
    end
end

if exist(filename)~=2
    error('Cannot open %s.',filename)
end
try
    xyz0 = load(filename);
    simplexyz = 1;
catch
    try
        xyz0 = asciiload(filename);
        simplexyz = 1;
    catch
        simplexyz = 0;
    end
end

if simplexyz
    switch readtype
        case {'simple','default'}
            xyz = xyz0;
        otherwise
            xyz.XYZ = xyz0;
            npar = size(xyz0,2);            
            xyz.Params = cell(1,npar);
            for i=1:npar
                xyz.Params{i}=sprintf('Parameter %i',i);
            end
            xyz.FileType = 'samples';
            xyz.FileName = filename;
            %
            fid=fopen(filename,'r');
            str=fgetl(fid);
            xyz.Header = {};
            while ~isempty(str) && str(1)=='%'
                xyz.Header{end+1} = str;
                str=fgetl(fid);
            end
            fclose(fid);
            %
            if ~isempty(xyz.Header)
                for i = length(xyz.Header):-1:1
                    j = strfind(xyz.Header{i},'Run:');
                    if ~isempty(j)
                        xyz.Run = strtok(xyz.Header{i}(j+4:end));
                    end
                    j = strfind(xyz.Header{i},'Table:');
                    if ~isempty(j)
                        xyz.Table = strtok(xyz.Header{i}(j+6:end));
                    end
                    j = strfind(xyz.Header{i},'SWAN version:');
                    if ~isempty(j)
                        xyz.SWAN_version = strtok(xyz.Header{i}(j+13:end));
                    end
                    j1 = strfind(xyz.Header{i},'[');
                    j2 = strfind(xyz.Header{i},']');
                    if length(j1) == npar && length(j2) == npar
                        xyz.ParamUnits = repmat({''},1,npar);
                        for j = 1:npar
                            xyz.ParamUnits{j} = xyz.Header{i}(j1(j)+1:j2(j)-1);
                        end
                        par = textscan(xyz.Header{i-1}(2:end),'%s');
                        xyz.Params = par{1};
                    end
                end
            end
    end
else % readtype always forced to 'struct'
    fid=fopen(filename,'r');
    try
        cloc=0;
        str=fgetl(fid);
        while ischar(str) && ~isempty(str) && str(1)=='*'
            cloc=ftell(fid);
            str=fgetl(fid);
        end
        if ~ischar(str)
            fclose(fid);
            error('%s does not contain samples.',filename);
        end
        [X,n,er]=sscanf(str,'%g');
        Params={};
        while ~isempty(er)
            [Param,n,er,ni]=sscanf(str,' "%[^"]%["]',2);
            if isempty(er) && n==2
                Params{end+1}=Param(1:end-1);
            else
                [Param,n,er]=sscanf(str,' %s',1);
                if isempty(er) && n==1
                    error('Reading line: %s\nIf this line contains a parameter name, then it should be enclosed by double quotes.',str);
                    %Params{end+1}=Param; %<--- makes it impossible to distinguish
                    %certain observation files from Tekal file format. For example:
                    %B001
                    %160 4 16 10
                    %1.0 2.0 3.0 4.0
                    % :   :   :   :
                else
                    break
                end
            end
            str=str(ni:end);
            if ~isempty(str)
                er='scan remainder of line';
            else
                cloc=ftell(fid);
                str=fgetl(fid);
                [X,n,er]=sscanf(str,'%g');
            end
        end
        [X,n,er]=sscanf(str,'%g');
        if ~isempty(er)
            error('Unable to data values on line: %s',str);
        elseif n<3
            error('Not enough values for sample data (X,Y,Value1,...)')
        end
        str=fgetl(fid);
        [X,n2]=sscanf(str,'%g');
        if n2~=n && ~feof(fid)
            error('Number of values per line should be constant.')
        end
        if length(Params)<n
            for i=(length(Params)+1):n
                Params{i}=sprintf('Parameter %i',i);
            end
        elseif length(Params)>n
            Params=Params(1:n);
        end
        if n==0
            fclose(fid);
            error('Number of values cannot be zero.')
        end
        fclose(fid);
    catch
        fclose(fid);
        rethrow(lasterror)
    end
    
    xyz.XYZ=asciiload(filename,'seek',cloc);
    xyz.Params=Params;
    xyz.FileType='samples';
    xyz.FileName=filename;
    
    if strcmp(readtype,'simple')
        xyz = xyz.XYZ;
    end
end
%
if isstruct(xyz)
    xyz.X = [];
    xyz.Y = [];
    xyz.Time = [];
    for i = 1:length(xyz.Params)
        switch lower(xyz.Params{i})
            case {'xp','x-coordinate','x coordinate'}
                xyz.X = i;
            case {'yp','y-coordinate','y coordinate'}
                xyz.Y = i;
            case {'time'}
                xyz.Time = i;
        end
    end
    if isempty(xyz.X) && isempty(xyz.Y)
        xyz.X = find(strcmp(xyz.Params,'Parameter 1'));
        if ~isempty(xyz.X)
           xyz.Y = find(strcmp(xyz.Params,'Parameter 2'));
        end
    end
    %
    if ~isempty(xyz.Time)
        [Times,idum,iTime] = unique(xyz.XYZ(:,xyz.Time));
        d = floor(Times);
        s = round((Times - d)*1000000);
        m = floor(d/100);
        d = d - 100*m;
        y = floor(m/100);
        m = m - 100*y;
        %
        mn = floor(s/100);
        s  = s - mn*100;
        h = floor(mn/100);
        mn = mn - h*100;
        %
        xyz.Times = datenum(y,m,d,h,mn,s);
        xyz.iTime = iTime;
        %
        nLoc = hist(xyz.iTime,max(xyz.iTime));
        if all(nLoc==nLoc(1))
            xyz.nLoc = nLoc(1);
        else
            xyz.nLoc = nLoc;
        end
    else
        xyz.nLoc = size(xyz.XYZ,1);
    end
end


function Local_write_samples(filename,x,y,z)
if strcmp(filename,'?')
    [fn,fp]=uiputfile('*.xyz');
    if ~ischar(fn)
        return
    end
    filename=[fp fn];
end
fid=fopen(filename,'wt');
if fid<0
    error(['Could not create or open: ',filename])
end

if nargin==4
    if size(x,2)==1 % column vectors
        xyz=transpose([x y z]);
    else % row vectors
        xyz=[x;y;z];
    end
    fprintf(fid,'%f %f %f\n',xyz);
else
    if size(x,2)==3 % column vector (3x)
        x=transpose(x);
    end
    fprintf(fid,'%f %f %f\n',x);
end
fclose(fid);
