function d = qp_strrep(c,key,val)
%QP_STRREP Replace string with another (case insensitive).
%    MODIFIEDSTR = QP_STRREP(ORIGSTR,OLDSUBSTR,NEWSUBSTR) replaces all 
%    (case insensitive) occurrences of the string OLDSUBSTR within string
%    ORIGSTR with the string NEWSUBSTR.
%
%    See also STRREP, REGEXP, REGEXPREP.

%    Can most likely be replaced by REGEXPREP ignorecase call, but not sure
%    about backward compatibility.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2013 Stichting Deltares.                                     
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
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/trunk/src/tools_lgpl/matlab/quickplot/progsrc/private/qp_createaxes.m $
%   $Id: qp_createaxes.m 3266 2013-12-30 23:01:48Z jagers $

lkey = lower(key);
lenkey = length(key);
%
waschar = ischar(c);
if ischar(c)
    c = {{c}};
end
d = cell(size(c));
if iscell(val)
    val = val(:)';
    val(2,:)={char(13)};
    val(2,end)={''};
    val = [val{:}];
    breakapart = 1;
else
    breakapart = 0;
end
for i = 1:length(c)
    found = 0;
    for j = 1:length(c{i})
        k = strfind(lower(c{i}{j}),lkey);
        for ik = 1:length(k)
            found = 1;
            c{i}{j}(k(ik)+(0:lenkey-1)) = lkey;
        end
    end
    d{i} = strrep(c{i},lkey,val);
    if found && breakapart
        cstr = d{i}(:)';
        cstr(2,:)={char(13)};
        cstr(2,end)={''};
        cstr = [cstr{:}];
        d{i} = splitcellstr(cstr,char(13));
    end
end
%
if waschar
    d = d{1}{1};
end