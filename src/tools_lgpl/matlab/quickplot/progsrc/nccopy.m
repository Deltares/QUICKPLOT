function nccopy(filename_source, filename_target, copyVars, subsetDims)
%NCCOPY - Copy data from one NetCDF file to a new NetCDF file.
%   This function copies data from a NetCDF file to a new NetCDF file. The
%   user can control which variables (and dimensions) are copied. The list
%   of variables (and dimensions) that will actually be copied is
%   automatically extended by checking the attributes of the selected
%   variables.
%
%   Syntax
%     NCCOPY(sourceFileName, targetFileName, copyVars, subsetDims)
%
%   Input Arguments
%     sourceFileName - Name of the source NetCDF file
%     targetFileName - Name of the new NetCDF file
%     copyVars - Names of the variables to be copied (default all)
%       '*' (all) | one variable name | cell array of variable names
%     subsetDims - N x 2 cell array where (default N = 0)
%       subsetDims{i,1} Name of a dimension
%       subsetDims{i,2} Vector of dimension indices to be kept
%       if the subsetDims{i,1} name matches the face dimension of a 2D
%       UGRID mesh then all mesh dimensions will be automatically reduced
%       to the selected area.
%
%   Notes
%     The code loads arrays up to 10 GB temporarily in memory.
%     Dimension filtering does not yet work for arrays larger than 10 GB.
%
%   See also NETCDF, NCDIFF

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2025 Stichting Deltares.                                     
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

followAttributes = true;
ncInfo = ncinfo(filename_source);

if nargin<4 || isempty(subsetDims)
    subsetDims = cell(0,2);
end

varNames = {ncInfo.Variables.Name};
if nargin<3 || isequal(copyVars,'*')
    copyVars = varNames;
elseif ischar(copyVars)
    copyVars = {copyVars};
end

doCopyVar = flag_variables_to_be_copied(ncInfo,copyVars,followAttributes);
doCopyDim = flag_dimensions_to_be_copied(ncInfo,doCopyVar);

err = [];
mapVar = cell(0,2);
nc_source = netcdf.open(filename_source,'NOWRITE');
try
    if ~isempty(subsetDims)
        [subsetDims,mapVar] = process_ugrid_dims(ncInfo,nc_source,doCopyDim,subsetDims,mapVar);
    end
    nc_target = netcdf.create(filename_target, bitor(netcdf.getConstant('NETCDF4'),netcdf.getConstant('CLOBBER')));
    try
        [dimId,dimLength,subsetDims] = copy_dimensions(ncInfo,nc_target,doCopyDim,subsetDims);
        varId = copy_variables(ncInfo,nc_target,doCopyVar,dimId);
        copy_global_attributes(ncInfo,nc_target);
        copy_data(ncInfo,nc_source,nc_target,doCopyVar,varId,dimLength,subsetDims,mapVar)
    catch err
    end
    netcdf.close(nc_target)
catch err
end
netcdf.close(nc_source)

if ~isempty(err)
    rethrow(err)
end


function doCopyVar = flag_variables_to_be_copied(ncInfo,copyVars,followAttributes)
varNames = {ncInfo.Variables.Name};
doCopyVar = ismember(varNames,copyVars);
nVariables = length(varNames);

if followAttributes
    newCopy = doCopyVar;
    while any(newCopy)
        copyAsWell = false(1,nVariables);
        for i = 1:nVariables
            if ~doCopyVar(i)
                searchVarName = ncInfo.Variables(i).Name;
                for j = 1:nVariables
                    if newCopy(j)
                        atts = ncInfo.Variables(j).Attributes;
                        if ~isempty(atts)
                            for ia = 1:numel(atts)
                                if ischar(atts(ia).Value) && ~isempty(strfind(atts(ia).Value, searchVarName))
                                    copyAsWell(i) = true;
                                    break
                                end
                            end
                        end
                    end
                    if copyAsWell(i)
                        break
                    end
                end
            end
        end
        newCopy = copyAsWell;
        doCopyVar(copyAsWell) = true;
    end
end


function doCopyDim = flag_dimensions_to_be_copied(ncInfo,doCopyVar)
dimNames = {ncInfo.Dimensions.Name};
doCopyDim = false(size(dimNames));
for i = find(doCopyVar)
    dims = ncInfo.Variables(i).Dimensions;
    if isstruct(dims)
        doCopyDim = doCopyDim | ismember(dimNames,{ncInfo.Variables(i).Dimensions.Name});
    end
