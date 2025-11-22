function Ans = process_netcdf_ugrid1d(Ans, meshInfo, FI, eBrNr_function)
%PROCESS_NETCDF_UGRID1D Processes 1D UGRID network data from a NetCDF file.
%   Ans = process_netcdf_ugrid1d(Ans, meshInfo, FI, eBrNr_function) reads and processes
%   mesh node and edge data from a NetCDF file using meshInfo and FI structures.
%
%   Inputs:
%     Ans            - Structure containing mesh node and edge data (fields X, Y, EdgeNodeConnect, etc.).
%     meshInfo       - Structure with mesh metadata and attribute information.
%     FI             - Structure representing the NetCDF file interface, including datasets and attributes.
%     eBrNr_function - Function handle to generate edge branch numbers if not present.
%
%   Outputs:
%     Ans            - Updated structure with processed mesh node indices, offsets, units,
%                      edge branch numbers, and edge geometry coordinates.
%
%   Ans.X contains mesh node branch index
%   Ans.Y contains mesh node offset/chainage
% network is completely stored on each involved partition file, read it
attcsp = strmatch('coordinate_space',{meshInfo.Attribute.Name});
csp = strmatch(meshInfo.Attribute(attcsp).Value,{FI.Dataset.Name},'exact');
[BrX,BrY,xUnit,BrL] = get_edge_geometry(FI,csp);

% Make sure that the branch indices are 1-based
if isempty(FI.Dataset(meshInfo.X).Attribute)
    istart = [];
else
    istart = strmatch('start_index',{FI.Dataset(meshInfo.X).Attribute.Name});
end
if isempty(istart)
    start_index = 0;
else
    start_index = FI.Dataset(meshInfo.X).Attribute(istart).Value;
end
start_index = verify_start_index(istart, start_index, min(Ans.X), max(Ans.X), length(BrX), 'branch', FI.Dataset(meshInfo.X).Name);
Ans.X = Ans.X-start_index+1;

% Get the edge_node_connectivity
e2n = Ans.EdgeNodeConnect;

% If the branch indices for the edges are not given, try to reconstruct
eBrNr = eBrNr_function(length(BrX));
if isempty(eBrNr)
    error('No branch indices found for the edges. Reconstructon algorithm not yet implemented.');
end
%
if ischar(xUnit)
    Ans.XUnits = xUnit;
    Ans.YUnits = xUnit;
end

% Process the indices and offsets and generate the x/y nodes and edge geometries
[Ans.X,Ans.Y,Ans.EdgeGeometry.X,Ans.EdgeGeometry.Y] = branch2xy(BrX,BrY,xUnit,BrL,Ans.X,Ans.Y,eBrNr,e2n);


% -----------------------------------------------------------------------------
function [X,Y,EdgeX,EdgeY] = branch2xy(BrX,BrY,xUnit,BrL,BrNr,BrOffset,eBrNr,EdgeNode)
EdgeX = cell(size(eBrNr));
EdgeY = EdgeX;
X = zeros(size(BrNr));
Y = X;
if strcmp(xUnit,'deg')
    cUnit = {'Geographic'};
else
    cUnit = {};
end
% need to loop over all branches on which at least one edge or one node is
% located. An edge may be located on a branch without nodes if the edge
% matches the whole branch. A node may be located on a branch without edge
% in case of the mesh covers only a part of the network (parallel
% partition).
uBrNr = unique([eBrNr;BrNr]);
doublePoints = false(size(uBrNr));
%
% first check all the nodes such that they are all available when checking
% whether an edge with one node on the branch is at the beginning or the
% end of the branch.
for i = 1:length(uBrNr)
    bN = uBrNr(i);
    bX = BrX{bN};
    bY = BrY{bN};
    Mask = diff(bX)==0 & diff(bY)==0;
    if any(Mask)
        doublePoints(i) = true;
        bX(Mask)=[];
        bY(Mask)=[];
        % Update BrX/Y such that we don't need to perform this check again
        % when processing the edges.
        BrX{bN} = bX;
        BrY{bN} = bY;
    end
    bS = pathdistance(bX,bY,cUnit{:});
    %
    for j = find(BrNr==bN)'
        s  = (BrOffset(j)/BrL(bN))*bS(end);
        if s>bS(end)
            error('Offset %g larger than branch length %g',BrOffset(j),BrL(bN));
        else
            x = interp1(bS,bX,s);
            y = interp1(bS,bY,s);
        end
        X(j) = x;
        Y(j) = y;
    end
