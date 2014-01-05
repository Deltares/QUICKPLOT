function S = qp_session(cmd,H,varargin)
%QP_SESSION Save QuickPlot figures to and rebuild them from an ASCII file.
%   QP_SESSION is still incomplete, not documented and subject to change.

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

switch cmd
    case 'read'
        S = local_read(H);
    case 'extract'
        S = local_extract(H);
    case 'rebuild'
        S = local_rebuild(H);
    case 'save'
        local_save(H,varargin{:})
end

function S = local_read(filename)
fid = fopen(filename,'r');
Str = getline(fid);
fgi = 0;
axi = 0;
S = [];
while ~isempty(Str)
    args = parseargs(Str);
    switch args{1}
        case 'Figure'
            fgi = length(S)+1;
            axi = 0;
            S(fgi).Name = args{2};
            S(fgi).PaperType = 'a4';
            S(fgi).PaperOrientation = 'portrait';
            S(fgi).PaperSize = [];
            S(fgi).PaperUnits = 'centimeters';
            S(fgi).WindowSize = [];
            S(fgi).Color = [];
            S(fgi).Frame.Type = 'none';
            S(fgi).Axes = [];
        case 'FrameStyle'
            S(fgi).Frame.Type = args{2};
        case 'Axes'
            axi = length(S(fgi).Axes)+1;
            S(fgi).Axes(axi).Name = args{2};
            S(fgi).Axes(axi).Position = [];
            S(fgi).Axes(axi).Color = get(0,'factoryuicontrolbackgroundcolor')*255;
            S(fgi).Axes(axi).Box = 'off';
            S(fgi).Axes(axi).Title = '<automatic>';
            for x = 'xyz'
                X = upper(x);
                S(fgi).Axes(axi).([X 'Label']) = '<automatic>';
                S(fgi).Axes(axi).([X 'Color']) = [0 0 0];
                S(fgi).Axes(axi).([X 'Grid'])  = 'off';
                if X=='X'
                    S(fgi).Axes(axi).([X 'Loc']) = 'bottom';
                elseif X=='Y'
                    S(fgi).Axes(axi).([X 'Loc']) = 'left';
                end
                S(fgi).Axes(axi).([X 'Scale']) = 'linear';
                S(fgi).Axes(axi).([X 'Lim']) = 'auto';
            end
        case 'EndAxes'
            axi = 0;
        case 'EndFigure'
            fgi = 0;
        otherwise
            if fgi>0
                if axi>0
                    S(fgi).Axes(axi).(args{1}) = args{2};
                elseif strncmp(args{1},'FrameText',9)
                    S(fgi).Frame.(args{1}) = args{2};
                else
                    S(fgi).(args{1}) = args{2};
                end
            end
    end
    Str = getline(fid);
end
fclose(fid);

function Str = getline(fid)
Str = '';
while isempty(Str) && ~feof(fid)
    Str = fgetl(fid);
end

function args = parseargs(Str)
i=0;
args = {};
while 1
    [Key,Rem] = strtok(Str);
    if isempty(Key)
        break
    elseif Key(1)=='['
        i1 = strfind(Str,'[');
        i2 = strfind(Str,']');
        Key = str2vec(Str(i1(1)+1:i2(1)-1),'%f');
        Str = Str(i2(1)+1:end);
    elseif Key(1)==''''
        i1 = strfind(Str,'''');
        Key = Str(i1(1)+1:i1(end)-1);
        Str = '';
    elseif i>0
        Key = str2double(Key);
        Str = Rem;
    else
        Str = Rem;
    end
    i=i+1;
    args{i} = Key;
end

