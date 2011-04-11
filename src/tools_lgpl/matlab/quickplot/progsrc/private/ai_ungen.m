function varargout=ai_ungen(cmd,varargin),
%AI_UNGEN Read/write ArcInfo (un)generate files.
%
%   FileInfo=AI_UNGEN('open',FileName)
%      Opens the specified file and reads its contents.
%
%   XY=AI_UNGEN('read',FileInfo)
%   [X,Y]=AI_UNGEN('read',FileInfo)
%      Returns the X and Y data in the file. If instead of the FileInfo
%      structure a file name is provided then the indicated file is
%      opened and the data is returned.
%
%   AI_UNGEN('write',FileName,XY)
%   AI_UNGEN('write',FileName,X,Y)
%      Writes the line segments to file. X,Y should either
%      contain NaN separated line segments or X,Y cell arrays
%      containing the line segments.
%   AI_UNGEN(...,'-1')
%      Doesn't write line segments of length 1.

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
%   http://www.delftsoftware.com
%   $HeadURL$
%   $Id$

if nargout>0,
    varargout=cell(1,nargout);
end;
if nargin==0,
    return;
end;
switch cmd,
    case 'open',
        Out=Local_open_file(varargin{:});
        varargout{1}=Out;
    case 'read',
        Out=Local_read_file(varargin{:});
        if nargout==1,
            varargout{1}=Out;
        elseif nargout>1,
            varargout{1}=Out(:,1);
            varargout{2}=Out(:,2);
        end;
    case 'write',
        Local_write_file(varargin{:});
    otherwise,
        uiwait(msgbox('unknown command','modal'));
end;


function T=Local_open_file(filename);
T=[];
if nargin==0,
    [fn,fp]=uigetfile('*.gen');
    if ~ischar(fn),
        return;
    end;
    filename=[fp fn];
end;

fid=fopen(filename,'r');
T.FileName=filename;
T.FileType='ArcInfoUngenerate';
T.Check='NotOK';
i=0;
ok=0;
SegPrev=[];
Points=0;
while ~feof(fid)
    if isempty(SegPrev)
        Line=fgetl(fid);
        id=sscanf(Line,'%f%*[ ,]');
        if length(id)>1
            Points=1;
        end
    end
    if isempty(id),
        END=sscanf(Line,' %[eE]%[nN]%[dD]',3);
        if ~isempty(END) & ~isequal(upper(END),'END')
            fclose(fid);
            error('Missing closing END statement in file.');
        end
        ok=1;
        break
    end
    i=i+1;
    if Points
        T.Seg(i).ID=id(1);
        T.Seg(i).Coord=id(2:end)';
        SegPrev=[];
    else
        T.Seg(i).ID=id;
        T.Seg(i).Coord=fscanf(fid,'%f%*[ ,]%f\n',[2 inf])';
        if ~isempty(SegPrev),
            T.Seg(i).Coord=cat(1,SegPrev,T.Seg(i).Coord);
            SegPrev=[];
        end
        END=fscanf(fid,'%[eE]%[nN]%[dD]',3);
        if isempty(END)
            id=T.Seg(i).Coord(end-1,1);
            SegPrev(1,1)=T.Seg(i).Coord(end-1,2);
            SegPrev(1,2)=T.Seg(i).Coord(end,1);
            T.Seg(i).Coord=T.Seg(i).Coord(1:end-2,:);
        elseif ~isequal(upper(END),'END')
            fclose(fid);
            error('Unexpected characters.');
        else
            dummy=fgetl(fid);
        end
    end
    if feof(fid), ok=1; end
end
fclose(fid);
if ~ok
    error('Missing closing END statement in file.');
end
T.Check='OK';
%
% Compute total number of points
%
nel=0;
for i=1:length(T.Seg)
    nel=nel+size(T.Seg(i).Coord,1)+1;
end
nel=nel-1;
T.TotalNPnt=nel;


function Data=Local_read_file(varargin);
Data=[];
if nargin==1 & isstruct(varargin{1})
    T=varargin{1};
else
    T=Local_open_file(varargin{:});
end

nel=T.TotalNPnt;

Data=repmat(NaN,nel,2);
offset=0;
for i=1:length(T.Seg)
    t1=size(T.Seg(i).Coord,1);
    Data(offset+(1:t1),:)=T.Seg(i).Coord;
    offset=offset+t1+1;
end


function Local_write_file(varargin);

j=0;
RemoveLengthOne=0;
XYSep=0;
BNA=0;
filename='';
for i=1:nargin
    if ischar(varargin{i}) & strcmp(varargin{i},'-1')
        RemoveLengthOne=1;
    elseif ischar(varargin{i}) & strcmp(varargin{i},'BNA')
        BNA=1;
    elseif ischar(varargin{i}) & isempty(filename)
        filename=varargin{i};
    elseif j==0
        Data1=varargin{i};
        j=j+1;
    elseif (isnumeric(varargin{i}) | iscell(varargin{i})) & j==1
        Data2=varargin{i};
        XYSep=1; % x and y supplied separately?
    else
        error(sprintf('Invalid input argument %i',i+2))
    end
end

if isempty(filename)
    [fn,fp]=uiputfile('*.*');
    if ~ischar(fn),
        return;
    end;
    filename=[fp fn];
end;

if isnumeric(Data1) % convert to column vectors
    if XYSep
        Data1=Data1(:);
        Data2=Data2(:);
    else
        if size(Data1,2)~=2 % [x;y] supplied
            Data1=transpose(Data1);
        end
    end
end

if iscell(Data1),
    j=0;
    for i=1:length(Data1),
        if XYSep
            Length=length(Data1{i}(:));
        else
            if size(Data1{i},2)~=2
                Data1{i}=transpose(Data1{i});
            end
            Length=size(Data1{i},1);
        end
        if ~(isempty(Data1{i}) | (RemoveLengthOne & Length==1)), % remove lines of length 0 (and optionally 1)
            j=j+1;
            T.Seg(j).ID = j;
            if XYSep
                T.Seg(j).Coord = [Data1{i}(:) Data2{i}(:)];
            else
                T.Seg(j).Coord = Data1{i};
            end
        end;
    end;
elseif ~isstruct(Data1),
    I=[0; find(isnan(Data1(:,1))); size(Data1,1)+1];
    j=0;
    for i=1:(length(I)-1),
        if I(i+1)>(I(i)+1+RemoveLengthOne), % remove lines of length 0  (and optionally 1)
            j=j+1;
            T.Seg(j).ID = j;
            if XYSep
                T.Seg(j).Coord = [Data1((I(i)+1):(I(i+1)-1)) Data2((I(i)+1):(I(i+1)-1))];
            else
                T.Seg(j).Coord = Data1((I(i)+1):(I(i+1)-1),:);
            end
        end;
    end;
else
    T=Data1;
end;

fid=fopen(filename,'w');
for j=1:length(T.Seg)
    if BNA
        if isfield(T.Seg(j),'ID1')
            id1=T.Seg(j).ID1;
            id2=T.Seg(j).ID2;
        else
            id1=num2str(T.Seg(j).ID);
            id2='';
        end
        fprintf(fid,'"%s","%s",%d\n',id1,id2,size(T.Seg(j).Coord,1));
    else
        if isfield(T.Seg(j),'ID')
            id=T.Seg(j).ID;
        else
            id=j;
        end
        fprintf(fid,'%d\n',id);
    end
    fprintf(fid,'%f, %f\n',transpose(T.Seg(j).Coord));
    if ~BNA, fprintf(fid,'END\n'); end
end
if ~BNA, fprintf(fid,'END\n'); end
fclose(fid);