end
%
% now we can check all the edges
distmax = 0;
nwarn = 0;
for i = 1:length(uBrNr)
    bN = uBrNr(i);
    bX = BrX{bN};
    bY = BrY{bN};
    bS = pathdistance(bX,bY,cUnit{:});
    %
    for j = find(eBrNr==bN)'
        n = EdgeNode(j,:);
        nBranches = BrNr(n);
        if all(nBranches==bN)
            % both nodes on this branch, select the segment
            s  = (sort(BrOffset(n))/BrL(bN))*bS(end);
            I = bS>s(1) & bS<s(2);
            x = interp1(bS,bX,s);
            y = interp1(bS,bY,s);
            EdgeX{j} = [x(1);bX(I);x(2)];
            EdgeY{j} = [y(1);bY(I);y(2)];
        elseif all(nBranches~=bN)
            % both nodes on other branches, select the whole branch
            EdgeX{j} = bX;
            EdgeY{j} = bY;
            x1 = X(n(1));
            y1 = Y(n(1));
            x2 = X(n(2));
            y2 = Y(n(2));
            dist1 = min(sqrt((bX([1 end])-x1).^2 + (bY([1 end])-y1).^2));
            dist2 = min(sqrt((bX([1 end])-x2).^2 + (bY([1 end])-y2).^2));
            if min(dist1) > 0 && min(dist2) > 0
                dist = max(min(dist1),min(dist2));
                nwarn = nwarn + 1;
                %if dist > distmax
                    msg = {'The edge %i connecting node %i to %i is supposed to lie on branch %i,\nbut both nodes don''t seem to lie on that branch (mismatch = %g).\n',j,n(1),n(2),bN,dist};
                    distmax = dist;
                        fprintf(msg{:});
                %end
            elseif min(dist1) > 0
                dist = min(dist1);
                nwarn = nwarn + 1;
                %if dist > distmax
                    msg = {'The edge %i connecting node %i to %i is supposed to lie on branch %i,\nbut node %i doesn''t seem to lie on that branch (mismatch = %g).\n',j,n(1),n(2),bN,n(1),dist};
                    distmax = dist;
                        fprintf(msg{:});
                %end
            elseif min(dist2) > 0
                dist = min(dist2);
                nwarn = nwarn + 1;
                %if dist > distmax
                    msg = {'The edge %i connecting node %i to %i is supposed to lie on branch %i,\nbut node %i doesn''t seem to lie on that branch (mismatch = %g).\n',j,n(1),n(2),bN,n(2),dist};
                    distmax = dist;
                        fprintf(msg{:});
                %end
            end
        else
            % one node on this branch, one on another branch
            if nBranches(1)==bN
                n1 = n(1);
                n2 = n(2);
            else
                n2 = n(1);
                n1 = n(2);
            end
            s  = (BrOffset(n1)/BrL(bN))*bS(end);
            x = interp1(bS,bX,s);
            y = interp1(bS,bY,s);
            x2 = X(n2);
            y2 = Y(n2);
            dist = sqrt((bX([1 end])-x2).^2 + (bY([1 end])-y2).^2);
            if dist(1) < dist(2)
                % second node seems closer to the beginning of the branch
                I = bS<s;
                EdgeX{j} = [bX(I);x];
                EdgeY{j} = [bY(I);y];
                if dist(1) > 0
                    nwarn = nwarn + 1;
                    %if dist(1) > distmax
                        msg = {'The edge %i connecting node %i to %i is supposed to lie on branch %i,\nbut node %i doesn''t seem to lie on that branch (mismatch = %g).\n',j,n(1),n(2),bN,n2,dist(1)};
                        distmax = dist(1);
                        fprintf(msg{:});
                    %end
                end
            else
                % second node seems closer to the end node of the branch
                I = bS>s;
                EdgeX{j} = [x;bX(I)];
                EdgeY{j} = [y;bY(I)];
                if dist(2) > 0
                    nwarn = nwarn + 1;
                    %if dist(2) > distmax
                        msg = {'The edge %i connecting node %i to %i is supposed to lie on branch %i,\nbut node %i doesn''t seem to lie on that branch (mismatch = %g).\n',j,n(1),n(2),bN,n2,dist(2)};
                        distmax = dist(2);
                        fprintf(msg{:});
                    %end
                end
            end
        end
    end
end
if distmax > eps(single(1))
    msg1 = sprintf('Detected %i branch mismatches. Largest mismatch occurred at:',nwarn);
    msg2 = sprintf(msg{:});
    ui_message('warning',{msg1,msg2});
end
if any(doublePoints)
    if sum(doublePoints)==1
        ui_message('warning','Double geometry points encountered on branch: %i',find(doublePoints))
    else
        ui_message('warning','Double geometry points encountered on branches: %s',vec2str(find(doublePoints),'nobrackets'))
    end
end
