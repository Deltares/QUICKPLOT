function p=qp_basedir(t)
%QP_BASEDIR Get various base directories.
%
%   PATH=QP_BASEDIR(TYPE)
%   where TYPE=
%      'deploy' returns directory of executable.
%      'exe'    returns directory of executable (default).
%      'pref'   returns preference directory of installation.

%      'base'   returns base directory of installation if
%               matlabversionnumber < 7 (obsolete).

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

if nargin==0
    t='exe';
elseif ~ischar(t)
    error('Invalid input argument.');
end
t=lower(t);
if isstandalone
    if matlabversionnumber<7
       p=matlabroot;
       switch t
           case 'exe'
               % default correct
           case 'deploy'
               % default correct
           case 'pref'
               p=qp_prefdir;
           otherwise
               slash=strfind(p,filesep);
               p=p(1:(slash(end-1)-1));
       end
    else
       p=exeroot;
       switch t
           case 'exe'
               % default correct
           case 'deploy'
               p=ctfroot;
           case 'pref'
               p=qp_prefdir;
           otherwise
               % default correct
       end
    end
else
    p=which('d3d_qp');
    if ~isempty(p)
        slash=strfind(p,filesep);
        p=p(1:(slash(end)-1));
    end
    switch t
        case 'exe'
            % default correct
        case 'deploy'
            % default correct
        case 'pref'
            p=qp_prefdir;
        otherwise
            % default correct
    end
end


%=======================
function folder = exeroot
c = computer;
if strcmp(c(1:2),'PC')
   [~, result] = system('set PATH');
   linefeed = strfind(result,newline);
   eql = strfind(result,'=');
   result = result(eql(1)+1:linefeed(1)-1);
   folders = strsplit(result,';');
   folder = '';
   for i = 1:length(folders)
       try % typically d3d_qp.exe is located in the first folder, but sometimes in the second one ...
           filename = check_path([folders{i} filesep 'd3d_qp.exe']);
           folder = fileparts(filename);
           return
       catch
       end
   end
   if isempty(folder)
       error('Unable to locate the QUICKPLOT executable.')
   end
else % Unix
   % call a mex file
   folder = fileparts(exepath);
end

%=======================
function dd = qp_prefdir
%QP_PREFDIR Preference directory name (adaptation of MATLAB's prefdir).
c = computer;
if strcmp(c(1:2),'PC')
    % Try %UserProfile% first. This is defined by NT
    dd = getenv('UserProfile');
    if isempty(dd)
        % Try the windows registry next. Win95/98 uses this
        % if User Profiles are turned on (you can check this
        % in the "Passwords" control panel).
        dd = get_profile_dir;
        if isempty(dd)
            % This must be Win95/98 with user profiles off.
            dd = getenv('windir');
        end
    end
    dd = fullfile(dd, 'Application Data', 'Deltares', '');
else % Unix
    dd = fullfile(getenv('HOME'), '.Deltares', '');
end
[success,~]=mkdir(dd); % need second output argument to avoid 'Directory already exists.' messages
if ~success
    dd='';
end


function profileDir = get_profile_dir
le = lasterr;
try
    profileDir = winqueryreg('HKEY_CURRENT_USER',...
        'Software\Microsoft\Windows\CurrentVersion\ProfileReconciliation',...
        'ProfileDirectory');
catch
    lasterr(le);
    profileDir = '';
end
