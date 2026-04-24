function varargout = qp_prefs(UD,mfig,cmd,cmdargs)
%QP_PREFS QuickPlot preferences dialog callback functions.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2026 Stichting Deltares.                                     
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

argout = cat(2,{cmd},cmdargs);

F = gcbf;
if isempty(F) || ~strcmp(get(F,'tag'),'PreferenceFig')
    F = findall(0,'type','figure','tag','PreferenceFig');
end

switch cmd
    case 'preferences'
        qp_preferences_interface;
        
    case 'prefpane'
        currentpane = get(F,'userdata');
        newpane = get(gcbo,'value');
        panehandles = get(gcbo,'userdata');
        set(panehandles{currentpane},'visible','off')
        set(panehandles{newpane},'visible','on')
        set(F,'userdata',newpane)
        
        % General

    case 'changefont'
        if ~isempty(cmdargs)
            uicontrolfont = struct(cmdargs{:});
        else
            uicontrolfont = qp_fontsettings('Font');
            uicontrolfont = uisetfont(uicontrolfont);
        end
        if ~isequal(uicontrolfont,0)
            qp_fontsettings(uicontrolfont);
            figs = [mfig UD.PlotMngr.Fig UD.FilOpt.Fig UD.GridView.Fig UD.ComLine.Fig F];
            MWfig = findall(0,'tag','UI_MESSAGE window');
            if ~isempty(MWfig)
                figs(end+1)=MWfig;
            end
            UICONTROL = findall(figs,'type','uicontrol');
            set(UICONTROL,uicontrolfont)
        end
        fn = fieldnames(uicontrolfont);
        val = struct2cell(uicontrolfont);
        fnval = [fn';val'];
        argout = cat(2,argout(1),fnval(:)');
        
    case 'organizationname'
        orgn = findobj(F,'tag','organizationname');
        name = get(orgn,'string');
        if ~isempty(cmdargs)
            name = cmdargs{1};
        end
        name = strtrim(name);
        qp_settings('organizationname',name);
        argout{2} = name;
        
    case 'timezonehandling'
        tzh=findobj(F,'tag','timezonehandling');
        tze=findobj(F,'tag','enforcedtimezone');
        itzh=get(tzh,'value');
        itze=get(tze,'value');
        tzhstr = qp_preferences_interface('timezonehandling');
        tzestr = qp_preferences_interface('enforcedtimezone');
        if ~isempty(cmdargs)
            if ismember(cmdargs{1},tzhstr)
                itzh = find(strcmp(cmdargs{1},tzhstr));
            elseif ismember(cmdargs{1},tzestr)
                itzh = 3;
                itze = find(strcmp(cmdargs{1},tzestr));
            end
        end
        if itzh<3
            argout(2) = tzhstr(itzh);
            qp_settings('timezone',argout{2})
            set(tzh,'value',itzh)
            set(tze,'enable','off')
        else % timezonehandling = enforced
            set(tzh,'value',3)
            set(tze,'value',itze,'enable','on')
            argout(2) = tzestr(itze);
            qp_settings('timezone',argout{2})
        end
        d3d_qp updatetimezone

    case 'enforcedtimezone'
        % called via GUI while timezonehandling = enforced
        tze=findobj(F,'tag','enforcedtimezone');
        set(tze,'enable','on')
        itze=get(tze,'value');
        tzestr=get(tze,'string');
        argout{1} = 'timezonehandling'; % command processing handled by timezonehandling
        argout(2) = tzestr(itze);
        qp_settings('timezone',argout{2})
        d3d_qp updatetimezone
        
    case 'ghostscript'
        h_ghostscript = findobj(F,'tag','ghostscript');
        filename = get(h_ghostscript,'string');
        if ~isempty(cmdargs)
            filename = cmdargs{1};
        end
        argout{2} = filename;
        qp_settings('ghostscript',filename)

    case 'ghostscript_browse'
        h_ghostscript = findobj(F,'tag','ghostscript');
        filename = get(h_ghostscript,'string');
        [f,p] = uigetfile('*.exe','Select Ghostscript Executable',filename);
        if ~isequal(f,0)
            filename = [p,f];
            set(h_ghostscript,'string',filename)
            argout{1} = 'ghostscript'; % command processing handled by ghostscript
            argout{2} = filename;
            qp_settings('ghostscript',filename)
        end

    case 'update_showversion'
        sv=get(gcbo,'value');
        if ~isempty(cmdargs)
            sv = cmdargs{1};
        end
        argout{2} = sv;
        if sv
            qp_settings('showversion','on')
            d3d_qp showversion
        else
            qp_settings('showversion','off')
            d3d_qp hideversion
        end

        % Data Fields

    case 'station_sorting'
        ss = findobj(F,'tag','station_sorting');
        sorters = qp_preferences_interface('sorters');
        if ~isempty(cmdargs)
            sorter = cmdargs{1};
            isorter = find(strcmpi(sorter,sorters));
            if isempty(isorter)
                sorter = qp_preferences_interface('default_station_sorter');
                sorter = qp_settings('station_sorter', sorter);
                isorter = find(strcmpi(sorter,sorters));
            end
        else
            isorter = get(ss,'value');
            sorter = sorters{isorter};
        end
        argout{2} = sorter;
        qp_settings('station_sorter', sorter);
        set(ss,'value',isorter)

        % Default Figure

    case {'defaultnewfigure','defaultfigure','defaultloadfigure','defaultfigurecolor'}
        rb1=findobj(F,'tag','defaultnewfigure');
        dfct=findobj(F,'tag','defaultfigurecolortext');
        dfc=findobj(F,'callback','d3d_qp defaultfigurecolor');
        rb2=findobj(F,'tag','defaultloadfigure');
        select=findobj(F,'callback','d3d_qp defaultfigure');
        df=findobj(F,'tag','defaultfigure');
        fn = '';
        color = qp_settings('defaultfigurecolor')/255;
        if ~isempty(cmdargs)
            if ischar(cmdargs{1})
                fn = cmdargs{1};
            else
                clr = cmdargs{1};
                if isnumeric(clr) && isequal(size(clr),[1 3])
                    if all(clr>=0 & clr<=1)
                        color = clr;
                    elseif all(clr==round(clr) & clr>=0 & clr<=255)
                        color = clr/255;
                    end
                end
            end

        else
            switch cmd
                case 'defaultfigurecolor'
                    newclr = uisetcolor(color);
                    if ~isequal(newclr,0)
                        color = newclr;
                    end

                case {'defaultfigure','defaultloadfigure'}
                    currentdir = pwd;
                    try
                        orig_fn = qp_settings('defaultfigure');
                        if ~isempty(orig_fn)
                            targetdir = fileparts(orig_fn);
                        else
                            targetdir = '';
                        end
                        if isempty(targetdir)
                            targetdir = qp_basedir('exe');
                        end
                        cd(targetdir)
                        [fn,pn] = uigetfile({'*.fig', 'MATLAB Figures (*.fig)'},'Select Default Figure File ...');
                        cd(currentdir)
                        if ischar(fn)
                            fn = [pn fn];
                        elseif isempty(orig_fn)
                            color = qp_settings('defaultfigurecolor')/255;
                        end
                    catch
                        cd(currentdir)
                    end
            end
        end
        argout{1} = 'defaultfigure';
        if isempty(fn)
            set(rb1,'value',1)
            set([dfct dfc],'enable','on')
            set(dfc,'backgroundcolor',color)
            set(rb2,'value',0)
            set(select,'enable','off')
            set(df,'string','','enable','off')
            qp_settings('defaultfigure',[])
            qp_settings('defaultfigurecolor', color*255)
            argout{2} = color*255;
        else
            set(rb1,'value',0)
            set([dfct dfc],'enable','off')
            set(dfc,'backgroundcolor',get(F,'color'))
            set(rb2,'value',1)
            set(select,'enable','on')
            set(df,'string',fn,'enable','inactive')
            qp_settings('defaultfigure',fn)
            argout{2} = fn;
        end
        
    case 'defaultfigurepos'
        Inactive = UD.Inactive;
        Active   = UD.Active;
        %
        dfpm = findobj(F,'tag','defaultfigurepos-menu');
        dfpe = findobj(F,'tag','defaultfigurepos-edit');
        FigPos = qp_preferences_interface('figure_positions');
        fpval = [];
        pos = [];
        if ~isempty(cmdargs)
            if ischar(cmdargs{1})
                fpval = find(strcmpi(cmdargs{1},FigPos));
            else
                fpval = 2;
                pos = cmdargs{1};
            end
        end
        if isempty(fpval)
            fpval = get(dfpm,'value');
        end
        if fpval==2 % Manual
            if isequal(gcbo,dfpe)
                fp = get(dfpe,'string');
                pos = sscanf(fp,'%i')';
            end
            if ~isnumeric(pos) || numel(pos)~=4 || pos(3)<=0 || pos(4)<=0
                pos = [];
            end
            if isempty(pos)
                f = qp_createfig('quick',[]);
                set(f,'units','pixels')
                pos = get(f,'position');
                delete(f)
            end
            fp = sprintf('%i %i %i %i',pos);
            set(dfpe,'enable','on', ...
                'string',fp, ...
                'backgroundcolor',Active)
            qp_settings('defaultfigurepos',fp)
            argout{2} = pos;
        else
            qp_settings('defaultfigurepos',lower(FigPos{fpval}))
            set(dfpe,'enable','off', ...
                'string','', ...
                'backgroundcolor',Inactive)
            argout{2} = lower(FigPos{fpval});
        end

    case 'defaultrenderer'
        dfr = findobj(F,'tag','defaultrenderer');
        Renderers = qp_preferences_interface('renderers');
        if ~isempty(cmdargs)
            rndr = cmdargs{1};
            if ~ismember(rndr,Renderers)
                rndr = qp_preferences_interface('default_renderer');
                rndr = qp_settings('defaultrenderer', rndr);
            end
            rval = find(strcmpi(rndr,Renderers));
        else
            rval = get(dfr,'value');
            rndr = Renderers{rval};
        end
        set(dfr,'value',rval);
        qp_settings('defaultrenderer', rndr)
        argout{2} = rndr;
        
    case 'defaultsmoothing'
        dfs = findobj(F,'tag','defaultsmoothing');
        if ~isempty(cmdargs)
            smo = cmdargs{1};
        else
            smo = get(dfs,'value');
        end
        set(dfs,'value',smo)
        qp_settings('graphicssmoothing', smo)
        argout{2} = smo;
        
        % Default Axes
        
    case {'defaultaxescolor'}
        dac = findobj(F,'tag','defaultaxescolor');
        clr = qp_settings('defaultaxescolor')/255;
        if ~isempty(cmdargs)
            newclr = cmdargs{1};
        else
            newclr = uisetcolor(clr);
        end
        if isnumeric(newclr) && isequal(size(newclr),[1 3])
            if all(newclr>=0 & newclr<=1)
                clr = newclr;
            elseif all(newclr == round(newclr) & newclr>=0 & newclr <= 255)
                clr = newclr/255;
            end
        end
        set(dac,'backgroundcolor',clr)
        qp_settings('defaultaxescolor',clr*255)
        argout{2} = clr*255;

    case {'boundingbox'}
        bb = findobj(F,'tag','boundingbox');
        if ~isempty(cmdargs)
            newval = cmdargs{1};
        else
            newval = get(bb,'value');
        end
        set(bb,'value',newval)
        qp_settings('boundingbox',newval);
        argout{2} = newval;

    case {'colorbar_ratio'}
        cbr = findobj(F,'tag','colorbar_ratio');
        if ~isempty(cmdargs)
            newval = cmdargs{1};
        else
            newval = round(str2double(get(cbr,'string')));
        end
        set(cbr,'string',num2str(newval))
        qp_settings(cmd,newval);
        argout{2} = newval;
        
        % Grid View
        
    case {'gridviewbackgroundcolor','gridviewgridcolor', ...
            'gridviewselectioncolor','gridviewlandboundarycolor'}
        clr = qp_settings(cmd)/255;
        newclr = uisetcolor(clr);
        if ~isequal(newclr,0)
            qp_settings(cmd,newclr*255)
            set(gcbo,'backgroundcolor',newclr)
            switch cmd
                case 'gridviewbackgroundcolor'
                    set(UD.GridView.Fig,'color',newclr)
                case 'gridviewgridcolor'
                    tags = {'GRID','GRIDother'};
                    for i=1:length(tags)
                        G=findobj(UD.GridView.Fig,'tag',tags{i});
                        recolor(G,clr,newclr)
                    end
                case 'gridviewselectioncolor'
                    tags = {'SELSURF','SELPATCH','SELLINE'};
                    for i=1:length(tags)
                        G=findobj(UD.GridView.Fig,'tag',tags{i});
                        recolor(G,clr,newclr)
                    end
                case 'gridviewlandboundarycolor'
                    G=findall(UD.GridView.Fig,'tag','landboundary');
                    recolor(G,clr,newclr)
            end
        end
        
    case {'gridviewshowindices','v6zoombehavior','showinactiveopt'}
        newval = get(gcbo,'value');
        qp_settings(cmd,newval);
        %
        switch cmd
            case 'v6zoombehavior'
                if newval
                    newval = 'on';
                else
                    newval = 'off';
                end
                qp_prefs(UD,mfig,'v6zoomswitch',newval)
        end
        
    case 'v6zoomswitch'
        F = findall(0,'type','figure');
        zoomon = logical(zeros(size(F)));
        for i = 1:length(F)
            zoomon(i) = ~strcmp(zoom(F(i),'getmode'),'off');
            if zoomon(i)
                zoom(F(i),'off')
            end
        end
        zoom('v6',cmdargs)
        for i = 1:length(F)
            if zoomon(i)
                zoom(F(i),'on')
                if strcmp(get(F(i),'name'),'Grid View')
                    set(F(i),'WindowButtonMotionFcn','qp_gridview trackcoord')
                end
            end
        end
        
        % File Filters

    case 'filefilterselection'
        filsel=findobj(F,'tag','filefilterselection');
        ifilters=get(filsel,'value');
        if length(ifilters)>15
           ui_message('error','For stability reasons, please select at most 15 filters.')
           % make sure ui_message isn't on top of the preferences dialog
           set(F,'visible','off') % hide it
           figure(F) % and show again
           %
           set(filsel,'value',get(filsel,'userdata'))
        else
           set(filsel,'userdata',ifilters)
           filters=get(filsel,'string');
           filterstring=sprintf('"%s",',filters{ifilters});
           filterstring(end)=[];
           qp_settings('filefilterselection',filterstring);
        end

        % NetCDF

    case 'netcdf_use_fillvalue'
        newval = get(gcbo,'value');
        string = {'exact_match','valid_range'};
        newval = string{newval};
        qp_settings(cmd,newval);
        
        % Export

    case {'export_max_ntimes'}
        newval = round(str2double(get(gcbo,'string')));
        qp_settings(cmd,newval);
        set(gcbo,'string',num2str(newval))

    otherwise
        error('Unknown command in qp_settings: %s',cmd)
end

if nargout > 0
    varargout{1} = argout;
end