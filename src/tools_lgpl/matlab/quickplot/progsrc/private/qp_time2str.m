function timeString = qp_time2str(timeValue,timeType)
%qp_time2str Convert time double to cell of time strings.
%   Converts a time value to a time string in a way very similar to
%   date2str, but this routine supports the QUICKPLOT specific time types.
%
%   Syntax:
%     timeStr = qp_time2str(timeValue,timeType)
%
%   Input Arguments
%     timeValue - Input time value
%     timeType - QUICKPLOT time type
%       1 or 2 : date number converted to 'dd-MMM-yyyy HH:mm:ss'
%       3 or 4 : relative date number converted to '"day" %i HH:mm:ss'
%       5 or 6 : time step converted to '%i' ('%f' if fractional)
%       7 or 8 : seconds converted to '%f "s"'
%       9 or 10: clock time converted to 'HH:mm:ss'
%
%   Output Arguments
%     timeStr - Output time string
%
%   See also DATESTR, DATETIME.

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

nTimes = length(timeValue);
switch timeType
    case {1,2} % day-month-year h:m:s
        % 1: discrete, 2: continuous
        if all(timeValue>0)
            datefmt = 'dd-MMM-yyyy HH:mm:ss';
        else
            datefmt = 'dd-MMM-yyyy G HH:mm:ss';
        end
        Date = datetime(timeValue,'ConvertFrom','datenum');
        timeString = char(Date,datefmt);
    case {3,4} % day h:m:s
        % 3: discrete, 4: continuous
        timeString=cat(2,repmat('day ',nTimes,1),num2str(floor(timeValue)), ...
            repmat(' ',nTimes,1),datestr(rem(timeValue,1),13));
    case {5,6} % i
        % 5: discrete, 6: continuous
        timeString=num2str(timeValue);
    case {7,8} % seconds
        % 7: discrete, 8: continuous
        timeString=cat(2,num2str(timeValue*24*3600),repmat(' s',nTimes,1));
    case {9,10} % h:m:s
        % 9: discrete, 10: continuous
        h = timeValue*24;
        m = rem(h,1)*60;
        s = round(rem(m,1)*60);
        m = floor(m);
        i = s==60;
        if any(i)
            m(i) = m(i)+1;
            s(i) = 0;
        end
        h = floor(h);
        i = m==60;
        if any(i)
            h(i) = h(i)+1;
            m(i) = 0;
        end
        T = [h(:) m(:) s(:)]';
        timeString = multiline(sprintf('%2i:%02i:%02i\n',T));
        timeString(end,:) = [];
    otherwise
        timeString = '';
end
