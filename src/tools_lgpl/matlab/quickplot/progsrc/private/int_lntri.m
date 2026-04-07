function [xo,yo,po,mo,to,lo,dxt,dyt,out] = int_lntri(xPoly,yPoly,TRI,xMesh,yMesh)
%INT_LNTRI - Line/mesh intersection function.
%
% Syntax
%   [xo,yo,po,mo,to,lo,dxt,dyt,out] = int_lntri(xPoly,yPoly,TRI,xMesh,yMesh,prefer)
%
% Input Arguments
%   xPoly - X-coordinates of polyline
%     vector
%   yPoly - Y-coordinates of polyline
%     vector
%   TRI - connectivity (triangles OR polygons with NaN padding)
%     matrix of size nFaces x 3 or nFaces x maxNumNodes
%   xMesh - X-coordinates of mesh nodes
%     vector | matrix
%   yMesh - Y-coordinates of mesh nodes
%     vector | matrix
%
% OUTPUTS:
%   xo - X-coordinates of intersection points between polyline and mesh
%     vector of size M x 1
%   yo - Y-coordinates of intersection points between polyline and mesh
%     vector of size M x 1
%   po - triangle node indices such that the values vo at intersection
%        points can be derived from the values V at mesh nodes by means of
%        the expression: vo = sum(V(po).*mo,2)
%     matrix of size M x 3
%   mo - barycentric weights
%     matrix of size M x 3
%   to - triangle index for each segment (between intersection points)
%     vector of size M-1 x 1
%   lo - polyline logical position (i + lambda)
%   dxt - X-component of unit vector defining direction of segment
%   dyt - Y-component of unit vector defining direction of segment
%   out - logical flagging segments outside mesh
%     vector of size M-1 x 1

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

%% Check input

if nargin < 5
    error('Too few input arguments.')
end

if numel(xPoly) ~= numel(yPoly)
    error('xPoly and yPoly must be of equal size.')
end
N = numel(xPoly);

if ~all(TRI == round(TRI) | isnan(TRI),'all')
    error('All indices of TRI must be integers or NaN.')
end
if numel(xMesh) ~= numel(yMesh)
    error('xMesh and yMesh must be of equal size.')
end
firstNodes = min(TRI(:));
lastNode = max(TRI(:));
if firstNodes < 1 || lastNode > numel(xMesh)
    error('TRI must only contain integers in range 1:numel(xMesh).')
end
xMesh = xMesh(:);
yMesh = yMesh(:);

%% Convert arrays to vectors
xPoly = xPoly(:);
yPoly = yPoly(:);
xMesh = xMesh(:);
yMesh = yMesh(:);
xyMesh = [xMesh yMesh];

%% Convert polygon mesh to triangles
map2polygon = size(TRI,2) > 3;
if map2polygon
    [TRI,tri2poly] = triangulateConvexFaces(TRI);
end

%% Precompute triangle geometry
[edgeNodes,edgeTRI,edgeLocalNodes] = meshEdges(TRI);

n1 = edgeNodes(:,1);
n2 = edgeNodes(:,2);

x1 = xMesh(n1);      y1 = yMesh(n1);
x2 = xMesh(n2);      y2 = yMesh(n2);

xEdgeNode1 = x1;
yEdgeNode1 = y1;
dxEdge = x2 - x1;
dyEdge = y2 - y1;

%% Pre-allocate arrays

xIntersect = cell(N-1,1);
yIntersect = cell(N-1,1);
lambdaIntersect = cell(N-1,1);
nodesIntersect = cell(N-1,1);
weightsIntersect = cell(N-1,1);
muIntersect = cell(N-1,1);
triNeighbors = cell(N-1,1);
edgeCrossed = cell(N-1,1);

%% Loop through polyline segments

for i = 1:N-1
    [xIntersect{i},yIntersect{i},lambda,mu,edge] = locateIntersections( ...
        xPoly(i), yPoly(i), ...
        xPoly(i+1)-xPoly(i), yPoly(i+1)-yPoly(i), ...
        xEdgeNode1, yEdgeNode1, ...
        dxEdge, dyEdge);
    edgeCrossed{i} = edge;
    muIntersect{i} = mu;
    lambdaIntersect{i} = i + lambda;

    nEdges = length(edge);
    triNodes = NaN(nEdges,3);
    triWeights = NaN(nEdges,3);
    neighbors = cell(nEdges,1);
    for j = 1:length(edge)
        if ~isnan(edge(j))
            triNodes(j,:) = TRI(edgeTRI(edge(j),1),:);
            triWeights(j,:) = 0;
            triWeights(j,edgeLocalNodes(edge(j),:)) = [1-mu(j),mu(j)];
            nb = edgeTRI(edge(j),:);
            neighbors{j} = nb(nb~=0); % for boundary edges remove second index
        end
    end
    nodesIntersect{i} = triNodes;
    weightsIntersect{i} = triWeights;
    triNeighbors{i} = neighbors;