end


function [dimId,newDimLength,subsetDims] = copy_dimensions(ncInfo,nc_target,doCopyDim,subsetDims)
dimNames = {ncInfo.Dimensions.Name};
dimLength = [ncInfo.Dimensions.Length];
newDimLength = zeros(size(dimLength));
dimId = -ones(size(dimNames));
for i = find(doCopyDim)
    iSubset = strcmp(dimNames{i},subsetDims(:,1));
    if any(iSubset)
        subset = subsetDims{iSubset,2};
        if any(subset<1) || any(subset>dimLength(i)) || any(subset~=round(subset))
            error('Invalid subset index for dimension %s.',dimNames{i})
        else
            subsetDims{iSubset,6} = subset - min(subset) + 1;
            subset = sort(subset);
            subsetDims{iSubset,3} = subset(1);
            count = subset(end) - subset(1) + 1;
            subsetDims{iSubset,4} = count;
            subsetDims{iSubset,5} = 1;
            if count > 1
                subsetSteps = diff(subset);
                if min(subsetSteps) > 1
                    div = subsetSteps(1);
                    for is = 2:length(subsetSteps)
                        div = gcd(div,subsetSteps(is));
                        if div == 1
                            break
                        end
                    end
                    if div > 1
                        subsetDims{iSubset,5} = div;
                        subsetDims{iSubset,4} = (count-1)/div + 1;
                        subsetDims{iSubset,6} = (subsetDims{iSubset,6}-1)/div + 1;
                    end
                end
            end
        end
        newDimLength(i) = length(subset);
    else
        newDimLength(i) = dimLength(i);
    end
    if ncInfo.Dimensions(i).Unlimited
        dimId(i) = netcdf.defDim(nc_target, dimNames{i}, netcdf.getConstant('UNLIMITED'));
    else
        dimId(i) = netcdf.defDim(nc_target, dimNames{i}, newDimLength(i));
    end
end


function varId = copy_variables(ncInfo,nc_target,doCopyVar,dimId)
varNames = {ncInfo.Variables.Name};
dimNames = {ncInfo.Dimensions.Name};
varId = -ones(size(varNames));
for i = find(doCopyVar)
    switch ncInfo.Variables(i).Datatype
        case 'int32'
            xtype = netcdf.getConstant('NC_INT');
        case 'double'
            xtype = netcdf.getConstant('NC_DOUBLE');
        case 'single'
            xtype = netcdf.getConstant('NC_FLOAT');
        case 'char'
            xtype = netcdf.getConstant('NC_CHAR');
        otherwise
            fprintf('Datatype "%s" not yet implemented.',ncInfo.Variables(i).Datatype);
    end

    dims = ncInfo.Variables(i).Dimensions;
    if isempty(dims)
        varDimIds = [];
    else
        varDims = {ncInfo.Variables(i).Dimensions.Name};
        varDimIds = zeros(size(varDims));
        for id = 1:numel(varDims)
            varDimIds(id) = dimId(strcmp(varDims{id},dimNames));
        end
    end

    varId(i) = netcdf.defVar(nc_target, varNames{i}, xtype,varDimIds);
    if isfield(ncInfo.Variables(i), 'ChunkSize') && ~isempty(ncInfo.Variables(i).ChunkSize)
        netcdf.defVarChunking(nc_target, varId(i), 'CHUNKED', ncInfo.Variables(i).ChunkSize)
    end
    if isfield(ncInfo.Variables(i), 'DeflateLevel') && ~isempty(ncInfo.Variables(i).DeflateLevel)
        netcdf.defVarDeflate(nc_target, varId(i), ncInfo.Variables(i).Shuffle, true, ncInfo.Variables(i).DeflateLevel)
    end

    Atts = ncInfo.Variables(i).Attributes;
    copy_attributes(Atts,nc_target,varId(i))
end


function copy_global_attributes(ncInfo,nc_target)
Atts = ncInfo.Attributes;
glob = netcdf.getConstant('NC_GLOBAL');
copy_attributes(Atts,nc_target,glob)


