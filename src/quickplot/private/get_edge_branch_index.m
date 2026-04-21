function eBrNr = get_edge_branch_index(FI, meshInfo, nBranches)
%GET_EDGE_BRANCH_INDEX

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

attECO = strmatch('edge_coordinates',{meshInfo.Attribute.Name});
if ~isempty(attECO)
    ecoords = strsplit(meshInfo.Attribute(attECO).Value);
    for iec = 1:length(ecoords)
        i_eBrNr = strmatch(ecoords{iec},{FI.Dataset.Name});
        if isempty(FI.Dataset(i_eBrNr).Attribute)
            ecAtt = {};
        else
            ecAtt = {FI.Dataset(i_eBrNr).Attribute.Name};
        end
        % the branch_id is "the" (so far this search gives a single
        % result ...) auxiliary coordinate variable without units or
        % standard_name specified ...
        if ismember('units',ecAtt) || ismember('standard_name',ecAtt)
            % x-coordinate, y-coordinate, offset
            continue
        else
            break
        end
    end
    % branch_id
    [eBrNr, status] = qp_netcdf_get(FI,FI.Dataset(i_eBrNr));
    if any(eBrNr<0)
        ui_message('warning','Negative branch ids read from "%s". Ignoring this data.',FI.Dataset(i_eBrNr).Name)
        eBrNr = [];
    else
        if isempty(FI.Dataset(i_eBrNr).Attribute)
            istart = [];
        else
            istart = strmatch('start_index',{FI.Dataset(i_eBrNr).Attribute.Name});
        end
        if ~isempty(istart)
            start_index = FI.Dataset(i_eBrNr).Attribute(istart).Value;
        else
            start_index = 0;
        end
        start_index = verify_start_index(istart, start_index, min(eBrNr), max(eBrNr), nBranches, 'branch',FI.Dataset(i_eBrNr).Name);
        eBrNr = eBrNr-start_index+1;
    end
else
    eBrNr = [];
end
