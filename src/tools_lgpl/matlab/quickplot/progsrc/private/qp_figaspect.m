function qp_figaspect(fig)
%QP_FIGASPECT Reshapes figure to match paper size.

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
%   $HeadURL$
%   $Id$

fu = get(fig,'units');
pu = get(fig,'paperunits');
set(fig,'units',pu)
pos = get(fig,'position');
sz  = get(fig,'papersize');
npos(3:4) = sz*sqrt(prod(pos(3:4))/prod(sz));
npos(1:2) = pos(1:2)+(pos(3:4)-npos(3:4))/2;
set(fig,'position',npos)

set(fig,'units','pixels')
pos = get(fig,'outerposition');
pxmon = qp_getscreen(fig);
if any(pos(3:4)>pxmon(3:4))
    % figure too big, so make it fit
    ipos      = get(fig,'position');
    bnd       = pos-ipos;
    mxsz      = pxmon(3:4)-bnd(3:4);
    ipos(3:4) = round(min(mxsz./ipos(3:4))*ipos(3:4));
    pos       = ipos+bnd;
end
% the figure fits (now), so now make sure it's on screen
pos(1:2) = max(pos(1:2),pxmon(1:2));
pos(1:2) = min(pos(1:2)+pos(3:4),pxmon(1:2)+pxmon(3:4)) - pos(3:4);
set(fig,'outerposition',pos)

set(fig,'units',fu)