function copy_attributes(Atts,nc_target,varId)
if ~isempty(Atts)
    for ia = 1:length(Atts)
        if isequal(Atts(ia).Name,'_FillValue')
            netcdf.defVarFill(nc_target, varId, false, Atts(ia).Value)
        else
            netcdf.putAtt(nc_target, varId, Atts(ia).Name, Atts(ia).Value)
        end
    end
end


function copy_data(ncInfo,nc_source,nc_target,doCopyVar,varId,dimLength,subsetDims,mapVar)
dimNames = {ncInfo.Dimensions.Name};
for i = find(doCopyVar)
    varInfo = ncInfo.Variables(i);
    sz = varInfo.Size;
    switch varInfo.Datatype
        case 'int32'
            nbytes = 4;
            fillValue = netcdf.getConstant('NC_FILL_INT');
        case 'double'
            nbytes = 8;
            fillValue = netcdf.getConstant('NC_FILL_DOUBLE');
        case 'single'
            nbytes = 4;
            fillValue = netcdf.getConstant('NC_FILL_FLOAT');
        case 'char'
            nbytes = 1;
            fillValue = netcdf.getConstant('NC_FILL_CHAR');
        otherwise
            fprintf('Datatype "%s" not yet implemented.',varInfo.Datatype);
    end
    tot_nbytes = prod(sz) * nbytes;

    dims = varInfo.Dimensions;
    remapVar = strcmp(varInfo.Name,mapVar(:,1));
    if any(remapVar)
        remap = mapVar{remapVar,2};
    else
        remap = [];
    end

    ffAttribute = strcmp('_FillValue',{varInfo.Attributes.Name});
    if any(ffAttribute)
        fillValue = varInfo.Attributes(ffAttribute).Value;
    end

    args = {};
    doSubset = {};
    if ~isempty(dims)
        varDims = {dims.Name};
        nVarDims = numel(varDims);
        varSubsetDims = intersect(varDims,subsetDims(:,1));
        if ~isempty(varSubsetDims)
            % start, count, stride
            start = zeros(1,nVarDims);
            count = ones(1,nVarDims);
            stride = ones(1,nVarDims);
            doSubset = cell(1,nVarDims);
            for ivd = 1:nVarDims
                if ismember(varDims{ivd},varSubsetDims)
                    isv = strcmp(varDims{ivd},subsetDims(:,1));
                    start(ivd) = subsetDims{isv,3}-1;
                    count(ivd) = subsetDims{isv,4};
                    stride(ivd) = subsetDims{isv,5};
                    doSubset{ivd} = subsetDims{isv,6};
                else
                    count(ivd) = dimLength(strcmp(varDims{ivd},dimNames));
                    doSubset{ivd} = ':';
                end
            end
            args = {start, count, stride};
        end
    else
        nVarDims = 0;
    end

    % if less than 10 GB, just read and write
    max_nbytes = 1e10;
    if tot_nbytes < max_nbytes
        % read data
        data = netcdf.getVar(nc_source, i-1, args{:});
        % subset
        if ~isempty(doSubset)
            data = data(doSubset{:});
        end
        % remap
        if ~isempty(remap)
            valid = data ~= fillValue;
            data(valid) = remap(data(valid));
        end
        % write data
        if nVarDims > 0
            % set start, count, stride for writing
            start = zeros(1,nVarDims);
            count = size(data,1:nVarDims);
            netcdf.putVar(nc_target, varId(i), start, count, data)
        else
            netcdf.putVar(nc_target, varId(i), data)
        end
    else
        % process in chunks ... this option does not yet work
        % together with dimension filtering ...
        lastDim = length(sz);
        dimLength = sz(lastDim);
        if isfield(varInfo, 'ChunkSize') && ~isempty(varInfo.ChunkSize)
            chunkSize = varInfo.ChunkSize(lastDim);
        else
            chunkSize = max(1, floor(max_nbytes/prod(sz(1:end-1))/nbytes));
        end
        start = zeros(1,nVarDims);
        count = sz;
        stride = ones(1,nVarDims);

        fprintf('Chunking %s: ',varInfo.Name);
        nChunks = ceil(dimLength/chunkSize);
        for chunk = 1:nChunks
            fprintf('%i ',nChunks - chunk);
            start(end) = (chunk-1) * chunkSize;
            count(end) = min(chunkSize, sz(end)-start(end));

            % read data
            data = netcdf.getVar(nc_source, i-1, start, count, stride);
            % write data
            netcdf.putVar(nc_target, varId(i), start, count, data)
        end
        fprintf('\n');
    end
