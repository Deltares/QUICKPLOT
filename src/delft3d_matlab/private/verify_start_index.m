function start_index = verify_start_index(istart, start_index, minIndex, maxIndex, limitIndex, location, variable)
%VERIFY_START_INDEX

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

if isempty(istart)
    if minIndex == 1 && maxIndex == limitIndex
        start_index = 1;
        ui_message('warning','No start_index found on %s.\nDefault value is 0, but data suggest otherwise.\nUsing start_index=1.', variable)
    else
        start_index = 0;
    end
else
    if minIndex-start_index+1 < 1
        error('File specifies start_index %g for %s, but lowest %s index in file is %g.', start_index, variable, location, minIndex)
    elseif maxIndex-start_index+1 > limitIndex
        error('File specifies start_index %g for %s and the largest %s index in file is %g, but the last %s is only %g.', start_index, variable, location, maxIndex, location, limitIndex)
    end
end
start_index = double(start_index);