end
xIntersect = cat(1,xIntersect{:},xPoly(N));
yIntersect = cat(1,yIntersect{:},yPoly(N));
lambdaIntersect = cat(1,lambdaIntersect{:},N);
nodesIntersect = cat(1,nodesIntersect{:},[NaN NaN NaN]);
weightsIntersect = cat(1,weightsIntersect{:},[NaN NaN NaN]);
muIntersect = cat(1,muIntersect{:},NaN);
edgeCrossed = cat(1,edgeCrossed{:},NaN);
nodeCrossed = NaN(size(edgeCrossed));
triNeighbors = cat(1,triNeighbors{:},{[]});

%% check for crossing at nodes
% crossing at begin node of edge
crossAtNode = muIntersect == 0;
if any(crossAtNode)
    nodeCrossed(crossAtNode) = edgeNodes(edgeCrossed(crossAtNode),1);
    for i = find(crossAtNode)'
        triNeighbors{i} = find(any(TRI==nodeCrossed(i),2))';
    end
end
% crossing at end node of edge
crossAtNode = muIntersect == 1;
if any(crossAtNode)
    nodeCrossed(crossAtNode) = edgeNodes(edgeCrossed(crossAtNode),2);
    for i = find(crossAtNode)'
        triNeighbors{i} = find(any(TRI==nodeCrossed(i),2))';
    end
end

nIntersections = length(xIntersect);
triSegment = NaN(nIntersections-1,1);
noNeighborDefined = cellfun(@isempty,triNeighbors);
if all(noNeighborDefined)
    % no intersections with points or lines at all
    % search triangle for one point
    [Ti,p] = tsearch_safe(xyMesh,TRI,xi(1),yi(1));
    if ~isnan(Ti) % inside a mesh face
        triSegment(:) = Ti;
        weightsIntersect(1,:) = p;
        nodesIntersect(1,:) = TRI(Ti,:);
        for i = 2:nIntersections
            [~,p] = tsearch_safe(xyMesh,TRI(Ti,:),xi(1),yi(1));
            weightsIntersect(i,:) = p;
            nodesIntersect(i,:) = TRI(Ti,:);
        end
    end
else
    firstIntersection = find(~noNeighborDefined,1);
    for i = firstIntersection:-1:2
        if ~isempty(triNeighbors{i})
            [Ti,p] = tsearch_safe(xyMesh,TRI(triNeighbors{i},:),xIntersect(i-1),yIntersect(i-1));
            if ~isnan(Ti)
                triNeighbors{i-1} = triNeighbors{i}(Ti);
                nodesIntersect(i-1,:) = TRI(triNeighbors{i-1},:);
                weightsIntersect(i-1,:) = p;
            end
        end
    end
end
for i = 1:nIntersections-1
    if isempty(triNeighbors{i+1}) && ~isempty(triNeighbors{i})
        [Ti,p] = tsearch_safe(xyMesh,TRI(triNeighbors{i},:),xIntersect(i+1),yIntersect(i+1));
        if isnan(Ti)
            triangles = [];
        else
            triangles = triNeighbors{i}(Ti);
            nodesIntersect(i+1,:) = TRI(triangles,:);
            weightsIntersect(i+1,:) = p;
            triNeighbors{i+1} = triangles;
        end
    else
        triangles = intersect(triNeighbors{i:i+1});
    end
    if ~isempty(triangles)
        triSegment(i) = min(triangles);
    end
end

xo = xIntersect;
yo = yIntersect;
po = nodesIntersect;
mo = weightsIntersect;
po(isnan(po)) = 1;
lo = lambdaIntersect;
dxt = xIntersect(2:end)-xIntersect(1:end-1);
dyt = yIntersect(2:end)-yIntersect(1:end-1);
mag = hypot(dxt,dyt);
dxt = dxt./mag;
dyt = dyt./mag;
out = isnan(triSegment);
triSegment(out) = 1;
if map2polygon
    to = tri2poly(triSegment);
else
    to = triSegment;
end
end % main function

function [Ti,p] = tsearch_safe(xyMesh,TRI,xp,yp)
warnstate = warning('query','MATLAB:tsearch:DeprecatedFunction');
warning('off','MATLAB:tsearch:DeprecatedFunction')
%
if matlabversionnumber >= 7.14
    [Ti,p] = tsearchn(xyMesh,TRI,[xp,yp]);
