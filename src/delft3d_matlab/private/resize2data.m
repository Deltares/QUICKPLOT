function [val,s,z] = resize2data(val,s,z,Ops)
%RESIZE2DATA
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

if isfield(Ops,'extend2edge') && Ops.extend2edge
    [s,z,val] = face2surf(s,z,val);
    return
end
nH = size(val,1);
nV = size(val,2);
if size(s,1)==nH+1
    s = (s(1:end-1,:)+s(2:end,:))/2;
end
if size(s,2)==1
    s = repmat(s,[1,nV]);
elseif size(s,2)==nV+1
    s = (s(:,1:end-1)+s(:,2:end))/2;
end
if size(z,1)==nH+1
    z = (z(1:end-1,:)+z(2:end,:))/2;
elseif size(z,1)==nH-1
    z = (z([1 1:end],:)+z([1:end end],:))/2;
end
if size(z,2)==nV+1
    z = (z(:,1:end-1)+z(:,2:end))/2;
end