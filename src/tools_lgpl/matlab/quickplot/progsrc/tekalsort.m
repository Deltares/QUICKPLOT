function varargout = tekalsort(varargin)
%TEKALSORT  Sort tekal data structure.
%
%   Sort tekal data structure alphabetically
%
%   Syntax:
%   output = tekalsort(input)
%
%   Example:
%   input  = tekal('read' ,'Dredge.pol');
%   output = tekalsort(input);
%   tekal('write',output,'Dredge_sort.pol');
%
%   See also tekal

%% Copyright notice
%   --------------------------------------------------------------------
%   Copyright (C) 2013 <COMPANY>
%       ottevan
%
%       <EMAIL>
%
%       <ADDRESS>
%
%   This library is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This library is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this library.  If not, see <http://www.gnu.org/licenses/>.
%   --------------------------------------------------------------------

% This tool is part of <a href="http://www.OpenEarth.eu">OpenEarthTools</a>.
% OpenEarthTools is an online collaboration to share and manage data and
% programming tools in an open source, version controlled environment.
% Sign up to recieve regular updates of this function, and to contribute
% your own tools.

%% Version <http://svnbook.red-bean.com/en/1.5/svn.advanced.props.special.keywords.html>
% Created: 04 Nov 2013
% Created with Matlab version: 8.1.0.604 (R2013a)

% $Id: $
% $Date: $
% $Author: $
% $Revision: $
% $HeadURL: $
% $Keywords: $

%%
if nargin==0;
    return
end
if nargin==1;
   input = varargin{1};
end 

%% code
for k = 1:length(input.Field);
   Namelist{k} = input.Field(k).Name;
end    
[y,idx] = sort(Namelist);
for k = 1:length(input.Field);
   output.Field(k) = input.Field(idx(k));
end
if nargout<=1;
   varargout = {output};
end