function local_save(S,filename)
fid = fopen(filename,'w');
for fgi = 1:length(S)
    fprintf(fid,'Figure             ''%s''\n',S(fgi).Name);
    fprintf(fid,'  PaperType        ''%s''\n',S(fgi).PaperType);
    fprintf(fid,'  PaperOrientation ''%s''\n',S(fgi).PaperOrientation);
    if strcmp(S(fgi).PaperType,'<custom>')
        fprintf(fid,'  PaperSize        [%g %g]\n',S(fgi).PaperSize);
        fprintf(fid,'  PaperUnits       ''%s''\n',S(fgi).PaperUnits);
    end
    if ~isequal(S(fgi).Color,get(0,'factoryuicontrolbackgroundcolor')*255)
        fprintf(fid,'  Color            [%i %i %i]\n',S(fgi).Color);
    end
    fprintf(fid,'  WindowSize       [%i %i]\n',S(fgi).WindowSize);
    fprintf(fid,'  FrameStyle       ''%s''\n',S(fgi).Frame.Type);
    ibt = 1;
    fld = 'FrameText1';
    while isfield(S(fgi).Frame,fld)
        fprintf(fid,'  FrameText%-4i    ''%s''\n',ibt,S(fgi).Frame.(fld));
        ibt = ibt+1;
        fld = sprintf('FrameText%i',ibt);
    end
    %
    for axi = 1:length(S(fgi).Axes)
        fprintf(fid,'\n  Axes        ''%s''\n',S(fgi).Axes(axi).Name);
        fprintf(fid,'    Position  [%g %g %g %g]\n',S(fgi).Axes(axi).Position);
        if ~strcmp(S(fgi).Axes(axi).Title,'<automatic>')
            fprintf(fid,'    Title     ''%s''\n',S(fgi).Axes(axi).Title);
        end
        if ischar(S(fgi).Axes(axi).Color)
            fprintf(fid,'    Color     ''none''\n');
        elseif ~isequal(S(fgi).Axes(axi).Color,[255 255 255])
            fprintf(fid,'    Color     [%i %i %i]\n',S(fgi).Axes(axi).Color);
        end
        fprintf(fid,'    Box       ''%s''\n',S(fgi).Axes(axi).Box);
        for X = 'XY'
            if ~strcmp(S(fgi).Axes(axi).([X 'Label']),'<automatic>')
                fprintf(fid,'    %sLabel    ''%s''\n',X,S(fgi).Axes(axi).([X 'Label']));
            end
            if ~strcmp(S(fgi).Axes(axi).([X 'Grid']),'off')
                fprintf(fid,'    %sGrid     ''%s''\n',X,S(fgi).Axes(axi).([X 'Grid']));
            end
            if X<'Z'
                fprintf(fid,'    %sLoc      ''%s''\n',X,S(fgi).Axes(axi).([X 'Loc']));
            end
            if ~strcmp(S(fgi).Axes(axi).([X 'Scale']),'linear')
                fprintf(fid,'    %sScale    ''%s''\n',X,S(fgi).Axes(axi).([X 'Scale']));
            end
            if ~ischar(S(fgi).Axes(axi).([X 'Lim'])) % i.e. not "auto"
                fprintf(fid,'    %sLim      [%g %g]\n',X,S(fgi).Axes(axi).([X 'Lim']));
            end
            if ~isequal(S(fgi).Axes(axi).([X 'Color']),[0 0 0])
                fprintf(fid,'    %sColor    [%i %i %i]\n',X,S(fgi).Axes(axi).([X 'Color']));
            end
        end
        fprintf(fid,'  EndAxes\n');
    end
    fprintf(fid,'EndFigure\n\n');
end
fclose(fid);