else
    Ti = tsearch(xyMesh(:,1),xyMesh(:,2),TRI,xp,yp);
end
%
warning(warnstate);
end

function [xo,yo,lambda,mu,edgeCrossed] = locateIntersections(xi,yi,dxi,dyi,xEdge,yEdge,dxEdge,dyEdge)
%% Determine the mu and lambda coefficients
% for which the vector equality
%   [xi1] + lambda*[dxi] == [xEdge] + mu*[dxEdge]
%   [yi1]          [dyi]    [yEdge]      [dyEdge]
% is satisfied.
%
Det = dxEdge.*dyi-dyEdge.*dxi;
Det(Det==0) = NaN;
mu = (dyi*(xi-xEdge)-dxi*(yi-yEdge)) ./Det;
lambda = (dyEdge.*(xi-xEdge)-dxEdge.*(yi-yEdge))./Det;

%% Determine crossing line segments.
isCrossing = mu>=0;
isCrossing(isCrossing) = mu(isCrossing)<=1;
isCrossing(isCrossing) = (lambda(isCrossing)>=0) & (lambda(isCrossing)<1);

edgeCrossed = find(isCrossing);
[~,sorted] = unique(lambda(edgeCrossed));
edgeCrossed = edgeCrossed(sorted);

mu = mu(edgeCrossed);
lambda = lambda(edgeCrossed);
edgeCrossed = edgeCrossed(:);
mu = mu(:);
lambda = lambda(:);
if isempty(lambda) || lambda(1) > 0
    edgeCrossed = cat(1,NaN,edgeCrossed);
    mu = cat(1,NaN,mu);
    lambda = cat(1,0,lambda);
end
xo = xi + lambda * dxi;
yo = yi + lambda * dyi;
end

% -------------------------------------------------------------------------
% Subfunction: triangulate convex polygon faces
% -------------------------------------------------------------------------
function [TRI,tri2poly] = triangulateConvexFaces(F)
nTriangles = sum(sum(~isnan(F),2)-2);
TRI = zeros(nTriangles,3);
tri2poly = zeros(nTriangles,1);
j = 0;
for i = 1:size(F,1)
    row = F(i,~isnan(F(i,:)));
    if numel(row) == 3
        j = j+1;
        TRI(j,:) = row;
        tri2poly(j) = i;
    else
        v1 = row(1);
        for k = 2:(numel(row)-1)
            j = j+1;
            TRI(j,:) = [v1 row(k) row(k+1)];
            tri2poly(j) = i;
        end
    end
end
end

function [edgeNodes,edgeTRI,edgeLocalNodes] = meshEdges(TRI)
% meshEdges  Extract unique mesh edges from triangular mesh.
%
% [edgeNodes,edgeTRI,edgeLocalNodes] = meshEdges(TRI)
%
% Input Arguments
%   TRI - Triangle connectivity
%     matrix, size nTriangles x 3
%
% Output Arguments
%   edgeNodes - Node indices of each unique edge
%     matrix, size nEdges x 2
%   edgeTRI - Triangles sharing each edge
%     matrix, size nEdges x 2, second column = 0 for boundary edges
%   edgeLocalNodes - Local node indices within first triangle
%     matrix, size nEdges x 2
%
% This function ensures each edge appears ONCE by sorting the node pair.

%% Collect edges from all triangles
% Each row of TRI contributes edges:
%   (1,2), (2,3), (3,1)
edges = [ ...
    TRI(:,[1 2]); ...
    TRI(:,[2 3]); ...
    TRI(:,[3 1]) ...
    ];

% Track triangles associated with each edge
nTRI = size(TRI,1);
triID = repmat(1:nTRI,1,3)';
triNodes = [repelem([1,2,3],nTRI)' repelem([2,3,1],nTRI)'];

%% Normalize edge orientation so duplicates match
[edgesSorted,nodeOrder] = sort(edges,2);

%% Identify unique edges
[edgeNodes,~,ic] = unique(edgesSorted,'rows');

nEdges = size(edgeNodes,1);

%% Map triangles to each unique edge
% each edge belongs to 1 or 2 triangles
edgeTRI = zeros(nEdges,2);
edgeLocalNodes = zeros(nEdges,2);

for k = 1:length(ic)
    e = ic(k);          % edge index
    t = triID(k);       % triangle ID
    if edgeTRI(e,1)==0
        edgeTRI(e,1) = t;
        edgeLocalNodes(e,:) = triNodes(k,nodeOrder(k,:));
    else
        edgeTRI(e,2) = t;
    end
end

end
