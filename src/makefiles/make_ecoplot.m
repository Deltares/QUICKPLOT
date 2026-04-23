function make_ecoplot(basedir,varargin)
%MAKE_ECOPLOT Compile ECOPLOT executable
%   Compile MATLAB code to ECOPLOT executable
%
%   MAKE_ECOPLOT(BASEDIR)
%   Use specified directory instead of current directory as base directory

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

curdir = pwd;
addpath(curdir)
if ~exist('mcc')
    error('Cannot find MATLAB compiler. Use another MATLAB installation!')
end
if nargin>0
    cd(basedir);
end
err = [];
try
    localmake(varargin{:});
catch err
end
if nargin>0
    cd(curdir);
end
rmpath(curdir)
if ~isempty(err)
    rethrow(err)
end


function localmake(qpversion,repo_url,hash,T)
if nargin<4
    [qpversion,hash,repo_url] = get_qpversion;
    T = now;
end

if strncmp(fliplr(computer),'46',2)
    target_dir = 'ecoplot64';
else
    target_dir = 'ecoplot32';
end
targetname = 'Delft3D-ECOPLOT';
main_file = 'ecoplot.m';
source_dir = pwd;
target_dir = [pwd,filesep,'..',filesep,target_dir];

if ~exist(target_dir, 'dir')
    fprintf('Creating %s directory ...\n', target_dir);
    mkdir(target_dir);
end
cd(target_dir)
diary make_ecoplot_diary

fprintf('Copying files ...\n');
if isunix
    unix(['cp -rf ', source_dir, '/* .']);
    unix('mv compileonly/* .');
else
    [s, msg] = dos(['xcopy "', source_dir, '\*.*" "." /E /Y']);
    if s == 0
        [s, msg] = dos('move compileonly\*.*  .');
    end
    if s ~= 0
        error(msg)
    end
end

fprintf('Including netCDF files ...\n');
copyfile('../../third_party/netcdfAll-4.1.jar','.')
addpath ../../third_party/mexnc
addpath ../../third_party/snctools
addpath ../../third_party/uiFileDnD

DateTimeStr = datestr(T);
fprintf('\nBuilding %s version %s\n\n', targetname, qpversion);
fprintf('Current date and time           : %s\n', DateTimeStr);

fprintf('Modifying files ...\n');
fstrrep('d3d_qp.m', '<VERSION>', qpversion)
fstrrep('d3d_qp.m', '<CREATIONDATE>', DateTimeStr)
fstrrep('d3d_qp.m', '<GITHASH>', hash)
fstrrep('d3d_qp.m', '<GITREPO>', repo_url)

fprintf('Include GhostScript for printing ...\n');
g = which('-all','gscript');
if ~isempty(g)
    copyfile(g{1},'.')
end

fprintf('Building executable ...\n');
if isunix
    appopt={'-m'};
else
    appopt={'-e'};
end
mcc(appopt,'-a','./units.ini','-a','./grib','-v',main_file)

fprintf('Cleaning up directory ...\n');
X = {'*.m'
    '*.mat'
    '*.c'
    '*.cpp'
    '*.h'
    'private'
    '@qp_data'
    '@qp_data_resource'
    '*.dll'
    '*.mex*'};
cleanup(X)
diary off
cd(source_dir)
fprintf('Finished.\n');