end


function [subsetDims,mapVar] = process_ugrid_dims(ncInfo,nc_source,doCopyDim,subsetDims,mapVar)
dimNames = {ncInfo.Dimensions.Name};
additionalSubsetDims = cell(2*size(subsetDims,1),2);
nAdditional = 0;
for i = 1:length(ncInfo.Variables)
    Atts = ncInfo.Variables(i).Attributes;
    if ~isempty(Atts)
        cfrAttribute = strcmp('cf_role',{Atts.Name});
        if any(cfrAttribute)
            cfrole = Atts(cfrAttribute).Value;
            if strcmp(cfrole,'mesh_topology')
                [faceDim,edgeDim,nodeDim] = get_ugrid_dimensions(Atts);
                if doCopyDim(strcmp(faceDim,dimNames))
                    fssd = strcmp(faceDim,subsetDims(:,1));
                    if any(fssd)
                        faces = subsetDims{fssd,2};
                        [edges,nodes,mapVar] = derive_edges_and_nodes(ncInfo,nc_source,i,faces,mapVar);
                        additionalSubsetDims(nAdditional+1,:) = {edgeDim,edges};
                        additionalSubsetDims(nAdditional+2,:) = {nodeDim,nodes};
                        nAdditional = nAdditional + 2;
                    end
                end
            end
        end
    end
end
if nAdditional > 0
    subsetDims = cat(1,subsetDims,additionalSubsetDims);
end


function [faceDim,edgeDim,nodeDim] = get_ugrid_dimensions(Atts)
AttNames = {Atts.Name};
td = strcmp('topology_dimension',AttNames);
dim = Atts(td).Value;
if dim >= 2
    fd = strcmp('face_dimension',AttNames);
    faceDim = Atts(fd).Value;
else
    faceDim = '';
end
ed = strcmp('edge_dimension',AttNames);
edgeDim = Atts(ed).Value;
nd = strcmp('node_dimension',AttNames);
nodeDim = Atts(nd).Value; 


function [edges,nodes,mapVar] = derive_edges_and_nodes(ncInfo,nc_source,i_ugrid,faces,mapVar)
varNames = {ncInfo.Variables.Name};
ugrid = ncInfo.Variables(i_ugrid);
Atts = ugrid.Attributes;
AttNames = {Atts.Name};
fncAttribute = strcmp('face_node_connectivity',AttNames);
if any(fncAttribute)
    fnc_name = Atts(fncAttribute).Value;
    i_fnc = find(strcmp(fnc_name,varNames));
else
    i_fnc = 0;
end
encAttribute = strcmp('edge_node_connectivity',AttNames);
if any(encAttribute)
    enc_name = Atts(encAttribute).Value;
    i_enc = find(strcmp(enc_name,varNames));
else
   i_enc = 0;
end
fecAttribute = strcmp('face_edge_connectivity',AttNames);
if any(fecAttribute)
    fec_name = Atts(fecAttribute).Value;
    i_fec = find(strcmp(fec_name,varNames));
else
    i_fec = 0;
end
efcAttribute = strcmp('edge_face_connectivity',AttNames);
if any(efcAttribute)
    efc_name = Atts(efcAttribute).Value;
    i_efc = find(strcmp(efc_name,varNames));
else
    i_efc = 0;
end
%
fnc = netcdf.getVar(nc_source, i_fnc-1);
nodes = unique(fnc(:,faces))';
efc = netcdf.getVar(nc_source, i_efc-1);
edges = find(any(ismember(efc,faces),1));
%
nFaces = size(fnc,2);
faceRenum = repmat(-999,1,nFaces);
faceRenum(faces) = 1:length(faces);
nEdges = size(efc,2);
edgeRenum = repmat(-999,1,nEdges);
edgeRenum(edges) = 1:length(edges);
nNodes = max(fnc(:));
nodeRenum = repmat(-999,1,nNodes);
nodeRenum(nodes) = 1:length(nodes);
%
if i_fnc > 0
    mapVar(end+1,:) = {fnc_name nodeRenum};
end
if i_enc > 0
    mapVar(end+1,:) = {enc_name nodeRenum};
end
if i_fec > 0
    mapVar(end+1,:) = {fec_name edgeRenum};
end
if i_efc > 0
    mapVar(end+1,:) = {efc_name faceRenum};
end