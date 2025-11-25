function [BrX,BrY,xUnit,BrL] = get_edge_geometry(FI,csp)
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
