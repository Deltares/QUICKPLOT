function add_third_party(type,name)
%ADD_THIRD_PARTY Search for folders and jar-files to add to the path.
%   add_third_party('folder',FOLDERNAME)
%   add_third_party('jar',JARFILE)

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

switch type
    case 'folder'
        check_dirs = get_check_dirs;
        for i = 1:length(check_dirs)
            test_dir = [check_dirs{i},filesep,name];
            if exist(test_dir, 'dir')
                addpath(test_dir)
                break
            end
        end

    case 'jar'
        check_dirs = get_check_dirs;
        for i = 1:length(check_dirs)
            test_file = [check_dirs{i},filesep,name];
            if exist(test_file, 'file')
                javaaddpath(test_file)
                break
            end
        end

    otherwise
        error('Only "folder" or "jar" supported as first argument.')
end

function check_dirs = get_check_dirs
qp_install_path = qp_basedir('exe');
up = [filesep, '..'];
check_dirs = {...
    qp_install_path ... % new distribution root
    [qp_install_path, filesep, 'netcdf'] ... % new distribution netcdf-root
    [qp_install_path, up, up, up, up, up, filesep, 'third_party'] ... % source tree checkout root and netcdf-root (2026-04-21)
    [qp_install_path, up, up, up, up, filesep, 'third_party_open'] ... % source tree checkout root
    [qp_install_path, up, up, up, up, filesep, 'third_party_open', filesep, 'netcdf', filesep, 'matlab'] ... % source tree checkout netcdf-root
    [qp_install_path, up, up, filesep, 'io', filesep, 'netcdf'] ... % open earth tools checkout netcdf-root (obsolete)
    };