function H = local_rebuild(S)
for fgi = length(S):-1:1
    d3d_qp('newfigure','free format figure',S(fgi).Name)
    H(fgi) = qpsf;
    if ~isempty(S(fgi).WindowSize)
        qp_figaspect(H(fgi),S(fgi).WindowSize)
    end
    d3d_qp('figurecolour',S(fgi).Color/255)
    if strcmp(S(fgi).PaperType,'<custom>')
        d3d_qp('figurepapertype','<custom>',S(fgi).PaperSize,S(fgi).PaperUnits)
    else
        d3d_qp('figurepapertype',S(fgi).PaperType,S(fgi).PaperOrientation)
    end
    d3d_qp('figureborderstyle',S(fgi).Frame.Type)
    if ~strcmp(S(fgi).Frame.Type,'none')
        ibt = 1;
        fld = 'FrameText1';
        BTx = {};
        while isfield(S(fgi).Frame,fld)
            BTx{ibt} = S(fgi).Frame.(fld);
            ibt = ibt+1;
            fld = sprintf('FrameText%i',ibt);
        end
        if ~isempty(BTx)
            d3d_qp('figureborder',BTx{:})
        end
        d3d_qp('deleteaxes') % delete default axes created by figure border
    end
    %
    for axi = 1:length(S(fgi).Axes)
        d3d_qp('newaxes_specloc',S(fgi).Axes(axi).Position,'normalized')
        d3d_qp('axesname',S(fgi).Axes(axi).Name)
        d3d_qp('axescolour',S(fgi).Axes(axi).Color/255)
        d3d_qp('axesboxed',strcmp(S(fgi).Axes(axi).Box,'on'))
        d3d_qp('axesgrid',strcmp(S(fgi).Axes(axi).XGrid,'on'),strcmp(S(fgi).Axes(axi).YGrid,'on'))
        d3d_qp('axesloc',S(fgi).Axes(axi).XLoc,S(fgi).Axes(axi).YLoc)
        d3d_qp('axeslimits',S(fgi).Axes(axi).XLim,S(fgi).Axes(axi).YLim)
        d3d_qp('axesscale',S(fgi).Axes(axi).XScale,S(fgi).Axes(axi).YScale)
        %
        d3d_qp('title',S(fgi).Axes(axi).Title)
        for x = 'xyz'
            X = upper(x);
            d3d_qp([x 'label'],S(fgi).Axes(axi).([X 'Label']))
            d3d_qp([x 'colour'],S(fgi).Axes(axi).([X 'Color'])/255)
        end
    end
end

function S = local_extract(H)
for fgi = length(H):-1:1
    HInfo = get(H(fgi));
    
    S(fgi).Name  = HInfo.Name;
    S(fgi).PaperType = HInfo.PaperType;
    S(fgi).PaperOrientation = HInfo.PaperOrientation;
    S(fgi).PaperSize = HInfo.PaperSize;
    S(fgi).PaperUnits = HInfo.PaperUnits;
    S(fgi).WindowSize = HInfo.Position(3:4); % Units = pixels
    S(fgi).Color = round(HInfo.Color*255);
    S(fgi).Frame.Type = 'none';
    
    axi = 0;
    for i = 1:length(HInfo.Children)
        A = HInfo.Children(i);
        AInfo = get(A);
        if strcmp(AInfo.Type,'axes') && strcmp(AInfo.Tag,'border')
            % use A.UserData;
            AInfo = md_paper(A,'getprops');
            S(fgi).Frame.Type = AInfo.Name;
            ibt = 1;
            btxt = 'BorderText1';
            ftxt = 'FrameText1';
            while isfield(AInfo,btxt)
                S(fgi).Frame.(ftxt) = AInfo.(btxt);
                ibt  = ibt+1;
                btxt = sprintf('BorderText%i',ibt);
                ftxt = sprintf('FrameText%i',ibt);
            end
        elseif strcmp(AInfo.Type,'axes')
            % normal axes
            axi = axi+1;
            S(fgi).Axes(axi).Name = AInfo.Tag;
            S(fgi).Axes(axi).Position = AInfo.Position;
            S(fgi).Axes(axi).Color = round(AInfo.Color*255);
            S(fgi).Axes(axi).Box = AInfo.Box;
            %
            if isappdata(A,'title')
                S(fgi).Axes(axi).Title = getappdata(A,'title');
            else
                S(fgi).Axes(axi).Title = '<automatic>';
            end
            for x = 'xyz'
                X = upper(x);
                if isappdata(A,[x 'label'])
                    S(fgi).Axes(axi).([X 'Label']) = getappdata(A,[x 'label']);
                else
                    S(fgi).Axes(axi).([X 'Label']) = '<automatic>';
                end
                S(fgi).Axes(axi).([X 'Color']) = round(AInfo.([X 'Color'])*255);
                S(fgi).Axes(axi).([X 'Grid']) = AInfo.([X 'Grid']);
                if X < 'Z'
                    S(fgi).Axes(axi).([X 'Loc']) = AInfo.([X 'AxisLocation']);
                end
                S(fgi).Axes(axi).([X 'Scale']) = AInfo.([X 'Scale']);
                if strcmp(AInfo.([X 'LimMode']),'manual')
                    S(fgi).Axes(axi).([X 'Lim']) = AInfo.([X 'Lim']);
                else
                    S(fgi).Axes(axi).([X 'Lim']) = 'auto';
                end
            end
        end
    end
end
