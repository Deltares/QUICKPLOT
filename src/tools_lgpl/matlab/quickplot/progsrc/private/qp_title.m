function qp_title(hAx,Str,varargin)
%QP_TITLE Set automatic title and parameters.

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
%   $HeadURL: $
%   $Id: $

hTl = get(hAx,'title');
if iscell(Str)
    Str_ = strjoin(Str(:)','\\n{}');
else
    Str_ = Str;
end
setappdata(hAx,'titleauto',Str_)
for i = 1:2:length(varargin)
    setappdata(hAx,['title' varargin{i}],varargin{i+1})
end
if isappdata(hAx,'title')
    Str = getappdata(hAx,'title');
    for i = 1:2:length(varargin)
        Str = qp_strrep(Str,['%' varargin{i} '%'],varargin{i+1});
    end
    if ~isempty(strfind(Str,'\n{}'))
        Str = strsplit(Str,'\\n{}');
    end
end
set(hTl,'string',Str)
