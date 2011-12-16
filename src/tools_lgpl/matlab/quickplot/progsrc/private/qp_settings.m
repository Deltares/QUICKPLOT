function valo=qp_settings(param,val)
%QP_SETTINGS Routine to store and retreive settings.

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
%   http://www.deltaressystems.com
%   $HeadURL$
%   $Id$

persistent Settings qppref
if isempty(Settings)
    qppref=fullfile(qp_basedir('pref'),'Delft-QUICKPLOT.ini');
    Settings=qp_read_settings(qppref);
end

grp='Options';
if iscell(param)
    grp=param{1};
    param=param{2};
end
if nargout==1
    % retrieve value
    valo=inifile('get',Settings,grp,param,{});
    if iscell(valo)
        if nargin==1
            val={};
        end
        valo=qp_settings_default(param,val);
    end
elseif isequal(param,'<SAVE>')
    Settings=qp_write_settings(Settings,qppref);
else
    Settings=inifile('set',Settings,grp,param,val);
end


function val=qp_settings_default(param,defval)
steelblue3 = [79 148 205]/255;
if 0%isunix
   Set.UIActiveColor      = steelblue3;
   Set.UIInActiveColor    = steelblue3;
   Set.UIForeGroundColor  = [1 1 1];
else
   Set.UIActiveColor      = [1 1 1];
   Set.UIInActiveColor    = get(0,'factoryuicontrolbackgroundcolor');
   Set.UIForeGroundColor  = get(0,'factoryuicontrolforegroundcolor');
end
Set.UIButtonMargin     = 0; %5;
Set.UIFontAngle        = get(0,'DefaultUicontrolFontAngle');
Set.UIFontName         = get(0,'DefaultUicontrolFontName');
Set.UIFontUnits        = get(0,'DefaultUicontrolFontUnits');
Set.UIFontSize         = get(0,'DefaultUicontrolFontSize');
Set.UIFontWeight       = get(0,'DefaultUicontrolFontWeight');
Set.figuredir          = '';
Set.gridviewbackgroundcolor   = [230 230 230];
Set.gridviewgridcolor         = [0 153 153];
Set.gridviewselectioncolor    = [255 0 0];
Set.gridviewlandboundarycolor = [0 0 0];
Set.gridviewshowindices       = 1;
Set.defaultfigure             = '';
Set.defaultfigurecolor        = get(0,'factoryuicontrolbackgroundcolor')*255;
Set.defaultaxescolor          = [255 255 255];
Set.boundingbox               = 0;
Set.v6zoombehavior            = 0;
Set.print_ID                  = 'PS file';
Set.print_method              = 2;
Set.print_DPI                 = 150;
Set.print_colour              = 1;
Set.print_inverthardcopy      = 1;
Set.organizationname          = 'Deltares';
if isfield(Set,param)
    val=getfield(Set,param);
elseif ~iscell(defval)
    val=defval;
else
    error(['Unknown parameter: ',param])
end


function Prefs=qp_read_settings(qppref)
try
    Prefs=inifile('open',qppref);
catch
    %Try old directory
    c = computer;
    if c(1:2) == 'PC'
        qppref = strrep(qppref,'Deltares','Deltares');
    else % Unix
        qppref = strrep(qppref,'Deltares','DelftHydraulics');
    end
    try
        Prefs=inifile('open',qppref);
    catch
        Prefs=inifile('new');
    end
end


function Prefs=qp_write_settings(Prefs,qppref)
try
    Prefs=inifile('write',qppref,Prefs);
catch
end
