function [BrX,BrY,xUnit,BrL] = get_edge_geometry(FI,csp)
%GET_EDGE_GEOMETRY
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

CSP = FI.Dataset(csp);
atteg = strmatch('edge_geometry',{CSP.Attribute.Name});
veg = strmatch(CSP.Attribute(atteg).Value,{FI.Dataset.Name},'exact');
% node count dimension
VEG = FI.Dataset(veg);
attnc = strmatch('node_count',{VEG.Attribute.Name});
ndc = [];
if ~isempty(attnc)
    ndc = strmatch(VEG.Attribute(attnc).Value,{FI.Dataset.Name},'exact');
    ndcd = strmatch(VEG.Attribute(attnc).Value,{FI.Dimension.Name},'exact');
    if isempty(ndc)
        if ~isempty(ndcd)
            ui_message('error','Geometry %s attribute node_count reads "%s". This is a dimension, but should be a variable.',VEG.Name,VEG.Attribute(attnc).Value)
        else
            ui_message('error','Geometry %s attribute node_count reads "%s". Variable not found.',VEG.Name,VEG.Attribute(attnc).Value)
        end
    end
end
if isempty(ndc)
    attnc = strmatch('part_node_count',{VEG.Attribute.Name});
    ui_message('error','Incorrect attribute "part_node_count" used for specifying the node_count for geometry variable "%s".',VEG.Name)
    ndc = strmatch(VEG.Attribute(attnc).Value,{FI.Dataset.Name},'exact');
end
%
if isempty(FI.Dataset(veg).X)
    error('Missing X coordinate for geometry variable "%s".',VEG.Name)
elseif isempty(FI.Dataset(veg).Y)
    error('Missing Y coordinate for geometry variable "%s".',VEG.Name)
end
[BrX, status] = qp_netcdf_get(FI,FI.Dataset(FI.Dataset(veg).X));
[BrY, status] = qp_netcdf_get(FI,FI.Dataset(FI.Dataset(veg).Y));
[NDC, status] = qp_netcdf_get(FI,FI.Dataset(ndc));
BrX = mat2cell(BrX,NDC,1);
BrY = mat2cell(BrY,NDC,1);
%
xUnit = get_unit(FI.Dataset(FI.Dataset(veg).X));
%
if nargout>3
    attbl = strmatch('edge_length',{CSP.Attribute.Name});
    if isempty(attbl)
        attbl = strmatch('branch_lengths',{CSP.Attribute.Name});
        if ~isempty(attbl)
            ui_message('error','Incorrect attribute "branch_lengths" used for specifying the edge_length for 1D UGRID variable "%s".',CSP.Name)
        end
    end
    if ~isempty(attbl)
        vbl = strmatch(CSP.Attribute(attbl).Value,{FI.Dataset.Name},'exact');
        [BrL, status] = qp_netcdf_get(FI,FI.Dataset(vbl));
    else
        BrL = zeros(size(BrX));
        for i = 1:length(BrX)
            brl = pathdistance(BrX{i},BrY{i}); % Cartesian or spherical?
            BrL(i) = brl(end);
        end
    end
end
