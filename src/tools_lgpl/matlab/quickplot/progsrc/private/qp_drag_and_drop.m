function qp_drag_and_drop(cmd,varargin)
%QP_DRAG_AND_DROP QuickPlot wrapper for drag 'n drop functionality.
%   Currently only supported for Windows.
%   Code throws Java exception on Linux.

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

if ~ispc
    return
end

switch cmd
    case 'initialize'
        try
            addprop(groot,'ForceIndependentlyHostedFigures');
        catch
        end
        if ~isstandalone
            add_third_party('folder','uiFileDnD')
        end
        
    case 'activate'
        try
            fig_handle = varargin{1};
            uiFileDnD(fig_handle, @(o,dat)d3d_qp('openfiles',dat.names{:}));
        catch
        end
end