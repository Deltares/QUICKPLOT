function ColLabels = getcollabels(ncol,Cmnt)
%getcollabels Extracts column labels from a cell string variable.
%   This function searches a cell string argument for lines matching
%   [.] column <number> [: or =] string
%   where [.] matches any first character (typically a comment line marker
%   such as # or %), <number> an integer representing the column number,
%   and [: or =] either a colon or equal-sign. Lines for which the number
%   exceeds the number of columns are ignored.
%
%   Syntax
%     columns = getcollabels(nColumns,text)
%
%   Input Arguments
%     nColumns - Number of columns to return
%     text - Cell string containing a header/comment block possibly
%       containing lines matching the format described above
%
%   Output Argument
%     columns - Cell array of length nColumns

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

ColLabels = repmat({''},1,ncol);
if ~isempty(Cmnt)
    for i = 1:length(Cmnt)
        [Tk,Rm] = strtok(Cmnt{i});
        if ~strcmpi(Tk,'column')
            % if the first token isn't "column" try ignoring the first
            % character; it might be a comment character.
            [Tk,Rm] = strtok(Cmnt{i}(2:end));
        end
        if (length(Cmnt{i})>10) && strcmpi(Tk,'column')
            [a,c,~,idx] = sscanf(Rm,'%i%*[ :=]%c',2);
            if (c==2) && a(1)<=ncol && a(1)>0
                ColLabels{a(1)} = deblank(Rm(idx-1:end));
            end
        end
    end
end