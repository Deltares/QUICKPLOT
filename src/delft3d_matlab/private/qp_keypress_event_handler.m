function qp_keypress_event_handler(handle,event)
%QP_KEYPRESS_EVENT_HANDLER Handle keypress events for QUICKPLOT.
%    QP_KEYPRESS_EVENT_HANDLER(HANDLE, EVENT) handles the keypress EVENT
%    associated with object HANDLE. The keypress event is expected to have
%    the following fields:
%
%      Character: the interpretation of the key-combination pressed, e.g.
%        'a', 'A', '=', etc.
%      Modifier: cell array containing the key modifiers, i.e. empty or a
%        combination of 'control', 'alt' and 'shift'. Note: caps lock is
%        not visible as modifier, it's noticeable as a difference in the
%        character field.
%      Key: the base name of the key pressed, i.e. a lower case character,
%        digit or key name, e.g. 'equal'.
%      Source: the object generating the event
%      EventName: event name, always: 'KeyPress'
%
%    See also QP_UIFIGURE, QP_CREATEFIG.

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

if ismember('control',event.Modifier)
    if isequal(event.Key,'t') || isequal(event.Key,'s')
        if ismember('alt',event.Modifier)
            d3d_qp('move_onscreen')
        else
            d3d_qp('move_onscreen',handle)
        end
    end
end