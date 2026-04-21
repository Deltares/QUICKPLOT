function init_netcdf_settings
%INIT_NETCDF_SETTINGS Check and set netCDF settings as needed.

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

mlock
persistent run_once
if ~isempty(run_once)
    return
end

run_once = 1;
if isstandalone
    try
        % Insert a try-catch block here since the setpref command sometimes fails on a write error to matlabprefs.mat.
        setpref('SNCTOOLS','USE_JAVA',true);
    catch
        ui_message('message','Failed to persist preferences during initialization.')
    end

else
    % if nc_info can be found we assume that the settings were
    % preconfigured correctly either during a previous start of d3d_qp, or
    % via oetsettings, or by the user
    p = which('nc_info');
    if isempty(p)
        add_third_party('folder','mexnc')
        add_third_party('folder','snctools')

        % check if nc_info can now be found ...
        p = which('nc_info');
        if isempty(p)
            ui_message('message','Unable to locate mexnc and snctools for accessing netCDF files.')
        end
    end
end
try
    add_third_party('jar','netcdfAll-4.1.jar')
catch
end
