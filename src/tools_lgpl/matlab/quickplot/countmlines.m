function countmlines
%COUNTMLINES Count lines in QUICKPLOT source code
%   Count number of lines in the m-files in the
%   directories progsrc and progsrc/private

%----- LGPL --------------------------------------------------------------------
%
%   Copyright (C) 2011-2014 Stichting Deltares.
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

[X1,n1,nc1]=countmlines_dir('progsrc/');
[X2,n2,nc2]=countmlines_dir('progsrc/private/');
fprintf('Grand total: %i (%i)\n',n1+n2,nc1+nc2);


function [X,total_nl,total_ncl]=countmlines_dir(subdir)
%COUNTMLINES_DIR
%    Count number of lines in the m-files in the
%    specified directory

fprintf('%s:\n',subdir);
X={};
for d=dir([subdir '*.m'])'
    nl=0;
    ncl=0;
    fid=fopen([subdir d.name],'r');
    while ~feof(fid)
        line = fgetl(fid);
        nl=nl+1;
        tok = strtok(line);
        if ~isempty(tok) && tok(1)~='%'
           ncl=ncl+1;
        end
    end
    fclose(fid);
    nl=nl-1;
    X(end+1,1:3)={d.name nl ncl};
    fprintf('%-30s %i (%i)\n',X{end,:});
end
total_nl=sum([X{:,2}]);
total_ncl=sum([X{:,3}]);
fprintf('This directory: %i\n\n',total_nl);
Xt=X';
