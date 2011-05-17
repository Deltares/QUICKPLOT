function qp_plotmanager(cmd,PM)
%QP_PLOTMANAGER QuickPlot Plot Manager callback functions.

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

switch cmd
    case 'resize'
        %
        % Get new and old figure size (note: for this to work the figure size
        % must be initialized before the first call).
        %
        fig = PM.Fig;
        PrevSize = getappdata(fig,'FigureSize');
        MinSize = getappdata(fig,'MinimumFigureSize');
        if isempty(MinSize)
            MinSize = PrevSize;
            setappdata(fig,'MinimumFigureSize',MinSize)
        end
        NewPos = get(fig,'position');
        NewSize=NewPos(3:4);
        if any(NewSize<MinSize)
            NewSize=max(NewSize,MinSize);
            NewPos(2)=NewPos(2)+NewPos(4)-NewSize(2);
            NewPos(3:4)=NewSize;
            set(fig,'position',NewPos)
        end
        %
        % Define some shift operators
        %
        aligntop   = [0 NewSize(2)-PrevSize(2) 0 0];
        alignright = [NewSize(1)-PrevSize(1) 0 0 0];
        stretchhor = [0 0 NewSize(1)-PrevSize(1) 0];
        stretchver = [0 0 0 NewSize(2)-PrevSize(2)];
        %
        % Shift the buttons
        %
        shiftcontrol(PM.FigTxt,aligntop)
        shiftcontrol(PM.FigList,aligntop+stretchhor)
        shiftcontrol(PM.FigAll,aligntop+alignright)
        shiftcontrol(PM.AxTxt,aligntop)
        shiftcontrol(PM.AxList,aligntop+stretchhor)
        shiftcontrol(PM.AxAll,aligntop+alignright)
        shiftcontrol(PM.ItTxt,aligntop)
        shiftcontrol(PM.ItList,stretchhor+stretchver)
        shiftcontrol(PM.ItUp,aligntop+alignright)
        shiftcontrol(PM.ItDown,alignright)
        %
        % Store the new figure size for usage during next resize command
        %
        setappdata(fig,'FigureSize',NewSize);
end
