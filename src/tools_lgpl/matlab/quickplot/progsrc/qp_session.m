function S = qp_session(cmd,H,varargin)
%QP_SESSION Save QuickPlot figures to and rebuild them from an ASCII file.
%   QP_SESSION is still incomplete, not documented and subject to change.

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
itm = 0;
opt = '';
S = [];
while ~isempty(Str)
    args = parseargs(Str);
    key  = lower(args{1});
    switch key
        case 'figure'
            fgi = length(S)+1;
            axi = 0;
            S(fgi).name = args{2};
            S(fgi).papertype = 'a4';
            S(fgi).paperorientation = 'portrait';
            S(fgi).papersize = [];
            S(fgi).paperunits = 'centimeters';
            S(fgi).windowsize = [];
            S(fgi).colour = get(0,'factoryuicontrolbackgroundcolor')*255;
            S(fgi).frame.style = 'none';
            S(fgi).axes = [];
        case 'framestyle'
            S(fgi).frame.style = args{2};
        case 'axes'
            axi = length(S(fgi).axes)+1;
            S(fgi).axes(axi).name = args{2};
            S(fgi).axes(axi).position = [];
            S(fgi).axes(axi).colour = [255 255 255];
            S(fgi).axes(axi).box = 'off';
            S(fgi).axes(axi).title = '<automatic>';
            for x = 'xyz'
                S(fgi).axes(axi).([x 'label']) = '<automatic>';
                S(fgi).axes(axi).([x 'colour']) = [0 0 0];
                S(fgi).axes(axi).([x 'grid'])  = 'off';
                if x=='x'
                    S(fgi).axes(axi).([x 'loc']) = 'bottom';
                elseif x=='y'
                    S(fgi).axes(axi).([x 'loc']) = 'left';
                end
                S(fgi).axes(axi).([x 'scale']) = 'linear';
                S(fgi).axes(axi).([x 'lim']) = 'auto';
            end
            S(fgi).axes(axi).items = [];
        case 'item'
            itm = length(S(fgi).axes(axi).items)+1;
            S(fgi).axes(axi).items(itm).name = args{2};
            S(fgi).axes(axi).items(itm).filename = '';
            S(fgi).axes(axi).items(itm).options  = [];
        case 'options'
            opt = 'item';
        case 'endoptions'
            opt = '';
        case 'enditem'
            itm = 0;
        case 'endaxes'
            axi = 0;
        case 'endfigure'
            fgi = 0;
        otherwise
            if fgi>0
                if length(key)>5 && strcmp(key(end-4:end),'color')
                    key = [key(1:end-5) 'colour'];
                end
                if length(args)>2
                    val = args(2:end);
                else
                    val = args{2};
                end
                if strcmp(opt,'item')
                    S(fgi).axes(axi).items(itm).options.(key) = val;
                elseif itm>0
                    S(fgi).axes(axi).items(itm).(key) = val;
                elseif axi>0
                    S(fgi).axes(axi).(key) = val;
                elseif strncmp(key,'frametext',9)
                    S(fgi).frame.(key) = val;
                else
                    S(fgi).(key) = val;
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
        j  = 2;
        while j<length(i1)-1 && i1(j)+1==i1(j+1)
            j = j+2;
        end
        Key = Str(i1(1)+1:i1(j)-1);
        Key = strrep(Key,'''''','''');
        Str = Str(i1(j)+1:end);
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
fprintf(fid,'Delft3D-QUICKPLOT 1.0 ''session file''\n');
for fgi = 1:length(S)
    fprintf(fid,'Figure             ''%s''\n',S(fgi).name);
    fprintf(fid,'  PaperType        ''%s''\n',S(fgi).papertype);
    fprintf(fid,'  PaperOrientation ''%s''\n',S(fgi).paperorientation);
    if strcmp(S(fgi).papertype,'<custom>')
        fprintf(fid,'  PaperSize        [%g %g]\n',S(fgi).papersize);
        fprintf(fid,'  PaperUnits       ''%s''\n',S(fgi).paperunits);
    end
    if ~isequal(S(fgi).colour,get(0,'factoryuicontrolbackgroundcolor')*255)
        fprintf(fid,'  Colour           [%i %i %i]\n',S(fgi).colour);
    end
    fprintf(fid,'  WindowSize       [%i %i]\n',S(fgi).windowsize);
    fprintf(fid,'  FrameStyle       ''%s''\n',S(fgi).frame.style);
    ibt = 1;
    fld = 'frametext1';
    while isfield(S(fgi).frame,fld)
        fprintf(fid,'  FrameText%-4i    ''%s''\n',ibt,S(fgi).frame.(fld));
        ibt = ibt+1;
        fld = sprintf('frametext%i',ibt);
    end
    %
    for axi = 1:length(S(fgi).axes)
        fprintf(fid,'\n  Axes        ''%s''\n',S(fgi).axes(axi).name);
        fprintf(fid,'    Position  [%g %g %g %g]\n',S(fgi).axes(axi).position);
        if ~strcmp(S(fgi).axes(axi).title,'<automatic>')
            fprintf(fid,'    Title     ''%s''\n',S(fgi).axes(axi).title);
        end
        if ischar(S(fgi).axes(axi).colour)
            fprintf(fid,'    Colour    ''none''\n');
        elseif ~isequal(S(fgi).axes(axi).colour,[255 255 255])
            fprintf(fid,'    Colour    [%i %i %i]\n',S(fgi).axes(axi).colour);
        end
        fprintf(fid,'    Box       ''%s''\n',S(fgi).axes(axi).box);
        for x = 'xy'
            X = upper(x);
            if ~strcmp(S(fgi).axes(axi).([x 'label']),'<automatic>')
                fprintf(fid,'    %sLabel    ''%s''\n',X,S(fgi).axes(axi).([x 'label']));
            end
            if ~strcmp(S(fgi).axes(axi).([x 'grid']),'off')
                fprintf(fid,'    %sGrid     ''%s''\n',X,S(fgi).axes(axi).([x 'grid']));
            end
            if X<'Z'
                fprintf(fid,'    %sLoc      ''%s''\n',X,S(fgi).axes(axi).([x 'loc']));
            end
            if ~strcmp(S(fgi).axes(axi).([x 'scale']),'linear')
                fprintf(fid,'    %sScale    ''%s''\n',X,S(fgi).axes(axi).([x 'scale']));
            end
            if ~ischar(S(fgi).axes(axi).([x 'lim'])) % i.e. not "auto"
                fprintf(fid,'    %sLim      [%g %g]\n',X,S(fgi).axes(axi).([x 'lim']));
            end
            if ~isequal(S(fgi).axes(axi).([x 'colour']),[0 0 0])
                fprintf(fid,'    %sColour   [%i %i %i]\n',X,S(fgi).axes(axi).([x 'colour']));
            end
        end
        %
        for itm = 1:length(S(fgi).axes(axi).items)
           fprintf(fid,'\n    Item        ''%s''\n',S(fgi).axes(axi).items(itm).name);
           fprintf(fid,'      FileName  ''%s''\n',S(fgi).axes(axi).items(itm).filename);
           if ~isempty(S(fgi).axes(axi).items(itm).options)
              fprintf(fid,'      Options\n');
              flds = fieldnames(S(fgi).axes(axi).items(itm).options);
              for ifld = 1:length(flds)
                  if strcmp(flds{ifld},'version')
                      continue
                  end
                  val = S(fgi).axes(axi).items(itm).options.(flds{ifld});
                  if ischar(val)
                      fprintf(fid,'        %-20s ''%s''\n',flds{ifld},val);
                  elseif isnumeric(val) && isequal(size(val),[1 1])
                      fprintf(fid,'        %-20s %g\n',flds{ifld},val);
                  elseif isnumeric(val) && size(val,1)==1
                      fprintf(fid,'        %-20s %s\n',flds{ifld},vec2str(val));
                  end
              end
              fprintf(fid,'      EndOptions\n');
           end
           fprintf(fid,'    EndItem\n');
        end
        fprintf(fid,'  EndAxes\n');
    end
    fprintf(fid,'EndFigure\n\n');
end
fclose(fid);

function H = local_rebuild(S)
for fgi = length(S):-1:1
    d3d_qp('newfigure','free format figure',S(fgi).name)
    H(fgi) = qpsf;
    if ~isempty(S(fgi).windowsize)
        qp_figaspect(H(fgi),S(fgi).windowsize)
    end
    d3d_qp('figurecolour',S(fgi).colour/255)
    if strcmp(S(fgi).papertype,'<custom>')
        d3d_qp('figurepapertype','<custom>',S(fgi).papersize,S(fgi).paperunits)
    else
        d3d_qp('figurepapertype',S(fgi).papertype,S(fgi).paperorientation)
    end
    d3d_qp('figureborderstyle',S(fgi).frame.style)
    if ~strcmp(S(fgi).frame.style,'none')
        ibt = 1;
        fld = 'frametext1';
        BTx = {};
        while isfield(S(fgi).frame,fld)
            BTx{ibt} = S(fgi).frame.(fld);
            ibt = ibt+1;
            fld = sprintf('frametext%i',ibt);
        end
        if ~isempty(BTx)
            d3d_qp('figureborder',BTx{:})
        end
        d3d_qp('deleteaxes') % delete default axes created by figure border
    end
    %
    for axi = 1:length(S(fgi).axes)
        d3d_qp('newaxes_specloc',S(fgi).axes(axi).position,'normalized')
        d3d_qp('axesname',S(fgi).axes(axi).name)
        d3d_qp('axescolour',S(fgi).axes(axi).colour/255)
        d3d_qp('axesboxed',strcmp(S(fgi).axes(axi).box,'on'))
        d3d_qp('axesgrid',strcmp(S(fgi).axes(axi).xgrid,'on'),strcmp(S(fgi).axes(axi).ygrid,'on'))
        d3d_qp('axesloc',S(fgi).axes(axi).xloc,S(fgi).axes(axi).yloc)
        d3d_qp('axeslimits',S(fgi).axes(axi).xlim,S(fgi).axes(axi).ylim)
        d3d_qp('axesscale',S(fgi).axes(axi).xscale,S(fgi).axes(axi).yscale)
        %
        d3d_qp('title',S(fgi).axes(axi).title)
        for x = 'xyz'
            d3d_qp([x 'label'],S(fgi).axes(axi).([x 'label']))
            d3d_qp([x 'colour'],S(fgi).axes(axi).([x 'colour'])/255)
        end
    end
end

function S = local_extract(H)
for fgi = length(H):-1:1
    HInfo = get(H(fgi));
    
    S(fgi).name        = HInfo.Name;
    S(fgi).papertype   = HInfo.PaperType;
    S(fgi).paperorientation = HInfo.PaperOrientation;
    S(fgi).papersize   = HInfo.PaperSize;
    S(fgi).paperunits  = HInfo.PaperUnits;
    S(fgi).windowsize  = HInfo.Position(3:4); % Units = pixels
    S(fgi).colour      = round(HInfo.Color*255);
    S(fgi).frame.style = 'none';
    
    axi = 0;
    for i = 1:length(HInfo.Children)
        A = HInfo.Children(i);
        AInfo = get(A);
        if strcmp(AInfo.Type,'axes') && strcmp(AInfo.Tag,'border')
            % use A.UserData;
            AInfo = md_paper(A,'getprops');
            S(fgi).frame.style = AInfo.Name;
            ibt = 1;
            btxt = 'BorderText1';
            ftxt = 'frametext1';
            while isfield(AInfo,btxt)
                S(fgi).frame.(ftxt) = AInfo.(btxt);
                ibt  = ibt+1;
                btxt = sprintf('BorderText%i',ibt);
                ftxt = sprintf('frametext%i',ibt);
            end
        elseif strcmp(AInfo.Type,'axes')
            % normal axes
            axi = axi+1;
            S(fgi).axes(axi).name      = AInfo.Tag;
            S(fgi).axes(axi).position  = AInfo.Position;
            S(fgi).axes(axi).colour    = round(AInfo.Color*255);
            S(fgi).axes(axi).box       = AInfo.Box;
            %
            if isappdata(A,'title')
                S(fgi).axes(axi).title = getappdata(A,'title');
            else
                S(fgi).axes(axi).title = '<automatic>';
            end
            for x = 'xyz'
                X = upper(x);
                if isappdata(A,[x 'label'])
                    S(fgi).axes(axi).([x 'label']) = getappdata(A,[x 'label']);
                else
                    S(fgi).axes(axi).([x 'label']) = '<automatic>';
                end
                S(fgi).axes(axi).([x 'colour']) = round(AInfo.([X 'Color'])*255);
                S(fgi).axes(axi).([x 'grid']) = AInfo.([X 'Grid']);
                if X < 'Z'
                    S(fgi).axes(axi).([x 'loc']) = AInfo.([X 'AxisLocation']);
                end
                S(fgi).axes(axi).([x 'scale']) = AInfo.([X 'Scale']);
                if strcmp(AInfo.([X 'LimMode']),'manual')
                    S(fgi).axes(axi).([x 'lim']) = AInfo.([X 'Lim']);
                else
                    S(fgi).axes(axi).([x 'lim']) = 'auto';
                end
            end
            %
            c = get(A,'children');
            u = get(c,'userdata');
            if iscell(u)
                u = u(~cellfun('isempty',u));
            else
                u = {u};
            end
            for itm = length(u):-1:1
                IInfo = u{itm};
                S(fgi).axes(axi).items(itm).name     = IInfo.PlotState.Props.Name;
                S(fgi).axes(axi).items(itm).filename = IInfo.PlotState.FI.Name;
                S(fgi).axes(axi).items(itm).options  = IInfo.PlotState.Ops;
            end
        end
    end
end
