function val = qp_option(FI,field,setval)
%QP_OPTION Set/get QuickPlot file options.
%   STRUCT = QP_OPTION(STRUCT,FIELD,VALUE) sets STRUCT.QP_Options.(FIELD) to
%   the specified VALUE.
%
%   VALUE = QP_OPTION(STRUCT,FIELD) returns the STRUCT.QP_Options.(FIELD)
%   value if it has been set before. Otherwise, it returns [].

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

if nargin>2
    val = FI;
    val.QP_Options.(field) = setval;
else
    val = [];
    if isfield(FI,'QP_Options')
        if isfield(FI.QP_Options,field)
            val = FI.QP_Options.(field);
        end
    elseif isfield(FI,field)
        val = FI.(field);
    elseif strcmp(field,'AttribFiles') && isfield(FI,'FileType') && strcmp(FI.FileType,'wlgrid') 
        val = FI.Data;
    end
end
