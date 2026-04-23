function make_d3dmatlab(basedir,varargin)
%MAKE_D3DMATLAB Prepare Delft3D-MATLAB toolbox for distribution
%   Prepare the files for distribution as Delft3D-MATLAB toolbox.
%
%   MAKE_D3DMATLAB(BASEDIR)
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


function localmake(qpversion,repo_url,hash,T,release)
if nargin<4
    [qpversion,hash,repo_url] = get_qpversion;
    T = now;
    release = 'UNKNOWN'
end

target_dir = 'delft3d_matlab_release';
targetname = 'Delft3D-MATLAB interface';
main_file = 'd3d_qp.m';
source_dir = pwd;
target_dir = [pwd,filesep,'..',filesep,target_dir];

if ~exist(target_dir, 'dir')
    fprintf('Creating %s directory ...\n', target_dir);
    mkdir(target_dir);
end
cd(target_dir)
diary off % no diary to avoid clutter in the distribution folder ...

fprintf('Copying files ...\n');
exportsrc(source_dir,target_dir)

fprintf('Including netCDF files ...\n');
mkdir('netcdf');
copyfile('../../third_party/netcdfAll-4.1.jar','netcdf')
mkdir('netcdf/mexnc');
exportsrc('../../third_party/mexnc', 'netcdf/mexnc')
mkdir('netcdf/snctools');
exportsrc('../../third_party/snctools', 'netcdf/snctools')

% strip off the platform flag (binaries for Windows and Linux are included)
% ... but don't strip of (changed)
% ... the platform is the last string between brackets
brackets = strfind(qpversion,'(');
qpversion = qpversion(1:max(brackets)-2);
% for the progress statement add the platform statement
qpversion_ = [qpversion, ' (all platforms)'];

DateStr = datestr(floor(T));
DateTimeStr = datestr(T);
fprintf('\nBuilding %s version %s\n\n', targetname, qpversion_);
fprintf('Current date and time           : %s\n', DateTimeStr);

fprintf('Modifying files ...\n');
fstrrep(main_file, '<VERSION>', qpversion)
fstrrep(main_file, '<CREATIONDATE>', DateTimeStr)
fstrrep(main_file, '<GITHASH>', hash)
fstrrep(main_file, '<GITREPO>', repo_url)
fstrrep('Contents.m', '<VERSION>', qpversion)
fstrrep('Contents.m', '<RELEASE>', release)
fstrrep('Contents.m', '<CREATIONDATE>', DateStr) % MATLAB toolboxes don't have a time stamp

fprintf('Add source information to all files ...\n');
Keywords.HeadURL = ['Source ', repo_url, ': ', hash];
Keywords.Id = ['Release ', release, ': ', DateTimeStr];
process_keywords(target_dir, Keywords)

fprintf('Cleaning up directory ...\n');
X = {}; % nothing to do ...
cleanup(X)
diary off
cd(source_dir)
fprintf('Finished.\n');


function exportsrc(source_dir,target_dir)
d = dir(source_dir);
for i = 1:length(d)
    source = [source_dir filesep d(i).name];
    target = [target_dir filesep d(i).name];
    if d(i).isdir
        switch d(i).name
            case {'.','..'}
                % skip
            otherwise
                mkdir(target);
                fprintf('  [Entering: %s]\n', d(i).name);
                exportsrc(source,target)
        end
    else
        fprintf('  %s -> %s\n', d(i).name, target);
        copyfile(source,target)
    end
end