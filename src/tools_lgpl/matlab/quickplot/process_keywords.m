function process_keywords(basedir, varargin)
%PROCESS_KEYWORDS Replace keywords by strings
%    PROCESS_KEYWORDS(BaseDir,KeywordValues) recursively processes all .m, .c
%    and .cpp files in the directory BaseDir and below, replacing the keywords
%    specified as fields in KeywordValues by the string value assigned to those
%    fields.

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

d = dir(basedir);
for i = 1:length(d)
    if d(i).isdir
        if strcmp(d(i).name,'.') || strcmp(d(i).name,'..')
            %
            % don't process this directory or higher directory
            %
            continue
        end
        %
        % recursive processing of child directories
        %
        svnstripfile([basedir filesep d(i).name],varargin{:})
    else
        [p,f,e] = fileparts(d(i).name);
        if ~strcmp(e,'.m') && ~strcmp(e,'.c') && ~strcmp(e,'.cpp') && ~strcmp(e,'.ini')
            %
            % only process m, c and cpp files
            %
            continue
        end
        %
        % read file
        %
        filename = [basedir filesep d(i).name];
        fid = fopen(filename,'r');
        c = {};
        while 1
            line = fgetl(fid);
            if ~ischar(line)
                break
            end
            c{end+1} = line;
        end
        fclose(fid);
        %
        % process the keywords
        %
        ValueOf = vararin{1};
        Keywords = fieldnames(ValueOf);
        for l = 1:length(c)
            for k = 1:length(Keywords)
                keyword = Keywords{k};
                j = strfind(c{l},['$' keyword]);
                if ~isempty(j)
                    j2 = strfind(c{l},'$');
                    j2 = min(j2(j2>j));
                    c{l} = [c{l}(1:j-1) ValueOf.(keyword) c{l}(j2+1:end)];
                end
            end
        end
        %
        fid = fopen(filename,'w');
        fprintf(fid,'%s\n',c{:});
        fclose(fid);
    end
end